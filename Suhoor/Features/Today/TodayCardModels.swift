import Foundation

enum TodayCardKind: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case countdown
    case ramadanProgress
    case fastCheckIn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .countdown:
            return "Next Countdown"
        case .ramadanProgress:
            return "Ramadan Progress"
        case .fastCheckIn:
            return "Fast Check-in"
        }
    }
}

struct TodayCardLayout: Codable, Equatable, Hashable, Sendable {
    var ordered: [TodayCardKind]
    var hidden: Set<TodayCardKind>

    static let `default` = TodayCardLayout(
        ordered: [.countdown, .ramadanProgress, .fastCheckIn],
        hidden: []
    )

    func isVisible(_ card: TodayCardKind) -> Bool {
        !hidden.contains(card)
    }

    func visibleOrderedCards() -> [TodayCardKind] {
        ordered.filter(isVisible)
    }
}

