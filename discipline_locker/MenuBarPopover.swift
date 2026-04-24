import SwiftUI

struct MenuBarPopover: View {
    @Environment(ScheduleStore.self) var store
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Discipline Locker")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(store.isActive ? .green : .gray)
                    .frame(width: 8, height: 8)
            }

            Divider()

            if store.isActive, let next = store.nextShutdown() {
                let remaining = next.date.timeIntervalSinceNow

                Text("Next shutdown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(next.day.fullName) at \(String(format: "%02d:%02d", next.hour, next.minute))")
                    .font(.body.bold())

                if remaining > 0 {
                    Text(timeRemainingString(remaining))
                        .font(.title2.monospacedDigit().bold())
                        .foregroundStyle(remaining < 600 ? .red : .primary)
                }
            } else {
                Text("No shutdown scheduled")
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Open Settings...") {
                openWindow(id: "settings")
                NSApp.activate()
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 220)
    }

    private func timeRemainingString(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
}
