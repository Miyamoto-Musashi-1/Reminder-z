import AppKit
import SwiftUI

private final class BreakOverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class BreakOverlayController {
    private var windows: [NSWindow] = []
    private var hostingViews: [NSHostingView<BreakOverlayView>] = []
    private var currentMessage = ""
    private var currentRemainingSeconds = 0
    private var skipAction: (() -> Void)?

    func show(message: String, remainingSeconds: Int, fadeIn: Bool, onSkip: @escaping () -> Void) {
        currentMessage = message
        currentRemainingSeconds = remainingSeconds
        skipAction = onSkip

        rebuildWindows()
        NSApp.activate(ignoringOtherApps: true)

        for (index, pair) in zip(windows.indices, zip(windows, hostingViews)) {
            let (window, hostingView) = pair
            hostingView.rootView = makeOverlayView()
            window.alphaValue = fadeIn ? 0 : 1
            if index == 0 {
                window.makeKeyAndOrderFront(nil)
            } else {
                window.orderFrontRegardless()
            }
        }

        if fadeIn {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.35
                for window in windows {
                    window.animator().alphaValue = 1
                }
            }
        }
    }

    func update(message: String, remainingSeconds: Int) {
        currentMessage = message
        currentRemainingSeconds = remainingSeconds
        for hostingView in hostingViews {
            hostingView.rootView = makeOverlayView()
        }
    }

    func hide() {
        for window in windows {
            window.orderOut(nil)
        }
    }

    private func makeOverlayView() -> BreakOverlayView {
        BreakOverlayView(
            message: currentMessage,
            remainingSeconds: currentRemainingSeconds,
            onSkip: { [weak self] in
                self?.skipAction?()
            }
        )
    }

    private func rebuildWindows() {
        for window in windows {
            window.orderOut(nil)
        }

        windows.removeAll()
        hostingViews.removeAll()

        for screen in NSScreen.screens {
            let window = BreakOverlayWindow(
                contentRect: CGRect(origin: .zero, size: screen.frame.size),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            let hostingView = NSHostingView(rootView: makeOverlayView())
            hostingView.frame = CGRect(origin: .zero, size: screen.frame.size)
            hostingView.autoresizingMask = [.width, .height]

            window.contentView = hostingView
            window.backgroundColor = .clear
            window.isOpaque = false
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.ignoresMouseEvents = false
            window.hasShadow = false
            window.isReleasedWhenClosed = false
            window.setFrame(screen.frame, display: true)
            window.setFrameOrigin(screen.frame.origin)

            hostingViews.append(hostingView)
            windows.append(window)
        }
    }
}

struct BreakOverlayView: View {
    let message: String
    let remainingSeconds: Int
    let onSkip: () -> Void

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.7))
                .background(.ultraThinMaterial.opacity(0.7))
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(formattedTime)
                    .font(.system(size: 85, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.black.opacity(0.5))

                Text(message)
                    .font(.system(size: 40, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 500)

                Button("Skip") {
                    onSkip()
                }
                .buttonStyle(.plain)
                .font(.system(size: 24))
                .foregroundStyle(Color.black.opacity(0.48))
                .padding(.horizontal, 34)
                .padding(.vertical, 18)
            }
            .padding(40)
        }
    }
}
