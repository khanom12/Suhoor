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
            return "Fajr State Explorer"
        case .suhoorStateExplorer:
            return "Suhoor State Explorer"
        case .suhoorUnconfirmedToFajr:
            return "Suhoor Not Confirmed -> Fajr Begins"
        case .quietBeforeExecution:
            return "Quiet Before Execution"
        case .sliderReschedule:
            return "Slider Reschedule Test"
        case .alarmStopVsAwake:
            return "Alarm Stop vs Awake"
        case .permissionFailure:
            return "Permission Failure"
        case .morningLogInspector:
            return "MorningLog Inspector"
        case .crossSurfaceConsistency:
            return "Cross-Surface Consistency"
        case .realAlarmKitMappedPlayback:
            return "Real AlarmKit Mapped Playback"
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
    case stateExplorer
    case previewHomeUI
    case homeSimulation
    case realAlarmKitMappedPlayback
    case fakeSchedulerPlayback
    case dryRun

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stateExplorer:
            return "State Explorer"
        case .previewHomeUI:
            return "Preview Home UI"
        case .homeSimulation:
            return "Home Simulation"
        case .realAlarmKitMappedPlayback:
            return "Real Alarm Test"
        case .fakeSchedulerPlayback:
            return "Fake Scheduler Playback"
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

enum SimulationPrayerWindowSource: String, CaseIterable, Identifiable, Sendable {
    case realCalculation
    case customArtificialWindow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .realCalculation:
            return "Real Calculation"
        case .customArtificialWindow:
            return "Custom Window"
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
    case beforeFajrBegins
    case atFajrBegins
    case beforePrimaryWake
    case atPrimaryWake
    case primaryAlarmFired
    case wakeCheck1Pending
    case wakeCheck2Pending
    case wakeCheck3Pending
    case wakeCheck4Pending
    case wakeCheck5Pending
    case awakeConfirmed
    case prayerCTAAvailable
    case prayerConfirmed
    case fiveMinutesBeforeFajrEnds
    case afterFajrEnds
    case beforeFinalThird
    case atFinalThirdBegins
    case suhoorWindowOpen
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
        case .beforeFajrBegins:
            return "Before Fajr begins"
        case .atFajrBegins:
            return "At Fajr begins"
        case .beforePrimaryWake:
            return "Before primary alarm"
        case .atPrimaryWake:
            return "At primary alarm"
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
            return "Primary + 1 wake check"
        case .primaryPlusTwo:
            return "Primary + 2 wake checks"
        case .primaryPlusThree:
            return "Primary + 3 wake checks"
        case .primaryPlusFour:
            return "Primary + 4 wake checks"
        case .primaryPlusFive:
            return "Primary + 5 wake checks"
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
    let simulatedDateTime: String
    let simulatedHijriDate: String?
    let location: String
    let runMode: String
    let jumpPoint: String
    let expectedStateGuidance: String
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
    case quiet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fajr:
            return "Fajr"
        case .suhoor:
            return "Suhoor"
        case .quiet:
            return "Quiet"
        }
    }

    var scenario: WakeSessionTestScenario {
        switch self {
        case .fajr:
            return .fajrStateExplorer
        case .suhoor:
            return .suhoorStateExplorer
        case .quiet:
            return .quietBeforeExecution
        }
    }
}

struct WakeSessionPreviewScenarioCard: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String
    let whatThisTests: String
    let realAlarms: String
    let approximateDuration: String
    let whatToExpect: String
    let primaryActionTitle: String
    let scenario: WakeSessionTestScenario?
    let initialJumpPoint: WakeSessionSimulationJumpPoint?

    static let defaultCards: [WakeSessionPreviewScenarioCard] = [
        WakeSessionPreviewScenarioCard(
            id: "fajr-flow",
            title: "Fajr Flow",
            description: "Preview the Home Hero from Fajr beginning to prayer confirmation.",
            whatThisTests: "Active Fajr, Time to wake, Next alarm soon, Final alarm this morning, post-awake Fajr, and Fajr prayer confirmation.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "1-2 minutes.",
            whatToExpect: "Home will open with TEST MODE ACTIVE. Use Next State to move through the Fajr flow.",
            primaryActionTitle: "Start Fajr Preview",
            scenario: .fajrStateExplorer,
            initialJumpPoint: .atFajrBegins
        ),
        WakeSessionPreviewScenarioCard(
            id: "suhoor-flow",
            title: "Suhoor Flow",
            description: "Preview the Suhoor alarm, fasting intention, and the handoff to Fajr prayer.",
            whatThisTests: "Active Suhoor, post-awake Suhoor, boundary cutoff, fasting intent, and the Fajr-end handoff.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "1-2 minutes.",
            whatToExpect: "Home will open in a Suhoor state. Use Next State to reach Fajr handoff states.",
            primaryActionTitle: "Start Suhoor Preview",
            scenario: .suhoorStateExplorer,
            initialJumpPoint: .suhoorWindowOpen
        ),
        WakeSessionPreviewScenarioCard(
            id: "quiet-flow",
            title: "Quiet Before Execution",
            description: "Preview a morning that is set Quiet before the first alarm begins.",
            whatThisTests: "Quiet Fajr, Quiet Suhoor vocabulary, preserved wake purpose, no active-session Quiet action, and quietMorning logging.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "1-2 minutes.",
            whatToExpect: "Home will show Quiet as an alarm state without scheduling or exposing an active wake action.",
            primaryActionTitle: "Start Quiet Preview",
            scenario: .quietBeforeExecution,
            initialJumpPoint: .quietFajrActive
        ),
        WakeSessionPreviewScenarioCard(
            id: "paused-exception-states",
            title: "Paused & Ring Exception",
            description: "Preview the wording for globally paused alarms and the one-morning ring exception.",
            whatThisTests: "Paused Fajr, Paused Suhoor, Rings tomorrow only while paused, and alarm-state vocabulary separate from Fajr/Suhoor purpose.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "1 minute.",
            whatToExpect: "Use Custom Preview for the exact date; the card keeps Pause and ring-once checks grouped for review.",
            primaryActionTitle: "Start Pause Preview",
            scenario: .fajrStateExplorer,
            initialJumpPoint: .beforePrimaryWake
        ),
        WakeSessionPreviewScenarioCard(
            id: "setup-issue-states",
            title: "Setup & Alarm Issue",
            description: "Preview setup and delivery issue language without changing real permissions.",
            whatThisTests: "Turn on alarms, Set location, Alarm issue, permission failure, and degraded delivery messaging.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "1 minute.",
            whatToExpect: "The harness uses simulated permission states; real iOS permission settings are not changed.",
            primaryActionTitle: "Start Issue Preview",
            scenario: .permissionFailure,
            initialJumpPoint: .beforePrimaryWake
        ),
        WakeSessionPreviewScenarioCard(
            id: "boundary-handoff-states",
            title: "Boundary & Handoff",
            description: "Preview state changes around Fajr begin, Fajr end, and Suhoor-to-Fajr handoff.",
            whatThisTests: "Boundary state, cutoff behavior, post-awake handoff, and Fajr-end next-morning handoff.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "1-2 minutes.",
            whatToExpect: "Home will open near the handoff path; use Next State to walk through the boundary states.",
            primaryActionTitle: "Start Handoff Preview",
            scenario: .suhoorUnconfirmedToFajr,
            initialJumpPoint: .fajrBeginsAfterSuhoor
        ),
        WakeSessionPreviewScenarioCard(
            id: "custom-date-time",
            title: "Custom Date & Time",
            description: "Choose any date, time, location, and state to preview on Home.",
            whatThisTests: "Seasonal timing, Ramadan/Eid/White Day contexts, custom locations, and specific Hero states.",
            realAlarms: "No. This is a Home preview.",
            approximateDuration: "As long as needed.",
            whatToExpect: "Choose Date, Location, Mode, and State, then preview the real Home UI.",
            primaryActionTitle: "Open Custom Preview",
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
            whatThisTests: "Real AlarmKit ringing, Stop, Open Subh, and five-minute Wake Checks.",
            realAlarms: "Yes. Your iPhone will ring.",
            approximateDuration: "Primary only: a few minutes. Full sequence: about 25-30 minutes.",
            whatToExpect: "The primary alarm rings first. If you stop it without confirming awake, the next Wake Check rings five minutes later.",
            primaryActionTitle: "Set Up Fajr Alarm Test",
            scenario: .fajrStateExplorer
        ),
        WakeSessionRealAlarmScenarioCard(
            id: "suhoor-alarm-test",
            title: "Suhoor Alarm Test",
            description: "Map a simulated Suhoor Wake Session onto real alarms starting soon.",
            whatThisTests: "Suhoor alarm delivery, awake confirmation, separate fasting intent, and Wake Check cancellation.",
            realAlarms: "Yes. Your iPhone will ring.",
            approximateDuration: "Primary only: a few minutes. Full sequence: about 25-30 minutes.",
            whatToExpect: "Confirming awake for Suhoor cancels remaining checks; fasting intent is confirmed separately.",
            primaryActionTitle: "Set Up Suhoor Alarm Test",
            scenario: .suhoorStateExplorer
        )
    ]
}
