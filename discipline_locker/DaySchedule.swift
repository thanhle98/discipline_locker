import Foundation

enum Weekday: Int, CaseIterable, Codable, Identifiable, Sendable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 0

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        case .sunday: "Sun"
        }
    }

    var fullName: String {
        switch self {
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        case .sunday: "Sunday"
        }
    }

    static func from(calendarWeekday: Int) -> Weekday? {
        Weekday(rawValue: calendarWeekday - 1)
    }
}

struct DaySchedule: Codable, Identifiable, Sendable {
    var id: Weekday { day }
    let day: Weekday
    var isEnabled: Bool
    var hour: Int
    var minute: Int

    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }

    static func defaultSchedules() -> [DaySchedule] {
        Weekday.allCases.map { day in
            DaySchedule(
                day: day,
                isEnabled: day != .saturday && day != .sunday,
                hour: 23,
                minute: 0
            )
        }
    }
}
