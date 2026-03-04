import Foundation

enum TodayCardKind: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case countdown
    case ramadanProgress
    case shawwalSixProgress
    case shawwalPlan
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
        case .shawwalSixProgress:
            return "Shawwal 6"
        case .shawwalPlan:
            return "Shawwal Planner"
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
            .shawwalSixProgress,
            .shawwalPlan,
            .fastCheckIn,
            .eidAlFitrNotice,
            .eidAlAdhaNotice,
            .tashreeqNotice
        ],
        hidden: [.eidAlFitrNotice, .eidAlAdhaNotice, .tashreeqNotice]
    )

    func isVisible(_ card: TodayCardKind) -> Bool {
        !hidden.contains(card)
    }

    func visibleOrderedCards() -> [TodayCardKind] {
        ordered.filter(isVisible)
    }
}
