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
    case globalDefaultSuhoorOffset
    case quickSelectorDefault
    case manualDragOverride
    case dateSpecificOverride
    case planGenerated
    case restoredPersistedValue
    case clampedToBoundary
    case noWakeAnchor
    case unavailable

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "globalDefaultFastOffset":
            self = .globalDefaultSuhoorOffset
        default:
            guard let value = WakeTimeOrigin(rawValue: rawValue) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown WakeTimeOrigin raw value: \(rawValue)"
                )
            }
            self = value
        }
    }
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

enum WakePurpose: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajr
    case suhoor

    var id: String { rawValue }
}

enum DateAlarmOverride: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case quiet
    case ringDespitePause

    var id: String { rawValue }
}

enum GlobalWakeAlarmPolicy: String, Codable, CaseIterable, Identifiable, Sendable {
    case active
    case pausedIndefinitely

    var id: String { rawValue }
}

enum ResolvedAlarmState: String, Codable, CaseIterable, Identifiable, Sendable {
    case active
    case quiet
    case pausedInherited
    case ringsOnceDespitePause
    case blocked
    case issue
    case unavailable

    var id: String { rawValue }
}

enum WakeAcknowledgementSource: String, Codable, CaseIterable, Identifiable, Sendable {
    case inAppButton
    case earlyAwakeButton
    case platformAwakeAction
    case systemAlarmDismiss

    var id: String { rawValue }
}

enum WakeAttemptDismissalSource: String, Codable, CaseIterable, Identifiable, Sendable {
    case systemAlarmDismiss
    case alarmKitDismiss
    case notificationDismiss
    case unknown

    var id: String { rawValue }
}

enum AlarmActivation: String, Codable, CaseIterable, Identifiable, Sendable {
    case active
    case quietSuppressed
    case pausedSuppressed
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
    case notScheduledBecausePaused
    case scheduledDespitePause
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
    let wakePurpose: WakePurpose
    let quickWakeSelection: QuickWakeMode
    let underlyingWakeMode: MorningWakeUnderlyingMode
    let dateAlarmOverride: DateAlarmOverride
    let globalWakeAlarmPolicy: GlobalWakeAlarmPolicy
    let resolvedAlarmState: ResolvedAlarmState
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
