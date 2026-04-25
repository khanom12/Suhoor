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

enum PrayerCompletionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case unknown
    case completed
    case missed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unknown:
            return "Not logged"
        case .completed:
            return "Fajr completed"
        case .missed:
            return "Not prayed"
        }
    }
}

struct PrayerCompletionState: Codable, Equatable, Hashable, Sendable {
    let status: PrayerCompletionStatus
    let updatedAt: Date?
    let source: String?

    static let empty = PrayerCompletionState(
        status: .unknown,
        updatedAt: nil,
        source: nil
    )
}

enum FastCompletionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case notRequired
    case unknown
    case inProgress
    case completed
    case notCompleted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notRequired:
            return "Not a fasting day"
        case .unknown:
            return "Not logged"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Completed"
        case .notCompleted:
            return "Not completed"
        }
    }
}

struct FastCompletionState: Codable, Equatable, Hashable, Sendable {
    let status: FastCompletionStatus
    let intentSnapshot: FastIntentSnapshot?
    let updatedAt: Date?
    let source: String?

    static let notRequired = FastCompletionState(
        status: .notRequired,
        intentSnapshot: nil,
        updatedAt: nil,
        source: nil
    )
}

enum WakeSupportStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case active

    var id: String { rawValue }
}

struct WakeSupportState: Codable, Equatable, Hashable, Sendable {
    let status: WakeSupportStatus
    let detail: String?

    static let none = WakeSupportState(status: .none, detail: nil)
}

struct QadaEffect: Codable, Equatable, Hashable, Sendable {
    let countsTowardQada: Bool
    let completedDelta: Int
    let remainingAfterEffect: Int?
    let explanation: String?

    static let none = QadaEffect(
        countsTowardQada: false,
        completedDelta: 0,
        remainingAfterEffect: nil,
        explanation: nil
    )
}

enum OutstandingCompletionAction: String, Codable, CaseIterable, Identifiable, Sendable {
    case prayerCheckIn
    case fastingStatus
    case fastCompletion

    var id: String { rawValue }
}

struct DailyCompletionSnapshot: Codable, Equatable, Hashable, Sendable {
    let dateKey: String
    let prayer: PrayerCompletionState
    let fast: FastCompletionState
    let qadaEffect: QadaEffect
    let wakeSupport: WakeSupportState
    let outstandingAction: OutstandingCompletionAction?
    let isMeaningfullyResolved: Bool

    static func empty(dateKey: String) -> DailyCompletionSnapshot {
        DailyCompletionSnapshot(
            dateKey: dateKey,
            prayer: .empty,
            fast: .notRequired,
            qadaEffect: .none,
            wakeSupport: .none,
            outstandingAction: nil,
            isMeaningfullyResolved: false
        )
    }
}

struct CompletionStateSnapshot: Sendable {
    let recordsByDateKey: [String: [CompletionRecord]]
    let qadaLedgerSnapshot: QadaLedgerSnapshot

    func records(for dateKey: String) -> [CompletionRecord] {
        recordsByDateKey[dateKey] ?? []
    }

    static let empty = CompletionStateSnapshot(
        recordsByDateKey: [:],
        qadaLedgerSnapshot: QadaLedgerSnapshot(
            trackingStartDateKey: "",
            baselineOwed: 0,
            completed: 0,
            remaining: 0
        )
    )
}
