import Foundation

enum WakeAnchorType: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajrStart
    case fajrEnd
    case masjidFajr

    var id: String { rawValue }
}

struct WakeAnchor: Codable, Equatable, Hashable, Sendable {
    let type: WakeAnchorType
    let date: Date
    let providerNotes: String?
}

enum WakeDeltaRelation: String, Codable, CaseIterable, Identifiable, Sendable {
    case before
    case after

    var id: String { rawValue }
}

struct WakeDelta: Codable, Equatable, Hashable, Sendable {
    let relation: WakeDeltaRelation
    let minutes: Int

    var signedMinutes: Int {
        switch relation {
        case .before:
            return -minutes
        case .after:
            return minutes
        }
    }
}

struct MorningBehaviorProfile: Codable, Equatable, Hashable, Sendable {
    let wakeAnchorType: WakeAnchorType
    let wakeDelta: WakeDelta
    let fixedWakeTimeCompatibilityMinutesFromMidnight: Int?
    let reminderEnabled: Bool
    let wakeAlarmEnabled: Bool
    let wakeFollowUpEnabled: Bool
    let fajrBoundaryNoticeEnabled: Bool
    let iftarReminderEnabled: Bool
}

enum MorningPlanKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case defaultDaily
    case explicitDateOverride
    case observanceOverlay
    case qadaAssignment
    case generatedObservance

    var id: String { rawValue }
}

struct MorningPlan: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let kind: MorningPlanKind
    let wakeAnchorType: WakeAnchorType
    let wakeDelta: WakeDelta
    let fixedWakeTimeCompatibilityMinutesFromMidnight: Int?
    let reminderEnabled: Bool
    let wakeAlarmEnabled: Bool
    let fajrBoundaryNoticeEnabled: Bool
    let iftarReminderEnabled: Bool
}

struct PlanDateAssignment: Codable, Equatable, Hashable, Sendable {
    let dateKey: String
    let planID: String
}

enum MorningPlanActivationMode: String, Codable, Sendable {
    case dailyActive
    case legacyCompat
}

struct MorningPlanState: Codable, Equatable, Sendable {
    let schemaVersion: Int
    var activationMode: MorningPlanActivationMode
    var defaultDailyPlan: MorningPlan
    var lastMigrationAt: Date?
}

struct RulePlanCandidate: Codable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let kind: MorningPlanKind
}

struct MorningPlanResolution: Sendable {
    let selectedPlan: MorningPlan
    let candidates: [RulePlanCandidate]
    let precedenceReason: String
}
