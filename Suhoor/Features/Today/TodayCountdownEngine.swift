import Foundation

struct TodayCountdownEngine {
    struct Target: Equatable, Sendable {
        enum Kind: String, Equatable, Sendable {
            case suhoor
            case fajr
            case iftar
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
            let iftarOrMaghrib = schedule.iftarDate ?? schedule.maghribDate

            guard now < iftarOrMaghrib else { continue }

            if now < schedule.wakeDate, activeDay.effectiveConfig.suhoorEnabled {
                return Target(kind: .suhoor, targetDate: schedule.wakeDate, day: activeDay)
            }

            if now < schedule.fajrDate {
                return Target(kind: .fajr, targetDate: schedule.fajrDate, day: activeDay)
            }

            return Target(kind: .iftar, targetDate: iftarOrMaghrib, day: activeDay)
        }

        return nil
    }
}
