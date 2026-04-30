import Foundation

struct ResolvedDayPurpose: Codable, Equatable, Hashable, Sendable {
    let dateKey: String
    let opportunities: [ObservanceOpportunity]
    let intention: ResolvedDayIntention
    let wakeClassification: DayWakeClassification
    let requiredActions: [DayRequiredAction]
    let analyticsCredits: [ObservanceCredit]
    let explanation: DayPurposeExplanation
}

struct ObservanceOpportunity: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let kind: ObservanceKind
    let eligibility: ObservanceEligibility
    let source: ObservanceSource
    let priority: Int
    let isActionable: Bool
    let title: String
    let detail: String?
}

enum ObservanceKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case ordinary
    case ramadan
    case qadaAssignable
    case voluntaryGeneral
    case mondayThursday
    case whiteDays
    case arafah
    case ashura
    case dhulHijjahFirstNine
    case shawwalSixPotential
    case eidAlFitr
    case eidAlAdha
    case tashreeq
    case tahajjudEligible

    var id: String { rawValue }
}

enum ObservanceEligibility: String, Codable, Sendable {
    case obligatory
    case recommended
    case permissible
    case forbidden
    case neutral
    case notApplicable
}

enum ObservanceSource: Codable, Equatable, Hashable, Sendable {
    case hijriCalendar
    case gregorianWeekday
    case scheduledDateSource(ScheduledDateSourceOrigin)
    case userSelection
    case defaultDailyPlan
    case derivedFallback
}

struct ResolvedDayIntention: Codable, Equatable, Hashable, Sendable {
    let kind: DayIntentionKind
    let source: DayIntentionSource
    let selectedOpportunityIDs: Set<String>
    let fastIntent: FastIntentSelection?
    let suppressesPrompts: Bool
    let explanation: String
}

enum DayIntentionKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case defaultFajr
    case fast
    case tahajjud
    case quiet

    var id: String { rawValue }
}

enum DayIntentionSource: String, Codable, CaseIterable, Identifiable, Sendable {
    case defaultDailyPlan
    case autoRamadan
    case userSelected
    case userDateOverride
    case migratedFastTagSelection
    case quietOverlay
    case derivedFallback

    var id: String { rawValue }
}

struct DayIntentionOverrides: Codable, Equatable, Hashable, Sendable {
    let quietDateKeys: Set<String>
    let tahajjudDateKeys: Set<String>

    static let empty = DayIntentionOverrides(quietDateKeys: [], tahajjudDateKeys: [])
}

struct DayWakeClassification: Codable, Equatable, Hashable, Sendable {
    let kind: DayWakeClassificationKind
    let plannedWakeState: MorningWakeRuleState
    let resolvedWakeState: ResolvedWakeState
    let anchorType: WakeAnchorType
    let explanation: String
}

enum DayWakeClassificationKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case defaultInFajr
    case earlyPreFajr
    case fixedClock
    case disabled
    case overridden

    var id: String { rawValue }
}

enum DayRequiredAction: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajrCheckIn
    case fastStatus
    case fastCompletion
    case qadaCompletionCredit
    case tahajjudCheckIn

    var id: String { rawValue }
}

struct ObservanceCredit: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let dateKey: String
    let opportunityID: String?
    let kind: ObservanceKind
    let creditType: ObservanceCreditType
    let source: ObservanceCreditSource
    let explanation: String?
}

enum ObservanceCreditType: String, Codable, CaseIterable, Identifiable, Sendable {
    case opportunityAvailable
    case planned
    case completed
    case missedAfterPlanning
    case keptDefault
    case suppressedByQuiet
    case invalidForbiddenFast

    var id: String { rawValue }
}

enum ObservanceCreditSource: String, Codable, CaseIterable, Identifiable, Sendable {
    case opportunityResolver
    case intentionResolver
    case completionRecord
    case qadaLedger
    case quietOverlay
    case forbiddenPolicy

    var id: String { rawValue }
}

struct DayPurposeExplanation: Codable, Equatable, Hashable, Sendable {
    let summary: String
    let details: [String]
}
