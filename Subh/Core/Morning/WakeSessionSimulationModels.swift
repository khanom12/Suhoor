import Foundation

typealias SubhClock = TimeProviding
typealias RealSubhClock = SystemTimeProvider
typealias TestSubhClock = MutableTimeProvider

enum WakeSessionSimulationScenarioKind: String, CaseIterable, Identifiable, Sendable {
    case fajrStateExplorer
    case suhoorStateExplorer
    case suhoorUnconfirmedToFajr
    case quietBeforeExecution
    case sliderReschedule
    case alarmStopVsAwake
    case permissionFailure
    case morningLogInspector
    case crossSurfaceConsistency
    case realAlarmKitMappedPlayback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fajrStateExplorer:
            return "Active Fajr Morning"
        case .suhoorStateExplorer:
            return "Active Suhoor Morning"
        case .suhoorUnconfirmedToFajr:
            return "Suhoor to Fajr Handoff"
        case .quietBeforeExecution:
            return "Quiet Before Execution"
        case .sliderReschedule:
            return "Slider Adjustment"
        case .alarmStopVsAwake:
            return "System Dismissal Test"
        case .permissionFailure:
            return "Alarm Setup Issue"
        case .morningLogInspector:
            return "Morning Log Inspector"
        case .crossSurfaceConsistency:
            return "Cross-Surface Consistency"
        case .realAlarmKitMappedPlayback:
            return "Real Alarm Test"
        }
    }

    var wakeMode: WakeSessionMode {
        switch self {
        case .suhoorStateExplorer, .suhoorUnconfirmedToFajr:
            return .suhoor
        case .fajrStateExplorer, .quietBeforeExecution, .sliderReschedule, .alarmStopVsAwake,
             .permissionFailure, .morningLogInspector, .crossSurfaceConsistency, .realAlarmKitMappedPlayback:
            return .fajr
        }
    }
}

enum SimulationRunMode: String, CaseIterable, Identifiable, Sendable {
    case previewHomeUI
    case realAlarmTest
    case fakeSchedulerPlayback
    case crossSurfaceAudit
    case dryRun

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .previewHomeUI:
            return "Preview Home UI"
        case .realAlarmTest:
            return "Real Alarm Test"
        case .fakeSchedulerPlayback:
            return "Preview Scheduler"
        case .crossSurfaceAudit:
            return "Cross-Surface Audit"
        case .dryRun:
            return "Dry Run"
        }
    }
}

enum SimulationClockMode: String, CaseIterable, Identifiable, Sendable {
    case frozen
    case runningRealTime
    case jumpOnly
    case mappedPlayback

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .frozen:
            return "Frozen"
        case .runningRealTime:
            return "Running"
        case .jumpOnly:
            return "Jump Only"
        case .mappedPlayback:
            return "Mapped Playback"
        }
    }
}

enum WakeSessionSimulationScrubHorizon: String, CaseIterable, Identifiable, Sendable {
    case next24Hours
    case next48Hours

    var id: String { rawValue }

    var title: String {
        switch self {
        case .next24Hours:
            return "Next 24 hours"
        case .next48Hours:
            return "Next 48 hours"
        }
    }

    var minuteCount: Int {
        switch self {
        case .next24Hours:
            return 24 * 60
        case .next48Hours:
            return 48 * 60
        }
    }
}

enum SimulationPrayerWindowSource: String, CaseIterable, Identifiable, Sendable {
    case realCalculation
    case customArtificialWindow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .realCalculation:
            return "Real calculation"
        case .customArtificialWindow:
            return "Custom test window"
        }
    }
}

enum SimulationLocation: String, CaseIterable, Identifiable, Sendable {
    case currentAppLocation
    case toronto
    case mecca
    case tromsoSummer
    case reykjavikWinter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .currentAppLocation:
            return "Current app location"
        case .toronto:
            return "Toronto"
        case .mecca:
            return "Mecca"
        case .tromsoSummer:
            return "Summer long-Fajr example"
        case .reykjavikWinter:
            return "Winter short-Fajr example"
        }
    }
}

enum WakeSessionSimulationDatePreset: String, CaseIterable, Identifiable, Sendable {
    case today
    case tomorrow
    case pickDate
    case ordinaryDay
    case ramadanDay
    case eidDay
    case whiteDay
    case monday
    case thursday
    case summerLongFajr
    case winterShortFajr

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .tomorrow:
            return "Tomorrow"
        case .pickDate:
            return "Pick date"
        case .ordinaryDay:
            return "Ordinary Day"
        case .ramadanDay:
            return "Ramadan Day"
        case .eidDay:
            return "Eid Day"
        case .whiteDay:
            return "White Day"
        case .monday:
            return "Monday"
        case .thursday:
            return "Thursday"
        case .summerLongFajr:
            return "Summer Long-Fajr"
        case .winterShortFajr:
            return "Winter Short-Fajr"
        }
    }
}

enum WakeSessionSimulationJumpPoint: String, CaseIterable, Identifiable, Sendable {
    case daytime
    case evening
    case beforeMidnight
    case midnight
    case beforeFajrBegins
    case atFajrBegins
    case fajrActiveWindow
    case beforePrimaryWake
    case atPrimaryWake
    case defaultWakeTime
    case primaryAlarmFired
    case wakeCheck1Pending
    case wakeCheck2Pending
    case wakeCheck3Pending
    case wakeCheck4Pending
    case wakeCheck5Pending
    case finalWakeCheck
    case awakeConfirmed
    case prayerCTAAvailable
    case prayerConfirmed
    case fiveMinutesBeforeFajrEnds
    case afterFajrEnds
    case beforeFinalThird
    case atFinalThirdBegins
    case suhoorWindowOpen
    case suhoorCutoff
    case beforePrimarySuhoorWake
    case atPrimarySuhoorWake
    case primarySuhoorAlarmFired
    case suhoorAwakeConfirmed
    case fastingIntentConfirmed
    case fajrBeginsAfterSuhoor
    case fajrPrayerCTAAvailable
    case fajrPrayerConfirmed
    case quietFajrActive
    case quietMorningLogged

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daytime:
            return "Daytime"
        case .evening:
            return "Evening"
        case .beforeMidnight:
            return "Before midnight"
        case .midnight:
            return "Midnight"
        case .beforeFajrBegins:
            return "Before Fajr begins"
        case .atFajrBegins:
            return "At Fajr begins"
        case .fajrActiveWindow:
            return "Fajr active window"
        case .beforePrimaryWake:
            return "Before primary alarm"
        case .atPrimaryWake:
            return "At primary alarm"
        case .defaultWakeTime:
            return "Default wake time"
        case .primaryAlarmFired:
            return "Primary alarm fired"
        case .wakeCheck1Pending:
            return "Wake check 1 pending"
        case .wakeCheck2Pending:
            return "Wake check 2 pending"
        case .wakeCheck3Pending:
            return "Wake check 3 pending"
        case .wakeCheck4Pending:
            return "Wake check 4 pending"
        case .wakeCheck5Pending:
            return "Wake check 5 pending"
        case .finalWakeCheck:
            return "Final check"
        case .awakeConfirmed:
            return "Awake confirmed"
        case .prayerCTAAvailable:
            return "Prayer CTA available"
        case .prayerConfirmed:
            return "Prayer confirmed"
        case .fiveMinutesBeforeFajrEnds:
            return "5 min before Fajr ends"
        case .afterFajrEnds:
            return "After Fajr ends"
        case .beforeFinalThird:
            return "Before final third"
        case .atFinalThirdBegins:
            return "At final third begins"
        case .suhoorWindowOpen:
            return "Suhoor window open"
        case .suhoorCutoff:
            return "Suhoor cutoff"
        case .beforePrimarySuhoorWake:
            return "Before primary Suhoor alarm"
        case .atPrimarySuhoorWake:
            return "At primary Suhoor alarm"
        case .primarySuhoorAlarmFired:
            return "Primary Suhoor alarm fired"
        case .suhoorAwakeConfirmed:
            return "Suhoor awake confirmed"
        case .fastingIntentConfirmed:
            return "Fasting intent confirmed"
        case .fajrBeginsAfterSuhoor:
            return "Fajr begins after Suhoor"
        case .fajrPrayerCTAAvailable:
            return "Fajr prayer CTA available"
        case .fajrPrayerConfirmed:
            return "Fajr prayer confirmed"
        case .quietFajrActive:
            return "Quiet before alarm"
        case .quietMorningLogged:
            return "quietMorning logged"
        }
    }

    var wakeCheckIndex: Int? {
        switch self {
        case .wakeCheck1Pending:
            return 1
        case .wakeCheck2Pending:
            return 2
        case .wakeCheck3Pending:
            return 3
        case .wakeCheck4Pending:
            return 4
        case .wakeCheck5Pending:
            return 5
        default:
            return nil
        }
    }
}

enum WakeSessionMappedSequenceLength: Int, CaseIterable, Identifiable, Sendable {
    case primaryOnly = 0
    case primaryPlusOne = 1
    case primaryPlusTwo = 2
    case primaryPlusThree = 3
    case primaryPlusFour = 4
    case primaryPlusFive = 5

    static let defaultSelection: WakeSessionMappedSequenceLength = .primaryPlusFive

    var id: Int { rawValue }

    var requestedWakeCheckCount: Int { rawValue }

    var title: String {
        switch self {
        case .primaryOnly:
            return "Primary only"
        case .primaryPlusOne:
            return "Primary + 1 follow-up alarm"
        case .primaryPlusTwo:
            return "Primary + 2 follow-up alarms"
        case .primaryPlusThree:
            return "Primary + 3 follow-up alarms"
        case .primaryPlusFour:
            return "Primary + 4 follow-up alarms"
        case .primaryPlusFive:
            return "Primary + 5 follow-up alarms"
        }
    }
}

struct SimulatedPrayerWindow: Equatable, Sendable {
    let finalThirdStart: Date?
    let fajrBegins: Date
    let fajrEnds: Date?
    let maghrib: Date
}

struct MappedAlarmEvent: Identifiable, Equatable, Sendable {
    let id: String
    let event: ScheduledEvent
    let role: WakeSessionTestAlarmRole
    let simulatedFireDate: Date
    let mappedRealFireDate: Date
}

struct AlarmKitMappingPlan: Equatable, Sendable {
    let simulationID: String
    let anchorEventID: String
    let startDelaySeconds: TimeInterval
    let sequenceLength: WakeSessionMappedSequenceLength
    let createdAtRealDate: Date
    let mappedEvents: [MappedAlarmEvent]
    let cutoffExplanation: String?

    var realEvents: [ScheduledEvent] {
        mappedEvents.map(\.event)
    }

    var nextPending: MappedAlarmEvent? {
        mappedEvents
            .filter { $0.mappedRealFireDate >= createdAtRealDate }
            .sorted { $0.mappedRealFireDate < $1.mappedRealFireDate }
            .first
    }
}

struct ActiveSimulationContext: Equatable, Identifiable, Sendable {
    let simulationID: String
    let isTest: Bool
    var scenarioKind: WakeSessionSimulationScenarioKind
    var runMode: SimulationRunMode
    var simulatedDate: Date
    var simulatedNow: Date
    var simulatedTimeZone: TimeZone
    var simulatedLocation: SimulationLocation
    var prayerWindowSource: SimulationPrayerWindowSource
    var simulatedPrayerWindow: SimulatedPrayerWindow
    var wakePurpose: WakePurpose
    var dateAlarmOverride: DateAlarmOverride
    var globalWakeAlarmPolicy: GlobalWakeAlarmPolicy
    var resolvedAlarmState: ResolvedAlarmState
    var wakeSessionID: String?
    var alarmMapping: AlarmKitMappingPlan?
    var clockMode: SimulationClockMode
    var jumpPoint: WakeSessionSimulationJumpPoint?
    let createdAtRealDate: Date

    var id: String { simulationID }

    var scenarioTitle: String {
        scenarioKind.title
    }
}

struct HomeSimulationOverlayModel: Equatable, Sendable {
    let title: String
    let scenario: String
    let wakePurpose: String
    let alarmState: String
    let simulatedDateTime: String
    let simulatedHijriDate: String?
    let location: String
    let fajrRange: String
    let alarmTime: String
    let runMode: String
    let jumpPoint: String
    let expectedStateGuidance: String
    let expectedHeroSummary: String
    let hasScheduledTestAlarms: Bool
    let nextRealAlarmCountdown: String?
    let nextSimulatedEventName: String?
    let nextMappedRealFireTime: String?
}

enum WakeSessionLabTopLevelArea: String, CaseIterable, Identifiable, Sendable {
    case previewHomeUI
    case realAlarmTest
    case diagnostics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .previewHomeUI:
            return "Preview Home UI"
        case .realAlarmTest:
            return "Real Alarm Test"
        case .diagnostics:
            return "Diagnostics"
        }
    }
}

enum WakeSessionCustomPreviewMode: String, CaseIterable, Identifiable, Sendable {
    case fajr
    case suhoor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fajr:
            return "Fajr"
        case .suhoor:
            return "Suhoor"
        }
    }

    var wakePurpose: WakePurpose {
        switch self {
        case .fajr:
            return .fajr
        case .suhoor:
            return .suhoor
        }
    }

    var scenario: WakeSessionTestScenario {
        switch self {
        case .fajr:
            return .fajrStateExplorer
        case .suhoor:
            return .suhoorStateExplorer
        }
    }
}

enum WakeSessionCustomAlarmState: String, CaseIterable, Identifiable, Sendable {
    case active
    case quiet
    case paused
    case ringsOnce
    case blocked
    case issue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active:
            return "Active"
        case .quiet:
            return "Quiet for this morning"
        case .paused:
            return "Alarms paused"
        case .ringsOnce:
            return "Ring this morning only"
        case .blocked:
            return "Blocked"
        case .issue:
            return "Alarm setup issue"
        }
    }

    var shortTitle: String {
        switch self {
        case .active:
            return "Active"
        case .quiet:
            return "Quiet"
        case .paused:
            return "Paused"
        case .ringsOnce:
            return "Rings once"
        case .blocked:
            return "Blocked"
        case .issue:
            return "Issue"
        }
    }

    var dateAlarmOverride: DateAlarmOverride {
        switch self {
        case .quiet:
            return .quiet
        case .ringsOnce:
            return .ringDespitePause
        case .active, .paused, .blocked, .issue:
            return .none
        }
    }

    var globalWakeAlarmPolicy: GlobalWakeAlarmPolicy {
        switch self {
        case .paused, .ringsOnce:
            return .pausedIndefinitely
        case .active, .quiet, .blocked, .issue:
            return .active
        }
    }

    var resolvedAlarmState: ResolvedAlarmState {
        switch self {
        case .active:
            return .active
        case .quiet:
            return .quiet
        case .paused:
            return .pausedInherited
        case .ringsOnce:
            return .ringsOnceDespitePause
        case .blocked:
            return .blocked
        case .issue:
            return .issue
        }
    }
}

enum WakeSessionScenarioGroup: String, CaseIterable, Identifiable, Sendable {
    case planAndPreview
    case quietAndPause
    case wakeExecution
    case suhoorToFajrHandoff
    case dateContexts
    case setupIssueStates
    case crossSurfaceChecks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planAndPreview:
            return "Plan & Preview"
        case .quietAndPause:
            return "Quiet & Pause"
        case .wakeExecution:
            return "Wake Execution"
        case .suhoorToFajrHandoff:
            return "Suhoor -> Fajr Handoff"
        case .dateContexts:
            return "Date Contexts"
        case .setupIssueStates:
            return "Setup / Issue States"
        case .crossSurfaceChecks:
            return "Cross-Surface Checks"
        }
    }
}

struct WakeSessionPreviewScenarioCard: Identifiable, Equatable, Sendable {
    let id: String
    let group: WakeSessionScenarioGroup
    let title: String
    let description: String
    let wakePurpose: WakePurpose
    let alarmState: WakeSessionCustomAlarmState
    let datePreset: WakeSessionSimulationDatePreset
    let dateContext: String
    let whatThisTests: String
    let realAlarms: String
    let approximateDuration: String
    let whatToExpect: String
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let scenario: WakeSessionTestScenario?
    let initialJumpPoint: WakeSessionSimulationJumpPoint?

    static let defaultCards: [WakeSessionPreviewScenarioCard] = [
        WakeSessionPreviewScenarioCard(
            id: "active-fajr-morning",
            group: .planAndPreview,
            title: "Active Fajr Morning",
            description: "Preview normal Fajr planning and wake execution.",
            wakePurpose: .fajr,
            alarmState: .active,
            datePreset: .tomorrow,
            dateContext: "Tomorrow · ordinary morning",
            whatThisTests: "Active Fajr, calculated Fajr begins/end, Fajr alarm time, follow-up alarms, awake acknowledgement, and Fajr prayer logging.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "1-2 minutes",
            whatToExpect: "Home opens with TEST MODE ACTIVE. The selector stays Fajr/Suhoor and the alarm state stays Active until execution.",
            primaryActionTitle: "Preview on Home",
            secondaryActionTitle: "Inspect expected states",
            scenario: .fajrStateExplorer,
            initialJumpPoint: .beforePrimaryWake
        ),
        WakeSessionPreviewScenarioCard(
            id: "active-suhoor-morning",
            group: .planAndPreview,
            title: "Active Suhoor Morning",
            description: "Preview normal Suhoor wake and fasting flow.",
            wakePurpose: .suhoor,
            alarmState: .active,
            datePreset: .ramadanDay,
            dateContext: "Ramadan-capable morning",
            whatThisTests: "Active Suhoor, calculated Fajr begins, Suhoor alarm time, follow-up cutoff, awake acknowledgement, and fasting today as a separate fact.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "1-2 minutes",
            whatToExpect: "Home opens in a Suhoor planning state. Use Next State to reach Suhoor awake and fasting states.",
            primaryActionTitle: "Preview on Home",
            secondaryActionTitle: "Inspect expected states",
            scenario: .suhoorStateExplorer,
            initialJumpPoint: .beforePrimarySuhoorWake
        ),
        WakeSessionPreviewScenarioCard(
            id: "quiet-pause-pack",
            group: .quietAndPause,
            title: "Quiet & Pause Pack",
            description: "Preview Quiet, global Pause, and one-morning ring exception states.",
            wakePurpose: .fajr,
            alarmState: .quiet,
            datePreset: .tomorrow,
            dateContext: "Tomorrow · ordinary morning",
            whatThisTests: "Quiet Fajr, Quiet Suhoor, Alarms paused, Rings tomorrow only, Quiet surviving resume, and Quiet unavailable after execution begins.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "1-2 minutes",
            whatToExpect: "Quiet and Pause appear as alarm status, not as wake-purpose choices.",
            primaryActionTitle: "Preview on Home",
            secondaryActionTitle: "Open pack details",
            scenario: .quietBeforeExecution,
            initialJumpPoint: .quietFajrActive
        ),
        WakeSessionPreviewScenarioCard(
            id: "suhoor-fajr-handoff",
            group: .suhoorToFajrHandoff,
            title: "Suhoor -> Fajr Handoff",
            description: "Preview Suhoor wake, fasting status, Fajr wake acknowledgement, and Fajr prayer logging as separate steps.",
            wakePurpose: .suhoor,
            alarmState: .active,
            datePreset: .ramadanDay,
            dateContext: "Ramadan-capable morning",
            whatThisTests: "Suhoor I am awake, I am fasting today, Fajr begins, I am awake for Fajr, and I prayed Fajr as separate test-only facts.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "2-3 minutes",
            whatToExpect: "Use Next State through the handoff. Suhoor acknowledgement must not unlock Fajr prayer by itself.",
            primaryActionTitle: "Preview on Home",
            secondaryActionTitle: "Inspect expected states",
            scenario: .suhoorUnconfirmedToFajr,
            initialJumpPoint: .beforePrimarySuhoorWake
        ),
        WakeSessionPreviewScenarioCard(
            id: "custom-test-builder",
            group: .dateContexts,
            title: "Custom Test Builder",
            description: "Choose date, location, wake purpose, alarm state, and execution point.",
            wakePurpose: .fajr,
            alarmState: .active,
            datePreset: .tomorrow,
            dateContext: "Any supported test date",
            whatThisTests: "Day Detail, Next 7, Month Planning, Weekly Fajrcast, scheduler consequences, logs, resolver diagnostics, and seasonal date contexts.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "As long as needed.",
            whatToExpect: "Advanced controls stay collapsed until needed. Wake purpose only offers Fajr and Suhoor.",
            primaryActionTitle: "Open Custom Builder",
            secondaryActionTitle: "View diagnostics",
            scenario: nil,
            initialJumpPoint: nil
        )
    ]
}

struct WakeSessionRealAlarmScenarioCard: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String
    let whatThisTests: String
    let realAlarms: String
    let approximateDuration: String
    let whatToExpect: String
    let primaryActionTitle: String
    let scenario: WakeSessionTestScenario

    static let defaultCards: [WakeSessionRealAlarmScenarioCard] = [
        WakeSessionRealAlarmScenarioCard(
            id: "fajr-alarm-test",
            title: "Fajr Alarm Test",
            description: "Map a simulated Fajr Wake Session onto real alarms starting soon.",
            whatThisTests: "Real AlarmKit ringing, in-app awake acknowledgement, and five-minute follow-up alarms.",
            realAlarms: "Yes. Your iPhone will ring.",
            approximateDuration: "Primary only: a few minutes. Full sequence: about 25-30 minutes.",
            whatToExpect: "The primary alarm rings first. If awake is not confirmed, the next follow-up alarm rings five minutes later.",
            primaryActionTitle: "Set Up Fajr Alarm Test",
            scenario: .fajrStateExplorer
        ),
        WakeSessionRealAlarmScenarioCard(
            id: "suhoor-alarm-test",
            title: "Suhoor Alarm Test",
            description: "Map a simulated Suhoor Wake Session onto real alarms starting soon.",
            whatThisTests: "Suhoor alarm delivery, awake confirmation, separate fasting status, and follow-up cancellation.",
            realAlarms: "Yes. Your iPhone will ring.",
            approximateDuration: "Primary only: a few minutes. Full sequence: about 25-30 minutes.",
            whatToExpect: "Confirming awake for Suhoor cancels remaining checks; fasting intent is confirmed separately.",
            primaryActionTitle: "Set Up Suhoor Alarm Test",
            scenario: .suhoorStateExplorer
        ),
        WakeSessionRealAlarmScenarioCard(
            id: "system-dismissal-test",
            title: "System Dismissal Test",
            description: "Verify explicit system alarm dismissal records awake acknowledgement where supported.",
            whatThisTests: "acknowledgedBy = systemAlarmDismiss, remaining follow-ups cancelled where callback support is available, and diagnostics if callback support is unavailable.",
            realAlarms: "Yes. Your iPhone will ring.",
            approximateDuration: "Primary only: a few minutes. Full sequence: about 25-30 minutes.",
            whatToExpect: "Dismiss the system alarm, then confirm Diagnostics records the system acknowledgement source.",
            primaryActionTitle: "Set Up Dismissal Test",
            scenario: .alarmStopVsAwake
        ),
        WakeSessionRealAlarmScenarioCard(
            id: "cancel-remaining-alarms-test",
            title: "Cancel Remaining Alarms Test",
            description: "Verify acknowledging awake cancels every remaining test follow-up alarm.",
            whatThisTests: "I am awake cancels pending follow-ups and leaves no stale test alarms.",
            realAlarms: "Yes. Your iPhone will ring.",
            approximateDuration: "Primary + 1: about 7 minutes. Full sequence: about 25-30 minutes.",
            whatToExpect: "After confirming awake, open Scheduled Test Alarms and confirm pending follow-ups are cancelled.",
            primaryActionTitle: "Set Up Cancel Test",
            scenario: .sliderReschedule
        )
    ]
}

struct WakeSessionTimeValidationReport: Equatable, Sendable {
    let passed: Bool
    let reason: String?
    let simulatedNow: Date
    let timeZone: TimeZone
    let location: String
    let prayerTimeSource: String
    let fajrBegins: Date?
    let fajrEnds: Date?
    let selectedWakePurpose: WakePurpose
    let savedFajrAlarmTime: Date?
    let savedSuhoorAlarmTime: Date?
    let resolvedAlarmTime: Date?
    let primaryAlarmTime: Date?
    let followUpAlarmTimes: [Date]
    let cutoffBoundary: Date?
    let omittedFollowUpReason: String?
}

struct WakeSessionHeroSlotInspectionRow: Identifiable, Equatable, Sendable {
    let id: String
    let slot: String
    let expected: String
    let actual: String
    let passed: Bool
}

struct WakeSessionSurfaceConsistencyRow: Identifiable, Equatable, Sendable {
    let id: String
    let surface: String
    let expectedState: String
    let actualState: String
    let passed: Bool
}
