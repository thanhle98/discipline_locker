import Foundation
import AppKit

@Observable
class ScheduleStore {
    var schedules: [DaySchedule] {
        didSet { save() }
    }

    var isActive: Bool {
        didSet { UserDefaults.standard.set(isActive, forKey: "isActive") }
    }

    var hideFromDock: Bool {
        didSet {
            UserDefaults.standard.set(hideFromDock, forKey: "hideFromDock")
            NSApp.setActivationPolicy(hideFromDock ? .accessory : .regular)
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "daySchedules"),
           let decoded = try? JSONDecoder().decode([DaySchedule].self, from: data) {
            self.schedules = decoded
        } else {
            self.schedules = DaySchedule.defaultSchedules()
        }
        self.isActive = UserDefaults.standard.bool(forKey: "isActive")
        self.hideFromDock = UserDefaults.standard.bool(forKey: "hideFromDock")
    }

    func applyDockPolicy() {
        NSApp.setActivationPolicy(hideFromDock ? .accessory : .regular)
    }

    var enabledSchedules: [DaySchedule] {
        schedules.filter(\.isEnabled)
    }

    func nextShutdown() -> (day: Weekday, hour: Int, minute: Int, date: Date)? {
        guard isActive else { return nil }
        let now = Date()
        let cal = Calendar.current
        let currentHour = cal.component(.hour, from: now)
        let currentMinute = cal.component(.minute, from: now)

        for dayOffset in 0..<7 {
            guard let checkDate = cal.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let weekday = cal.component(.weekday, from: checkDate)

            guard let day = Weekday.from(calendarWeekday: weekday),
                  let schedule = enabledSchedules.first(where: { $0.day == day }) else {
                continue
            }

            if dayOffset == 0 {
                guard schedule.hour > currentHour ||
                      (schedule.hour == currentHour && schedule.minute > currentMinute) else {
                    continue
                }
            }

            var dc = cal.dateComponents([.year, .month, .day], from: checkDate)
            dc.hour = schedule.hour
            dc.minute = schedule.minute
            dc.second = 0
            if let date = cal.date(from: dc) {
                return (schedule.day, schedule.hour, schedule.minute, date)
            }
        }
        return nil
    }

    private func save() {
        if let data = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(data, forKey: "daySchedules")
        }
    }
}
