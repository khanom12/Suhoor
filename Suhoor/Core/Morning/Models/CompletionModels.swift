import Foundation

enum CompletionKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajr
    case fast
    case wakeSupport

    var id: String { rawValue }
}

enum CompletionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case completed
    case missed
    case unknown

    var id: String { rawValue }
}

struct CompletionRecord: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let dateKey: String
    let kind: CompletionKind
    let status: CompletionStatus
    let updatedAt: Date
    let source: String
    let metadata: [String: String]
}

struct QadaLedgerSnapshot: Codable, Equatable, Hashable, Sendable {
    let trackingStartDateKey: String
    let baselineOwed: Int
    let completed: Int
    let remaining: Int
}
