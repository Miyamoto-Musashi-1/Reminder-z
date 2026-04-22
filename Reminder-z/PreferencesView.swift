import SwiftUI

struct PreferencesView: View {
    var body: some View {
        TabView {
            GeneralPreferencesView()
                .tabItem {
                    Label("General", systemImage: "switch.2")
                }

            BreakPreferencesView()
                .tabItem {
                    Label("Break", systemImage: "timer")
                }

            AboutPreferencesView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding(20)
        .frame(width: 500, height: 340)
    }
}

private struct GeneralPreferencesView: View {
    @EnvironmentObject private var scheduler: BreakScheduler

    var body: some View {
        Form {
            Toggle("Fade in mask window", isOn: $scheduler.fadeInMaskWindow)
            Toggle("Show time in menu bar", isOn: $scheduler.showTimeInMenuBar)
            Toggle("Launch at system startup", isOn: $scheduler.launchAtStartup)
        }
        .formStyle(.grouped)
    }
}

private struct BreakPreferencesView: View {
    @EnvironmentObject private var scheduler: BreakScheduler

    var body: some View {
        Form {
            HStack {
                Text("Every")
                Spacer()
                TextField("20", value: $scheduler.breakIntervalMinutes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Text("mins")
            }

            HStack {
                Text("Break for")
                Spacer()
                TextField("20", value: $scheduler.breakDurationSeconds, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Text("seconds")
            }

            TextField("Text to show in fade in window", text: $scheduler.breakMessage, axis: .vertical)
                .lineLimit(2...4)
        }
        .formStyle(.grouped)
    }
}

private struct AboutPreferencesView: View {
    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) Build \(build)"
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 46))
                .foregroundStyle(.orange)

            Text("Reminder-z")
                .font(.title2.weight(.semibold))

            Text(versionText)
                .foregroundStyle(.secondary)

            Text("A simple break app for recurring short screen breaks.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
