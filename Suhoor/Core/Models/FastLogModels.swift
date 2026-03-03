import Foundation

enum FastLogStatus: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case unknown
    case completed
    case missed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unknown:
            return "Not logged"
        case .completed:
            return "Completed"
        case .missed:
            return "Missed"
        }
    }
}

struct FastIntentSnapshot: Codable, Equatable, Hashable, Sendable {
    var primaryIntent: FastPrimaryIntent
    var secondaryTags: Set<FastSecondaryVirtueTag>

    static let empty = FastIntentSnapshot(primaryIntent: .other, secondaryTags: [])
}

struct FastLogEntry: Codable, Equatable, Hashable, Sendable {
    let dateKey: String
    var status: FastLogStatus
    var updatedAt: Date
    var intentSnapshot: FastIntentSnapshot?
}

