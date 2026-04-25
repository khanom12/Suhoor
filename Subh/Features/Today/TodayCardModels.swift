import Foundation

enum TodaySeasonalCardMode: Equatable, Sendable {
    case live
    case reference
}

enum TodayCardKind: String, CaseIterable, Identifiable, Hashable, Sendable {
    case countdown
    case ramadanProgress
    case eidMubarak
    case shawwalSixProgress
    case dhulHijjahNineProgress
    case ashuraProgress
    case whiteDaysProgress
    case fastCheckIn
    case eidAlFitrNotice
    case eidAlAdhaNotice
    case tashreeqNotice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .countdown:
            return "Next Countdown"
        case .ramadanProgress:
            return "Ramadan Progress"
        case .eidMubarak:
            return "Eid Mubarak"
        case .shawwalSixProgress:
            return "Shawwal 6"
        case .dhulHijjahNineProgress:
            return "Dhul Hijjah Progress"
        case .ashuraProgress:
            return "Ashura Progress"
        case .whiteDaysProgress:
            return "White Days Progress"
        case .fastCheckIn:
            return "Fast Check-in"
        case .eidAlFitrNotice:
            return "Eid al-Fitr"
        case .eidAlAdhaNotice:
            return "Eid al-Adha"
        case .tashreeqNotice:
            return "Days of Tashreeq"
        }
    }
}

struct TodayCardLayout: Codable, Equatable, Hashable, Sendable {
    var ordered: [TodayCardKind]
    var hidden: Set<TodayCardKind>

    static let `default` = TodayCardLayout(
        ordered: [
            .countdown,
            .ramadanProgress,
            .eidMubarak,
            .eidAlFitrNotice,
            .eidAlAdhaNotice,
            .tashreeqNotice,
            .shawwalSixProgress,
            .dhulHijjahNineProgress,
            .ashuraProgress,
            .whiteDaysProgress,
            .fastCheckIn,
        ],
        hidden: [
            .shawwalSixProgress,
            .dhulHijjahNineProgress,
            .ashuraProgress,
            .eidAlFitrNotice,
            .eidAlAdhaNotice,
            .tashreeqNotice,
        ]
    )

    func isVisible(_ card: TodayCardKind) -> Bool {
        !hidden.contains(card)
    }

    func visibleOrderedCards() -> [TodayCardKind] {
        ordered.filter(isVisible)
    }

    private enum CodingKeys: String, CodingKey {
        case ordered
        case hidden
    }

    init(ordered: [TodayCardKind], hidden: Set<TodayCardKind>) {
        self.ordered = ordered
        self.hidden = hidden
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let orderedRaw = try container.decodeIfPresent([String].self, forKey: .ordered) ?? []
        let hiddenRaw = try container.decodeIfPresent([String].self, forKey: .hidden) ?? []

        self.ordered = orderedRaw.compactMap(TodayCardKind.init(rawValue:))
        self.hidden = Set(hiddenRaw.compactMap(TodayCardKind.init(rawValue:)))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ordered.map(\.rawValue), forKey: .ordered)
        try container.encode(Array(hidden).map(\.rawValue), forKey: .hidden)
    }
}
