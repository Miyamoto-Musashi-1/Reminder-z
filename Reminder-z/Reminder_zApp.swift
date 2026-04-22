//
//  Reminder_zApp.swift
//  Reminder-z
//
//  Created by Huy Duong on 22/4/26.
//

import AppKit
import SwiftUI

@main
struct Reminder_zApp: App {
    @StateObject private var scheduler = BreakScheduler()

    var body: some Scene {
        WindowGroup("Reminder-z") {
            ContentView()
                .environmentObject(scheduler)
        }

        Settings {
            PreferencesView()
                .environmentObject(scheduler)
        }

        MenuBarExtra {
            ContentView()
                .environmentObject(scheduler)
        } label: {
            MenuBarLabelView(scheduler: scheduler)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabelView: View {
    @ObservedObject var scheduler: BreakScheduler

    var body: some View {
        if scheduler.showTimeInMenuBar {
            HStack(spacing: 6) {
                Image(systemName: "cup.and.saucer.fill")
                Text(scheduler.formattedRemainingTime)
                    .monospacedDigit()
            }
        } else {
            Image(systemName: "cup.and.saucer.fill")
        }
    }
}
