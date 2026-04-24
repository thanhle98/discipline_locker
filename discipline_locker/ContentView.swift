import SwiftUI

struct ContentView: View {
    @Environment(ScheduleStore.self) var store
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false

    var body: some View {
        @Bindable var store = store

        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                Text("Discipline Locker")
                    .font(.title.bold())
            }

            Text("Configure forced shutdown times for each day. Once active, your Mac will shut down at the scheduled times. No snooze, no cancel.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Divider()

            ForEach($store.schedules) { $schedule in
                DayScheduleRow(schedule: $schedule)
            }

            Divider()

            HStack {
                Circle()
                    .fill(store.isActive ? .green : .gray)
                    .frame(width: 10, height: 10)
                Text(store.isActive ? "Active" : "Inactive")
                    .font(.callout)

                Spacer()

                if store.isActive {
                    Button("Deactivate") {
                        deactivate()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isProcessing)
                } else {
                    Button("Activate Schedule") {
                        activate()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(store.enabledSchedules.isEmpty || isProcessing)
                }
            }

            if store.isActive, let next = store.nextShutdown() {
                Text("Next shutdown: \(next.day.fullName) at \(String(format: "%02d:%02d", next.hour, next.minute))")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            Divider()

            Toggle("Launch at Login", isOn: $store.launchAtLogin)
                .font(.callout)
            Toggle("Hide from Dock", isOn: $store.hideFromDock)
                .font(.callout)
        }
        .padding(24)
        .frame(width: 420)
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func activate() {
        isProcessing = true
        Task {
            do {
                try ShutdownDaemonManager.install(schedules: store.schedules)
                store.isActive = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isProcessing = false
        }
    }

    private func deactivate() {
        isProcessing = true
        Task {
            do {
                try ShutdownDaemonManager.uninstall()
                store.isActive = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isProcessing = false
        }
    }
}
