import Foundation

enum FastLogStatus: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case unknown
    case inProgress
    case completed
    case missed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unknown:
            return "Not logged"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Completed"
        case .missed:
            return "Missed"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = FastLogStatus(rawValue: rawValue) ?? .unknown
    }
}

struct FastIntentSnapshot: Codable, Equatable, Hashable, Sendable {
    var primaryIntent: FastPrimaryIntent
    var secondaryTags: Set<FastSecondaryVirtueTag>

    static let empty = FastIntentSnapshot(primaryIntent: .other, secondaryTags: [])
}

struct PersistedQadaEffect: Codable, Equatable, Hashable, Sendable {
    var countsTowardQada: Bool
    var completedDelta: Int
    var remainingAfterEffect: Int?
    var explanation: String?

    static let none = PersistedQadaEffect(
        countsTowardQada: false,
        completedDelta: 0,
        remainingAfterEffect: nil,
        explanation: nil
    )

    var asQadaEffect: QadaEffect {
        QadaEffect(
            countsTowardQada: countsTowardQada,
            completedDelta: completedDelta,
            remainingAfterEffect: remainingAfterEffect,
            explanation: explanation
        )
    }
}

struct FastLogEntry: Codable, Equatable, Hashable, Sendable {
    let dateKey: String
    var status: FastLogStatus
    var updatedAt: Date
    var intentSnapshot: FastIntentSnapshot?
    var qadaEffect: PersistedQadaEffect?
    var source: String?

    init(
        dateKey: String,
        status: FastLogStatus,
        updatedAt: Date,
        intentSnapshot: FastIntentSnapshot?,
        qadaEffect: PersistedQadaEffect? = nil,
        source: String? = nil
    ) {
        self.dateKey = dateKey
        self.status = status
        self.updatedAt = updatedAt
        self.intentSnapshot = intentSnapshot
        self.qadaEffect = qadaEffect
        self.source = source
    }
}
