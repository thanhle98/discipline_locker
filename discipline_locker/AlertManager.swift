import Foundation
import UserNotifications

@Observable
class AlertManager {
    private var timerTask: Task<Void, Never>?
    private var notified10Min = false
    private var notified5Min = false

    func start(store: ScheduleStore) {
        stop()
        Task {
            try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        }
        timerTask = Task {
            while !Task.isCancelled {
                checkAndNotify(store: store)
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func checkAndNotify(store: ScheduleStore) {
        guard let next = store.nextShutdown() else { return }
        let remaining = next.date.timeIntervalSinceNow

        if remaining <= 600 && remaining > 300 && !notified10Min {
            sendNotification(
                title: "Shutdown in 10 minutes",
                body: "Mac will shut down at \(String(format: "%02d:%02d", next.hour, next.minute)). Save your work now!"
            )
            notified10Min = true
        } else if remaining <= 300 && remaining > 0 && !notified5Min {
            sendNotification(
                title: "Shutdown in 5 minutes!",
                body: "FINAL WARNING - Shutdown at \(String(format: "%02d:%02d", next.hour, next.minute)) is imminent. No snooze."
            )
            notified5Min = true
        } else if remaining > 600 {
            notified10Min = false
            notified5Min = false
        }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .defaultCritical

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        Task {
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
}
