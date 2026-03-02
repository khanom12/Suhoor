import Foundation

enum CalculationMethod: String, Codable, CaseIterable, Identifiable, Sendable {
    case muslimWorldLeague
    case egyptian
    case karachi
    case northAmerica
    case makkah

    var id: String { rawValue }

    var fajrAngle: Double {
        switch self {
        case .muslimWorldLeague: return 18.0
        case .egyptian: return 19.5
        case .karachi: return 18.0
        case .northAmerica: return 15.0
        case .makkah: return 18.5
        }
    }

    var displayName: String {
        switch self {
        case .muslimWorldLeague: return "Muslim World League"
        case .egyptian: return "Egyptian"
        case .karachi: return "Karachi"
        case .northAmerica: return "North America"
        case .makkah: return "Umm al-Qura"
        }
    }

    static func defaultForTimeZone(_ timeZone: TimeZone) -> CalculationMethod {
        let id = timeZone.identifier
        if id.hasPrefix("America/") {
            return .northAmerica
        }
        if id.hasPrefix("Europe/") || id.hasPrefix("Africa/") {
            return .muslimWorldLeague
        }
        if id.hasPrefix("Asia/") {
            return .karachi
        }
        return .muslimWorldLeague
    }
}
