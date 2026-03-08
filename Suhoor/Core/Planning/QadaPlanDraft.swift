import Foundation

enum QadaPlanWizardStep: Hashable, Sendable {
    case setup
    case review
}

enum QadaPlanPace: String, CaseIterable, Identifiable, Codable, Sendable {
    case finishSooner
    case steady
    case gentle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .finishSooner:
            return "Finish sooner"
        case .steady:
            return "Steady pace"
        case .gentle:
            return "Take it gently"
        }
    }

    var description: String {
        switch self {
        case .finishSooner:
            return "Complete your Qada more quickly."
        case .steady:
            return "A balanced rhythm with rest days."
        case .gentle:
            return "More recovery time between fasts."
        }
    }

    var differentiatorLine: String {
        switch self {
        case .finishSooner:
            return "Good if you want fewer gaps between fasts."
        case .steady:
            return "Good if you want something sustainable."
        case .gentle:
            return "Good if you prefer a lighter pace."
        }
    }

    var strategy: QadaPlanStrategy {
        switch self {
        case .finishSooner:
            return .focused
        case .steady:
            return .balanced
        case .gentle:
            return .gentle
        }
    }
}

struct QadaPlanDraft: Equatable, Sendable {
    var baselineOwed: Int
    var pace: QadaPlanPace
    var avoidShawwal: Bool
    var avoidImportantSunnah: Bool
    var planBatchCount: Int

    static let empty = QadaPlanDraft(
        baselineOwed: 0,
        pace: .steady,
        avoidShawwal: true,
        avoidImportantSunnah: true,
        planBatchCount: 3
    )
}

struct QadaPlanSummary: Equatable, Sendable {
    let plannedCount: Int
    let targetCount: Int
    let startDate: Date?
    let finishDate: Date?
    let paceTitle: String
    let protectedSummary: String
}
