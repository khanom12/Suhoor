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
    case fajrCompressed
    case suhoorCompressed
    case suhoorUnconfirmedToFajr
    case quietDuringWakeChecks
    case sliderReschedule
    case alarmStopVsAwake
    case permissionFailure
    case crossSurfaceConsistency
    case realAlarmKitCompressed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fajrCompressed:
            return "Start Fajr Wake Session Test"
        case .suhoorCompressed:
            return "Start Suhoor Wake Session Test"
        case .suhoorUnconfirmedToFajr:
            return "Start Suhoor Not Confirmed -> Fajr Begins"
        case .quietDuringWakeChecks:
            return "Start Quiet During Wake Checks Test"
        case .sliderReschedule:
            return "Start Slider Reschedule Test"
        case .alarmStopVsAwake:
            return "Start Alarm Stop vs Awake Confirmation Test"
        case .permissionFailure:
            return "Start Permission Failure Test"
        case .crossSurfaceConsistency:
            return "Start Cross-Surface Consistency Test"
        case .realAlarmKitCompressed:
            return "Start Real AlarmKit Compressed Test"
        }
    }

    var mode: WakeSessionMode {
        switch self {
        case .suhoorCompressed, .suhoorUnconfirmedToFajr:
            return .suhoor
        case .fajrCompressed, .quietDuringWakeChecks, .sliderReschedule, .alarmStopVsAwake,
             .permissionFailure, .crossSurfaceConsistency, .realAlarmKitCompressed:
            return .fajr
        }
    }
}

enum WakeSessionTestSchedulerMode: String, CaseIterable, Identifiable, Sendable {
    case fake
    case realAlarmKit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fake:
            return "Fake"
        case .realAlarmKit:
            return "Real AlarmKit"
        }
    }
}

enum WakeSessionTestPermissionState: String, CaseIterable, Identifiable, Sendable {
    case available
    case alarmKitDenied
    case notificationsDenied
    case scheduleFailure

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .available:
            return "Available"
        case .alarmKitDenied:
            return "AlarmKit denied"
        case .notificationsDenied:
            return "Notifications denied"
        case .scheduleFailure:
            return "Schedule failure"
        }
    }

    var blocksScheduling: Bool {
        self != .available
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

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fake:
            return "Fake"
        case .realAlarmKit:
            return "Real AlarmKit"
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

    func schedule(plan: WakeSessionTestScenarioPlan, channel: WakeSessionTestAlarmChannel, now: Date) {
        for event in plan.events {
            let role = event.wakeSessionRole == .primaryWake
                ? WakeSessionTestAlarmRole.primary
                : WakeSessionTestAlarmRole.wakeCheck
            let identifier = SchedulingIdentifiers.identifier(for: event, deliveryKind: .wake)
            let status: WakeSessionTestAlarmStatus = permissionState.blocksScheduling ? .failed : .pending
            let failureReason = permissionState.blocksScheduling ? permissionState.displayName : nil
            records.append(
                WakeSessionTestAlarmRecord(
                    id: identifier,
                    wakeSessionID: plan.wakeSessionID,
                    scenarioID: plan.scenarioID,
                    scheduledEventID: event.id,
                    fireDate: event.fireDate,
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

    @Published private(set) var clock: MutableTimeProvider
    @Published private(set) var activePlan: WakeSessionTestScenarioPlan?
    @Published private(set) var schedulerMode: WakeSessionTestSchedulerMode = .fake
    @Published private(set) var permissionState: WakeSessionTestPermissionState = .available
    @Published private(set) var alarmRecords: [WakeSessionTestAlarmRecord] = []
    @Published private(set) var statusMessage: String = "Test mode is off."
    @Published private(set) var realAlarmKitWarningAcknowledged = false

    private let wakeSessionStore: WakeSessionStore
    private let fakeScheduler: FakeWakeSessionTestScheduler
    private let realAlarmKitScheduler: RealAlarmKitScheduler?
    private let refreshSurfaces: () -> Void
    private let realTimeProvider: any TimeProviding
    private let timeZone: TimeZone

    init(
        wakeSessionStore: WakeSessionStore,
        fakeScheduler: FakeWakeSessionTestScheduler? = nil,
        realAlarmKitScheduler: RealAlarmKitScheduler? = nil,
        refreshSurfaces: @escaping () -> Void = {},
        realTimeProvider: any TimeProviding = SystemTimeProvider(),
        initialNow: Date = Date(),
        timeZone: TimeZone = .current
    ) {
        self.wakeSessionStore = wakeSessionStore
        self.fakeScheduler = fakeScheduler ?? FakeWakeSessionTestScheduler()
        self.realAlarmKitScheduler = realAlarmKitScheduler
        self.refreshSurfaces = refreshSurfaces
        self.realTimeProvider = realTimeProvider
        self.clock = MutableTimeProvider(now: initialNow)
        self.timeZone = timeZone
        refreshPublishedSchedulerState()
    }

    var isActive: Bool {
        activePlan != nil
    }

    var activeScenarioTitle: String {
        activePlan?.scenario.title ?? "None"
    }

    var simulatedNow: Date {
        clock.now()
    }

    var realDeviceNow: Date {
        realTimeProvider.now()
    }

    var activeSession: WakeSession? {
        activePlan.flatMap { wakeSessionStore.session(id: $0.wakeSessionID) }
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

    func start(_ scenario: WakeSessionTestScenario) async {
        permissionState = scenario == .permissionFailure ? .alarmKitDenied : .available
        fakeScheduler.permissionState = permissionState
        schedulerMode = scenario == .realAlarmKitCompressed ? .realAlarmKit : .fake
        let now = scenario == .realAlarmKitCompressed ? realTimeProvider.now() : clock.now()
        clock.setNow(now)
        let plan = makePlan(for: scenario, now: now)
        activePlan = plan
        _ = wakeSessionStore.upsertScheduledSession(from: plan.draft, now: now)

        if scenario == .realAlarmKitCompressed {
            realAlarmKitWarningAcknowledged = true
            let scheduled = await realAlarmKitScheduler?(plan.events, plan.mode, now) ?? false
            fakeScheduler.permissionState = scheduled ? .available : .scheduleFailure
            fakeScheduler.schedule(plan: plan, channel: .realAlarmKit, now: now)
            if !scheduled {
                markCurrentPendingRecordsFailed(reason: "Real AlarmKit scheduling unavailable")
            }
            statusMessage = scheduled
                ? "Real AlarmKit compressed test scheduled. Real alarms will ring."
                : "Real AlarmKit compressed test could not be scheduled on this target."
        } else {
            fakeScheduler.schedule(plan: plan, channel: .fake, now: now)
            statusMessage = permissionState.blocksScheduling
                ? "Permission failure simulated. Wake intent remains \(plan.mode.confirmationTitle)."
                : "\(scenario.title) started with compressed test timing."
        }

        if scenario == .quietDuringWakeChecks || scenario == .alarmStopVsAwake {
            recordPrimaryAlarmFired()
            recordAlarmStopped()
        }

        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func jumpToPrimaryWake() {
        guard let plan = activePlan else { return }
        setSimulatedNow(plan.primaryWakeTime)
    }

    func jumpToFajrBegins() {
        guard let plan = activePlan else { return }
        setSimulatedNow(plan.fajrBegins)
    }

    func jumpToWakeCheck(index: Int) {
        guard let event = activePlan?.wakeCheckEvents.first(where: { $0.id.hasSuffix(".\(index)") || $0.id.hasSuffix("check.\(index)") }) else {
            return
        }
        setSimulatedNow(event.fireDate)
    }

    func returnToRealTime() {
        setSimulatedNow(realTimeProvider.now())
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
        statusMessage = "Alarm stopped. Awake is still unconfirmed."
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
        statusMessage = "Quiet Morning logged. Pending test Wake Checks cancelled."
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
        statusMessage = "Wake time rescheduled. Stale test IDs cancelled."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func cancelAllTestAlarms() {
        _ = fakeScheduler.cancelAllTestAlarms(now: clock.now())
        statusMessage = "All pending test alarms cancelled."
        refreshPublishedSchedulerState()
    }

    func clearTestWakeSessions() {
        wakeSessionStore.clearTestWakeSessions()
        activePlan = nil
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
        permissionState = .available
        fakeScheduler.permissionState = .available
        schedulerMode = .fake
        statusMessage = "Test mode is off."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    func makeRealAlarmKitPreviewEvents(now: Date = Date()) -> [ScheduledEvent] {
        makePlan(for: .realAlarmKitCompressed, now: now).events
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
        statusMessage = "Awake confirmed for \(mode.confirmationTitle). Remaining test Wake Checks cancelled."
        refreshPublishedSchedulerState()
        refreshSurfaces()
    }

    private func setSimulatedNow(_ now: Date) {
        clock.setNow(now)
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
        case .suhoorCompressed:
            finalThirdStart = now
            fajrBegins = now.addingTimeInterval(8 * 60)
            fajrEnds = now.addingTimeInterval(14 * 60)
            primaryWakeTime = overridePrimaryWakeTime ?? now.addingTimeInterval(2 * 60)
        case .suhoorUnconfirmedToFajr:
            finalThirdStart = now
            fajrBegins = now.addingTimeInterval(6 * 60)
            fajrEnds = now.addingTimeInterval(12 * 60)
            primaryWakeTime = overridePrimaryWakeTime ?? now.addingTimeInterval(2 * 60)
        case .realAlarmKitCompressed:
            finalThirdStart = nil
            fajrBegins = now.addingTimeInterval(60)
            fajrEnds = now.addingTimeInterval(8 * 60)
            primaryWakeTime = overridePrimaryWakeTime ?? now.addingTimeInterval(2 * 60)
        case .fajrCompressed, .quietDuringWakeChecks, .sliderReschedule, .alarmStopVsAwake,
             .permissionFailure, .crossSurfaceConsistency:
            finalThirdStart = nil
            fajrBegins = now.addingTimeInterval(60)
            fajrEnds = now.addingTimeInterval(8 * 60)
            primaryWakeTime = overridePrimaryWakeTime ?? now.addingTimeInterval(2 * 60)
        }

        let prayerWindow = DailyPrayerWindow(
            date: morningDate,
            fajrStart: fajrBegins,
            fajrEnd: fajrEnds,
            maghrib: morningDate.addingTimeInterval(18 * 60 * 60),
            calculationSource: .userOverride,
            methodID: "test-compressed",
            methodDisplayName: "Compressed test window",
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
        let wakeChecks = makeCompressedWakeCheckEvents(
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

    private func makeCompressedWakeCheckEvents(
        scenarioID: String,
        dateKey: String,
        wakeSessionID: String,
        mode: WakeSessionMode,
        primaryWakeTime: Date,
        prayerWindow: DailyPrayerWindow,
        now: Date
    ) -> [ScheduledEvent] {
        let configuration = WakeSessionPlanner.WakeCheckConfiguration.compressedTest
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
