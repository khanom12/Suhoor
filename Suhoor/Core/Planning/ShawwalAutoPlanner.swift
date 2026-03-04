import Foundation

enum ShawwalPlanStrategy: String, CaseIterable, Identifiable {
    case startEarly
    case maximizeReward
    case spreadOut

    var id: String { rawValue }

    var title: String {
        switch self {
        case .startEarly:
            return "Start Early"
        case .maximizeReward:
            return "Maximize Rewards"
        case .spreadOut:
            return "Spread Out"
        }
    }

    var description: String {
        switch self {
        case .startEarly:
            return "Schedule the earliest eligible Shawwal days."
        case .maximizeReward:
            return "Prioritize White Days and Monday/Thursday overlap."
        case .spreadOut:
            return "Space days across the month with small gaps."
        }
    }
}

enum ShawwalAutoPlanner {
    static func generate(
        dates: [Date],
        desiredCount: Int,
        strategy: ShawwalPlanStrategy,
        timeZone: TimeZone = .current
    ) -> [Date] {
        guard desiredCount > 0, !dates.isEmpty else { return [] }
        let sorted = dates.sorted()
        switch strategy {
        case .startEarly:
            return Array(sorted.prefix(desiredCount))
        case .maximizeReward:
            return Array(sortedByScore(sorted, timeZone: timeZone).prefix(desiredCount))
        case .spreadOut:
            let scored = sortedByScore(sorted, timeZone: timeZone)
            let spaced = spread(scored, desiredCount: desiredCount, minGapDays: 2, timeZone: timeZone)
            if spaced.count == desiredCount {
                return spaced
            }
            var filled = spaced
            for date in scored where filled.count < desiredCount {
                if filled.contains(date) == false {
                    filled.append(date)
                }
            }
            return Array(filled.prefix(desiredCount))
        }
    }

    private static func sortedByScore(_ dates: [Date], timeZone: TimeZone) -> [Date] {
        dates.sorted { lhs, rhs in
            score(for: lhs, timeZone: timeZone) < score(for: rhs, timeZone: timeZone)
        }
    }

    private static func score(for date: Date, timeZone: TimeZone) -> (Int, Date) {
        let tags = FastIntentEngine.dateDerivedObservanceTags(
            for: date,
            timeZone: timeZone,
            includeShawwalPotential: true
        )
        let hasWhite = tags.contains(.whiteDays)
        let hasMonThu = tags.contains(.mondayThursday)
        let rank: Int
        switch (hasWhite, hasMonThu) {
        case (true, true):
            rank = 0
        case (true, false):
            rank = 1
        case (false, true):
            rank = 2
        default:
            rank = 3
        }
        return (rank, date)
    }

    private static func spread(
        _ dates: [Date],
        desiredCount: Int,
        minGapDays: Int,
        timeZone: TimeZone
    ) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var selected: [Date] = []
        for date in dates {
            guard selected.count < desiredCount else { break }
            if selected.allSatisfy({ !isWithinGap(date, $0, minGapDays: minGapDays, calendar: calendar) }) {
                selected.append(date)
            }
        }
        return selected
    }

    private static func isWithinGap(
        _ lhs: Date,
        _ rhs: Date,
        minGapDays: Int,
        calendar: Calendar
    ) -> Bool {
        let daySpan = calendar.dateComponents([.day], from: calendar.startOfDay(for: lhs), to: calendar.startOfDay(for: rhs)).day ?? 0
        return abs(daySpan) <= minGapDays
    }
}
