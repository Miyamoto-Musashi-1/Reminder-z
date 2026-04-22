import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var scheduler: BreakScheduler

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Spacer()

                Menu {
                    SettingsLink {
                        Text("Preferences…")
                    }

                    Button("Quit") {
                        NSApp.terminate(nil)
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                }
                .menuStyle(.borderlessButton)
            }

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.22), lineWidth: 24)

                Circle()
                    .trim(from: 0, to: scheduler.progress)
                    .stroke(
                        Color.gray.opacity(0.42),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Circle()
                    .fill(Color.black.opacity(0.66))
                    .padding(28)

                Button {
                    scheduler.togglePause()
                } label: {
                    Image(
                        systemName: scheduler.isPaused ? "play.fill" : (scheduler.isOnBreak ? "pause.fill" : "pause.fill")
                    )
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 140, height: 140)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 220, height: 220)

            VStack(spacing: 10) {
                Text(scheduler.formattedRemainingTime)
                    .font(.system(size: 42, weight: .medium, design: .rounded))
                    .monospacedDigit()

                Text(scheduler.statusText)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 18) {
                Button("Reset") {
                    scheduler.resetSession()
                }
                .frame(width: 110)

                Button("Skip") {
                    scheduler.skipSession()
                }
                .frame(width: 110)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()
        }
        .padding(32)
        .frame(minWidth: 380, minHeight: 500)
    }
}
