import Foundation

enum MorningWakeUnderlyingMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajr
    case earlyWorship

    var id: String { rawValue }
}

enum MorningWakeDayContextKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case ordinary
    case fajrIntendedOnly
    case fastingOpportunity
    case fastingIntended
    case ramadanFasting
    case qadaFastIntended
    case sunnahFastIntended
    case customFastIntended
    case tahajjudIntended
    case fastingAndTahajjudIntended
    case observanceOnly
    case adjusted
    case unknown

    var id: String { rawValue }
}

enum WakeBoundaryRegime: String, Codable, CaseIterable, Identifiable, Sendable {
    case defaultFajrWindow
    case earlyWorshipWindow
    case quietDefaultFajrWindow
    case quietEarlyWorshipWindow
    case customOutOfRange
    case unavailable

    var id: String { rawValue }
}

enum WakeBoundaryKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajrBegins
    case finalThirdOfNight
    case unavailable

    var id: String { rawValue }
}

enum WakeBoundaryReason: String, Codable, CaseIterable, Identifiable, Sendable {
    case defaultFajrMorning
    case intendedFasting
    case intendedTahajjud
    case intendedFastingAndTahajjud
    case fallbackMissingNightData
    case quietPreserved
    case unavailable

    var id: String { rawValue }
}

struct WakeBoundaryResolution: Codable, Equatable, Sendable {
    let kind: WakeBoundaryKind
    let leftBoundaryTime: Date?
    let rightBoundaryTime: Date?
    let finalThirdStart: Date?
    let fajrBegins: Date?
    let fajrEnds: Date?
    let reason: WakeBoundaryReason
    let isEstimated: Bool

    var isAvailable: Bool {
        leftBoundaryTime != nil && rightBoundaryTime != nil
    }
}

enum WakeTimeOrigin: String, Codable, CaseIterable, Identifiable, Sendable {
    case globalDefaultFajrOffset
    case globalDefaultFastOffset
    case quickSelectorDefault
    case manualDragOverride
    case dateSpecificOverride
    case planGenerated
    case restoredPersistedValue
    case clampedToBoundary
    case noWakeAnchor
    case unavailable

    var id: String { rawValue }
}

enum WakeTimeRelationBoundary: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajrBegin
    case fajrEnd
    case finalThirdStart
    case none
    case unavailable

    var id: String { rawValue }
}

struct WakeTimeResolution: Codable, Equatable, Sendable {
    let wakeTime: Date?
    let displayText: String?
    let origin: WakeTimeOrigin
    let offsetMinutes: Int?
    let relationBoundary: WakeTimeRelationBoundary
    let isEndpoint: Bool
    let isAdjusted: Bool
    let isClamped: Bool
    let minutesBeforeFajrEnd: Int?
    let minutesBeforeFajrBegin: Int?
}

enum AlarmActivation: String, Codable, CaseIterable, Identifiable, Sendable {
    case active
    case quietSuppressed
    case offWithAnchor
    case noAnchor
    case unavailable

    var id: String { rawValue }
}

enum MorningWakeScheduleStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case scheduled
    case pending
    case failed
    case permissionBlocked
    case notScheduledBecauseQuiet
    case notScheduledBecauseNoAnchor
    case notScheduledBecauseUnavailable
    case unavailable

    var id: String { rawValue }
}

enum MorningWakeVisualMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case interactiveDefaultFajr
    case staticDefaultFajrQuiet
    case interactiveEarlyWorship
    case staticEarlyWorshipQuiet
    case staticNoAlarmWithBoundaries
    case hiddenUnavailable
    case hiddenOutOfRange

    var id: String { rawValue }
}

enum WakeCopyTone: String, Codable, CaseIterable, Identifiable, Sendable {
    case normal
    case urgentRed
    case warning
    case stateText

    var id: String { rawValue }
}

struct WakeCopyState: Codable, Equatable, Sendable {
    let primaryHeroText: String
    let finalRelationText: String?
    let relationTone: WakeCopyTone
    let detailExplanation: String?
    let scheduleWarningText: String?
    let accessibilityText: String
}

enum MorningWakePersistenceState: String, Codable, CaseIterable, Identifiable, Sendable {
    case clean
    case dirty
    case saving
    case failed

    var id: String { rawValue }
}

struct ResolvedMorningWakeState: Codable, Equatable, Sendable {
    let dateKey: String
    let morningDate: Date
    let dayContext: MorningWakeDayContextKind
    let quickWakeSelection: QuickWakeMode
    let underlyingWakeMode: MorningWakeUnderlyingMode
    let boundaryRegime: WakeBoundaryRegime
    let wakeBoundaryResolution: WakeBoundaryResolution
    let wakeTimeResolution: WakeTimeResolution
    let alarmActivation: AlarmActivation
    let scheduleStatus: MorningWakeScheduleStatus
    let visualMode: MorningWakeVisualMode
    let copyState: WakeCopyState
    let persistenceState: MorningWakePersistenceState
    let accessibilitySummary: String
}
