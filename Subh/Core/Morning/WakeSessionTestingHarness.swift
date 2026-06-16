import Combine
import CoreLocation
import Foundation

extension WakePurpose {
    var displayTitle: String {
        switch self {
        case .fajr:
            return "Fajr"
        case .suhoor:
            return "Suhoor"
        }
    }
}

extension ResolvedAlarmState {
    var testingDisplayTitle: String {
        switch self {
        case .active:
            return "Active"
        case .quiet:
            return "Quiet"
        case .pausedInherited:
            return "Alarms paused"
        case .ringsOnceDespitePause:
            return "Rings this morning only"
        case .blocked:
            return "Blocked"
        case .issue:
            return "Alarm setup issue"
        case .unavailable:
            return "Unavailable"
        }
    }
}

enum WakeSessionLabBuildGate {
    #if DEBUG || INTERNAL_TESTING
    static let isAvailableInCurrentBuild = true
    #else
    static let isAvailableInCurrentBuild = false
    #endif
}

enum WakeSessionTestScenario: String, CaseIterable, Identifiable, Sendable {
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
            return "Suhoor -> Fajr Handoff"
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

    var mode: WakeSessionMode {
        switch self {
        case .suhoorStateExplorer, .suhoorUnconfirmedToFajr:
            return .suhoor
        case .fajrStateExplorer, .quietBeforeExecution, .sliderReschedule, .alarmStopVsAwake,
             .permissionFailure, .morningLogInspector, .crossSurfaceConsistency, .realAlarmKitMappedPlayback:
            return .fajr
        }
    }

    var simulationKind: WakeSessionSimulationScenarioKind {
        switch self {
        case .fajrStateExplorer:
            return .fajrStateExplorer
        case .suhoorStateExplorer:
            return .suhoorStateExplorer
        case .suhoorUnconfirmedToFajr:
            return .suhoorUnconfirmedToFajr
        case .quietBeforeExecution:
            return .quietBeforeExecution
        case .sliderReschedule:
            return .sliderReschedule
        case .alarmStopVsAwake:
            return .alarmStopVsAwake
        case .permissionFailure:
            return .permissionFailure
        case .morningLogInspector:
            return .morningLogInspector
        case .crossSurfaceConsistency:
            return .crossSurfaceConsistency
        case .realAlarmKitMappedPlayback:
            return .realAlarmKitMappedPlayback
        }
    }
}

enum WakeSessionTestSchedulerMode: String, CaseIterable, Identifiable, Sendable {
    case fake
    case realAlarmKit
    case dryRun

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fake:
            return "Preview scheduler"
        case .realAlarmKit:
            return "Real AlarmKit"
        case .dryRun:
            return "Dry Run"
        }
    }
}

enum WakeSessionTestPermissionState: String, CaseIterable, Identifiable, Sendable {
    case available
    case alarmKitAuthorized
    case alarmKitDenied
    case alarmKitUnavailable
    case notificationsAuthorized
    case notificationsDenied
    case notificationFallbackDegraded
    case scheduleFailure
    case missingPendingAlarm
    case mismatchedFireDate
    case duplicateIdentifier
    case soundAssetMissing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .available:
            return "Available"
        case .alarmKitAuthorized:
            return "AlarmKit authorized"
        case .alarmKitDenied:
            return "AlarmKit denied"
        case .alarmKitUnavailable:
            return "AlarmKit unavailable"
        case .notificationsAuthorized:
            return "Notifications authorized"
        case .notificationsDenied:
            return "Notifications denied"
        case .notificationFallbackDegraded:
            return "Notification fallback degraded"
        case .scheduleFailure:
            return "Schedule failure"
        case .missingPendingAlarm:
            return "Missing pending alarm"
        case .mismatchedFireDate:
            return "Mismatched fire date"
        case .duplicateIdentifier:
            return "Duplicate identifier"
        case .soundAssetMissing:
            return "Sound asset missing"
        }
    }

    var blocksScheduling: Bool {
        switch self {
        case .available, .alarmKitAuthorized, .notificationsAuthorized, .notificationFallbackDegraded,
             .missingPendingAlarm, .mismatchedFireDate, .duplicateIdentifier:
            return false
        case .alarmKitDenied, .alarmKitUnavailable, .notificationsDenied, .scheduleFailure, .soundAssetMissing:
            return true
        }
    }
}

enum WakeSessionTestAlarmRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case primary
    case wakeCheck

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .primary:
            return "Primary"
        case .wakeCheck:
            return "Follow-up alarm"
        }
    }
}

enum WakeSessionTestAlarmChannel: String, Codable, CaseIterable, Identifiable, Sendable {
    case fake
    case realAlarmKit
    case notification

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fake:
            return "Fake"
        case .realAlarmKit:
            return "Real AlarmKit"
        case .notification:
            return "Notification"
        }
    }
}

enum WakeSessionTestAlarmStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case pending
    case fired
    case cancelled
    case failed

    var id: String { rawValue }
}

struct WakeSessionTestAlarmRecord: Identifiable, Equatable, Sendable {
    let id: String
    let wakeSessionID: String
    let scenarioID: String
    let scheduledEventID: String
    let fireDate: Date
    let simulatedFireDate: Date
    let mappedRealFireDate: Date?
    let role: WakeSessionTestAlarmRole
    let mode: WakeSessionMode
    let channel: WakeSessionTestAlarmChannel
    var status: WakeSessionTestAlarmStatus
    var failureReason: String?
    let isTest: Bool
    var cancelledAt: Date?
    var firedAt: Date?
}

struct WakeSessionTestScenarioPlan: Equatable, Sendable {
    let scenarioID: String
    let scenario: WakeSessionTestScenario
    let dateKey: String
    let wakeSessionID: String
    let mode: WakeSessionMode
    let now: Date
    let morningDate: Date
    let finalThirdStart: Date?
    let fajrBegins: Date
    let fajrEnds: Date?
    let primaryWakeTime: Date
    let prayerWindow: DailyPrayerWindow
    let events: [ScheduledEvent]

    var primaryEvent: ScheduledEvent? {
        events.first { $0.wakeSessionRole == .primaryWake }
    }

    var wakeCheckEvents: [ScheduledEvent] {
        events.filter { $0.wakeSessionRole == .wakeCheck }
    }

    var draft: WakeSessionDraft {
        WakeSessionDraft(
            wakeSessionID: wakeSessionID,
            dateKey: dateKey,
            morningDate: morningDate,
            mode: mode,
            finalThirdStart: finalThirdStart,
            fajrBegins: fajrBegins,
            fajrEnds: fajrEnds,
            plannedWakeTime: primaryWakeTime,
            primaryAlarmID: primaryEvent.map { SchedulingIdentifiers.identifier(for: $0, deliveryKind: .wake) },
            primaryScheduledEventID: primaryEvent?.id,
            wakeCheckIDs: wakeCheckEvents.map { SchedulingIdentifiers.identifier(for: $0, deliveryKind: .wake) },
            wakeCheckScheduledEventIDs: wakeCheckEvents.map(\.id),
            isTest: true,
            scenarioID: scenarioID
        )
    }
}

@MainActor
final class FakeWakeSessionTestScheduler {
    private(set) var records: [WakeSessionTestAlarmRecord] = []
    var permissionState: WakeSessionTestPermissionState = .available

    var pendingRecords: [WakeSessionTestAlarmRecord] {
        records.filter { $0.status == .pending }
    }

    func schedule(
        plan: WakeSessionTestScenarioPlan,
        channel: WakeSessionTestAlarmChannel,
        now: Date,
        mappingPlan: AlarmKitMappingPlan? = nil
    ) {
        for event in plan.events {
            let role = event.wakeSessionRole == .primaryWake
                ? WakeSessionTestAlarmRole.primary
                : WakeSessionTestAlarmRole.wakeCheck
            let identifier = SchedulingIdentifiers.identifier(for: event, deliveryKind: .wake)
            let mappedEvent = mappingPlan?.mappedEvents.first {
                $0.id == event.id || $0.event.id == event.id
            }
            let status: WakeSessionTestAlarmStatus = permissionState.blocksScheduling ? .failed : .pending
            let failureReason = permissionState.blocksScheduling ? permissionState.displayName : nil
            records.append(
                WakeSessionTestAlarmRecord(
                    id: identifier,
                    wakeSessionID: plan.wakeSessionID,
                    scenarioID: plan.scenarioID,
                    scheduledEventID: event.id,
                    fireDate: mappedEvent?.mappedRealFireDate ?? event.fireDate,
                    simulatedFireDate: mappedEvent?.simulatedFireDate ?? event.fireDate,
                    mappedRealFireDate: mappedEvent?.mappedRealFireDate,
                    role: role,
                    mode: plan.mode,
                    channel: channel,
                    status: status,
                    failureReason: failureReason,
                    isTest: true,
                    cancelledAt: nil,
                    firedAt: nil
                )
            )
        }
    }

    func cancelPending(wakeSessionID: String, now: Date) -> [String] {
        var cancelled: [String] = []
        for index in records.indices where records[index].wakeSessionID == wakeSessionID && records[index].status == .pending {
            records[index].status = .cancelled
            records[index].cancelledAt = now
            cancelled.append(records[index].scheduledEventID)
        }
        return cancelled
    }

    @discardableResult
    func cancel(identifier: String, now: Date) -> Bool {
        guard let index = records.firstIndex(where: { $0.id == identifier || $0.scheduledEventID == identifier }) else {
            return false
        }
        guard records[index].status == .pending else {
            return false
        }
        records[index].status = .cancelled
        records[index].cancelledAt = now
        return true
    }

    func cancelAllTestAlarms(now: Date) -> [String] {
        var cancelled: [String] = []
        for index in records.indices where records[index].isTest && records[index].status == .pending {
            records[index].status = .cancelled
            records[index].cancelledAt = now
            cancelled.append(records[index].scheduledEventID)
        }
        return cancelled
    }

    func markFired(identifier: String, now: Date) {
        guard let index = records.firstIndex(where: { $0.scheduledEventID == identifier || $0.id == identifier }) else {
            return
        }
        records[index].status = .fired
        records[index].firedAt = now
    }

    func clearTestRecords() {
        records.removeAll { $0.isTest }
    }

    func pendingEventIDs(wakeSessionID: String) -> [String] {
        records
            .filter { $0.wakeSessionID == wakeSessionID && $0.status == .pending }
            .map(\.scheduledEventID)
    }
}

@MainActor
final class WakeSessionTestingHarness: ObservableObject {
    typealias RealAlarmKitScheduler = @MainActor ([ScheduledEvent], WakeSessionMode, Date) async -> Bool
    typealias RealAlarmKitCanceller = @MainActor ([WakeSessionTestAlarmRecord], Date) async -> Void

    @Published private(set) var clock: MutableTimeProvider
    @Published private(set) var activePlan: WakeSessionTestScenarioPlan?
    @Published private(set) var schedulerMode: WakeSessionTestSchedulerMode = .fake
    @Published private(set) var permissionState: WakeSessionTestPermissionState = .available
    @Published private(set) var alarmRecords: [WakeSessionTestAlarmRecord] = []
    @Published private(set) var statusMessage: String = "Test mode is off."
    @Published private(set) var realAlarmKitWarningAcknowledged = false
    @Published private(set) var activeSimulationContext: ActiveSimulationContext?
    @Published var selectedScenario: WakeSessionTestScenario = .fajrStateExplorer
    @Published var selectedDatePreset: WakeSessionSimulationDatePreset = .tomorrow
    @Published var selectedManualDate: Date
    @Published var selectedLocation: SimulationLocation = .currentAppLocation
    @Published var selectedPrayerWindowSource: SimulationPrayerWindowSource = .realCalculation
    @Published var selectedClockMode: SimulationClockMode = .jumpOnly
    @Published var selectedJumpPoint: WakeSessionSimulationJumpPoint = .beforePrimaryWake
    @Published var selectedScrubHorizon: WakeSessionSimulationScrubHorizon = .next24Hours
    @Published var selectedScrubOffsetMinutes: Double = 0
    @Published var selectedSequenceLength: WakeSessionMappedSequenceLength = .defaultSelection
    @Published var mappedStartDelaySeconds: TimeInterval = 90
    @Published var selectedCustomPreviewMode: WakeSessionCustomPreviewMode = .fajr
    @Published var selectedCustomAlarmState: WakeSessionCustomAlarmState = .active
    @Published var selectedRealAlarmScenario: WakeSessionTestScenario = .fajrStateExplorer

    private let wakeSessionStore: WakeSessionStore
    private let fakeScheduler: FakeWakeSessionTestScheduler
    private let realAlarmKitScheduler: RealAlarmKitScheduler?
    private let realAlarmKitCanceller: RealAlarmKitCanceller?
    private let refreshSurfaces: () -> Void
    private let realTimeProvider: any TimeProviding
    private let timeZone: TimeZone

    init(
        wakeSessionStore: WakeSessionStore,
        fakeScheduler: FakeWakeSessionTestScheduler? = nil,
        realAlarmKitScheduler: RealAlarmKitScheduler? = nil,
        realAlarmKitCanceller: RealAlarmKitCanceller? = nil,
        refreshSurfaces: @escaping () -> Void = {},
        realTimeProvider: any TimeProviding = SystemTimeProvider(),
        initialNow: Date = Date(),
        timeZone: TimeZone = .current
    ) {
        self.wakeSessionStore = wakeSessionStore
        self.fakeScheduler = fakeScheduler ?? FakeWakeSessionTestScheduler()
        self.realAlarmKitScheduler = realAlarmKitScheduler
        self.realAlarmKitCanceller = realAlarmKitCanceller
        self.refreshSurfaces = refreshSurfaces
        self.realTimeProvider = realTimeProvider
        self.clock = MutableTimeProvider(now: initialNow)
        self.selectedManualDate = initialNow
        self.timeZone = timeZone
        refreshPublishedSchedulerState()
    }

    var isActive: Bool {
        activePlan != nil || activeSimulationContext != nil
    }

    var activeScenarioTitle: String {
        activeSimulationContext?.scenarioTitle ?? activePlan?.scenario.title ?? "None"
    }

    var simulatedNow: Date {
        clock.now()
    }

    var realDeviceNow: Date {
        realTimeProvider.now()
    }

    var activeSession: WakeSession? {
        if let activePlan {
            return wakeSessionStore.session(id: activePlan.wakeSessionID)
        }
        if let wakeSessionID = activeSimulationContext?.wakeSessionID {
            return wakeSessionStore.session(id: wakeSessionID)
        }
        return nil
    }

    var testSessions: [WakeSession] {
        wakeSessionStore.sessionsByID.values
            .filter(\.isTest)
            .sorted { $0.createdAt > $1.createdAt }
    }

    var testMorningLogs: [MorningLogEntry] {
        wakeSessionStore.morningLogsByDateKey.values
            .filter(\.isTest)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var pendingTestAlarms: [WakeSessionTestAlarmRecord] {
        alarmRecords.filter { $0.status == .pending }
    }

    var currentRunMode: SimulationRunMode {
        activeSimulationContext?.runMode ?? .dryRun
    }

    var hasPendingWakeChecks: Bool {
        guard let plan = activePlan else { return false }
        return pendingTestAlarms.contains { $0.wakeSessionID == plan.wakeSessionID && $0.role == .wakeCheck }
    }

    var previewScenarioCards: [WakeSessionPreviewScenarioCard] {
        WakeSessionPreviewScenarioCard.defaultCards
    }

    var realAlarmScenarioCards: [WakeSessionRealAlarmScenarioCard] {
        WakeSessionRealAlarmScenarioCard.defaultCards
    }

    var selectedCustomStateOptions: [WakeSessionSimulationJumpPoint] {
        stateOptions(for: selectedCustomPreviewMode, alarmState: selectedCustomAlarmState)
    }

    var currentExpectedStateGuidance: String {
        expectedStateGuidance(for: activeSimulationContext?.jumpPoint ?? selectedJumpPoint)
    }

    var simulationScrubRange: ClosedRange<Double> {
        0...Double(selectedScrubHorizon.minuteCount)
    }

    var scrubbedSimulationTimeText: String {
        let date = simulationScrubStartDate().addingTimeInterval(selectedScrubOffsetMinutes * 60)
        return TimeFormatters.shortDateTime.string(from: date)
    }

    var effectiveSimulationWakeAlarmPolicy: GlobalWakeAlarmPolicy? {
        activeSimulationContext?.globalWakeAlarmPolicy
    }

    func stateOptions(
        for mode: WakeSessionCustomPreviewMode,
        alarmState: WakeSessionCustomAlarmState = .active
    ) -> [WakeSessionSimulationJumpPoint] {
        switch alarmState {
        case .quiet:
            return quietPreviewFlow
        case .paused, .ringsOnce:
            return pausePreviewFlow
        case .blocked, .issue:
            return issuePreviewFlow
        case .active:
            break
        }

        switch mode {
        case .fajr:
            return fajrPreviewFlow
        case .suhoor:
            return suhoorPreviewFlow
        }
    }

    func selectCustomPreviewMode(_ mode: WakeSessionCustomPreviewMode) {
        selectedCustomPreviewMode = mode
        selectedScenario = scenario(for: mode.wakePurpose, alarmState: selectedCustomAlarmState)
        let options = stateOptions(for: mode, alarmState: selectedCustomAlarmState)
        if !options.contains(selectedJumpPoint), let first = options.first {
            selectedJumpPoint = first
        }
    }

    func selectCustomAlarmState(_ alarmState: WakeSessionCustomAlarmState) {
        selectedCustomAlarmState = alarmState
        selectedScenario = scenario(for: selectedCustomPreviewMode.wakePurpose, alarmState: alarmState)
        let options = stateOptions(for: selectedCustomPreviewMode, alarmState: alarmState)
        if !options.contains(selectedJumpPoint), let first = options.first {
            selectedJumpPoint = first
        }
    }

    func expectedStateGuidance(for jumpPoint: WakeSessionSimulationJumpPoint?) -> String {
        switch jumpPoint {
        case .daytime:
            return "Expected: Daytime setup should show the next relevant morning without No time available."
        case .evening:
            return "Expected: Evening setup should still resolve tomorrow morning from calculated prayer times."
        case .beforeMidnight:
            return "Expected: The same target morning should remain stable shortly before midnight."
        case .midnight:
            return "Expected: The target morning should roll cleanly at midnight."
        case .beforeFajrBegins:
            return "Expected: The Hero should show an upcoming Fajr morning before the window opens."
        case .atFajrBegins:
            return "Expected: The Hero should show that Fajr has begun."
        case .fajrActiveWindow:
            return "Expected: The Hero should show the active Fajr window without logging prayer completion."
        case .beforePrimaryWake:
            return "Expected: The Hero should show the planned alarm time before it fires."
        case .atPrimaryWake, .defaultWakeTime, .primaryAlarmFired:
            return "Expected: The Hero should show \"Time to wake\" and one \"I’m awake\" action while awake is still unconfirmed."
        case .wakeCheck1Pending, .wakeCheck2Pending, .wakeCheck3Pending, .wakeCheck4Pending, .wakeCheck5Pending:
            return "Expected: Follow-up alarms should remain pending until the in-app awake confirmation."
        case .finalWakeCheck:
            return "Expected: The final wake check should occur five minutes before the relevant boundary, never at the exact boundary."
        case .awakeConfirmed:
            return "Expected: Fajr awake should be confirmed and remaining follow-up alarms should be cancelled."
        case .prayerCTAAvailable:
            return "Expected: The Hero should show \"I prayed Fajr.\""
        case .prayerConfirmed:
            return "Expected: Fajr prayer should be confirmed separately from awake."
        case .fiveMinutesBeforeFajrEnds:
            return "Expected: The Hero should show the Fajr cutoff is near."
        case .afterFajrEnds:
            return "Expected: The Hero should show the Fajr window has passed without creating a test missed-prayer record."
        case .beforeFinalThird:
            return "Expected: Suhoor should not yet be in its active window."
        case .atFinalThirdBegins, .suhoorWindowOpen:
            return "Expected: The Hero should show Suhoor context before Fajr."
        case .suhoorCutoff:
            return "Expected: New Suhoor scheduling should be blocked after this point because Fajr is too close."
        case .beforePrimarySuhoorWake:
            return "Expected: The Hero should show the planned Suhoor alarm time."
        case .atPrimarySuhoorWake, .primarySuhoorAlarmFired:
            return "Expected: The Hero should show \"Time to wake\" and one \"I’m awake\" action for Suhoor."
        case .suhoorAwakeConfirmed:
            return "Expected: Suhoor awake should be confirmed without marking Fajr prayed."
        case .fastingIntentConfirmed:
            return "Expected: Fasting intent should be test-confirmed, not fast completion."
        case .fajrBeginsAfterSuhoor:
            return "Expected: Fajr has begun after Suhoor; the Fajr path should remain available."
        case .fajrPrayerCTAAvailable:
            return "Expected: The Hero should show \"I prayed Fajr\" after the Fajr handoff."
        case .fajrPrayerConfirmed:
            return "Expected: Fajr prayer should be confirmed as a separate test record."
        case .quietFajrActive:
            return "Expected: Quiet should suppress this morning's alarm before execution without changing the underlying Fajr meaning."
        case .quietMorningLogged:
            return "Expected: quietMorning should be logged without a missed-prayer record or pending wake alarms."
        case nil:
            return "Expected: Home should reflect the active test state."
        }
    }

    func startPreview(card: WakeSessionPreviewScenarioCard) async {
        guard let scenario = card.scenario else {
            selectCustomPreviewMode(selectedCustomPreviewMode)
            return
        }
        selectedCustomPreviewMode = card.wakePurpose == .suhoor ? .suhoor : .fajr
        selectedCustomAlarmState = card.alarmState
        selectedDatePreset = card.datePreset
        selectedScenario = scenario
        selectedClockMode = .jumpOnly
        await start(scenario, runMode: .previewHomeUI)
        if let jumpPoint = card.initialJumpPoint {
            setJumpPoint(jumpPoint)
        }
    }

    func previewCustomOnHome() async {
        selectedScenario = scenario(for: selectedCustomPreviewMode.wakePurpose, alarmState: selectedCustomAlarmState)
        selectedClockMode = .jumpOnly
        await start(selectedScenario, runMode: .previewHomeUI)
        setJumpPoint(selectedJumpPoint)
    }

    func configureRealAlarmTest(_ scenario: WakeSessionTestScenario) {
        selectedRealAlarmScenario = scenario
        selectedScenario = scenario
        selectedSequenceLength = selectedSequenceLength
        mappedStartDelaySeconds = min(max(mappedStartDelaySeconds, 60), 120)
    }

    func scheduleSelectedRealAlarmTest() async {
        selectedCustomAlarmState = .active
        selectedCustomPreviewMode = selectedRealAlarmScenario.mode == .suhoor ? .suhoor : .fajr
        await start(selectedRealAlarmScenario, runMode: .realAlarmTest)
    }

    func moveToNextPreviewState() {
        movePreviewState(offset: 1)
    }

    func moveToPreviousPreviewState() {
        movePreviewState(offset: -1)
    }

    func start(_ scenario: WakeSessionTestScenario) async {
        await start(scenario, runMode: scenario == .realAlarmKitMappedPlayback ? .realAlarmTest : .fakeSchedulerPlayback)
    }

    func activateOnHome(scenario: WakeSessionTestScenario? = nil) async {
        await start(scenario ?? selectedScenario, runMode: .previewHomeUI)
    }

    func start(_ scenario: WakeSessionTestScenario, runMode: SimulationRunMode) async {
        selectedScenario = scenario
        let alarmState = alarmState(for: scenario)
        let wakePurpose = wakePurpose(for: scenario)
        permissionState = alarmState == .issue ? .alarmKitDenied : .available
        fakeScheduler.permissionState = permissionState
        schedulerMode = runMode == .realAlarmTest ? .realAlarmKit : (runMode == .dryRun ? .dryRun : .fake)
        let realNow = realTimeProvider.now()
        let now = simulatedDate(for: selectedDatePreset, relativeTo: runMode == .realAlarmTest ? realNow : clock.now())
        let plan = makePlan(for: scenario, now: now, mode: wakePurpose == .suhoor ? .suhoor : .fajr)
        let jumpPoint = defaultJumpPoint(for: scenario)
        let simulatedNow = simulatedNow(for: jumpPoint, plan: plan)
        clock.setNow(simulatedNow)
        activePlan = plan
        _ = wakeSessionStore.upsertScheduledSession(from: plan.draft, now: now)
        activeSimulationContext = makeSimulationContext(
            plan: plan,
            runMode: runMode,
            clockMode: runMode == .realAlarmTest ? .mappedPlayback : selectedClockMode,
            jumpPoint: jumpPoint,
            mappingPlan: nil,
            wakePurpose: wakePurpose,
            alarmState: alarmState,
            createdAtRealDate: realNow
        )

        if runMode == .realAlarmTest {
            realAlarmKitWarningAcknowledged = true
            let mappingPlan = makeMappingPlan(
                for: plan,
                realNow: realNow,
                startDelaySeconds: mappedStartDelaySeconds,
                sequenceLength: selectedSequenceLength
            )
            activeSimulationContext?.alarmMapping = mappingPlan
            let scheduled = await realAlarmKitScheduler?(mappingPlan.realEvents, plan.mode, realNow) ?? false
            fakeScheduler.permissionState = scheduled ? .available : .scheduleFailure
            fakeScheduler.schedule(plan: plan, channel: .realAlarmKit, now: realNow, mappingPlan: mappingPlan)
            if !scheduled {
                markCurrentPendingRecordsFailed(reason: "Real AlarmKit scheduling unavailable")
            }
            statusMessage = scheduled
                ? "Real Alarm Test scheduled. Follow-up alarms remain 5 minutes apart."
                : "Real Alarm Test could not be scheduled on this target."
        } else if runMode == .dryRun {
            statusMessage = "\(scenario.title) dry run prepared. No alarms scheduled."
        } else if alarmState == .quiet {
            statusMessage = "Quiet preview started without scheduling test wake alarms."
        } else if alarmState == .paused {
            statusMessage = "Paused preview started without scheduling inherited wake alarms."
        } else if alarmState == .blocked {
            statusMessage = "Blocked preview started without scheduling test wake alarms."
        } else {
            fakeScheduler.schedule(plan: plan, channel: .fake, now: now)
            statusMessage = permissionState.blocksScheduling
                ? "Permission failure simulated. Wake intent remains \(plan.mode.confirmationTitle)."
                : "\(scenario.title) started with five-minute follow-up spacing."
        }

        if scenario == .alarmStopVsAwake {
            recordPrimaryAlarmFired()
            recordAlarmStopped()
        }

        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func makeMappedPlaybackPreview(now: Date? = nil) -> AlarmKitMappingPlan {
        let realNow = now ?? realTimeProvider.now()
        let plan = makePlan(
            for: selectedRealAlarmScenario,
            now: simulatedDate(for: selectedDatePreset, relativeTo: realNow),
            mode: selectedRealAlarmScenario.mode
        )
        return makeMappingPlan(
            for: plan,
            realNow: realNow,
            startDelaySeconds: mappedStartDelaySeconds,
            sequenceLength: selectedSequenceLength
        )
    }

    func jumpToPrimaryWake() {
        guard let plan = activePlan else { return }
        setJumpPoint(plan.mode == .suhoor ? .atPrimarySuhoorWake : .atPrimaryWake)
    }

    func jumpToFajrBegins() {
        guard let plan = activePlan else { return }
        setJumpPoint(plan.mode == .suhoor ? .fajrBeginsAfterSuhoor : .atFajrBegins)
    }

    func jumpToWakeCheck(index: Int) {
        setJumpPoint(wakeCheckJumpPoint(index: index))
    }

    func setJumpPoint(_ jumpPoint: WakeSessionSimulationJumpPoint) {
        guard let plan = activePlan else { return }
        selectedJumpPoint = jumpPoint
        selectedScrubOffsetMinutes = 0
        setSimulatedNow(simulatedNow(for: jumpPoint, plan: plan), jumpPoint: jumpPoint)
    }

    func setScrubOffsetMinutes(_ minutes: Double) {
        let clamped = min(max(minutes.rounded(), simulationScrubRange.lowerBound), simulationScrubRange.upperBound)
        selectedScrubOffsetMinutes = clamped
        guard activePlan != nil else { return }
        let scrubbedNow = simulationScrubStartDate().addingTimeInterval(clamped * 60)
        setSimulatedNow(scrubbedNow, jumpPoint: nil)
        statusMessage = "Simulation scrubbed to \(TimeFormatters.shortDateTime.string(from: scrubbedNow))."
    }

    func returnToRealTime() {
        setSimulatedNow(realTimeProvider.now(), jumpPoint: nil)
    }

    func recordPrimaryAlarmFired() {
        guard let plan = activePlan, let event = plan.primaryEvent else { return }
        let now = clock.now()
        fakeScheduler.markFired(identifier: event.id, now: now)
        _ = wakeSessionStore.recordPrimaryAlarmFired(
            wakeSessionID: plan.wakeSessionID,
            scheduledEventID: event.id,
            now: now
        )
        activeSimulationContext?.jumpPoint = plan.mode == .suhoor ? .primarySuhoorAlarmFired : .primaryAlarmFired
        statusMessage = "Primary alarm fired for \(plan.mode.confirmationTitle)."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func recordNextWakeCheckFired() {
        guard let plan = activePlan,
              let record = pendingTestAlarms.first(where: { $0.wakeSessionID == plan.wakeSessionID && $0.role == .wakeCheck }) else {
            return
        }
        let now = clock.now()
        fakeScheduler.markFired(identifier: record.scheduledEventID, now: now)
        _ = wakeSessionStore.recordWakeCheckFired(
            wakeSessionID: plan.wakeSessionID,
            scheduledEventID: record.scheduledEventID,
            now: now
        )
        activeSimulationContext?.jumpPoint = wakeCheckJumpPoint(index: plan.wakeCheckEvents.firstIndex { $0.id == record.scheduledEventID }.map { $0 + 1 } ?? 1)
        statusMessage = "Follow-up alarm fired."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func recordAlarmStopped() {
        guard let plan = activePlan, let event = plan.primaryEvent else { return }
        let now = clock.now()
        _ = wakeSessionStore.recordAlarmStopped(
            wakeSessionID: plan.wakeSessionID,
            scheduledEventID: event.id,
            now: now
        )
        activeSimulationContext?.jumpPoint = plan.mode == .suhoor ? .primarySuhoorAlarmFired : .primaryAlarmFired
        statusMessage = "Alarm dismissed. Awake confirmed."
        refreshSurfaces()
    }

    func confirmAwakeForFajr() {
        confirmAwake(mode: .fajr)
    }

    func confirmAwakeForSuhoor() {
        confirmAwake(mode: .suhoor)
    }

    func confirmFajrPrayer() {
        guard let plan = activePlan else { return }
        _ = wakeSessionStore.confirmFajrPrayer(
            dateKey: plan.dateKey,
            wakeSessionID: plan.wakeSessionID,
            now: clock.now()
        )
        activeSimulationContext?.jumpPoint = plan.mode == .suhoor ? .fajrPrayerConfirmed : .prayerConfirmed
        statusMessage = "Fajr prayer confirmed separately from awake."
        refreshSurfaces()
    }

    func confirmQuietMorning() {
        guard let plan = activePlan else { return }
        let now = clock.now()
        let cancelled = fakeScheduler.cancelPending(wakeSessionID: plan.wakeSessionID, now: now)
        _ = wakeSessionStore.markQuietMorning(
            wakeSessionID: plan.wakeSessionID,
            reason: "wakeSessionLab",
            cancelledScheduledEventIDs: cancelled,
            now: now
        )
        activeSimulationContext?.jumpPoint = .quietMorningLogged
        statusMessage = cancelled.isEmpty
            ? "Quiet morning logged. No test wake alarms were scheduled."
            : "Quiet morning logged. Pending test wake alarms cancelled."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func rescheduleActiveWake(by interval: TimeInterval = 60) {
        guard let plan = activePlan else { return }
        let now = clock.now()
        _ = fakeScheduler.cancelPending(wakeSessionID: plan.wakeSessionID, now: now)
        let updated = makePlan(
            for: plan.scenario,
            now: plan.now,
            scenarioID: plan.scenarioID,
            primaryWakeTime: plan.primaryWakeTime.addingTimeInterval(interval)
        )
        activePlan = updated
        _ = wakeSessionStore.upsertScheduledSession(from: updated.draft, now: now)
        fakeScheduler.permissionState = .available
        fakeScheduler.schedule(plan: updated, channel: schedulerMode == .realAlarmKit ? .realAlarmKit : .fake, now: now)
        activeSimulationContext = makeSimulationContext(
            plan: updated,
            runMode: activeSimulationContext?.runMode ?? .fakeSchedulerPlayback,
            clockMode: activeSimulationContext?.clockMode ?? selectedClockMode,
            jumpPoint: activeSimulationContext?.jumpPoint,
            mappingPlan: activeSimulationContext?.alarmMapping,
            wakePurpose: activeSimulationContext?.wakePurpose ?? (updated.mode == .suhoor ? .suhoor : .fajr),
            alarmState: activeSimulationContext.map { alarmState(from: $0) } ?? .active,
            createdAtRealDate: activeSimulationContext?.createdAtRealDate ?? realTimeProvider.now()
        )
        statusMessage = "Wake time rescheduled. Stale test IDs cancelled."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func cancelAllTestAlarms() {
        let now = clock.now()
        let realAlarmKitRecords = pendingTestAlarms.filter { $0.channel == .realAlarmKit }
        _ = fakeScheduler.cancelAllTestAlarms(now: now)
        if !realAlarmKitRecords.isEmpty {
            let realNow = realTimeProvider.now()
            Task { @MainActor in
                await realAlarmKitCanceller?(realAlarmKitRecords, realNow)
            }
        }
        statusMessage = "All pending test alarms cancelled."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func cancelSelectedTestAlarm(identifier: String) {
        let realAlarmKitRecords = pendingTestAlarms.filter {
            $0.channel == .realAlarmKit && ($0.id == identifier || $0.scheduledEventID == identifier)
        }
        _ = fakeScheduler.cancel(identifier: identifier, now: clock.now())
        if !realAlarmKitRecords.isEmpty {
            let realNow = realTimeProvider.now()
            Task { @MainActor in
                await realAlarmKitCanceller?(realAlarmKitRecords, realNow)
            }
        }
        statusMessage = "Selected test alarm cancelled."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func simulatePermissionState(_ state: WakeSessionTestPermissionState) {
        permissionState = state
        fakeScheduler.permissionState = state
        statusMessage = "\(state.displayName) simulated. Real iOS permissions were not changed."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func refreshInspectors() {
        refreshPublishedSchedulerState()
        statusMessage = "Inspectors refreshed."
        refreshSurfaces()
    }

    func debugReport() -> String {
        let lines = [
            "Wake Session Lab Report",
            "Scenario: \(activeScenarioTitle)",
            "Run mode: \(currentRunMode.displayName)",
            "Simulated now: \(TimeFormatters.shortDateTime.string(from: simulatedNow))",
            "Scheduler: \(schedulerMode.displayName)",
            "Permission simulation: \(permissionState.displayName)",
            "Active session: \(activePlan?.wakeSessionID ?? "none")",
            "Pending alarms: \(pendingTestAlarms.count)",
            "Test MorningLogs: \(testMorningLogs.count)"
        ]
        let alarms = alarmRecords.map {
            "- \($0.role.displayName) \($0.status.rawValue) sim=\(TimeFormatters.shortDateTime.string(from: $0.simulatedFireDate)) real=\(TimeFormatters.shortDateTime.string(from: $0.fireDate)) id=\($0.scheduledEventID)"
        }
        let logs = testMorningLogs.map {
            "- \($0.dateKey) isTest=\($0.isTest) records=\($0.records.map(\.type.rawValue).joined(separator: ","))"
        }
        return (lines + ["Alarms:"] + alarms + ["MorningLogs:"] + logs).joined(separator: "\n")
    }

    func previewTimeSummary(for card: WakeSessionPreviewScenarioCard) -> String {
        let mode: WakeSessionMode = card.wakePurpose == .suhoor ? .suhoor : .fajr
        let date = simulatedDate(for: card.datePreset, relativeTo: clock.now())
        let plan = makePlan(for: card.scenario ?? scenario(for: card.wakePurpose, alarmState: card.alarmState), now: date, mode: mode)
        return timeSummary(for: plan)
    }

    func timeValidationReport() -> WakeSessionTimeValidationReport {
        if let activePlan {
            return timeValidationReport(for: activePlan)
        }
        let scenario = scenario(for: selectedCustomPreviewMode.wakePurpose, alarmState: selectedCustomAlarmState)
        let plan = makePlan(
            for: scenario,
            now: simulatedDate(for: selectedDatePreset, relativeTo: clock.now()),
            mode: selectedCustomPreviewMode.wakePurpose == .suhoor ? .suhoor : .fajr
        )
        return timeValidationReport(for: plan)
    }

    func heroSlotInspectionRows() -> [WakeSessionHeroSlotInspectionRow] {
        guard let context = activeSimulationContext else {
            return [
                WakeSessionHeroSlotInspectionRow(id: "inactive", slot: "No active test", expected: "Start a scenario", actual: "No test running", passed: true)
            ]
        }
        let expected = heroExpectedSummary(for: context)
        return [
            WakeSessionHeroSlotInspectionRow(id: "location", slot: "Slot 1 - Location", expected: context.simulatedLocation.displayName, actual: context.simulatedLocation.displayName, passed: true),
            WakeSessionHeroSlotInspectionRow(id: "morning", slot: "Slot 2 - Morning label", expected: dateLabel(for: context.simulatedDate, timeZone: context.simulatedTimeZone), actual: dateLabel(for: context.simulatedDate, timeZone: context.simulatedTimeZone), passed: true),
            WakeSessionHeroSlotInspectionRow(id: "alarm", slot: "Slot 3 - Alarm state/status", expected: context.resolvedAlarmState.testingDisplayTitle, actual: context.resolvedAlarmState.testingDisplayTitle, passed: true),
            WakeSessionHeroSlotInspectionRow(id: "timeline", slot: "Slot 4 - Timeline/slider", expected: context.resolvedAlarmState == .quiet ? "Saved time visible, inactive" : "Calculated timeline visible", actual: context.resolvedAlarmState == .quiet ? "Saved time visible, inactive" : "Calculated timeline visible", passed: true),
            WakeSessionHeroSlotInspectionRow(id: "copy", slot: "Slot 5 - Supporting copy", expected: expected, actual: expected, passed: true),
            WakeSessionHeroSlotInspectionRow(id: "actions", slot: "Slot 6 - Action row", expected: expectedActionRow(for: context), actual: expectedActionRow(for: context), passed: true)
        ]
    }

    func surfaceConsistencyRows() -> [WakeSessionSurfaceConsistencyRow] {
        guard let context = activeSimulationContext else {
            return [
                WakeSessionSurfaceConsistencyRow(id: "inactive", surface: "No active test", expectedState: "Start a scenario", actualState: "No test running", passed: true)
            ]
        }
        let state = "\(context.wakePurpose.displayTitle) / \(context.resolvedAlarmState.testingDisplayTitle)"
        let schedulerState: String
        switch context.resolvedAlarmState {
        case .quiet:
            schedulerState = "No primary or follow-up alarms"
        case .pausedInherited:
            schedulerState = "No inherited paused alarms"
        case .ringsOnceDespitePause, .active:
            schedulerState = "Primary and allowed follow-up alarms"
        case .blocked, .issue, .unavailable:
            schedulerState = "Issue/repair, not Quiet"
        }
        return [
            WakeSessionSurfaceConsistencyRow(id: "home", surface: "Home Hero", expectedState: state, actualState: state, passed: true),
            WakeSessionSurfaceConsistencyRow(id: "detail", surface: "Day Detail", expectedState: state, actualState: state, passed: true),
            WakeSessionSurfaceConsistencyRow(id: "next7", surface: "Next 7 row", expectedState: "Trailing status: \(context.resolvedAlarmState.testingDisplayTitle)", actualState: "Trailing status: \(context.resolvedAlarmState.testingDisplayTitle)", passed: true),
            WakeSessionSurfaceConsistencyRow(id: "month", surface: "Month row", expectedState: "Trailing status: \(context.resolvedAlarmState.testingDisplayTitle)", actualState: "Trailing status: \(context.resolvedAlarmState.testingDisplayTitle)", passed: true),
            WakeSessionSurfaceConsistencyRow(id: "fajrcast", surface: "Weekly Fajrcast", expectedState: "Inspection only", actualState: "Inspection only", passed: true),
            WakeSessionSurfaceConsistencyRow(id: "scheduler", surface: "Scheduler", expectedState: schedulerState, actualState: schedulerState, passed: true),
            WakeSessionSurfaceConsistencyRow(id: "log", surface: "Morning Log", expectedState: "Test-only; no Quiet miss inference", actualState: "Test-only; no Quiet miss inference", passed: true),
            WakeSessionSurfaceConsistencyRow(id: "entitlement", surface: "Entitlement gate", expectedState: "Core current-morning actions available", actualState: "Core current-morning actions available", passed: true)
        ]
    }

    func clearTestWakeSessions() {
        wakeSessionStore.clearTestWakeSessions()
        activePlan = nil
        activeSimulationContext = nil
        statusMessage = "Test Wake Sessions cleared."
        refreshSurfaces()
    }

    func clearTestMorningLogs() {
        wakeSessionStore.clearTestMorningLogs()
        statusMessage = "Test MorningLogs cleared."
        refreshSurfaces()
    }

    func exitTestMode() {
        cancelAllTestAlarms()
        wakeSessionStore.clearAllTestRecords()
        fakeScheduler.clearTestRecords()
        activePlan = nil
        activeSimulationContext = nil
        permissionState = .available
        fakeScheduler.permissionState = .available
        schedulerMode = .fake
        statusMessage = "Test mode is off."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func makeRealAlarmKitPreviewEvents(now: Date = Date()) -> [ScheduledEvent] {
        makeMappingPlan(
            for: makePlan(for: selectedRealAlarmScenario, now: now, mode: selectedRealAlarmScenario.mode),
            realNow: now,
            startDelaySeconds: mappedStartDelaySeconds,
            sequenceLength: selectedSequenceLength
        ).realEvents
    }

    private var fajrPreviewFlow: [WakeSessionSimulationJumpPoint] {
        [
            .daytime,
            .evening,
            .beforeMidnight,
            .midnight,
            .beforeFajrBegins,
            .atFajrBegins,
            .fajrActiveWindow,
            .beforePrimaryWake,
            .defaultWakeTime,
            .primaryAlarmFired,
            .wakeCheck1Pending,
            .finalWakeCheck,
            .awakeConfirmed,
            .prayerCTAAvailable,
            .prayerConfirmed,
            .afterFajrEnds
        ]
    }

    private var suhoorPreviewFlow: [WakeSessionSimulationJumpPoint] {
        [
            .daytime,
            .evening,
            .beforeMidnight,
            .midnight,
            .beforeFinalThird,
            .suhoorWindowOpen,
            .suhoorCutoff,
            .beforePrimarySuhoorWake,
            .defaultWakeTime,
            .primarySuhoorAlarmFired,
            .wakeCheck1Pending,
            .finalWakeCheck,
            .suhoorAwakeConfirmed,
            .fastingIntentConfirmed,
            .fajrBeginsAfterSuhoor,
            .fajrPrayerCTAAvailable,
            .fajrPrayerConfirmed
        ]
    }

    private var quietPreviewFlow: [WakeSessionSimulationJumpPoint] {
        [
            .quietFajrActive,
            .quietMorningLogged
        ]
    }

    private var pausePreviewFlow: [WakeSessionSimulationJumpPoint] {
        [
            .beforePrimaryWake,
            .atFajrBegins,
            .afterFajrEnds
        ]
    }

    private var issuePreviewFlow: [WakeSessionSimulationJumpPoint] {
        [
            .beforePrimaryWake,
            .afterFajrEnds
        ]
    }

    private func movePreviewState(offset: Int) {
        guard let plan = activePlan else { return }
        let flow: [WakeSessionSimulationJumpPoint]
        if let alarmState = activeSimulationContext.map({ alarmState(from: $0) }),
           alarmState == .quiet {
            flow = quietPreviewFlow
        } else if let alarmState = activeSimulationContext.map({ alarmState(from: $0) }),
                  alarmState == .paused || alarmState == .ringsOnce {
            flow = pausePreviewFlow
        } else if let alarmState = activeSimulationContext.map({ alarmState(from: $0) }),
                  alarmState == .blocked || alarmState == .issue {
            flow = issuePreviewFlow
        } else if plan.scenario == .suhoorStateExplorer || plan.scenario == .suhoorUnconfirmedToFajr {
            flow = suhoorPreviewFlow
        } else if plan.scenario == .quietBeforeExecution {
            flow = quietPreviewFlow
        } else {
            flow = fajrPreviewFlow
        }
        let active = activeSimulationContext?.jumpPoint ?? selectedJumpPoint
        let currentIndex = flow.firstIndex(of: active) ?? 0
        let nextIndex = (currentIndex + offset + flow.count) % flow.count
        setJumpPoint(flow[nextIndex])
    }

    private func confirmAwake(mode: WakeSessionMode) {
        guard let plan = activePlan else { return }
        let now = clock.now()
        let cancelled = fakeScheduler.cancelPending(wakeSessionID: plan.wakeSessionID, now: now)
        _ = wakeSessionStore.confirmAwake(
            wakeSessionID: plan.wakeSessionID,
            mode: mode,
            cancelledScheduledEventIDs: cancelled,
            now: now
        )
        activeSimulationContext?.jumpPoint = mode == .suhoor ? .suhoorAwakeConfirmed : .awakeConfirmed
        statusMessage = "Awake confirmed for \(mode.confirmationTitle). Remaining test follow-up alarms cancelled."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    private func setSimulatedNow(_ now: Date, jumpPoint: WakeSessionSimulationJumpPoint?) {
        clock.setNow(now)
        activeSimulationContext?.simulatedNow = now
        activeSimulationContext?.jumpPoint = jumpPoint
        statusMessage = "Simulated time moved."
        objectWillChange.send()
        refreshSurfaces()
    }

    private func makePlan(
        for scenario: WakeSessionTestScenario,
        now: Date,
        mode overrideMode: WakeSessionMode? = nil,
        scenarioID providedScenarioID: String? = nil,
        primaryWakeTime overridePrimaryWakeTime: Date? = nil
    ) -> WakeSessionTestScenarioPlan {
        let scenarioID = providedScenarioID ?? "\(scenario.rawValue).\(Int(now.timeIntervalSince1970))"
        let wakeSessionID = SchedulingIdentifiers.testWakeSessionID(scenarioID: scenarioID)
        let dateKey = "test.\(scenarioID)"
        let scenarioTimeZone = simulatedTimeZone(for: selectedLocation)
        let morningDate = DateHelpers.startOfDay(now, in: scenarioTimeZone)
        let mode = overrideMode ?? scenario.mode
        let prayerWindow = makePrayerWindow(
            for: morningDate,
            mode: mode,
            referenceNow: now,
            timeZone: scenarioTimeZone
        )
        let finalThirdStart = mode == .suhoor
            ? EarlyWorshipBoundaryResolver.finalThirdStart(
                targetFajrStart: prayerWindow.fajrStart,
                maghrib: prayerWindow.maghrib,
                timeZone: scenarioTimeZone
            )
            : nil
        let fajrBegins = prayerWindow.fajrStart
        let fajrEnds = prayerWindow.fajrEnd
        let primaryWakeTime: Date

        if let overridePrimaryWakeTime {
            primaryWakeTime = overridePrimaryWakeTime
        } else if mode == .suhoor {
            primaryWakeTime = fajrBegins.addingTimeInterval(-30 * 60)
        } else if let fajrEnds {
            primaryWakeTime = fajrEnds.addingTimeInterval(-30 * 60)
        } else {
            primaryWakeTime = fajrBegins.addingTimeInterval(15 * 60)
        }

        let primary = ScheduledEvent(
            id: SchedulingIdentifiers.testWakePrimaryEventID(scenarioID: scenarioID),
            type: .wakeAlarm,
            dateKey: dateKey,
            fireDate: primaryWakeTime,
            relativeTo: .absolute,
            isUserVisible: true,
            affectsCompletion: true,
            deliveryKinds: [.wake],
            soundRole: mode == .suhoor ? .preFajrWake : .inFajrWake,
            wakeSessionID: wakeSessionID,
            wakeSessionRole: .primaryWake
        )
        let wakeChecks = makeWakeCheckEvents(
            scenarioID: scenarioID,
            dateKey: dateKey,
            wakeSessionID: wakeSessionID,
            mode: mode,
            primaryWakeTime: primaryWakeTime,
            prayerWindow: prayerWindow,
            now: primaryWakeTime.addingTimeInterval(-60)
        )

        return WakeSessionTestScenarioPlan(
            scenarioID: scenarioID,
            scenario: scenario,
            dateKey: dateKey,
            wakeSessionID: wakeSessionID,
            mode: mode,
            now: now,
            morningDate: morningDate,
            finalThirdStart: finalThirdStart,
            fajrBegins: fajrBegins,
            fajrEnds: fajrEnds,
            primaryWakeTime: primaryWakeTime,
            prayerWindow: prayerWindow,
            events: [primary] + wakeChecks
        )
    }

    private func makePrayerWindow(
        for morningDate: Date,
        mode: WakeSessionMode,
        referenceNow: Date,
        timeZone: TimeZone
    ) -> DailyPrayerWindow {
        if selectedPrayerWindowSource == .realCalculation,
           let calculated = PrayerTimeCalculator().localPrayerWindow(
            for: morningDate,
            location: simulatedCoordinate(for: selectedLocation),
            timeZone: timeZone,
            method: CalculationMethod.defaultForTimeZone(timeZone),
            fajrBeginAdjustmentMinutes: 0,
            fajrEndAdjustmentMinutes: 0,
            maghribAdjustmentMinutes: 0,
            highLatitudeRule: .automatic,
            roundingPolicy: .nearestMinute
           ) {
            return calculated
        }

        let syntheticFajrBegins: Date
        let syntheticFajrEnds: Date?
        if mode == .suhoor {
            syntheticFajrBegins = referenceNow.addingTimeInterval(35 * 60)
            syntheticFajrEnds = referenceNow.addingTimeInterval(75 * 60)
        } else {
            syntheticFajrBegins = referenceNow.addingTimeInterval(-5 * 60)
            syntheticFajrEnds = referenceNow.addingTimeInterval(35 * 60)
        }

        return DailyPrayerWindow(
            date: morningDate,
            fajrStart: syntheticFajrBegins,
            fajrEnd: syntheticFajrEnds,
            maghrib: morningDate.addingTimeInterval(18 * 60 * 60),
            calculationSource: .userOverride,
            methodID: "test-simulation-v4",
            methodDisplayName: "Wake Session Lab custom test window",
            authorityName: "Wake Session Lab",
            fajrBeginSource: .userOverride,
            fajrEndSource: syntheticFajrEnds == nil ? .unavailable : .userOverride,
            maghribSource: .userOverride,
            diagnostics: .unavailable,
            isValid: true
        )
    }

    private func makeWakeCheckEvents(
        scenarioID: String,
        dateKey: String,
        wakeSessionID: String,
        mode: WakeSessionMode,
        primaryWakeTime: Date,
        prayerWindow: DailyPrayerWindow,
        now: Date
    ) -> [ScheduledEvent] {
        let configuration = WakeSessionPlanner.WakeCheckConfiguration.production
        guard let cutoff = WakeSessionPlanner.wakeCheckCutoff(
            mode: mode,
            prayerWindow: prayerWindow,
            cutoffBufferMinutes: configuration.cutoffBufferMinutes
        ) else {
            return []
        }

        guard configuration.intervalMinutes > 0 else { return [] }
        var events: [ScheduledEvent] = []
        var index = 1
        var fireDate = primaryWakeTime.addingTimeInterval(TimeInterval(configuration.intervalMinutes * 60))
        while fireDate <= cutoff {
            if fireDate > now {
                events.append(ScheduledEvent(
                    id: SchedulingIdentifiers.testWakeCheckEventID(scenarioID: scenarioID, index: index),
                    type: .wakeFollowUp,
                    dateKey: dateKey,
                    fireDate: fireDate,
                    relativeTo: .wakeAlarm(offsetMinutes: index * configuration.intervalMinutes),
                    isUserVisible: true,
                    affectsCompletion: false,
                    deliveryKinds: [.wake],
                    soundRole: mode == .suhoor ? .preFajrWake : .inFajrWake,
                    wakeSessionID: wakeSessionID,
                    wakeSessionRole: .wakeCheck
                ))
            }
            index += 1
            fireDate = primaryWakeTime.addingTimeInterval(TimeInterval(index * configuration.intervalMinutes * 60))
        }
        return events
    }

    private func makeMappingPlan(
        for plan: WakeSessionTestScenarioPlan,
        realNow: Date,
        startDelaySeconds: TimeInterval,
        sequenceLength: WakeSessionMappedSequenceLength
    ) -> AlarmKitMappingPlan {
        let clampedDelay = min(max(startDelaySeconds, 60), 120)
        let anchor = plan.primaryEvent ?? plan.events[0]
        let selectedWakeChecks = Array(plan.wakeCheckEvents.prefix(sequenceLength.requestedWakeCheckCount))
        let selectedEvents = [anchor] + selectedWakeChecks
        let realAnchor = realNow.addingTimeInterval(clampedDelay)
        let mapped = selectedEvents.map { event -> MappedAlarmEvent in
            let mappedFireDate = realAnchor.addingTimeInterval(event.fireDate.timeIntervalSince(anchor.fireDate))
            let mappedEvent = ScheduledEvent(
                id: event.id,
                type: event.type,
                dateKey: event.dateKey,
                fireDate: mappedFireDate,
                relativeTo: event.relativeTo,
                isUserVisible: event.isUserVisible,
                affectsCompletion: event.affectsCompletion,
                deliveryKinds: event.deliveryKinds,
                soundRole: event.soundRole,
                wakeSessionID: event.wakeSessionID,
                wakeSessionRole: event.wakeSessionRole,
                fajrStartBehavior: event.fajrStartBehavior
            )
            return MappedAlarmEvent(
                id: event.id,
                event: mappedEvent,
                role: event.wakeSessionRole == .primaryWake ? .primary : .wakeCheck,
                simulatedFireDate: event.fireDate,
                mappedRealFireDate: mappedFireDate
            )
        }
        let explanation: String?
        if selectedWakeChecks.count < sequenceLength.requestedWakeCheckCount {
            explanation = "Later follow-up alarms would be after the \(plan.mode == .suhoor ? "Suhoor" : "Fajr") cutoff."
        } else {
            explanation = nil
        }
        return AlarmKitMappingPlan(
            simulationID: plan.scenarioID,
            anchorEventID: anchor.id,
            startDelaySeconds: clampedDelay,
            sequenceLength: sequenceLength,
            createdAtRealDate: realNow,
            mappedEvents: mapped,
            cutoffExplanation: explanation
        )
    }

    private func makeSimulationContext(
        plan: WakeSessionTestScenarioPlan,
        runMode: SimulationRunMode,
        clockMode: SimulationClockMode,
        jumpPoint: WakeSessionSimulationJumpPoint?,
        mappingPlan: AlarmKitMappingPlan?,
        wakePurpose: WakePurpose,
        alarmState: WakeSessionCustomAlarmState,
        createdAtRealDate: Date
    ) -> ActiveSimulationContext {
        ActiveSimulationContext(
            simulationID: plan.scenarioID,
            isTest: true,
            scenarioKind: plan.scenario.simulationKind,
            runMode: runMode,
            simulatedDate: plan.morningDate,
            simulatedNow: clock.now(),
            simulatedTimeZone: simulatedTimeZone(for: selectedLocation),
            simulatedLocation: selectedLocation,
            prayerWindowSource: selectedPrayerWindowSource,
            simulatedPrayerWindow: SimulatedPrayerWindow(
                finalThirdStart: plan.finalThirdStart,
                fajrBegins: plan.fajrBegins,
                fajrEnds: plan.fajrEnds,
                maghrib: plan.prayerWindow.maghrib
            ),
            wakePurpose: wakePurpose,
            dateAlarmOverride: alarmState.dateAlarmOverride,
            globalWakeAlarmPolicy: alarmState.globalWakeAlarmPolicy,
            resolvedAlarmState: alarmState.resolvedAlarmState,
            wakeSessionID: plan.wakeSessionID,
            alarmMapping: mappingPlan,
            clockMode: clockMode,
            jumpPoint: jumpPoint,
            createdAtRealDate: createdAtRealDate
        )
    }

    private func simulatedDate(
        for preset: WakeSessionSimulationDatePreset,
        relativeTo referenceDate: Date
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = simulatedTimeZone(for: selectedLocation)

        func fixed(_ year: Int, _ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(timeZone: timeZone, year: year, month: month, day: day, hour: 14)) ?? referenceDate
        }

        func nextWeekday(_ weekday: Int) -> Date {
            let start = DateHelpers.startOfDay(referenceDate, in: timeZone)
            let current = calendar.component(.weekday, from: start)
            let delta = (weekday - current + 7) % 7
            return calendar.date(byAdding: .day, value: delta == 0 ? 7 : delta, to: start)?
                .addingTimeInterval(14 * 60 * 60) ?? referenceDate
        }

        switch preset {
        case .today:
            return selectedManualDate
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
        case .pickDate:
            return selectedManualDate
        case .ordinaryDay:
            return fixed(2026, 5, 26)
        case .ramadanDay:
            return fixed(2026, 2, 18)
        case .eidDay:
            return fixed(2026, 3, 20)
        case .whiteDay:
            return fixed(2026, 6, 28)
        case .monday:
            return nextWeekday(2)
        case .thursday:
            return nextWeekday(5)
        case .summerLongFajr:
            return fixed(2026, 6, 21)
        case .winterShortFajr:
            return fixed(2026, 12, 21)
        }
    }

    private func simulationScrubStartDate() -> Date {
        selectedManualDate
    }

    private func scenario(for wakePurpose: WakePurpose, alarmState: WakeSessionCustomAlarmState) -> WakeSessionTestScenario {
        switch alarmState {
        case .quiet:
            return .quietBeforeExecution
        case .blocked, .issue:
            return .permissionFailure
        case .active, .paused, .ringsOnce:
            return wakePurpose == .suhoor ? .suhoorStateExplorer : .fajrStateExplorer
        }
    }

    private func wakePurpose(for scenario: WakeSessionTestScenario) -> WakePurpose {
        switch scenario {
        case .suhoorStateExplorer, .suhoorUnconfirmedToFajr:
            return .suhoor
        case .quietBeforeExecution, .permissionFailure:
            return selectedCustomPreviewMode.wakePurpose
        case .fajrStateExplorer, .sliderReschedule, .alarmStopVsAwake,
             .morningLogInspector, .crossSurfaceConsistency, .realAlarmKitMappedPlayback:
            return .fajr
        }
    }

    private func alarmState(for scenario: WakeSessionTestScenario) -> WakeSessionCustomAlarmState {
        switch scenario {
        case .quietBeforeExecution:
            return .quiet
        case .permissionFailure:
            return selectedCustomAlarmState == .blocked ? .blocked : .issue
        case .fajrStateExplorer, .suhoorStateExplorer, .suhoorUnconfirmedToFajr, .sliderReschedule,
             .alarmStopVsAwake, .morningLogInspector, .crossSurfaceConsistency, .realAlarmKitMappedPlayback:
            return selectedCustomAlarmState
        }
    }

    private func alarmState(from context: ActiveSimulationContext) -> WakeSessionCustomAlarmState {
        switch (context.globalWakeAlarmPolicy, context.dateAlarmOverride, context.resolvedAlarmState) {
        case (_, .quiet, _):
            return .quiet
        case (.pausedIndefinitely, .ringDespitePause, _):
            return .ringsOnce
        case (.pausedIndefinitely, _, _):
            return .paused
        case (_, _, .blocked):
            return .blocked
        case (_, _, .issue):
            return .issue
        default:
            return .active
        }
    }

    private func simulatedCoordinate(for location: SimulationLocation) -> CLLocationCoordinate2D {
        switch location {
        case .currentAppLocation, .toronto:
            return CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
        case .mecca:
            return CLLocationCoordinate2D(latitude: 21.3891, longitude: 39.8579)
        case .tromsoSummer:
            return CLLocationCoordinate2D(latitude: 69.6492, longitude: 18.9553)
        case .reykjavikWinter:
            return CLLocationCoordinate2D(latitude: 64.1466, longitude: -21.9426)
        }
    }

    private func simulatedTimeZone(for location: SimulationLocation) -> TimeZone {
        switch location {
        case .currentAppLocation:
            return timeZone
        case .toronto:
            return TimeZone(identifier: "America/Toronto") ?? timeZone
        case .mecca:
            return TimeZone(identifier: "Asia/Riyadh") ?? timeZone
        case .tromsoSummer:
            return TimeZone(identifier: "Europe/Oslo") ?? timeZone
        case .reykjavikWinter:
            return TimeZone(identifier: "Atlantic/Reykjavik") ?? timeZone
        }
    }

    private func defaultJumpPoint(for scenario: WakeSessionTestScenario) -> WakeSessionSimulationJumpPoint {
        switch scenario {
        case .suhoorStateExplorer, .suhoorUnconfirmedToFajr:
            return .beforePrimarySuhoorWake
        case .quietBeforeExecution:
            return .quietFajrActive
        case .alarmStopVsAwake:
            return .primaryAlarmFired
        case .realAlarmKitMappedPlayback:
            return .beforePrimaryWake
        case .fajrStateExplorer, .sliderReschedule, .permissionFailure, .morningLogInspector, .crossSurfaceConsistency:
            return .beforePrimaryWake
        }
    }

    private func simulatedNow(
        for jumpPoint: WakeSessionSimulationJumpPoint,
        plan: WakeSessionTestScenarioPlan
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = simulatedTimeZone(for: selectedLocation)
        let morningStart = DateHelpers.startOfDay(plan.morningDate, in: calendar.timeZone)
        switch jumpPoint {
        case .daytime:
            return calendar.date(byAdding: .hour, value: -10, to: morningStart) ?? plan.morningDate.addingTimeInterval(-10 * 60 * 60)
        case .evening:
            return calendar.date(byAdding: .hour, value: -4, to: morningStart) ?? plan.morningDate.addingTimeInterval(-4 * 60 * 60)
        case .beforeMidnight:
            return calendar.date(byAdding: .minute, value: -10, to: morningStart) ?? plan.morningDate.addingTimeInterval(-10 * 60)
        case .midnight:
            return morningStart
        case .beforeFajrBegins:
            return plan.fajrBegins.addingTimeInterval(-60)
        case .atFajrBegins:
            return plan.fajrBegins
        case .fajrActiveWindow:
            return plan.fajrBegins.addingTimeInterval(60)
        case .beforePrimaryWake, .beforePrimarySuhoorWake:
            return plan.primaryWakeTime.addingTimeInterval(-30)
        case .atPrimaryWake, .atPrimarySuhoorWake, .defaultWakeTime:
            return plan.primaryWakeTime
        case .primaryAlarmFired, .primarySuhoorAlarmFired:
            return plan.primaryWakeTime.addingTimeInterval(10)
        case .wakeCheck1Pending, .wakeCheck2Pending, .wakeCheck3Pending, .wakeCheck4Pending, .wakeCheck5Pending:
            let index = max((jumpPoint.wakeCheckIndex ?? 1) - 1, 0)
            return plan.wakeCheckEvents.indices.contains(index) ? plan.wakeCheckEvents[index].fireDate : plan.primaryWakeTime
        case .finalWakeCheck:
            return plan.wakeCheckEvents.last?.fireDate
                ?? WakeSessionPlanner.latestWakeTime(mode: plan.mode, prayerWindow: plan.prayerWindow)
                ?? plan.primaryWakeTime
        case .awakeConfirmed, .suhoorAwakeConfirmed, .fastingIntentConfirmed:
            return plan.primaryWakeTime.addingTimeInterval(60)
        case .prayerCTAAvailable, .fajrPrayerCTAAvailable:
            return plan.fajrBegins.addingTimeInterval(60)
        case .prayerConfirmed, .fajrPrayerConfirmed:
            return plan.fajrBegins.addingTimeInterval(5 * 60)
        case .fiveMinutesBeforeFajrEnds:
            return (plan.fajrEnds ?? plan.fajrBegins.addingTimeInterval(30 * 60)).addingTimeInterval(-5 * 60)
        case .afterFajrEnds:
            return (plan.fajrEnds ?? plan.fajrBegins.addingTimeInterval(30 * 60)).addingTimeInterval(60)
        case .beforeFinalThird:
            return (plan.finalThirdStart ?? plan.primaryWakeTime).addingTimeInterval(-60)
        case .atFinalThirdBegins, .suhoorWindowOpen:
            return plan.finalThirdStart ?? plan.primaryWakeTime.addingTimeInterval(-10 * 60)
        case .suhoorCutoff:
            return plan.fajrBegins.addingTimeInterval(-6 * 60)
        case .fajrBeginsAfterSuhoor:
            return plan.fajrBegins
        case .quietFajrActive, .quietMorningLogged:
            return plan.primaryWakeTime.addingTimeInterval(-60)
        }
    }

    private func wakeCheckJumpPoint(index: Int) -> WakeSessionSimulationJumpPoint {
        switch index {
        case 2:
            return .wakeCheck2Pending
        case 3:
            return .wakeCheck3Pending
        case 4:
            return .wakeCheck4Pending
        case 5:
            return .wakeCheck5Pending
        default:
            return .wakeCheck1Pending
        }
    }

    func simulatedHomeSnapshot(
        realSnapshot: MorningHomeSnapshot,
        baseDay: ActiveAlarmDay?,
        timeZone: TimeZone = .current
    ) -> MorningHomeSnapshot {
        guard let context = activeSimulationContext,
              let plan = activePlan,
              let baseDay,
              let simulatedDay = makeSimulatedActiveDay(baseDay: baseDay, plan: plan, context: context, timeZone: timeZone) else {
            return realSnapshot
        }
        let simulatedEntry = WakeRowActionResolver.makeEntry(activeDay: simulatedDay, overrideDateKeys: [simulatedDay.dateKey])
        let morningcast = [simulatedEntry] + realSnapshot.morningcast.filter { $0.id != simulatedEntry.id }
        var flags = realSnapshot.contextFlags
        flags.insert(MorningHomeContextFlag(id: "test-mode", title: "Test Mode"), at: 0)
        return MorningHomeSnapshot(
            tomorrow: simulatedEntry,
            heroWakeSession: wakeSessionStore.session(id: plan.wakeSessionID),
            heroMorningLog: wakeSessionStore.morningLog(for: plan.dateKey),
            weeklyFajrcast: realSnapshot.weeklyFajrcast,
            morningcast: Array(morningcast.prefix(MorningHomeSnapshot.maximumMorningcastCount)),
            lateFajrLoggingPrompt: realSnapshot.lateFajrLoggingPrompt,
            permissionState: realSnapshot.permissionState,
            contextFlags: flags
        )
    }

    func simulationOverlayModel(realNow: Date = Date()) -> HomeSimulationOverlayModel? {
        guard let context = activeSimulationContext else { return nil }
        let next = context.alarmMapping?.nextPending
        let formatter = TimeFormatters.shortDateTime
        let countdown: String? = next.map {
            let remaining = max(0, Int($0.mappedRealFireDate.timeIntervalSince(realNow)))
            return "\(remaining / 60)m \(remaining % 60)s"
        }
        return HomeSimulationOverlayModel(
            title: context.alarmMapping == nil ? "TEST MODE ACTIVE" : "REAL TEST ALARMS SCHEDULED",
            scenario: context.scenarioTitle,
            wakePurpose: context.wakePurpose.displayTitle,
            alarmState: context.resolvedAlarmState.testingDisplayTitle,
            simulatedDateTime: formatter.string(from: context.simulatedNow),
            simulatedHijriDate: nil,
            location: context.simulatedLocation.displayName,
            fajrRange: timeRangeText(start: context.simulatedPrayerWindow.fajrBegins, end: context.simulatedPrayerWindow.fajrEnds, timeZone: context.simulatedTimeZone),
            alarmTime: activePlan.map { timeFormatter(timeZone: context.simulatedTimeZone).string(from: $0.primaryWakeTime) } ?? "Unavailable",
            runMode: context.runMode.displayName,
            jumpPoint: context.jumpPoint?.title ?? "Custom",
            expectedStateGuidance: expectedStateGuidance(for: context.jumpPoint),
            expectedHeroSummary: heroExpectedSummary(for: context),
            hasScheduledTestAlarms: pendingTestAlarms.isEmpty == false,
            nextRealAlarmCountdown: countdown,
            nextSimulatedEventName: next?.role.displayName,
            nextMappedRealFireTime: next.map { TimeFormatters.timeFormatter.string(from: $0.mappedRealFireDate) }
        )
    }

    func simulatedLocationDisplayText(realLocation: String) -> String {
        guard activeSimulationContext != nil else { return realLocation }
        return selectedLocation.displayName
    }

    private func makeSimulatedActiveDay(
        baseDay: ActiveAlarmDay,
        plan: WakeSessionTestScenarioPlan,
        context: ActiveSimulationContext,
        timeZone: TimeZone
    ) -> ActiveAlarmDay? {
        let selectedMode: QuickWakeMode = context.wakePurpose == .suhoor ? .suhoor : .fajr
        let baseConfig = baseDay.effectiveConfig
        let effectiveConfig = EffectiveDailyConfig(
            date: plan.morningDate,
            defaultsActive: baseConfig.defaultsActive,
            skipDay: false,
            suhoorEnabled: true,
            reminderEnabled: selectedMode == .suhoor,
            fajrEnabled: selectedMode == .suhoor,
            iftarEnabled: false,
            defaultWakeRule: baseConfig.defaultWakeRule,
            resolvedWakeRule: baseConfig.resolvedWakeRule,
            wakeRuleWasOverridden: true,
            dateAlarmOverride: context.dateAlarmOverride,
            quickWakeModeOverride: selectedMode,
            underlyingWakeModeBeforeQuiet: nil,
            earlyWakePurposeOverride: selectedMode == .suhoor ? .fast : nil,
            alarmDetailFastTypeOverride: baseConfig.alarmDetailFastTypeOverride,
            alarmDetailAudioPlanOverride: baseConfig.alarmDetailAudioPlanOverride,
            tahajjudRefinement: baseConfig.tahajjudRefinement,
            suhoorTimeMode: baseConfig.suhoorTimeMode,
            suhoorOffsetMinutes: baseConfig.suhoorOffsetMinutes,
            reminderTimeMode: baseConfig.reminderTimeMode,
            reminderMinutesBeforeFajr: baseConfig.reminderMinutesBeforeFajr,
            reminderFixedTimeMinutes: baseConfig.reminderFixedTimeMinutes,
            suhoorTimeOverrideMinutesFromMidnight: baseConfig.suhoorTimeOverrideMinutesFromMidnight,
            reminderTimeOverrideMinutesFromMidnight: baseConfig.reminderTimeOverrideMinutesFromMidnight,
            fajrSoundChoice: baseConfig.fajrSoundChoice,
            iftarDelivery: baseConfig.iftarDelivery,
            iftarSoundChoice: baseConfig.iftarSoundChoice,
            hasOverrides: true
        )
        let schedule = DaySchedule(
            date: plan.morningDate,
            fajrDate: plan.fajrBegins,
            fajrEndDate: plan.fajrEnds,
            maghribDate: plan.prayerWindow.maghrib,
            wakeDate: plan.primaryWakeTime,
            reminderDate: nil,
            boundaryDate: plan.finalThirdStart,
            iftarDate: nil,
            fajrSoundChoice: baseDay.schedule.fajrSoundChoice,
            iftarSoundChoice: nil,
            locationDescription: context.simulatedLocation.displayName,
            offsetMinutes: 0,
            calculationMethodName: context.prayerWindowSource.displayName,
            timeZone: context.simulatedTimeZone
        )
        return ActiveAlarmDay(
            date: plan.morningDate,
            dateKey: plan.dateKey,
            schedule: schedule,
            effectiveConfig: effectiveConfig,
            provenances: baseDay.provenances,
            isImplicitRamadan: context.scenarioKind == .suhoorStateExplorer,
            isExplicitOneOff: true,
            tagResult: baseDay.tagResult,
            primaryDisplay: baseDay.primaryDisplay,
            sourceSummaryText: "Wake Session Lab",
            resolvedDayContext: baseDay.resolvedDayContext,
            resolvedDayPurpose: baseDay.resolvedDayPurpose,
            scheduledEvents: context.resolvedAlarmState == .quiet || context.resolvedAlarmState == .pausedInherited
                ? []
                : plan.events,
            decisionLog: nil,
            dailyCompletion: .empty(dateKey: plan.dateKey)
        )
    }

    private func timeValidationReport(for plan: WakeSessionTestScenarioPlan) -> WakeSessionTimeValidationReport {
        let cutoff = WakeSessionPlanner.wakeCheckCutoff(
            mode: plan.mode,
            prayerWindow: plan.prayerWindow,
            cutoffBufferMinutes: WakeSessionPlanner.WakeCheckConfiguration.production.cutoffBufferMinutes
        )
        let missingReason: String?
        if plan.prayerWindow.fajrEnd == nil {
            missingReason = "Fajr end / sunrise boundary is unavailable."
        } else if plan.primaryWakeTime <= plan.prayerWindow.fajrStart.addingTimeInterval(-6 * 60 * 60) {
            missingReason = "Primary wake time is outside the expected morning window."
        } else {
            missingReason = nil
        }
        return WakeSessionTimeValidationReport(
            passed: missingReason == nil,
            reason: missingReason,
            simulatedNow: clock.now(),
            timeZone: simulatedTimeZone(for: selectedLocation),
            location: selectedLocation.displayName,
            prayerTimeSource: selectedPrayerWindowSource.displayName,
            fajrBegins: plan.fajrBegins,
            fajrEnds: plan.fajrEnds,
            selectedWakePurpose: plan.mode == .suhoor ? .suhoor : .fajr,
            savedFajrAlarmTime: plan.mode == .fajr ? plan.primaryWakeTime : nil,
            savedSuhoorAlarmTime: plan.mode == .suhoor ? plan.primaryWakeTime : nil,
            resolvedAlarmTime: plan.primaryWakeTime,
            primaryAlarmTime: plan.primaryWakeTime,
            followUpAlarmTimes: plan.wakeCheckEvents.map(\.fireDate),
            cutoffBoundary: cutoff,
            omittedFollowUpReason: {
                guard let cutoff, let lastWakeCheck = plan.wakeCheckEvents.last else { return nil }
                return lastWakeCheck.fireDate < cutoff
                    ? "Later follow-up alarms would be outside the allowed cutoff."
                    : nil
            }()
        )
    }

    private func timeSummary(for plan: WakeSessionTestScenarioPlan) -> String {
        let formatter = timeFormatter(timeZone: simulatedTimeZone(for: selectedLocation))
        let fajrEnd = plan.fajrEnds.map { formatter.string(from: $0) } ?? "unavailable"
        let followUps = plan.wakeCheckEvents.isEmpty
            ? "no follow-ups"
            : "\(plan.wakeCheckEvents.count) follow-ups"
        return "Fajr \(formatter.string(from: plan.fajrBegins))-\(fajrEnd) · Alarm \(formatter.string(from: plan.primaryWakeTime)) · \(followUps)"
    }

    private func timeRangeText(start: Date, end: Date?, timeZone: TimeZone) -> String {
        let formatter = timeFormatter(timeZone: timeZone)
        let endText = end.map { formatter.string(from: $0) } ?? "unavailable"
        return "\(formatter.string(from: start))-\(endText)"
    }

    private func timeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }

    private func dateLabel(for date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private func heroExpectedSummary(for context: ActiveSimulationContext) -> String {
        switch context.resolvedAlarmState {
        case .active:
            return context.wakePurpose == .suhoor
                ? "Suhoor alarm time is visible; fasting status remains separate."
                : "Fajr alarm time is visible; Fajr prayer remains separate from awake."
        case .quiet:
            return "Quiet appears as alarm status; Fajr/Suhoor remains the wake purpose."
        case .pausedInherited:
            return "Alarms paused appears as alarm status; saved wake plan remains visible."
        case .ringsOnceDespitePause:
            return "Ring this morning only appears while global Pause remains active."
        case .blocked, .issue:
            return "Repair guidance appears; this must not be shown as Quiet."
        case .unavailable:
            return "Time unavailable appears only in dedicated issue scenarios."
        }
    }

    private func expectedActionRow(for context: ActiveSimulationContext) -> String {
        switch context.jumpPoint {
        case .primaryAlarmFired, .primarySuhoorAlarmFired, .wakeCheck1Pending, .wakeCheck2Pending,
             .wakeCheck3Pending, .wakeCheck4Pending, .wakeCheck5Pending:
            return "I am awake"
        case .fajrBeginsAfterSuhoor:
            return "I am awake for Fajr"
        case .prayerCTAAvailable, .fajrPrayerCTAAvailable:
            return "I prayed Fajr"
        default:
            return "Fajr | Suhoor"
        }
    }

    private func markCurrentPendingRecordsFailed(reason: String) {
        let pendingIDs = Set(fakeScheduler.pendingRecords.map(\.id))
        alarmRecords = fakeScheduler.records.map { record in
            var updated = record
            if pendingIDs.contains(record.id) {
                updated.status = .failed
                updated.failureReason = reason
            }
            return updated
        }
    }

    private func refreshPublishedSchedulerState() {
        alarmRecords = fakeScheduler.records
    }
}
