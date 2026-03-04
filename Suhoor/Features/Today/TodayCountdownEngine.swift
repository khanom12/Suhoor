import Foundation

struct TodayCountdownEngine {
    struct Target: Equatable, Sendable {
        enum Kind: String, Equatable, Sendable {
            case fajr
            case maghrib
        }

        let kind: Kind
        let targetDate: Date
        let day: ActiveAlarmDay
    }

    static func target(
        now: Date,
        snapshot: ActiveAlarmWindowSnapshot,
        timeZone: TimeZone = .current
    ) -> Target? {
        guard snapshot.visibleDays.isEmpty == false else { return nil }

        for activeDay in snapshot.visibleDays {
            let schedule = activeDay.schedule
            if now < schedule.fajrDate {
                return Target(kind: .fajr, targetDate: schedule.fajrDate, day: activeDay)
            }
            if now < schedule.maghribDate {
                return Target(kind: .maghrib, targetDate: schedule.maghribDate, day: activeDay)
            }
        }

        return nil
    }
}
