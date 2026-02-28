import Foundation

enum RamadanProfile: String, Codable, CaseIterable, Identifiable {
    case ramadan2026

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ramadan2026: return "Ramadan 2026"
        }
    }

    var gregorianYear: Int {
        switch self {
        case .ramadan2026: return 2026
        }
    }
}
