import Foundation

enum HijriMonth: Int, CaseIterable, Codable, Hashable, Identifiable {
    case muharram = 1
    case safar = 2
    case rabiAlAwwal = 3
    case rabiAlThani = 4
    case jumadaAlAwwal = 5
    case jumadaAlThani = 6
    case rajab = 7
    case shaban = 8
    case ramadan = 9
    case shawwal = 10
    case dhulQadah = 11
    case dhulHijjah = 12

    var id: Int { rawValue }

    static let adjustmentMonths: [HijriMonth] = [.muharram, .ramadan, .shawwal, .dhulHijjah]

    static func isValid(_ rawValue: Int) -> Bool {
        Self(rawValue: rawValue) != nil
    }

    var displayName: String {
        switch self {
        case .muharram:
            return "Muharram"
        case .safar:
            return "Safar"
        case .rabiAlAwwal:
            return "Rabi al-Awwal"
        case .rabiAlThani:
            return "Rabi al-Thani"
        case .jumadaAlAwwal:
            return "Jumada al-Awwal"
        case .jumadaAlThani:
            return "Jumada al-Thani"
        case .rajab:
            return "Rajab"
        case .shaban:
            return "Sha'ban"
        case .ramadan:
            return "Ramadan"
        case .shawwal:
            return "Shawwal"
        case .dhulQadah:
            return "Dhul Qa'dah"
        case .dhulHijjah:
            return "Dhul Hijjah"
        }
    }

    var persistenceValue: String {
        String(format: "%02d", rawValue)
    }
}
