import Foundation

enum MorningContextType: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard
    case tahajjud
    case suhoor
    case fasting
    case qadaFast
    case sunnahFast
    case jamaah
    case specialDay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard:
            return "Standard"
        case .tahajjud:
            return "Tahajjud"
        case .suhoor:
            return "Suhoor"
        case .fasting:
            return "Fasting"
        case .qadaFast:
            return "Qada"
        case .sunnahFast:
            return "Sunnah"
        case .jamaah:
            return "Jama'ah"
        case .specialDay:
            return "Special day"
        }
    }
}

enum DayTag: String, Codable, CaseIterable, Identifiable, Sendable {
    case dailyPlan
    case manualDay
    case manualRange
    case ramadan
    case qada
    case kaffarah
    case vow
    case voluntary
    case shawwalSix
    case arafah
    case ashura
    case whiteDays
    case mondayThursday
    case dhulHijjahFirstNine
    case eid
    case tashreeq
    case locationBased
    case fixedTimeCompatibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dailyPlan:
            return "Daily plan"
        case .manualDay:
            return "Manual day"
        case .manualRange:
            return "Manual range"
        case .ramadan:
            return "Ramadan"
        case .qada:
            return "Qada"
        case .kaffarah:
            return "Kaffarah"
        case .vow:
            return "Vow"
        case .voluntary:
            return "Voluntary"
        case .shawwalSix:
            return "Shawwal 6"
        case .arafah:
            return "Arafah"
        case .ashura:
            return "Ashura"
        case .whiteDays:
            return "White Days"
        case .mondayThursday:
            return "Monday & Thursday"
        case .dhulHijjahFirstNine:
            return "Dhul Hijjah"
        case .eid:
            return "Eid"
        case .tashreeq:
            return "Tashreeq"
        case .locationBased:
            return "Location-based"
        case .fixedTimeCompatibility:
            return "Fixed wake compatibility"
        }
    }
}

struct ContextExplanation: Codable, Equatable, Hashable, Sendable {
    let summary: String
    let details: [String]

    static let empty = ContextExplanation(summary: "", details: [])
}

struct ResolvedDayContext: Codable, Equatable, Hashable, Sendable {
    let primaryContext: MorningContextType
    let secondaryContexts: [MorningContextType]
    let supportingTags: [DayTag]
    let explanation: ContextExplanation

    static let standard = ResolvedDayContext(
        primaryContext: .standard,
        secondaryContexts: [],
        supportingTags: [],
        explanation: ContextExplanation(
            summary: "Using the default morning plan.",
            details: []
        )
    )
}
