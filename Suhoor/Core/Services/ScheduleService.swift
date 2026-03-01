import Foundation
import CoreLocation
import Combine
import UserNotifications
import AlarmKit
import os

@MainActor
final class ScheduleManager: ObservableObject {
    struct TestRunResult {
        let success: Bool
        let message: String
        let details: [String]
    }
    @Published var schedules: [DaySchedule] = []
    @Published var schedulingMode: SchedulingMode = .none
    @Published var lastUpdated: Date?
    @Published var permissionSummary: String = ""
    @Published var statusText: String = ""
    @Published var lastEnableFailureMessage: String?
    @Published var alarmAuthorizationText: String = "--"
    @Published var notificationAuthorizationText: String = "--"

    private let settingsStore: SuhoorSettingsStore
    private let alarmConfigStore: AlarmConfigStore
    private let locationService: LocationService
    private let cacheStore = ScheduleCacheStore()
    private let calculator = PrayerTimeCalculator()
    private let alarmRecordStore = AlarmRecordStore()
    private let alarmStateStore = AlarmStateStore()
    private let countdownStore = CountdownSessionStore()
    let testSettingsStore = AlarmKitTestSettingsStore()
    private let testRunStore = AlarmKitTestRunStore()

    private var alarmKitScheduler: AlarmKitScheduler?
    private let notificationScheduler = NotificationScheduler()
    private let routineScheduler: RoutineScheduler
    private let alarmScheduler: AlarmScheduler
    private let alarmCoordinator: AlarmCoordinator?
    private let countdownManager: CountdownManager
    private let alarmEventRouter: AlarmEventRouter?

    init(settingsStore: SuhoorSettingsStore, locationService: LocationService, alarmConfigStore: AlarmConfigStore) {
        self.settingsStore = settingsStore
        self.alarmConfigStore = alarmConfigStore
        self.locationService = locationService
        var resolvedAlarmKit: AlarmKitScheduler?
        #if !targetEnvironment(simulator)
        if #available(iOS 26.0, *) {
            resolvedAlarmKit = AlarmKitScheduler()
        }
        #endif
        self.alarmKitScheduler = resolvedAlarmKit
        let liveActivityManager: LiveActivityManaging
        if #available(iOS 16.1, *) {
            liveActivityManager = CountdownLiveActivityManager()
        } else {
            liveActivityManager = NoopLiveActivityManager()
        }
        self.countdownManager = CountdownManager(
            store: countdownStore,
            activityManager: liveActivityManager
        )
        var resolvedCoordinator: AlarmCoordinator?
        if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let resolvedAlarmKit {
            resolvedCoordinator = AlarmCoordinator(
                alarmScheduler: resolvedAlarmKit,
                recordStore: alarmRecordStore,
                stateStore: alarmStateStore
            )
        }
        self.alarmCoordinator = resolvedCoordinator
        self.routineScheduler = RoutineScheduler(
            notificationScheduler: notificationScheduler,
            alarmKitScheduler: resolvedAlarmKit,
            alarmCoordinator: resolvedCoordinator
        )
        self.alarmScheduler = AlarmScheduler(routineScheduler: routineScheduler)
        if FeatureFlags.enableCountdown, #available(iOS 26.0, *), alarmCoordinator != nil {
            self.alarmEventRouter = AlarmEventRouter(
                recordStore: alarmRecordStore,
                stateStore: alarmStateStore,
                countdownManager: countdownManager,
                enableCountdown: FeatureFlags.enableCountdown
            )
            self.alarmEventRouter?.start()
        } else {
            self.alarmEventRouter = nil
        }
        let cache = cacheStore.load()
        self.schedules = cache.schedules
        self.schedulingMode = cache.schedulingMode
        self.lastUpdated = cache.lastUpdated
    }

    var nextUpcomingSchedule: DaySchedule? {
        schedules.first
    }

    var lastUpdatedText: String {
        guard let date = lastUpdated else { return "--" }
        return TimeFormatters.shortDateTime.string(from: date)
    }

    var usesNotificationFallback: Bool {
        hasAnyEnabledAlarms && schedulingMode == .notifications
    }

    var isAlarmKitDenied: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if #available(iOS 26.0, *), let alarmKitScheduler {
            return alarmKitScheduler.authorizationState == .denied
        }
        return false
        #endif
    }

    var isAlarmKitUnavailable: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        if #available(iOS 26.0, *) {
            return alarmKitScheduler == nil
        }
        return true
        #endif
    }

    func dayLabel(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        return TimeFormatters.dayFormatter.string(from: date)
    }

    func ensureScheduleWindow(reason: ScheduleRefreshReason) async {
        if FeatureFlags.enableCountdown {
            await countdownManager.reconcileIfNeeded()
        }
        let now = Date()
        if reason == .foreground || reason == .appLaunch {
            if DateHelpers.isSameDay(settingsStore.settings.lastScheduledDate, now, in: .current) {
                return
            }
        }
        await refreshSchedules(force: true)
    }

    func enableFromUserAction() async -> Bool {
        lastEnableFailureMessage = nil

        if !isLocationAuthorized {
            locationService.requestAuthorization()
            lastEnableFailureMessage = "Location required to calculate Fajr."
            return false
        }

        if canRequestAlarmKitAuthorization {
            _ = await requestAlarmAuthorization()
        }

        let canUseAlarmKit = await alarmKitAvailableAndAuthorized()
        let requiresNotifications = !canUseAlarmKit

        if requiresNotifications {
            let status = await notificationAuthorizationStatus()
            if status == .denied {
                lastEnableFailureMessage = "Notifications are used for your reminder before Fajr and Fajr alert."
                return false
            }
            if status == .notDetermined {
                let granted = await requestNotificationAuthorization()
                if !granted {
                    lastEnableFailureMessage = "Notifications are used for your reminder before Fajr and Fajr alert."
                    return false
                }
            }
        }

        settingsStore.update { draft in
            draft.isConfigured = true
        }
        alarmConfigStore.defaults.suhoorEnabledDefault = true

        await refreshSchedules(force: true)
        return true
    }

    func disableFromUserAction() async {
        lastEnableFailureMessage = nil
        alarmConfigStore.defaults.suhoorEnabledDefault = false
        alarmConfigStore.defaults.reminderEnabledDefault = false
        alarmConfigStore.defaults.fajrEnabledDefault = false
        await refreshSchedules(force: true)
    }

    func refreshSchedules(force: Bool) async {
        let settings = settingsStore.settings
        EventTimelineLog.shared.record(category: "schedule", message: "refreshSchedules(force=\(force))")

        guard isLocationAuthorized else {
            statusText = "Location permission required."
            schedules = []
            schedulingMode = .none
            return
        }

        let coordinate: CLLocationCoordinate2D
        switch settings.locationMode {
        case .auto:
            guard let autoCoord = locationService.lastLocation?.coordinate else {
                locationService.requestLocation()
                statusText = "Locating…"
                schedules = []
                schedulingMode = .none
                return
            }
            coordinate = autoCoord
        case .fixed:
            guard let fixed = settings.fixedLocation else {
                statusText = "Fixed location required."
                schedules = []
                schedulingMode = .none
                return
            }
            coordinate = CLLocationCoordinate2D(latitude: fixed.latitude, longitude: fixed.longitude)
        }

        let timeZone = TimeZone.current
        let method = settings.calculationMethod
        let startDate = DateHelpers.startOfToday(in: timeZone)
        let canUseAlarmKit = await alarmKitAvailableAndAuthorized()
        let mode: SchedulingMode = canUseAlarmKit ? .alarmKit : .notifications
        let windowDays = max(1, alarmConfigStore.defaults.scheduleWindowDays)
        let maxScheduleDays = 60
        let scheduleDays = max(windowDays, maxScheduleDays)
        let ruleEngine = RuleEngine(settings: settings, configStore: alarmConfigStore, timeZone: timeZone)
        let scheduleDates = scheduledDates(
            startingFrom: startDate,
            days: scheduleDays,
            timeZone: timeZone
        )

        let entries = generateSchedules(
            for: scheduleDates,
            coordinate: coordinate,
            timeZone: timeZone,
            method: method,
            adjustmentMinutes: settings.fajrAdjustmentMinutes,
            effectiveConfigProvider: { date in
                alarmConfigStore.effectiveConfig(
                    for: date,
                    ruleSummary: ruleEngine.ruleSummary(for: date),
                    settings: settings,
                    timeZone: timeZone
                )
            },
            locationDescription: "Based on your location"
        )

        let displaySchedules = Array(entries.prefix(windowDays)).map { $0.0 }
        schedules = displaySchedules
        lastUpdated = Date()

        let hasAnyEnabled = entries.contains { entry in
            let config = entry.1
            return !config.skipDay && config.hasAnyEnabled
        }

        if hasAnyEnabled {
            schedulingMode = mode
            let scheduled = await alarmScheduler.scheduleAll(
                entries: entries,
                settings: settings,
                canUseAlarmKit: canUseAlarmKit,
                cancelWindowDays: maxScheduleDays
            )
            statusText = scheduled ? "Scheduled" : "Unable to schedule"
        } else {
            await cancelAll()
            schedulingMode = .none
            statusText = "Off"
        }

        settingsStore.update { draft in
            draft.lastScheduledDate = Date()
            draft.lastSchedulingMode = schedulingMode
        }

        cacheStore.save(
            ScheduleCacheStore.Cache(
                lastScheduledDate: settingsStore.settings.lastScheduledDate,
                lastUpdated: lastUpdated,
                schedulingMode: schedulingMode,
                schedules: displaySchedules
            )
        )

        permissionSummary = await permissionSummaryText()
        alarmAuthorizationText = await alarmAuthorizationStateText()
        notificationAuthorizationText = await notificationAuthorizationStateText()
    }

    func rescheduleDay(_ date: Date) async {
        guard isLocationAuthorized else { return }
        guard let coordinate = currentCoordinate() else { return }

        let settings = settingsStore.settings
        let timeZone = TimeZone.current
        let method = settings.calculationMethod
        let ruleEngine = RuleEngine(settings: settings, configStore: alarmConfigStore, timeZone: timeZone)
        let effectiveConfig = alarmConfigStore.effectiveConfig(
            for: date,
            ruleSummary: ruleEngine.ruleSummary(for: date),
            settings: settings,
            timeZone: timeZone
        )

        guard let schedule = buildSchedule(
            for: date,
            coordinate: coordinate,
            timeZone: timeZone,
            method: method,
            adjustmentMinutes: settings.fajrAdjustmentMinutes,
            effectiveConfig: effectiveConfig,
            locationDescription: "Based on your location"
        ) else { return }

        let canUseAlarmKit = await alarmKitAvailableAndAuthorized()
        _ = await alarmScheduler.scheduleDay(
            schedule: schedule,
            config: effectiveConfig,
            settings: settings,
            canUseAlarmKit: canUseAlarmKit
        )

        let start = DateHelpers.startOfToday(in: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let end = calendar.date(
            byAdding: .day,
            value: max(0, alarmConfigStore.defaults.scheduleWindowDays - 1),
            to: start
        ) ?? start

        if schedule.date >= start && schedule.date <= end {
            if let index = schedules.firstIndex(where: { DateHelpers.isSameDay($0.date, date, in: timeZone) }) {
                schedules[index] = schedule
            } else {
                schedules.append(schedule)
                schedules.sort { $0.date < $1.date }
            }
        }

        lastUpdated = Date()
        cacheStore.save(
            ScheduleCacheStore.Cache(
                lastScheduledDate: settingsStore.settings.lastScheduledDate,
                lastUpdated: lastUpdated,
                schedulingMode: schedulingMode,
                schedules: schedules
            )
        )
    }

    func schedule(for date: Date) -> DaySchedule? {
        guard isLocationAuthorized else { return nil }
        guard let coordinate = currentCoordinate() else { return nil }

        let settings = settingsStore.settings
        let timeZone = TimeZone.current
        let method = settings.calculationMethod
        let ruleEngine = RuleEngine(settings: settings, configStore: alarmConfigStore, timeZone: timeZone)
        let effectiveConfig = alarmConfigStore.effectiveConfig(
            for: date,
            ruleSummary: ruleEngine.ruleSummary(for: date),
            settings: settings,
            timeZone: timeZone
        )

        return buildSchedule(
            for: date,
            coordinate: coordinate,
            timeZone: timeZone,
            method: method,
            adjustmentMinutes: settings.fajrAdjustmentMinutes,
            effectiveConfig: effectiveConfig,
            locationDescription: "Based on your location"
        )
    }

    func cancelDay(_ date: Date) async {
        guard let schedule = scheduleForCancellation(on: date) else { return }
        await alarmScheduler.cancelDay(schedule: schedule)
    }

    func requestAlarmAuthorization() async -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if #available(iOS 26.0, *), let alarmKitScheduler {
            return await alarmKitScheduler.requestAuthorization()
        }
        return false
        #endif
    }

    func requestNotificationAuthorization() async -> Bool {
        await notificationScheduler.requestAuthorization()
    }

    func scheduleTestNotification(kind: ScheduleEventKind) async -> Bool {
        let status = await notificationScheduler.authorizationStatus()
        if status == .denied {
            return false
        }
        if status == .notDetermined {
            let granted = await requestNotificationAuthorization()
            if !granted { return false }
        }
        return await notificationScheduler.scheduleTestNotification(
            kind: kind,
            settings: settingsStore.settings,
            delaySeconds: 5
        )
    }

    func scheduleFajrAdhanTest() async -> Bool {
        let canUseAlarmKit = await alarmKitAvailableAndAuthorized()
        if canUseAlarmKit, #available(iOS 26.0, *), let alarmKitScheduler {
            let soundName = alarmSoundName(for: settingsStore.settings.atFajrSoundSelectionGlobal)
            let date = Date().addingTimeInterval(60)
            return await alarmKitScheduler.scheduleTestAlarm(
                id: SchedulingIdentifiers.testAlarmID(for: .boundary),
                date: date,
                label: settingsStore.settings.label,
                kind: .boundary,
                soundName: soundName
            )
        }

        let status = await notificationScheduler.authorizationStatus()
        if status == .denied {
            return false
        }
        if status == .notDetermined {
            let granted = await requestNotificationAuthorization()
            if !granted { return false }
        }
        return await notificationScheduler.scheduleFajrAdhanTest(delaySeconds: 60)
    }

    func cancelTestNotifications() async {
        await notificationScheduler.cancelTestNotifications()
    }

    func requestLocationAuthorization() {
        locationService.requestAuthorization()
    }

    func refreshPermissionSummary() async {
        permissionSummary = await permissionSummaryText()
        alarmAuthorizationText = await alarmAuthorizationStateText()
        notificationAuthorizationText = await notificationAuthorizationStateText()
        EventTimelineLog.shared.record(category: "permissions", message: "Permission summary: \(permissionSummary)")
    }

    var canRequestAlarmKitAuthorization: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if #available(iOS 26.0, *), let alarmKitScheduler {
            return !alarmKitScheduler.isAuthorized
        }
        return false
        #endif
    }

    func notificationAuthorizationStatus() async -> UNAuthorizationStatus {
        await notificationScheduler.authorizationStatus()
    }

    func resetAll() async {
        await cancelAll()
        schedules = []
        schedulingMode = .none
        lastUpdated = nil
        permissionSummary = ""
        cacheStore.clear()
        settingsStore.reset()
    }

    func scheduleTestAlarm() async -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if #available(iOS 26.0, *), let alarmKitScheduler {
            if alarmKitScheduler.authorizationState != .authorized {
                _ = await alarmKitScheduler.requestAuthorization()
            }
            guard alarmKitScheduler.isAuthorized else { return false }
            let date = Date().addingTimeInterval(60)
            return await alarmKitScheduler.scheduleTestAlarm(date: date, label: settingsStore.settings.label)
        }
        return false
        #endif
    }

    func cancelTestAlarm() async {
        #if targetEnvironment(simulator)
        return
        #else
        if #available(iOS 26.0, *), let alarmKitScheduler {
            alarmKitScheduler.cancelTestAlarms()
        }
        await notificationScheduler.cancelTestNotifications()
        #endif
    }

    func runThreeEventTest() async -> Bool {
        let canUseAlarmKit = await alarmKitAvailableAndAuthorized()
        let details = await routineScheduler.scheduleTestEventsDetails(
            settings: settingsStore.settings,
            canUseAlarmKit: canUseAlarmKit
        )
        await refreshSchedules(force: true)
        return details.allSatisfy { $0.success }
    }

    func runThreeEventTestWithPermissions() async -> TestRunResult {
        if canRequestAlarmKitAuthorization {
            _ = await requestAlarmAuthorization()
        }

        let canUseAlarmKit = await alarmKitAvailableAndAuthorized()
        let notificationStatus = await notificationAuthorizationStatus()
        if notificationStatus == .denied {
            return TestRunResult(
                success: false,
                message: "Notifications are denied. Enable them in Settings to run tests.",
                details: []
            )
        }
        if notificationStatus == .notDetermined {
            let granted = await requestNotificationAuthorization()
            if !granted {
                return TestRunResult(
                    success: false,
                    message: "Notifications weren’t granted. Enable them to run tests.",
                    details: []
                )
            }
        }

        let details = await routineScheduler.scheduleTestEventsDetails(
            settings: settingsStore.settings,
            canUseAlarmKit: canUseAlarmKit
        )
        await refreshSchedules(force: true)
        let success = details.allSatisfy { $0.success }
        let summary = success
            ? "All test events scheduled. Check alarms/notifications in 1–3 minutes."
            : "Some test events failed. See details below."
        let detailLines = details.map { detail in
            let status = detail.success ? "Scheduled" : "Failed"
            return "\(detail.kind.title): \(status) via \(detail.channel). \(detail.message)"
        }
        return TestRunResult(success: success, message: summary, details: detailLines)
    }

    func runAlarmKitTestScenario() async -> Bool {
        guard FeatureFlags.enableAlarmKitTestMode else { return false }
        guard #available(iOS 26.0, *), let alarmCoordinator else { return false }
        guard testSettingsStore.settings.isEnabled else { return false }
        if canRequestAlarmKitAuthorization {
            _ = await requestAlarmAuthorization()
        }
        let canUseAlarmKit = await alarmKitAvailableAndAuthorized()
        guard canUseAlarmKit else { return false }

        let settings = testSettingsStore.settings
        let label = "\(settingsStore.settings.label) (TEST)"
        let snoozeDuration = settingsStore.settings.snoozeEnabled
            ? TimeInterval(settingsStore.settings.snoozeMinutes * 60)
            : nil
        let runner = AlarmKitTestScenarioRunner(
            alarmCoordinator: alarmCoordinator,
            testRunStore: testRunStore,
            timeProvider: SystemTimeProvider()
        )
        alarmRecordStore.clearAllTests()
        let success = await runner.run(
            settings: settings,
            label: label,
            soundName: alarmSoundName(for: settingsStore.settings.atFajrSoundSelectionGlobal),
            snoozeDuration: snoozeDuration
        )
        testSettingsStore.settings.testRunId = testRunStore.load()?.testRunId
        return success
    }

    func cancelAlarmKitTestAlarms() async {
        guard FeatureFlags.enableAlarmKitTestMode else { return }
        guard #available(iOS 26.0, *), let alarmCoordinator else { return }
        let ids = ScheduleEventKind.allCases.map { SchedulingIdentifiers.testAlarmID(for: $0) }
        alarmCoordinator.cancel(ids: ids)
        alarmRecordStore.clearAllTests()
        alarmStateStore.clear()
        testRunStore.clear()
        DebugEventLog.shared.record(.canceledTestAlarms)
    }

    func stopCountdownUI() async {
        guard FeatureFlags.enableCountdown else { return }
        await countdownManager.stopCountdownByUser()
    }

    func resetAlarmKitTestState() async {
        guard FeatureFlags.enableAlarmKitTestMode else { return }
        await cancelAlarmKitTestAlarms()
        await countdownManager.stopCountdownByUser()
        testSettingsStore.reset()
        testRunStore.clear()
    }

    func cleanupLiveActivities() async -> Int {
        guard FeatureFlags.enableCountdown else { return 0 }
        return await countdownManager.cleanupLiveActivities()
    }

    func alarmKitTestSnapshot() -> AlarmKitTestSnapshot {
        guard FeatureFlags.enableAlarmKitTestMode else {
            return AlarmKitTestSnapshot(
                now: Date(),
                testRun: nil,
                alarmStates: [],
                countdownSession: nil,
                events: []
            )
        }
        return AlarmKitTestSnapshot(
            now: Date(),
            testRun: testRunStore.load(),
            alarmStates: alarmStateStore.entries(),
            countdownSession: countdownStore.loadSession(),
            events: DebugEventLog.shared.events(limit: 20)
        )
    }

    func makeSchedulingAudit() async -> SchedulingAuditSnapshot {
        let settings = settingsStore.settings
        let timeZone = TimeZone.current
        let now = Date()
        let canUseAlarmKit = await alarmKitAvailableAndAuthorized()
        let ruleEngine = RuleEngine(settings: settings, configStore: alarmConfigStore, timeZone: timeZone)

        guard let coordinate = currentCoordinate() else {
            let mismatch = AuditMismatch(severity: .error, message: "Location unavailable; unable to compute expected events.")
            return SchedulingAuditSnapshot(
                generatedAt: Date(),
                expectedEvents: [],
                notificationItems: [],
                alarmKitItems: [],
                mismatches: [mismatch]
            )
        }

        let today = DateHelpers.startOfToday(in: timeZone)
        let tomorrow = DateHelpers.startOfTomorrow(in: timeZone)
        let dates = [today, tomorrow]
        var expectedEvents: [ExpectedScheduledEvent] = []

        for date in dates {
            let effectiveConfig = alarmConfigStore.effectiveConfig(
                for: date,
                ruleSummary: ruleEngine.ruleSummary(for: date),
                settings: settings,
                timeZone: timeZone
            )
            guard let schedule = buildSchedule(
                for: date,
                coordinate: coordinate,
                timeZone: timeZone,
                method: settings.calculationMethod,
                adjustmentMinutes: settings.fajrAdjustmentMinutes,
                effectiveConfig: effectiveConfig,
                locationDescription: "Audit"
            ) else { continue }

            let dayLabelText = dayLabel(for: date)
            if effectiveConfig.suhoorEnabled && !effectiveConfig.skipDay {
                let channel: ExpectedScheduledEvent.Channel = canUseAlarmKit ? .alarmKit : .notification
                let identifier = channel == .alarmKit
                    ? SchedulingIdentifiers.alarmID(for: schedule, kind: .wake).uuidString
                    : SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .wake)
                expectedEvents.append(
                    ExpectedScheduledEvent(
                        kind: .wake,
                        date: schedule.wakeDate,
                        dayLabel: dayLabelText,
                        scheduleId: schedule.id,
                        channel: channel,
                        identifier: identifier,
                        isPast: schedule.wakeDate <= now
                    )
                )
            }

            if effectiveConfig.reminderEnabled, !effectiveConfig.skipDay, let reminderDate = schedule.reminderDate {
                let channel: ExpectedScheduledEvent.Channel = canUseAlarmKit ? .alarmKit : .notification
                let identifier = channel == .alarmKit
                    ? SchedulingIdentifiers.alarmID(for: schedule, kind: .reminder).uuidString
                    : SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .reminder)
                expectedEvents.append(
                    ExpectedScheduledEvent(
                        kind: .reminder,
                        date: reminderDate,
                        dayLabel: dayLabelText,
                        scheduleId: schedule.id,
                        channel: channel,
                        identifier: identifier,
                        isPast: reminderDate <= now
                    )
                )
            }

            if effectiveConfig.fajrEnabled, !effectiveConfig.skipDay, let boundaryDate = schedule.boundaryDate {
                let channel: ExpectedScheduledEvent.Channel = canUseAlarmKit ? .alarmKit : .notification
                let identifier = channel == .alarmKit
                    ? SchedulingIdentifiers.alarmID(for: schedule, kind: .boundary).uuidString
                    : SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .boundary)
                expectedEvents.append(
                    ExpectedScheduledEvent(
                        kind: .boundary,
                        date: boundaryDate,
                        dayLabel: dayLabelText,
                        scheduleId: schedule.id,
                        channel: channel,
                        identifier: identifier,
                        isPast: boundaryDate <= now
                    )
                )
            }
        }

        let pendingRequests = await notificationScheduler.pendingRequests()
        let notificationItems = pendingRequests.map { NotificationAuditItem(request: $0) }

        let alarmKitItems: [AlarmKitAuditItem]
        if #available(iOS 26.0, *), let alarmKitScheduler {
            alarmKitItems = alarmKitScheduler.fetchScheduledAlarms()
        } else {
            alarmKitItems = []
        }

        let mismatches = buildAuditMismatches(
            expectedEvents: expectedEvents,
            notificationItems: notificationItems,
            alarmKitItems: alarmKitItems
        )

        Logging.scheduler.info("Scheduling audit: expected=\(expectedEvents.count) notifications=\(notificationItems.count) alarms=\(alarmKitItems.count) mismatches=\(mismatches.count)")
        EventTimelineLog.shared.record(category: "audit", message: "Audit expected=\(expectedEvents.count) notifications=\(notificationItems.count) alarms=\(alarmKitItems.count) mismatches=\(mismatches.count)")

        return SchedulingAuditSnapshot(
            generatedAt: Date(),
            expectedEvents: expectedEvents,
            notificationItems: notificationItems,
            alarmKitItems: alarmKitItems,
            mismatches: mismatches
        )
    }

    private var isLocationAuthorized: Bool {
        locationService.authorizationStatus == .authorizedAlways || locationService.authorizationStatus == .authorizedWhenInUse
    }

    private var hasAnyEnabledAlarms: Bool {
        alarmConfigStore.hasAnyEnabledDefaults || alarmConfigStore.hasAnyEnabledOverride()
    }

    private func currentCoordinate() -> CLLocationCoordinate2D? {
        switch settingsStore.settings.locationMode {
        case .auto:
            return locationService.lastLocation?.coordinate
        case .fixed:
            guard let fixed = settingsStore.settings.fixedLocation else { return nil }
            return CLLocationCoordinate2D(latitude: fixed.latitude, longitude: fixed.longitude)
        }
    }

    private func buildAuditMismatches(
        expectedEvents: [ExpectedScheduledEvent],
        notificationItems: [NotificationAuditItem],
        alarmKitItems: [AlarmKitAuditItem]
    ) -> [AuditMismatch] {
        var mismatches: [AuditMismatch] = []
        let notificationIDs = Set(notificationItems.map { $0.id })
        let alarmIDs = Set(alarmKitItems.map { $0.id.uuidString })

        let counts = expectedEvents.reduce(into: [String: Int]()) { partial, event in
            partial[event.identifier, default: 0] += 1
        }
        let duplicateIDs = counts.filter { $0.value > 1 }.map { $0.key }
        for duplicateID in duplicateIDs {
            mismatches.append(AuditMismatch(severity: .error, message: "Identifier collision: \(duplicateID)"))
        }

        for expected in expectedEvents {
            let isPresent = expected.channel == .notification
                ? notificationIDs.contains(expected.identifier)
                : alarmIDs.contains(expected.identifier)
            if !isPresent {
                mismatches.append(
                    AuditMismatch(
                        severity: .error,
                        message: "Missing \(expected.kind.title) for \(expected.dayLabel) (id: \(expected.identifier))"
                    )
                )
                continue
            }

            let scheduledDate: Date?
            switch expected.channel {
            case .notification:
                scheduledDate = notificationItems.first { $0.id == expected.identifier }?.triggerDate
            case .alarmKit:
                scheduledDate = alarmKitItems.first { $0.id.uuidString == expected.identifier }?.nextTriggerDate
            }

            if let scheduledDate {
                let delta = abs(scheduledDate.timeIntervalSince(expected.date))
                if delta > 60 {
                    mismatches.append(
                        AuditMismatch(
                            severity: .warning,
                            message: "Time mismatch for \(expected.kind.title) (id: \(expected.identifier)) expected \(TimeFormatters.shortDateTime.string(from: expected.date)) got \(TimeFormatters.shortDateTime.string(from: scheduledDate))"
                        )
                    )
                }
            }
        }

        let expectedNotificationIDs = Set(expectedEvents.filter { $0.channel == .notification }.map { $0.identifier })
        let expectedAlarmIDs = Set(expectedEvents.filter { $0.channel == .alarmKit }.map { $0.identifier })

        for item in notificationItems where item.id.hasPrefix("suhoor.") && !expectedNotificationIDs.contains(item.id) {
            mismatches.append(AuditMismatch(severity: .warning, message: "Extra notification scheduled: \(item.id)"))
        }

        for item in alarmKitItems where !expectedAlarmIDs.contains(item.id.uuidString) {
            mismatches.append(AuditMismatch(severity: .warning, message: "Extra AlarmKit alarm scheduled: \(item.id.uuidString)"))
        }

        return mismatches
    }

    private func alarmKitAvailableAndAuthorized() async -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if #available(iOS 26.0, *), let alarmKitScheduler {
            return alarmKitScheduler.isAuthorized
        }
        return false
        #endif
    }

    private func permissionSummaryText() async -> String {
        #if targetEnvironment(simulator)
        let notificationState = await notificationScheduler.authorizationStateText
        return "AlarmKit: Unavailable on Simulator · Notifications: \(notificationState)"
        #else
        if #available(iOS 26.0, *), let alarmKitScheduler {
            let alarmState = alarmKitScheduler.authorizationStateText
            let notificationState = await notificationScheduler.authorizationStateText
            return "AlarmKit: \(alarmState) · Notifications: \(notificationState)"
        }
        let notificationState = await notificationScheduler.authorizationStateText
        return "Notifications: \(notificationState)"
        #endif
    }

    private func alarmAuthorizationStateText() async -> String {
        #if targetEnvironment(simulator)
        return "Unavailable on Simulator"
        #else
        if #available(iOS 26.0, *), let alarmKitScheduler {
            return alarmKitScheduler.authorizationStateText
        }
        return "Unavailable"
        #endif
    }

    private func notificationAuthorizationStateText() async -> String {
        await notificationScheduler.authorizationStateText
    }

    private func alarmSoundName(for soundChoice: SoundChoice) -> String? {
        guard soundChoice == .adhanSoft else { return nil }
        if Bundle.main.url(forResource: "adhan_fajr", withExtension: "caf") != nil {
            return "adhan_fajr.caf"
        }
        return nil
    }

    private func cancelAll() async {
        await routineScheduler.cancelAllUpcoming(days: 30)
        alarmRecordStore.clearAll()
        alarmStateStore.clear()
    }

    private func scheduleForCancellation(on date: Date) -> DaySchedule? {
        let timeZone = TimeZone.current
        if let existing = schedules.first(where: { DateHelpers.isSameDay($0.date, date, in: timeZone) }) {
            return existing
        }
        return schedule(for: date)
    }

    private func buildSchedule(
        for day: Date,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        method: CalculationMethod,
        adjustmentMinutes: Int,
        effectiveConfig: EffectiveDailyConfig,
        locationDescription: String
    ) -> DaySchedule? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        guard let fajr = calculator.fajrDate(
            for: day,
            location: coordinate,
            timeZone: timeZone,
            method: method,
            adjustmentMinutes: adjustmentMinutes
        ) else { return nil }

        let wake = resolvedSuhoorDate(for: day, fajr: fajr, config: effectiveConfig, calendar: calendar)
        let offsetMinutes = Int(round(fajr.timeIntervalSince(wake) / 60))
        var reminder: Date?
        if effectiveConfig.reminderEnabled {
            reminder = resolvedReminderDate(
                for: day,
                suhoor: wake,
                fajr: fajr,
                config: effectiveConfig,
                calendar: calendar
            )
        }
        let boundary = effectiveConfig.fajrEnabled ? fajr : nil
        let fajrSoundChoice = effectiveConfig.fajrSoundChoice

        return DaySchedule(
            date: day,
            fajrDate: fajr,
            wakeDate: wake,
            reminderDate: reminder,
            boundaryDate: boundary,
            fajrSoundChoice: fajrSoundChoice,
            locationDescription: locationDescription,
            offsetMinutes: offsetMinutes,
            calculationMethodName: method.displayName,
            timeZone: timeZone
        )
    }

    private func generateSchedules(
        for dates: [Date],
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        method: CalculationMethod,
        adjustmentMinutes: Int,
        effectiveConfigProvider: (Date) -> EffectiveDailyConfig,
        locationDescription: String
    ) -> [(DaySchedule, EffectiveDailyConfig)] {
        var results: [(DaySchedule, EffectiveDailyConfig)] = []
        for day in dates {
            let config = effectiveConfigProvider(day)
            if let schedule = buildSchedule(
                for: day,
                coordinate: coordinate,
                timeZone: timeZone,
                method: method,
                adjustmentMinutes: adjustmentMinutes,
                effectiveConfig: config,
                locationDescription: locationDescription
            ) {
                results.append((schedule, config))
            }
        }
        return results
    }

    private func resolvedSuhoorDate(
        for day: Date,
        fajr: Date,
        config: EffectiveDailyConfig,
        calendar: Calendar
    ) -> Date {
        if let overrideMinutes = config.suhoorTimeOverrideMinutesFromMidnight {
            return dateFromMidnight(for: day, minutes: overrideMinutes, calendar: calendar)
        }
        if config.suhoorTimeMode == .fixedTime {
            return dateFromMidnight(for: day, minutes: config.suhoorOffsetMinutes, calendar: calendar)
        }
        return ScheduleEventCalculator.wakeDate(for: fajr, offsetMinutes: config.suhoorOffsetMinutes, calendar: calendar)
    }

    private func resolvedReminderDate(
        for day: Date,
        suhoor: Date,
        fajr: Date,
        config: EffectiveDailyConfig,
        calendar: Calendar
    ) -> Date? {
        let result = computedReminderTime(
            for: day,
            suhoor: suhoor,
            fajr: fajr,
            config: config,
            calendar: calendar
        )
        if result.wasClampedToSuhoor {
            Logging.scheduler.info("Reminder clamped to Suhoor for \\(DateHelpers.dayIdentifier(for: day, timeZone: calendar.timeZone)).")
        }
        return result.reminderTime
    }

    private func computedReminderTime(
        for day: Date,
        suhoor: Date,
        fajr: Date,
        config: EffectiveDailyConfig,
        calendar: Calendar
    ) -> TimeValidationResult {
        let reminderDate: Date
        if let overrideMinutes = config.reminderTimeOverrideMinutesFromMidnight {
            reminderDate = dateFromMidnight(for: day, minutes: overrideMinutes, calendar: calendar)
        } else if config.reminderTimeMode == .fixedTime {
            reminderDate = dateFromMidnight(for: day, minutes: config.reminderFixedTimeMinutes, calendar: calendar)
        } else {
            reminderDate = ScheduleEventCalculator.reminderDate(
                for: fajr,
                reminderMinutes: config.reminderMinutesBeforeFajr,
                calendar: calendar
            )
        }
        return TimeValidation.validateDailyTimes(suhoorTime: suhoor, reminderTime: reminderDate)
    }

    private func dateFromMidnight(for day: Date, minutes: Int, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: start) ?? start
    }

    private func scheduledDates(
        startingFrom startDate: Date,
        days: Int,
        timeZone: TimeZone
    ) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedStart = calendar.startOfDay(for: startDate)
        return DateHelpers.dates(startingFrom: normalizedStart, count: days, calendar: calendar)
    }
}

enum ScheduleRefreshReason {
    case appLaunch
    case foreground
    case settingsChanged
    case locationUpdated
    case manual
}
