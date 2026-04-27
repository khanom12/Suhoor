import Foundation

enum MorningHomeCardKind: Equatable, Sendable {
    case tomorrowMorning
    case weeklyFajrcast
    case morningcast
}

struct MorningHomeContextFlag: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
}

struct MorningHomeSnapshot {
    static let maximumMorningcastCount = 10
    static let mvpCardKinds: [MorningHomeCardKind] = [
        .tomorrowMorning,
        .weeklyFajrcast,
        .morningcast
    ]

    let tomorrow: WakeRowEntry?
    let weeklyFajrcast: FajrWindowCompactSnapshot
    let morningcast: [WakeRowEntry]
    let permissionState: PermissionSnapshot
    let contextFlags: [MorningHomeContextFlag]

    static let empty = MorningHomeSnapshot(
        tomorrow: nil,
        weeklyFajrcast: .empty,
        morningcast: [],
        permissionState: .empty,
        contextFlags: []
    )

    var cardKinds: [MorningHomeCardKind] {
        Self.mvpCardKinds
    }

    static func morningcastEntries(
        from entries: [WakeRowEntry],
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> [WakeRowEntry] {
        entries.filter { shouldShowInMorningcast($0, currentDate: currentDate, timeZone: timeZone) }
    }

    static func shouldShowInMorningcast(
        _ entry: WakeRowEntry,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: currentDate)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        return entry.schedule.date > tomorrow
    }
}

extension MorningHomeContextFlag {
    static func flags(for context: ResolvedDayContext) -> [MorningHomeContextFlag] {
        var flags: [MorningHomeContextFlag] = []
        var seen = Set<String>()

        func append(id: String, title: String) {
            guard seen.insert(id).inserted else { return }
            flags.append(MorningHomeContextFlag(id: id, title: title))
        }

        if context.primaryContext != .standard {
            append(
                id: "primary-\(context.primaryContext.rawValue)",
                title: ProductSurfacePresentation.primaryContextTitle(context.primaryContext)
            )
        }

        for title in ProductSurfacePresentation.meaningfulSecondaryContextTitles(from: context, limit: 2) {
            append(id: "secondary-\(title)", title: title)
        }

        for tag in context.supportingTags {
            guard tag != .dailyPlan && tag != .locationBased else { continue }
            append(id: "tag-\(tag.rawValue)", title: tag.title)
            if flags.count >= 4 {
                break
            }
        }

        return flags
    }
}
