import Combine
import Foundation

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
            return "Fajr State Explorer"
        case .suhoorStateExplorer:
            return "Suhoor State Explorer"
        case .suhoorUnconfirmedToFajr:
            return "Start Suhoor Not Confirmed -> Fajr Begins"
        case .quietBeforeExecution:
            return "Start Quiet Before Execution Test"
        case .sliderReschedule:
            return "Start Slider Reschedule Test"
        case .alarmStopVsAwake:
            return "Start Alarm Stop vs Awake Confirmation Test"
        case .permissionFailure:
            return "Start Permission Failure Test"
        case .morningLogInspector:
            return "Start MorningLog Inspector Test"
        case .crossSurfaceConsistency:
            return "Start Cross-Surface Consistency Test"
        case .realAlarmKitMappedPlayback:
            return "Start Real AlarmKit Mapped Playback"
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
            return "Fake"
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
            return "Wake Check"
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
    @Published var selectedDatePreset: WakeSessionSimulationDatePreset = .today
    @Published var selectedManualDate: Date
    @Published var selectedLocation: SimulationLocation = .currentAppLocation
    @Published var selectedPrayerWindowSource: SimulationPrayerWindowSource = .realCalculation
    @Published var selectedClockMode: SimulationClockMode = .jumpOnly
    @Published var selectedJumpPoint: WakeSessionSimulationJumpPoint = .beforePrimaryWake
    @Published var selectedSequenceLength: WakeSessionMappedSequenceLength = .defaultSelection
    @Published var mappedStartDelaySeconds: TimeInterval = 90
    @Published var selectedCustomPreviewMode: WakeSessionCustomPreviewMode = .fajr
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
        stateOptions(for: selectedCustomPreviewMode)
    }

    var currentExpectedStateGuidance: String {
        expectedStateGuidance(for: activeSimulationContext?.jumpPoint ?? selectedJumpPoint)
    }

    func stateOptions(for mode: WakeSessionCustomPreviewMode) -> [WakeSessionSimulationJumpPoint] {
        switch mode {
        case .fajr:
            return fajrPreviewFlow
        case .suhoor:
            return suhoorPreviewFlow
        case .quiet:
            return quietPreviewFlow
        }
    }

    func selectCustomPreviewMode(_ mode: WakeSessionCustomPreviewMode) {
        selectedCustomPreviewMode = mode
        selectedScenario = mode.scenario
        let options = stateOptions(for: mode)
        if !options.contains(selectedJumpPoint), let first = options.first {
            selectedJumpPoint = first
        }
    }

    func expectedStateGuidance(for jumpPoint: WakeSessionSimulationJumpPoint?) -> String {
        switch jumpPoint {
        case .beforeFajrBegins:
            return "Expected: The Hero should show an upcoming Fajr morning before the window opens."
        case .atFajrBegins:
            return "Expected: The Hero should show that Fajr has begun."
        case .beforePrimaryWake:
            return "Expected: The Hero should show the planned alarm time before it fires."
        case .atPrimaryWake, .primaryAlarmFired:
            return "Expected: The Hero should show \"Time to wake\" and one \"I’m awake\" action while awake is still unconfirmed."
        case .wakeCheck1Pending, .wakeCheck2Pending, .wakeCheck3Pending, .wakeCheck4Pending, .wakeCheck5Pending:
            return "Expected: Wake Checks should remain pending until the in-app awake confirmation."
        case .awakeConfirmed:
            return "Expected: Fajr awake should be confirmed and remaining Wake Checks should be cancelled."
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
        selectedScenario = scenario
        selectedClockMode = .jumpOnly
        await start(scenario, runMode: .previewHomeUI)
        if let jumpPoint = card.initialJumpPoint {
            setJumpPoint(jumpPoint)
        }
    }

    func previewCustomOnHome() async {
        selectedScenario = selectedCustomPreviewMode.scenario
        selectedClockMode = .jumpOnly
        await start(selectedCustomPreviewMode.scenario, runMode: .previewHomeUI)
        setJumpPoint(selectedJumpPoint)
    }

    func configureRealAlarmTest(_ scenario: WakeSessionTestScenario) {
        selectedRealAlarmScenario = scenario
        selectedScenario = scenario
        selectedSequenceLength = selectedSequenceLength
        mappedStartDelaySeconds = min(max(mappedStartDelaySeconds, 60), 120)
    }

    func scheduleSelectedRealAlarmTest() async {
        await start(selectedRealAlarmScenario, runMode: .realAlarmKitMappedPlayback)
    }

    func moveToNextPreviewState() {
        movePreviewState(offset: 1)
    }

    func moveToPreviousPreviewState() {
        movePreviewState(offset: -1)
    }

    func start(_ scenario: WakeSessionTestScenario) async {
        await start(scenario, runMode: scenario == .realAlarmKitMappedPlayback ? .realAlarmKitMappedPlayback : .fakeSchedulerPlayback)
    }

    func activateOnHome(scenario: WakeSessionTestScenario? = nil) async {
        await start(scenario ?? selectedScenario, runMode: .homeSimulation)
    }

    func start(_ scenario: WakeSessionTestScenario, runMode: SimulationRunMode) async {
        selectedScenario = scenario
        permissionState = scenario == .permissionFailure ? .alarmKitDenied : .available
        fakeScheduler.permissionState = permissionState
        schedulerMode = runMode == .realAlarmKitMappedPlayback ? .realAlarmKit : (runMode == .dryRun ? .dryRun : .fake)
        let realNow = realTimeProvider.now()
        let now = simulatedDate(for: selectedDatePreset, relativeTo: runMode == .realAlarmKitMappedPlayback ? realNow : clock.now())
        let plan = makePlan(for: scenario, now: now)
        let jumpPoint = defaultJumpPoint(for: scenario)
        let simulatedNow = simulatedNow(for: jumpPoint, plan: plan)
        clock.setNow(simulatedNow)
        activePlan = plan
        _ = wakeSessionStore.upsertScheduledSession(from: plan.draft, now: now)
        activeSimulationContext = makeSimulationContext(
            plan: plan,
            runMode: runMode,
            clockMode: runMode == .realAlarmKitMappedPlayback ? .mappedPlayback : selectedClockMode,
            jumpPoint: jumpPoint,
            mappingPlan: nil,
            createdAtRealDate: realNow
        )

        if runMode == .realAlarmKitMappedPlayback {
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
                ? "Real AlarmKit mapped playback scheduled. Wake Checks remain 5 minutes apart."
                : "Real AlarmKit mapped playback could not be scheduled on this target."
        } else if runMode == .dryRun {
            statusMessage = "\(scenario.title) dry run prepared. No alarms scheduled."
        } else if scenario == .quietBeforeExecution {
            statusMessage = "Quiet preview started without scheduling test wake alarms."
        } else {
            fakeScheduler.schedule(plan: plan, channel: .fake, now: now)
            statusMessage = permissionState.blocksScheduling
                ? "Permission failure simulated. Wake intent remains \(plan.mode.confirmationTitle)."
                : "\(scenario.title) started with five-minute Wake Check spacing."
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
        let plan = makePlan(for: selectedRealAlarmScenario, now: simulatedDate(for: selectedDatePreset, relativeTo: realNow))
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
        setSimulatedNow(simulatedNow(for: jumpPoint, plan: plan), jumpPoint: jumpPoint)
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
        statusMessage = "Wake Check fired."
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
            for: makePlan(for: selectedRealAlarmScenario, now: now),
            realNow: now,
            startDelaySeconds: mappedStartDelaySeconds,
            sequenceLength: selectedSequenceLength
        ).realEvents
    }

    private var fajrPreviewFlow: [WakeSessionSimulationJumpPoint] {
        [
            .beforeFajrBegins,
            .atFajrBegins,
            .beforePrimaryWake,
            .primaryAlarmFired,
            .wakeCheck1Pending,
            .awakeConfirmed,
            .prayerCTAAvailable,
            .prayerConfirmed,
            .afterFajrEnds
        ]
    }

    private var suhoorPreviewFlow: [WakeSessionSimulationJumpPoint] {
        [
            .beforeFinalThird,
            .suhoorWindowOpen,
            .beforePrimarySuhoorWake,
            .primarySuhoorAlarmFired,
            .wakeCheck1Pending,
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

    private func movePreviewState(offset: Int) {
        guard let plan = activePlan else { return }
        let flow: [WakeSessionSimulationJumpPoint]
        if plan.scenario == .suhoorStateExplorer || plan.scenario == .suhoorUnconfirmedToFajr {
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
        statusMessage = "Awake confirmed for \(mode.confirmationTitle). Remaining test Wake Checks cancelled."
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
        scenarioID providedScenarioID: String? = nil,
        primaryWakeTime overridePrimaryWakeTime: Date? = nil
    ) -> WakeSessionTestScenarioPlan {
        let scenarioID = providedScenarioID ?? "\(scenario.rawValue).\(Int(now.timeIntervalSince1970))"
        let wakeSessionID = SchedulingIdentifiers.testWakeSessionID(scenarioID: scenarioID)
        let dateKey = "test.\(scenarioID)"
        let morningDate = DateHelpers.startOfDay(now, in: timeZone)
        let mode = scenario.mode
        let finalThirdStart: Date?
        let fajrBegins: Date
        let fajrEnds: Date?
        let primaryWakeTime: Date

        switch scenario {
        case .suhoorStateExplorer:
            finalThirdStart = now.addingTimeInterval(-10 * 60)
            fajrBegins = now.addingTimeInterval(35 * 60)
            fajrEnds = now.addingTimeInterval(75 * 60)
            primaryWakeTime = overridePrimaryWakeTime ?? now.addingTimeInterval(2 * 60)
        case .suhoorUnconfirmedToFajr:
            finalThirdStart = now.addingTimeInterval(-10 * 60)
            fajrBegins = now.addingTimeInterval(35 * 60)
            fajrEnds = now.addingTimeInterval(75 * 60)
            primaryWakeTime = overridePrimaryWakeTime ?? now.addingTimeInterval(2 * 60)
        case .realAlarmKitMappedPlayback:
            finalThirdStart = nil
            fajrBegins = now.addingTimeInterval(-5 * 60)
            fajrEnds = now.addingTimeInterval(35 * 60)
            primaryWakeTime = overridePrimaryWakeTime ?? now.addingTimeInterval(2 * 60)
        case .fajrStateExplorer, .quietBeforeExecution, .sliderReschedule, .alarmStopVsAwake,
             .permissionFailure, .morningLogInspector, .crossSurfaceConsistency:
            finalThirdStart = nil
            fajrBegins = now.addingTimeInterval(-5 * 60)
            fajrEnds = now.addingTimeInterval(35 * 60)
            primaryWakeTime = overridePrimaryWakeTime ?? now.addingTimeInterval(2 * 60)
        }

        let prayerWindow = DailyPrayerWindow(
            date: morningDate,
            fajrStart: fajrBegins,
            fajrEnd: fajrEnds,
            maghrib: morningDate.addingTimeInterval(18 * 60 * 60),
            calculationSource: .userOverride,
            methodID: "test-simulation-v2",
            methodDisplayName: "Wake Session Lab simulation",
            authorityName: "Wake Session Lab",
            fajrBeginSource: .userOverride,
            fajrEndSource: fajrEnds == nil ? .unavailable : .userOverride,
            maghribSource: .userOverride,
            diagnostics: .unavailable,
            isValid: true
        )

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
            now: now
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

        return (1...configuration.maximumCount).compactMap { index in
            let fireDate = primaryWakeTime.addingTimeInterval(TimeInterval(index * configuration.intervalMinutes * 60))
            guard fireDate <= cutoff, fireDate > now else { return nil }
            return ScheduledEvent(
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
            )
        }
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
            explanation = "Later Wake Checks would be after the \(plan.mode == .suhoor ? "Suhoor" : "Fajr") cutoff."
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
        createdAtRealDate: Date
    ) -> ActiveSimulationContext {
        ActiveSimulationContext(
            simulationID: plan.scenarioID,
            isTest: true,
            scenarioKind: plan.scenario.simulationKind,
            runMode: runMode,
            simulatedDate: plan.morningDate,
            simulatedNow: clock.now(),
            simulatedTimeZone: timeZone,
            simulatedLocation: selectedLocation,
            prayerWindowSource: selectedPrayerWindowSource,
            simulatedPrayerWindow: SimulatedPrayerWindow(
                finalThirdStart: plan.finalThirdStart,
                fajrBegins: plan.fajrBegins,
                fajrEnds: plan.fajrEnds,
                maghrib: plan.prayerWindow.maghrib
            ),
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
        calendar.timeZone = timeZone

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
        switch jumpPoint {
        case .beforeFajrBegins:
            return plan.fajrBegins.addingTimeInterval(-60)
        case .atFajrBegins:
            return plan.fajrBegins
        case .beforePrimaryWake, .beforePrimarySuhoorWake:
            return plan.primaryWakeTime.addingTimeInterval(-30)
        case .atPrimaryWake, .atPrimarySuhoorWake:
            return plan.primaryWakeTime
        case .primaryAlarmFired, .primarySuhoorAlarmFired:
            return plan.primaryWakeTime.addingTimeInterval(10)
        case .wakeCheck1Pending, .wakeCheck2Pending, .wakeCheck3Pending, .wakeCheck4Pending, .wakeCheck5Pending:
            let index = max((jumpPoint.wakeCheckIndex ?? 1) - 1, 0)
            return plan.wakeCheckEvents.indices.contains(index) ? plan.wakeCheckEvents[index].fireDate : plan.primaryWakeTime
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
            title: "TEST MODE ACTIVE",
            scenario: context.scenarioTitle,
            simulatedDateTime: formatter.string(from: context.simulatedNow),
            simulatedHijriDate: nil,
            location: context.simulatedLocation.displayName,
            runMode: context.runMode.displayName,
            jumpPoint: context.jumpPoint?.title ?? "Custom",
            expectedStateGuidance: expectedStateGuidance(for: context.jumpPoint),
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
        let selectedMode = simulatedQuickWakeMode(plan: plan, context: context)
        let baseConfig = baseDay.effectiveConfig
        let effectiveConfig = EffectiveDailyConfig(
            date: plan.morningDate,
            defaultsActive: baseConfig.defaultsActive,
            skipDay: selectedMode == .quiet,
            suhoorEnabled: selectedMode != .quiet,
            reminderEnabled: selectedMode == .suhoor,
            fajrEnabled: selectedMode != .quiet && selectedMode != .fajr,
            iftarEnabled: false,
            defaultWakeRule: baseConfig.defaultWakeRule,
            resolvedWakeRule: baseConfig.resolvedWakeRule,
            wakeRuleWasOverridden: true,
            dateAlarmOverride: selectedMode == .quiet ? .quiet : baseConfig.dateAlarmOverride,
            quickWakeModeOverride: selectedMode,
            underlyingWakeModeBeforeQuiet: selectedMode == .quiet ? .fajr : nil,
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
            timeZone: timeZone
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
            scheduledEvents: plan.events,
            decisionLog: nil,
            dailyCompletion: .empty(dateKey: plan.dateKey)
        )
    }

    private func simulatedQuickWakeMode(plan: WakeSessionTestScenarioPlan, context: ActiveSimulationContext) -> QuickWakeMode {
        switch context.scenarioKind {
        case .quietBeforeExecution:
            return .quiet
        case .suhoorStateExplorer, .suhoorUnconfirmedToFajr:
            return .suhoor
        case .fajrStateExplorer, .sliderReschedule, .alarmStopVsAwake, .permissionFailure,
             .morningLogInspector, .crossSurfaceConsistency, .realAlarmKitMappedPlayback:
            return plan.mode == .suhoor ? .suhoor : .fajr
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
