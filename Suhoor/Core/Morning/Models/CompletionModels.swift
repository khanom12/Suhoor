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
            return "Made Fajr"
        case .missed:
            return "Missed Fajr"
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
}

struct CompletionHistoryProjection: Equatable, Sendable {
    let todayCompletion: DailyCompletionSnapshot
    let recentFajrCompletedCount: Int
    let recentFajrMissedCount: Int
    let recentFastCompletedCount: Int
    let recentFastMissedCount: Int
    let qadaProgress: QadaProgressSnapshot
}

struct CompletionHistoryWindow: Sendable {
    let resolvedDays: [ResolvedDaySnapshot]
    let dailyCompletions: [DailyCompletionSnapshot]
}

struct FajrHistoryRowSnapshot: Equatable, Identifiable, Sendable {
    let dateKey: String
    let gregorianText: String
    let hijriText: String
    let fajrTimeText: String?
    let status: PrayerCompletionStatus
    let statusText: String
    let canClear: Bool

    var id: String { dateKey }
}

struct FastHistoryRowSnapshot: Equatable, Identifiable, Sendable {
    let dateKey: String
    let gregorianText: String
    let hijriText: String
    let meaningText: String
    let status: FastCompletionStatus
    let statusText: String
    let qadaEffectText: String?
    let intentSnapshot: FastIntentSnapshot?
    let canClear: Bool

    var id: String { dateKey }
}

struct FajrHistorySurfaceSnapshot: Equatable, Sendable {
    let summaryText: String
    let rows: [FajrHistoryRowSnapshot]
    let emptyText: String
    let footerText: String
}

struct FastHistorySurfaceSnapshot: Equatable, Sendable {
    let summaryText: String
    let rows: [FastHistoryRowSnapshot]
    let emptyText: String
    let footerText: String
}

enum CompletionEditIntent: Equatable, Sendable {
    case setPrayerStatus(dateKey: String, status: PrayerCompletionStatus)
    case clearPrayerStatus(dateKey: String)
    case setFastStatus(dateKey: String, status: FastCompletionStatus, intentSnapshot: FastIntentSnapshot?)
    case clearFastStatus(dateKey: String)
}
