import Foundation

struct TodayCountdownEngine {
    struct Target: Equatable, Sendable {
        enum Kind: String, Equatable, Sendable {
            case fajr
            case iftar
        }

        let kind: Kind
        let targetDate: Date
    }

    static func target(
        now: Date,
        snapshot: ActiveAlarmWindowSnapshot,
        timeZone: TimeZone = .current
    ) -> Target? {
        guard snapshot.visibleDays.isEmpty == false else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfToday = calendar.startOfDay(for: now)
        let todayKey = DateHelpers.dayIdentifier(for: startOfToday, timeZone: timeZone)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        let tomorrowKey = DateHelpers.dayIdentifier(for: tomorrow, timeZone: timeZone)

        guard let today = snapshot.byDateKey[todayKey]?.schedule else { return nil }

        let iftarOrMaghrib = today.iftarDate ?? today.maghribDate
        if now < today.fajrDate {
            return Target(kind: .fajr, targetDate: today.fajrDate)
        }
        if now < iftarOrMaghrib {
            return Target(kind: .iftar, targetDate: iftarOrMaghrib)
        }

        guard let tomorrowSchedule = snapshot.byDateKey[tomorrowKey]?.schedule else { return nil }
        return Target(kind: .fajr, targetDate: tomorrowSchedule.fajrDate)
    }
}

