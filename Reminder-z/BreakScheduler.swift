import AppKit
import Combine
import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class BreakScheduler: ObservableObject {
    enum SessionState {
        case working
        case onBreak
    }

    private enum DefaultsKey {
        static let breakIntervalMinutes = "breakIntervalMinutes"
        static let breakDurationSeconds = "breakDurationSeconds"
        static let breakMessage = "breakMessage"
        static let fadeInMaskWindow = "fadeInMaskWindow"
        static let showTimeInMenuBar = "showTimeInMenuBar"
        static let launchAtStartup = "launchAtStartup"
    }

    @Published var breakIntervalMinutes: Int {
        didSet {
            let clampedValue = Self.clamp(breakIntervalMinutes, min: 1, max: 180)
            if clampedValue != breakIntervalMinutes {
                breakIntervalMinutes = clampedValue
                return
            }

            defaults.set(breakIntervalMinutes, forKey: DefaultsKey.breakIntervalMinutes)
            if sessionState == .working {
                resetSession()
            }
        }
    }

    @Published var breakDurationSeconds: Int {
        didSet {
            let clampedValue = Self.clamp(breakDurationSeconds, min: 5, max: 300)
            if clampedValue != breakDurationSeconds {
                breakDurationSeconds = clampedValue
                return
            }

            defaults.set(breakDurationSeconds, forKey: DefaultsKey.breakDurationSeconds)
            if sessionState == .onBreak {
                remainingSeconds = breakDurationSeconds
                refreshOverlay()
            }
        }
    }

    @Published var breakMessage: String {
        didSet {
            defaults.set(breakMessage, forKey: DefaultsKey.breakMessage)
            refreshOverlay()
        }
    }

    @Published var fadeInMaskWindow: Bool {
        didSet {
            defaults.set(fadeInMaskWindow, forKey: DefaultsKey.fadeInMaskWindow)
        }
    }

    @Published var showTimeInMenuBar: Bool {
        didSet {
            defaults.set(showTimeInMenuBar, forKey: DefaultsKey.showTimeInMenuBar)
        }
    }

    @Published var launchAtStartup: Bool {
        didSet {
            defaults.set(launchAtStartup, forKey: DefaultsKey.launchAtStartup)
            configureLaunchAtLogin(enabled: launchAtStartup)
        }
    }

    @Published private(set) var isPaused = false
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var sessionState: SessionState = .working

    private let defaults: UserDefaults
    private let overlayController = BreakOverlayController()
    private var countdownTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedInterval = defaults.object(forKey: DefaultsKey.breakIntervalMinutes) as? Int ?? 20
        let storedDuration = defaults.object(forKey: DefaultsKey.breakDurationSeconds) as? Int ?? 20

        breakIntervalMinutes = Self.clamp(storedInterval, min: 1, max: 180)
        breakDurationSeconds = Self.clamp(storedDuration, min: 5, max: 300)
        breakMessage = defaults.string(forKey: DefaultsKey.breakMessage) ?? "Look away from the screen and relax."
        fadeInMaskWindow = defaults.object(forKey: DefaultsKey.fadeInMaskWindow) as? Bool ?? true
        showTimeInMenuBar = defaults.object(forKey: DefaultsKey.showTimeInMenuBar) as? Bool ?? false
        launchAtStartup = defaults.object(forKey: DefaultsKey.launchAtStartup) as? Bool ?? false
        remainingSeconds = Self.clamp(storedInterval, min: 1, max: 180) * 60

        startCountdown()
    }

    deinit {
        countdownTask?.cancel()
    }

    var isOnBreak: Bool {
        sessionState == .onBreak
    }

    var progress: Double {
        let total = Double(currentSessionTotalSeconds)
        guard total > 0 else { return 0 }
        return min(max(1 - Double(remainingSeconds) / total, 0), 1)
    }

    var currentSessionTotalSeconds: Int {
        switch sessionState {
        case .working:
            breakIntervalMinutes * 60
        case .onBreak:
            breakDurationSeconds
        }
    }

    var statusText: String {
        if isPaused {
            return "Timer paused"
        }

        switch sessionState {
        case .working:
            return "After work, take a \(breakDurationSeconds) second break"
        case .onBreak:
            return "Break in progress"
        }
    }

    var menuBarTitle: String {
        showTimeInMenuBar ? formattedRemainingTime : "Break"
    }

    var formattedRemainingTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func resetSession() {
        isPaused = false
        remainingSeconds = currentSessionTotalSeconds
        refreshOverlay()
    }

    func skipSession() {
        isPaused = false

        switch sessionState {
        case .working:
            beginBreak()
        case .onBreak:
            endBreak()
        }
    }

    func togglePause() {
        isPaused.toggle()
    }

    private func startCountdown() {
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                tick()
            }
        }
    }

    private func tick() {
        guard !isPaused else { return }

        guard remainingSeconds > 0 else {
            advanceSession()
            return
        }

        remainingSeconds -= 1
        refreshOverlay()

        if remainingSeconds == 0 {
            advanceSession()
        }
    }

    private func advanceSession() {
        switch sessionState {
        case .working:
            beginBreak()
        case .onBreak:
            endBreak()
        }
    }

    private func beginBreak() {
        isPaused = false
        sessionState = .onBreak
        remainingSeconds = breakDurationSeconds

        overlayController.show(
            message: breakMessage,
            remainingSeconds: remainingSeconds,
            fadeIn: fadeInMaskWindow
        ) { [weak self] in
            Task { @MainActor in
                self?.skipSession()
            }
        }
    }

    private func endBreak() {
        overlayController.hide()
        isPaused = false
        sessionState = .working
        remainingSeconds = breakIntervalMinutes * 60
    }

    private func refreshOverlay() {
        guard sessionState == .onBreak else { return }
        overlayController.update(message: breakMessage, remainingSeconds: remainingSeconds)
    }

    private func configureLaunchAtLogin(enabled: Bool) {
        guard #available(macOS 13.0, *) else { return }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Failed to update launch at login state: \(error.localizedDescription)")
        }
    }

    private static func clamp(_ value: Int, min minValue: Int, max maxValue: Int) -> Int {
        Swift.min(Swift.max(value, minValue), maxValue)
    }
}
