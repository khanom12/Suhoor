import Foundation

enum QadaPlanWizardStep: Hashable {
    case setup
    case review
}

enum QadaPlanInputMode: String, CaseIterable, Identifiable {
    case exact
    case estimate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .exact:
            return "Exact"
        case .estimate:
            return "Estimate"
        }
    }
}

enum QadaPlanPace: String, CaseIterable, Identifiable {
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
            return "Faster completion with minimal gaps."
        case .steady:
            return "A sustainable rhythm with rest days."
        case .gentle:
            return "More recovery time between fasts."
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
    var inputMode: QadaPlanInputMode
    var pace: QadaPlanPace
    var avoidShawwal: Bool
    var avoidImportantSunnah: Bool
    var planBatchCount: Int

    static let empty = QadaPlanDraft(
        baselineOwed: 0,
        inputMode: .exact,
        pace: .steady,
        avoidShawwal: true,
        avoidImportantSunnah: true,
        planBatchCount: 6
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
