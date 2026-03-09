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
    @Published private(set) var currentRevision: Int = 0
    @Published private(set) var permissionSnapshot: PermissionSnapshot = .empty
    @Published private(set) var activeWindowSnapshot: ActiveAlarmWindowSnapshot = .empty {
        didSet {
            currentRevision += 1
        }
    }
    @Published private(set) var bootstrapState: AppBootstrapState = .welcome
    @Published private(set) var hijriAdjustmentChanges: [HijriAdjustmentChange] = []

    private let settingsStore: SuhoorSettingsStore
    private let alarmConfigStore: AlarmConfigStore
    private let morningPlanStore: MorningPlanStore
    private let locationService: LocationService
    private let fastTagStore: FastTagStore
    private let fastLogStore: FastLogStore
    private let fajrLogStore: FajrLogStore
    private let qadaBacklogStore: QadaBacklogStore
    private let qadaBatchStore: QadaBatchStore
    private let cacheStore: ScheduleCacheStore
    private let completionSurfaceProvider = CompletionSurfaceProvider()
    private let wakeSurfaceProvider = WakeSurfaceProvider()
    private let plansSurfaceProvider = PlansSurfaceProvider()
    private let homeSurfaceProvider = HomeSurfaceProvider()
    private let nextWakeEventResolver = NextWakeEventResolver()
    private let calendarPlanningProvider = CalendarPlanningProvider()
    private let quickAddPreviewProvider = QuickAddPreviewProvider()
    private let schedulingAuditProvider = SchedulingAuditProvider()
    private let completionCommandGateway: CompletionCommandGateway
    private let calculator = PrayerTimeCalculator()
    private let hijriAdjustmentStore: HijriMonthAdjustmentStore
    private let adjustedHijriCalendar: AdjustedHijriCalendar
    private let hijriAdjustmentChangeStore: HijriAdjustmentChangeStore
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
    private let visibleActiveDayLimit = 60
    private let scheduledActiveDayLimit = 30
    private var expandedMonthSnapshots: [String: ExpandedMonthSnapshot] = [:]
    private var expandedMonthInvalidationToken: Int = 0
    private var tagResultMonthCache: [HijriMonthKey: MonthTagCache] = [:]
    private var activeTagSelectionRevision: Int = -1
    private var queuedRefresh: PendingScheduleRefresh?
    private var refreshTask: Task<Void, Never>?
    private var pendingDayRescheduleTasks: [String: Task<Void, Never>] = [:]
    private var cancellables: Set<AnyCancellable> = []

    init(
        settingsStore: SuhoorSettingsStore,
        locationService: LocationService,
        alarmConfigStore: AlarmConfigStore,
        fastTagStore: FastTagStore = FastTagStore(),
        fastLogStore: FastLogStore = FastLogStore(),
        fajrLogStore: FajrLogStore = FajrLogStore(),
        qadaBacklogStore: QadaBacklogStore = QadaBacklogStore(),
        qadaBatchStore: QadaBatchStore = QadaBatchStore(),
        hijriAdjustmentStore: HijriMonthAdjustmentStore = HijriMonthAdjustmentStore(),
        hijriAdjustmentChangeStore: HijriAdjustmentChangeStore = HijriAdjustmentChangeStore(),
        cacheStore: ScheduleCacheStore = ScheduleCacheStore()
    ) {
        self.settingsStore = settingsStore
        self.alarmConfigStore = alarmConfigStore
        self.morningPlanStore = MorningPlanStore(
            defaults: alarmConfigStore.storageDefaults,
            legacySettings: settingsStore.settings,
            defaultConfig: alarmConfigStore.defaults
        )
        self.locationService = locationService
        self.fastTagStore = fastTagStore
        self.fastLogStore = fastLogStore
        self.fajrLogStore = fajrLogStore
        self.qadaBacklogStore = qadaBacklogStore
        self.qadaBatchStore = qadaBatchStore
        self.hijriAdjustmentStore = hijriAdjustmentStore
        self.hijriAdjustmentChangeStore = hijriAdjustmentChangeStore
        self.cacheStore = cacheStore
        self.completionCommandGateway = CompletionCommandGateway(
            fajrLogStore: fajrLogStore,
            fastLogStore: fastLogStore
        )
        let hijriCalendarService = HijriCalendarService(adjustmentStore: hijriAdjustmentStore)
        let adjustedHijriCalendar = AdjustedHijriCalendar(calendarService: hijriCalendarService)
        self.adjustedHijriCalendar = adjustedHijriCalendar
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
        self.activeWindowSnapshot = cache.activeWindowSnapshot
            ?? Self.makeLegacySnapshot(
                schedules: cache.schedules,
                settings: settingsStore.settings,
                defaults: alarmConfigStore.defaults,
                overridesByDay: alarmConfigStore.overridesByDay,
                provenanceProvider: { alarmConfigStore.provenance(for: $0, timeZone: $1) },
                selections: fastTagStore.selections,
                visibleHorizonDays: visibleActiveDayLimit,
                scheduledHorizonDays: scheduledActiveDayLimit,
                timeZone: .current
            )
        self.activeTagSelectionRevision = cache.tagSelectionRevision ?? -1
        self.schedules = activeWindowSnapshot.visibleDays.map(\.schedule)
        self.hijriAdjustmentChanges = hijriAdjustmentChangeStore.pendingChanges()

        fastTagStore.$selections
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.retagActiveWindow()
                }
            }
            .store(in: &cancellables)

        fastLogStore.$currentRevision
            .dropFirst()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        fajrLogStore.$currentRevision
            .dropFirst()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        qadaBacklogStore.$state
            .dropFirst()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settingsStore.$settings
            .sink { [weak self] _ in
                self?.updateBootstrapState()
            }
            .store(in: &cancellables)

        locationService.$authorizationStatus
            .sink { [weak self] _ in
                self?.updateBootstrapState()
            }
            .store(in: &cancellables)

        locationService.$lastLocation
            .sink { [weak self] _ in
                self?.updateBootstrapState()
            }
            .store(in: &cancellables)

        updateBootstrapState()
    }

    var nextUpcomingSchedule: DaySchedule? {
        nextWakeEventSummary?.day.schedule
            ?? activeWindowSnapshot.visibleDays.first(where: { !$0.effectiveConfig.skipDay && $0.effectiveConfig.hasAnyEnabled })?.schedule
            ?? schedules.first
    }

    var nextWakeEventSummary: NextWakeEventSummary? {
        nextWakeEventResolver.resolve(
            activeWindowSnapshot: activeWindowSnapshot,
            now: Date()
        )
    }

    var wakeSurfaceSnapshot: WakeSurfaceSnapshot {
        wakeSurfaceProvider.wakeSurfaceSnapshot(
            activeWindowSnapshot: activeWindowSnapshot,
            nextWakeEventSummary: nextWakeEventSummary,
            overrideDateKeys: Set(alarmConfigStore.overridesByDay.keys)
        )
    }

    func wakeListSnapshot(
        tagFilter: WakeTagFilter,
        pinnedEntryIDs: [String],
        timeZone: TimeZone = .current
    ) -> WakeListSnapshotBuildResult {
        wakeSurfaceProvider.wakeListSnapshot(
            wakeSnapshot: wakeSurfaceSnapshot,
            tagFilter: tagFilter,
            pinnedEntryIDs: pinnedEntryIDs,
            timeZone: timeZone,
            dependencies: WakeSurfaceProvider.Dependencies(
                totalScheduledCount: { [weak self] key in
                    self?.totalScheduledCount(for: key, timeZone: timeZone) ?? 0
                },
                rollingHijriMonths: { [weak self] in
                    self?.rollingHijriMonths(count: 12, timeZone: timeZone) ?? []
                },
                monthPreview: { [weak self] yearMonth in
                    self?.hijriMonthStartPreview(
                        for: yearMonth.month,
                        hijriYear: yearMonth.hijriYear,
                        timeZone: timeZone
                    )
                },
                cachedMonthEntries: { [weak self] key in
                    self?.cachedMonthEntries(for: key)
                }
            )
        )
    }

    var plansSurfaceSnapshot: PlansSurfaceSnapshot {
        plansSurfaceProvider.plansSurfaceSnapshot(
            defaults: alarmConfigStore.defaults,
            settings: settingsStore.settings,
            upcomingDays: activeWindowSnapshot.visibleDays,
            overrideDateKeys: Set(alarmConfigStore.overridesByDay.keys),
            qadaBacklogState: qadaBacklogStore.state,
            fastLogEntries: fastLogStore.entriesByDateKey
        )
    }

    func homeSurfaceSnapshot(
        now: Date,
        dismissedWarnings: Set<FastWarning>
    ) -> HomeSurfaceSnapshot {
        let hijriComponents = AdjustedHijriCalendar.shared.adjustedComponents(for: now, timeZone: .current)
        let todayKey = DateHelpers.dayIdentifier(for: now, timeZone: .current)
        let todayStart = DateHelpers.startOfDay(now, in: .current)
        let currentDay = activeWindowSnapshot.byDateKey[todayKey]
        let todaySchedule = currentDay?.schedule ?? schedule(for: todayStart)
        let completionProjection = CompletionProjectionBuilder.buildHome(
            now: now,
            currentDay: currentDay,
            todaySchedule: todaySchedule,
            settings: settingsStore.settings,
            permissionSnapshot: permissionSnapshot,
            hijriComponents: hijriComponents,
            dismissedWarnings: dismissedWarnings
        )

        return homeSurfaceProvider.homeSurfaceSnapshot(
            now: now,
            currentDay: currentDay,
            todaySchedule: todaySchedule,
            nextWakeEventSummary: nextWakeEventSummary,
            settings: settingsStore.settings,
            permissionSnapshot: permissionSnapshot,
            hijriComponents: hijriComponents,
            supportDecision: completionProjection.supportDecision,
            dayLabel: { [weak self] date in
                self?.dayLabel(for: date) ?? TimeFormatters.dayFormatter.string(from: date)
            }
        )
    }

    func progressSurfaceSnapshot(
        wakeProgressSource: WakeProgressSource = DebugEventLogWakeProgressSource()
    ) -> ProgressSurfaceSnapshot {
        return completionSurfaceProvider.progressSurfaceSnapshot(
            activeWindowSnapshot: activeWindowSnapshot,
            completionState: currentCompletionStateSnapshot(),
            settings: settingsStore.settings,
            wakeProgress: wakeProgressSource.snapshot(limit: 20)
        )
    }

    func fajrHistorySurfaceSnapshot(
        days: Int = 30,
        now: Date = Date()
    ) -> FajrHistorySurfaceSnapshot {
        completionSurfaceProvider.fajrHistorySurfaceSnapshot(
            days: days,
            now: now
        ) { [weak self] date, timeZone in
            self?.resolvedDaySnapshotForHistory(for: date, timeZone: timeZone)
        }
    }

    func fastHistorySurfaceSnapshot(
        days: Int = 30,
        now: Date = Date()
    ) -> FastHistorySurfaceSnapshot {
        completionSurfaceProvider.fastHistorySurfaceSnapshot(
            days: days,
            now: now
        ) { [weak self] date, timeZone in
            self?.resolvedDaySnapshotForHistory(for: date, timeZone: timeZone)
        }
    }

    func performCompletionEdit(
        _ intent: CompletionEditIntent,
        now: Date = Date()
    ) {
        completionCommandGateway.perform(intent, now: now)
    }

    var currentHijriAdjustmentYear: Int {
        resolvedCurrentHijriYear()
    }

    var lastUpdatedText: String {
        guard let date = lastUpdated else { return "--" }
        return TimeFormatters.shortDateTime.string(from: date)
    }

    var usesNotificationFallback: Bool {
        hasAnyEnabledAlarms && schedulingMode == .notifications
    }

    var showsHome: Bool {
        bootstrapState == .home
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

    private func totalScheduledCount(
        for key: HijriMonthKey,
        timeZone: TimeZone = .current
    ) -> Int {
        guard let month = HijriMonth(rawValue: key.month) else { return 0 }
        return alarmConfigStore.resolvedScheduledEntries(
            forHijriMonth: HijriYearMonth(hijriYear: key.year, month: month),
            timeZone: timeZone
        ).count
    }

    func hijriAdjustment(for month: HijriMonth) -> Int {
        hijriAdjustment(for: month, hijriYear: currentHijriAdjustmentYear)
    }

    func hijriAdjustment(for month: HijriMonth, hijriYear: Int) -> Int {
        hijriAdjustmentStore.readAdjustment(for: HijriYearMonth(hijriYear: hijriYear, month: month))
    }

    func hasHijriBaseline(for month: HijriMonth) -> Bool {
        hasHijriBaseline(for: month, hijriYear: currentHijriAdjustmentYear)
    }

    func hasHijriBaseline(for month: HijriMonth, hijriYear: Int) -> Bool {
        adjustedHijriCalendar.monthStartPreview(for: HijriYearMonth(hijriYear: hijriYear, month: month)) != nil
    }

    func setHijriMonthAdjustment(for month: HijriMonth, offsetDays: Int) async {
        await setHijriMonthAdjustment(for: month, hijriYear: currentHijriAdjustmentYear, offsetDays: offsetDays)
    }

    func setHijriMonthAdjustment(for month: HijriMonth, hijriYear: Int, offsetDays: Int) async {
        objectWillChange.send()
        let timeZone = TimeZone.current
        let key = HijriYearMonth(hijriYear: hijriYear, month: month)
        let hijriSources = alarmConfigStore.hijriSingleDaySources(for: key)
        let oldResolved = resolveHijriSourceDates(hijriSources, timeZone: timeZone)

        hijriAdjustmentStore.setAdjustment(for: key, offsetDays: offsetDays)

        let newResolved = resolveHijriSourceDates(hijriSources, timeZone: timeZone)
        let changes = applyHijriAdjustmentShifts(
            sources: hijriSources,
            oldResolved: oldResolved,
            newResolved: newResolved,
            timeZone: timeZone
        )
        if !changes.isEmpty {
            hijriAdjustmentChangeStore.record(changes)
            hijriAdjustmentChanges = hijriAdjustmentChangeStore.pendingChanges()
        }
        await refreshSchedules(force: true)
    }

    func hijriMonthStartPreview(for month: HijriMonth, timeZone: TimeZone = .current) -> HijriMonthStartPreview? {
        hijriMonthStartPreview(for: month, hijriYear: currentHijriAdjustmentYear, timeZone: timeZone)
    }

    func hijriMonthStartPreview(for month: HijriMonth, hijriYear: Int, timeZone: TimeZone = .current) -> HijriMonthStartPreview? {
        adjustedHijriCalendar.monthStartPreview(for: HijriYearMonth(hijriYear: hijriYear, month: month), timeZone: timeZone)
    }

    func acknowledgeHijriAdjustmentChanges() {
        hijriAdjustmentChangeStore.acknowledgeAll()
        hijriAdjustmentChanges = []
    }

    func currentHijriYearMonth(timeZone: TimeZone = .current, date: Date = Date()) -> HijriYearMonth? {
        if let components = adjustedHijriCalendar.adjustedComponents(for: date, timeZone: timeZone) {
            return HijriYearMonth(hijriYear: components.hijriYear, month: components.month)
        }
        var fallbackCalendar = Calendar(identifier: .islamicUmmAlQura)
        fallbackCalendar.timeZone = timeZone
        let fallback = fallbackCalendar.dateComponents([.year, .month], from: date)
        guard
            let year = fallback.year,
            let monthValue = fallback.month,
            let month = HijriMonth(rawValue: monthValue)
        else {
            return nil
        }
        return HijriYearMonth(hijriYear: year, month: month)
    }

    func rollingHijriMonths(count: Int = 12, timeZone: TimeZone = .current, date: Date = Date()) -> [HijriYearMonth] {
        guard let start = currentHijriYearMonth(timeZone: timeZone, date: date), count > 0 else { return [] }
        return (0..<count).compactMap { offset in
            let rawMonth = start.month.rawValue - 1 + offset
            let monthValue = (rawMonth % 12) + 1
            let yearOffset = rawMonth / 12
            guard let month = HijriMonth(rawValue: monthValue) else { return nil }
            return HijriYearMonth(hijriYear: start.hijriYear + yearOffset, month: month)
        }
    }

    func hasRecurringIslamicSchedules() -> Bool {
        alarmConfigStore.hasAnyRecurringIslamicSource()
    }

    func cachedMonthEntries(for key: HijriMonthKey) -> [ActiveAlarmDay]? {
        let identifier = expandedMonthIdentifier(for: key)
        guard let cached = expandedMonthSnapshots[identifier],
              cached.invalidationToken == expandedMonthInvalidationToken,
              cached.tagSelectionRevision == fastTagStore.currentRevision else {
            return nil
        }
        return cached.entries
    }

    func monthEntries(for key: HijriMonthKey, timeZone: TimeZone = .current) async -> [ActiveAlarmDay] {
        let identifier = expandedMonthIdentifier(for: key)
        if let cached = expandedMonthSnapshots[identifier],
           cached.invalidationToken == expandedMonthInvalidationToken,
           cached.tagSelectionRevision == fastTagStore.currentRevision {
            return cached.entries
        }

        guard let coordinate = currentCoordinate() else { return [] }
        guard let month = HijriMonth(rawValue: key.month) else { return [] }

        syncMorningPlanState()
        let resolvedEntries = resolvedEntriesForHijriMonth(
            HijriYearMonth(hijriYear: key.year, month: month),
            timeZone: timeZone
        )
        let entries = activeDays(
            from: resolvedEntries,
            coordinate: coordinate,
            timeZone: timeZone
        )

        expandedMonthSnapshots[identifier] = ExpandedMonthSnapshot(
            key: key,
            generatedAt: Date(),
            invalidationToken: expandedMonthInvalidationToken,
            tagSelectionRevision: fastTagStore.currentRevision,
            entries: entries
        )
        return entries
    }

    func invalidateExpandedMonthSnapshots(reason: String? = nil) {
        expandedMonthInvalidationToken += 1
        expandedMonthSnapshots.removeAll()
        invalidateTagResultMonthCache()
        if let reason {
            Logging.diagnostics.debug("[cache] invalidated expanded month snapshots: \(reason, privacy: .public)")
        }
    }

    private func invalidateTagResultMonthCache() {
        tagResultMonthCache.removeAll()
    }

    func upcomingResolvedEntries(limit: Int = 60, timeZone: TimeZone = .current) -> [ResolvedScheduledDateEntry] {
        let snapshotEntries = activeWindowSnapshot.visibleDays
            .prefix(limit)
            .map { day in
                ResolvedScheduledDateEntry(
                    date: day.date,
                    dateKey: day.dateKey,
                    provenances: day.provenances
                )
            }
        if !snapshotEntries.isEmpty {
            return snapshotEntries
        }
        syncMorningPlanState()
        return resolvedEntriesForActiveWindow(
            from: DateHelpers.startOfToday(in: timeZone),
            limit: limit,
            timeZone: timeZone
        )
    }

    func provenance(for date: Date, timeZone: TimeZone = .current) -> [ResolvedScheduledDateProvenance] {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let cached = activeWindowSnapshot.byDateKey[key] {
            return cached.provenances
        }
        syncMorningPlanState()
        return mergedProvenances(for: date, timeZone: timeZone)
    }

    func isExplicitSingleDaySource(on date: Date, timeZone: TimeZone = .current) -> Bool {
        alarmConfigStore.isExplicitSingleDaySource(on: date, timeZone: timeZone)
    }

    func activeDay(for date: Date, timeZone: TimeZone = .current) -> ActiveAlarmDay? {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let cached = activeWindowSnapshot.byDateKey[key] {
            return cached
        }
        return buildActiveDayIfNeeded(for: date, timeZone: timeZone)
    }

    func refreshedActiveDay(for date: Date, timeZone: TimeZone = .current) -> ActiveAlarmDay? {
        buildActiveDayIfNeeded(for: date, timeZone: timeZone, preferCached: false)
    }

    func duplicateStatus(for date: Date, timeZone: TimeZone = .current) -> DuplicateDateStatus {
        calendarPlanningProvider.duplicateStatus(
            for: date,
            timeZone: timeZone,
            dependencies: calendarPlanningDependencies()
        )
    }

    func tagPreviewResult(
        for date: Date,
        overrideSelection: FastIntentSelection? = nil,
        defaultPrimaryIntent: FastPrimaryIntent? = nil,
        timeZone: TimeZone = .current
    ) -> TagComputationResult {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if overrideSelection == nil,
           alarmConfigStore.provenance(for: date, timeZone: timeZone).isEmpty == false,
           let shawwalKey = shawwalMonthKey(for: date, timeZone: timeZone) {
            let results = monthTagResults(for: shawwalKey, timeZone: timeZone)
            if let monthResult = results[key] {
                return monthResult
            }
        }
        var seeds = activeWindowSnapshot.visibleDays.map(\.tagSeed)
        if defaultPrimaryIntent != nil, seeds.contains(where: { $0.dateKey == key }) == false {
            seeds.append(
                ActiveTagComputationSeed(
                    date: DateHelpers.startOfDay(date, in: timeZone),
                    dateKey: key,
                    defaultPrimaryIntent: defaultPrimaryIntent
                )
            )
        }
        return TagComputationEngine.result(
            for: date,
            seeds: seeds,
            selections: fastTagStore.selections,
            ruleset: .strict,
            timeZone: timeZone,
            overrideSelection: overrideSelection
        )
    }

    private func monthTagResults(for key: HijriMonthKey, timeZone: TimeZone) -> [String: TagComputationResult] {
        if let cached = tagResultMonthCache[key],
           cached.revision == fastTagStore.currentRevision {
            return cached.results
        }

        guard let month = HijriMonth(rawValue: key.month) else { return [:] }
        syncMorningPlanState()
        let resolvedEntries = resolvedEntriesForHijriMonth(
            HijriYearMonth(hijriYear: key.year, month: month),
            timeZone: timeZone
        )
        let seeds = resolvedEntries.map {
            ActiveTagComputationSeed(
                date: $0.date,
                dateKey: $0.dateKey,
                defaultPrimaryIntent: $0.provenances.defaultFastPrimaryIntent()
            )
        }
        let results = TagComputationEngine.results(
            seeds: seeds,
            selections: fastTagStore.selections,
            ruleset: .strict,
            timeZone: timeZone
        )
        tagResultMonthCache[key] = MonthTagCache(
            revision: fastTagStore.currentRevision,
            results: results
        )
        return results
    }

    private func applyShawwalTagResults(
        to days: [ActiveAlarmDay],
        timeZone: TimeZone
    ) -> [ActiveAlarmDay] {
        guard days.contains(where: { shawwalMonthKey(for: $0.date, timeZone: timeZone) != nil }) else {
            return days
        }

        var resultsByMonth: [HijriMonthKey: [String: TagComputationResult]] = [:]
        var updated: [ActiveAlarmDay] = []
        updated.reserveCapacity(days.count)
        var didChange = false

        for day in days {
            guard let monthKey = shawwalMonthKey(for: day.date, timeZone: timeZone) else {
                updated.append(day)
                continue
            }
            let results = resultsByMonth[monthKey] ?? monthTagResults(for: monthKey, timeZone: timeZone)
            resultsByMonth[monthKey] = results
            if let monthResult = results[day.dateKey], monthResult != day.tagResult {
                didChange = true
                updated.append(replacingTagResult(day, with: monthResult))
            } else {
                updated.append(day)
            }
        }

        return didChange ? updated : days
    }

    private func replacingTagResult(
        _ day: ActiveAlarmDay,
        with tagResult: TagComputationResult
    ) -> ActiveAlarmDay {
        guard let coordinate = currentCoordinate() else {
            return ActiveAlarmDay(
                date: day.date,
                dateKey: day.dateKey,
                schedule: day.schedule,
                effectiveConfig: day.effectiveConfig,
                provenances: day.provenances,
                isImplicitRamadan: day.isImplicitRamadan,
                isExplicitOneOff: day.isExplicitOneOff,
                tagResult: tagResult,
                primaryDisplay: day.primaryDisplay,
                sourceSummaryText: day.sourceSummaryText,
                resolvedDayContext: day.resolvedDayContext,
                scheduledEvents: day.scheduledEvents,
                decisionLog: day.decisionLog,
                dailyCompletion: day.dailyCompletion
            )
        }

        return resolveActiveDay(
            for: day.date,
            provenances: day.provenances,
            tagResult: tagResult,
            coordinate: coordinate,
            settings: settingsStore.settings,
            timeZone: .current
        ) ?? day
    }

    private func shawwalMonthKey(for date: Date, timeZone: TimeZone) -> HijriMonthKey? {
        guard let components = FastIntentEngine.adjustedComponents(for: date, timeZone: timeZone),
              components.month == .shawwal else {
            return nil
        }
        return FastIntentEngine.hijriMonthKey(for: date, timeZone: timeZone)
    }

    func previewIslamicQuickAdd(
        _ kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> IslamicQuickAddPreview? {
        quickAddPreviewProvider.previewIslamicQuickAdd(
            alarmConfigStore: alarmConfigStore,
            kind: kind,
            startDate: startDate,
            timeZone: timeZone
        )
    }

    func previewAshuraQuickAdd(
        _ pattern: AshuraQuickAddPattern,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> AshuraQuickAddPreview? {
        quickAddPreviewProvider.previewAshuraQuickAdd(
            alarmConfigStore: alarmConfigStore,
            pattern: pattern,
            startDate: startDate,
            timeZone: timeZone
        )
    }

    func previewGregorianRangeAdd(
        startDate: Date,
        endDate: Date,
        timeZone: TimeZone = .current
    ) -> AddScheduledDatesResult {
        quickAddPreviewProvider.previewGregorianRangeAdd(
            alarmConfigStore: alarmConfigStore,
            startDate: startDate,
            endDate: endDate,
            timeZone: timeZone
        )
    }

    func islamicQuickAddAvailability(
        _ kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> IslamicQuickAddAvailability {
        quickAddPreviewProvider.islamicQuickAddAvailability(
            alarmConfigStore: alarmConfigStore,
            kind: kind,
            startDate: startDate,
            timeZone: timeZone
        )
    }

    func recommendedAshuraQuickAddPattern(
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> AshuraQuickAddPattern {
        quickAddPreviewProvider.recommendedAshuraQuickAddPattern(
            alarmConfigStore: alarmConfigStore,
            startDate: startDate,
            timeZone: timeZone
        )
    }

    func ashuraQuickAddAvailability(
        _ pattern: AshuraQuickAddPattern,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> AshuraQuickAddAvailability {
        quickAddPreviewProvider.ashuraQuickAddAvailability(
            alarmConfigStore: alarmConfigStore,
            pattern: pattern,
            startDate: startDate,
            timeZone: timeZone
        )
    }

    func recurringRuleStatus(_ rule: RecurringIslamicRule) -> RecurringRuleStatus {
        let isAdded = alarmConfigStore.hasRecurringIslamicSource(rule)
        return RecurringRuleStatus(rule: rule, isAdded: isAdded, detailText: nil)
    }

    func calendarMonthContext(
        displayedMonth: Date,
        selectedDate: Date,
        allowedDateRange: ClosedRange<Date>,
        timeZone: TimeZone = .current
    ) -> CalendarMonthContext {
        calendarPlanningProvider.calendarMonthContext(
            displayedMonth: displayedMonth,
            selectedDate: selectedDate,
            allowedDateRange: allowedDateRange,
            timeZone: timeZone,
            dependencies: calendarPlanningDependencies()
        )
    }

    func calendarDayStates(
        dates: [Date],
        selectedDate: Date,
        allowedDateRange: ClosedRange<Date>,
        timeZone: TimeZone = .current
    ) -> [CalendarDayState] {
        calendarPlanningProvider.calendarDayStates(
            dates: dates,
            selectedDate: selectedDate,
            allowedDateRange: allowedDateRange,
            timeZone: timeZone,
            dependencies: calendarPlanningDependencies()
        )
    }

    func calendarDayDetail(
        for date: Date,
        overrideSelection: FastIntentSelection? = nil,
        timeZone: TimeZone = .current
    ) -> CalendarDayDetail {
        calendarPlanningProvider.calendarDayDetail(
            for: date,
            overrideSelection: overrideSelection,
            timeZone: timeZone,
            dependencies: calendarPlanningDependencies()
        )
    }

    @discardableResult
    func addSingleScheduledDate(
        _ date: Date,
        selection: FastIntentSelection? = nil
    ) async -> AddScheduledDatesResult {
        let normalizedDate = DateHelpers.startOfDay(date, in: .current)
        guard alarmConfigStore.provenance(for: normalizedDate, timeZone: .current).isEmpty else {
            return AddScheduledDatesResult(addedDates: [], skippedActiveDates: [normalizedDate])
        }

        alarmConfigStore.addSingleDaySource(normalizedDate)
        applyAddFlowSelection(
            selection ?? FastIntentEngine.defaultAddFlowSelection(for: normalizedDate, timeZone: .current),
            for: normalizedDate
        )
        await refreshSchedules(force: true)
        return AddScheduledDatesResult(addedDates: [normalizedDate], skippedActiveDates: [])
    }

    @discardableResult
    func planDates(
        _ dates: [Date],
        selection: FastIntentSelection,
        groupID: UUID?
    ) async -> AddScheduledDatesResult {
        guard !dates.isEmpty else { return .empty }

        let normalized = dates.map { DateHelpers.startOfDay($0, in: .current) }
        let provenanceByKey = alarmConfigStore.provenanceByDate(for: normalized, timeZone: .current)

        var addedDates: [Date] = []
        var skippedDates: [Date] = []
        var didChangeAnySelection = false
        for date in normalized {
            let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
            if (provenanceByKey[key] ?? []).isEmpty {
                alarmConfigStore.addSingleDaySource(date, origin: .manualSingleDay, groupID: groupID, timeZone: .current)
                addedDates.append(date)
            } else {
                skippedDates.append(date)
            }
            didChangeAnySelection = didChangeAnySelection || willChangeStoredSelection(selection, for: date)
            applyAddFlowSelection(selection, for: date)
        }

        if !addedDates.isEmpty {
            await refreshSchedules(force: true)
        } else if didChangeAnySelection {
            retagActiveWindow(reason: "plan_dates_tag_only_update")
        }

        return AddScheduledDatesResult(addedDates: addedDates, skippedActiveDates: skippedDates)
    }

    @discardableResult
    func addGregorianRange(
        startDate: Date,
        endDate: Date,
        purpose: RangePurposeSelection
    ) async -> AddScheduledDatesResult {
        let result = alarmConfigStore.addGregorianRangeSource(startDate: startDate, endDate: endDate)
        guard !result.addedDates.isEmpty else { return result }

        for date in result.addedDates {
            applyAddFlowSelection(purpose.selection(for: date, timeZone: .current), for: date)
        }
        await refreshSchedules(force: true)
        return result
    }

    @discardableResult
    func addIslamicQuickAdd(
        _ kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) async -> AddScheduledDatesResult {
        let result = alarmConfigStore.addIslamicQuickAdd(kind, startDate: startDate, timeZone: timeZone)
        guard !result.addedDates.isEmpty else { return result }

        for date in result.addedDates {
            applyAddFlowSelection(FastIntentEngine.defaultAddFlowSelection(for: date, timeZone: timeZone), for: date)
        }
        await refreshSchedules(force: true)
        return result
    }

    @discardableResult
    func addAshuraQuickAdd(
        _ pattern: AshuraQuickAddPattern,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) async -> AddScheduledDatesResult {
        let result = alarmConfigStore.addAshuraQuickAdd(pattern, startDate: startDate, timeZone: timeZone)
        guard !result.addedDates.isEmpty else { return result }

        for date in result.addedDates {
            applyAddFlowSelection(FastIntentEngine.defaultAddFlowSelection(for: date, timeZone: timeZone), for: date)
        }
        await refreshSchedules(force: true)
        return result
    }

    @discardableResult
    func addRecurringIslamicRule(
        _ rule: RecurringIslamicRule,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) async -> Bool {
        let added = alarmConfigStore.addRecurringIslamicSource(rule, startDate: startDate, timeZone: timeZone)
        guard added else { return false }
        await refreshSchedules(force: true)
        return true
    }

    func skipScheduledDate(
        _ date: Date,
        scope: SuppressionScope = .global
    ) async {
        alarmConfigStore.suppressScheduledDate(date, scope: scope)
        alarmConfigStore.removeOverride(for: date)
        await refreshSchedules(force: true)
    }

    func deleteDayAndSuppress(
        _ date: Date,
        scopes: [SuppressionScope],
        deleteExplicit: Bool
    ) async {
        if deleteExplicit {
            alarmConfigStore.deleteExplicitSources(on: date)
            alarmConfigStore.removeOverride(for: date)
        }
        for scope in scopes {
            alarmConfigStore.suppressScheduledDate(date, scope: scope)
        }
        await refreshSchedules(force: true)
    }

    func deleteExplicitScheduledDate(_ date: Date) async {
        alarmConfigStore.deleteExplicitSources(on: date)
        alarmConfigStore.removeOverride(for: date)
        await refreshSchedules(force: true)
    }

    func stopSeries(for provenance: ResolvedScheduledDateProvenance) async {
        alarmConfigStore.stopSeries(for: provenance)
        await refreshSchedules(force: true)
    }

    func deleteScheduledGroup(_ groupID: UUID) async {
        alarmConfigStore.deleteScheduledGroup(groupID)
        await refreshSchedules(force: true)
    }

    func requestRefresh(reason: ScheduleRefreshReason, force: Bool = true) {
        let request = PendingScheduleRefresh(reason: reason, force: force)
        queuedRefresh = queuedRefresh?.merged(with: request) ?? request
        guard refreshTask == nil else { return }
        scheduleQueuedRefresh()
    }

    private func applyAddFlowSelection(_ selection: FastIntentSelection?, for date: Date) {
        if let selection, selection.hasMeaningfulTags {
            fastTagStore.setSelection(selection, for: date, timeZone: .current)
        } else {
            fastTagStore.removeSelection(for: date, timeZone: .current)
        }
    }

    private func willChangeStoredSelection(_ selection: FastIntentSelection?, for date: Date) -> Bool {
        let existingSelection = fastTagStore.selection(for: date, timeZone: .current)
        let normalizedSelection = selection.map {
            FastIntentEngine.normalizedSelection($0, for: date, ruleset: .strict, timeZone: .current)
        }
        let storedSelection = normalizedSelection?.hasMeaningfulTags == true ? normalizedSelection : nil
        return existingSelection != storedSelection
    }

    private func summaryText(for provenances: [ResolvedScheduledDateProvenance]) -> String {
        let labels = provenances.map(\.label)
        return Array(NSOrderedSet(array: labels)).compactMap { $0 as? String }.joined(separator: " • ")
    }

    private func buildMorningStateSnapshot(
        settings: AppSettings,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        locationDescription: String,
        provenancesByDateKey: [String: [ResolvedScheduledDateProvenance]]
    ) -> MorningStateSnapshot {
        MorningStateAssembler.assemble(
            settings: settings,
            defaultConfig: alarmConfigStore.defaults,
            morningPlanStore: morningPlanStore,
            fastTagSelections: fastTagStore.selections,
            fastLogEntries: fastLogStore.entriesByDateKey,
            fajrLogEntries: fajrLogStore.entriesByDateKey,
            qadaBacklogState: qadaBacklogStore.state,
            qadaBatchState: qadaBatchStore.state,
            overridesByDateKey: alarmConfigStore.overridesByDay,
            coordinate: coordinate,
            timeZone: timeZone,
            locationDescription: locationDescription,
            provenancesByDateKey: provenancesByDateKey
        )
    }

    private func currentCompletionStateSnapshot() -> CompletionStateSnapshot {
        let legacySnapshot = LegacyCompletionAdapter.records(
            fajrEntries: fajrLogStore.entriesByDateKey,
            fastEntries: fastLogStore.entriesByDateKey,
            qadaBacklogState: qadaBacklogStore.state
        )
        return CompletionStateAssembler.assemble(
            completionRecords: legacySnapshot.records,
            qadaLedgerSnapshot: legacySnapshot.qadaLedgerSnapshot
        )
    }

    private func calendarPlanningDependencies() -> CalendarPlanningProvider.Dependencies {
        CalendarPlanningProvider.Dependencies(
            activeWindowSnapshot: activeWindowSnapshot,
            fastTagSelections: fastTagStore.selections,
            provenance: { [weak self] date, timeZone in
                self?.provenance(for: date, timeZone: timeZone) ?? []
            },
            activeDay: { [weak self] date, timeZone in
                self?.activeDay(for: date, timeZone: timeZone)
            },
            tagPreviewResult: { [weak self] date, overrideSelection, defaultPrimaryIntent, timeZone in
                self?.tagPreviewResult(
                    for: date,
                    overrideSelection: overrideSelection,
                    defaultPrimaryIntent: defaultPrimaryIntent,
                    timeZone: timeZone
                ) ?? .empty
            }
        )
    }

    private func resolvedDaySnapshotForHistory(
        for date: Date,
        timeZone: TimeZone = .current
    ) -> ResolvedDaySnapshot? {
        syncMorningPlanState()
        guard let coordinate = currentCoordinate() else { return nil }

        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
        let provenances = mergedProvenances(for: normalizedDate, timeZone: timeZone)
        let settings = settingsStore.settings
        let defaultPrimaryIntent = provenances.defaultFastPrimaryIntent()
        let tagResult: TagComputationResult

        if let shawwalKey = shawwalMonthKey(for: normalizedDate, timeZone: timeZone) {
            let results = monthTagResults(for: shawwalKey, timeZone: timeZone)
            tagResult = results[key] ?? tagPreviewResult(
                for: normalizedDate,
                defaultPrimaryIntent: defaultPrimaryIntent,
                timeZone: timeZone
            )
        } else {
            tagResult = tagPreviewResult(
                for: normalizedDate,
                defaultPrimaryIntent: defaultPrimaryIntent,
                timeZone: timeZone
            )
        }

        let effectiveConfig = ActiveWindowBuilder.effectiveConfig(
            for: normalizedDate,
            settings: settings,
            defaultConfig: alarmConfigStore.defaults,
            overridesByDay: alarmConfigStore.overridesByDay,
            timeZone: timeZone
        )
        let stateSnapshot = buildMorningStateSnapshot(
            settings: settings,
            coordinate: coordinate,
            timeZone: timeZone,
            locationDescription: "Based on your location",
            provenancesByDateKey: [key: provenances]
        )

        return ResolvedDayPipeline.resolve(
            date: normalizedDate,
            dateKey: key,
            provenances: provenances,
            effectiveConfig: effectiveConfig,
            tagResult: tagResult,
            stateSnapshot: stateSnapshot,
            calculator: calculator
        )
    }

    private func tagSummaryText(
        primaryIntent: FastPrimaryIntent,
        secondaryTags: Set<FastSecondaryVirtueTag>
    ) -> String {
        var parts: [String] = [primaryIntent.shortTitle]
        let secondary = secondaryTags.sorted { $0.title < $1.title }
        if !secondary.isEmpty {
            parts.append(secondary.map(\.shortTitle).joined(separator: ", "))
        }
        return parts.joined(separator: " • ")
    }

    private func reorderedWeekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let prefixIndex = max(0, calendar.firstWeekday - 1)
        return Array(symbols[prefixIndex...]) + Array(symbols[..<prefixIndex])
    }

    private func firstVisibleDate(in monthStart: Date, calendar: Calendar) -> Date {
        let weekday = calendar.component(.weekday, from: monthStart)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -offset, to: monthStart) ?? monthStart
    }

    func requestRescheduleDay(_ date: Date, debounce: TimeInterval = 0.18) {
        let normalizedDate = DateHelpers.startOfDay(date, in: .current)
        let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: .current)
        pendingDayRescheduleTasks[key]?.cancel()
        pendingDayRescheduleTasks[key] = Task { [weak self] in
            let token = PerformanceTrace.begin("schedule.reschedule-day", metadata: key)
            defer {
                Task { @MainActor [weak self] in
                    self?.pendingDayRescheduleTasks[key] = nil
                    PerformanceTrace.end(token)
                }
            }
            let delay = UInt64(max(0, debounce) * 1_000_000_000)
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.rescheduleDay(normalizedDate)
        }
    }

    func ensureScheduleWindow(reason: ScheduleRefreshReason) async {
        if FeatureFlags.enableCountdown {
            await countdownManager.reconcileIfNeeded()
        }
        let now = Date()
        if Self.shouldReuseScheduleWindow(
            reason: reason,
            lastScheduledDate: settingsStore.settings.lastScheduledDate,
            snapshot: activeWindowSnapshot,
            now: now,
            timeZone: .current
        ) {
            if activeTagSelectionRevision != fastTagStore.currentRevision {
                if !activeWindowSnapshot.visibleDays.isEmpty {
                    retagActiveWindow(reason: "tag_selection_revision_mismatch")
                    await refreshPermissionSummary()
                    return
                }
                await refreshSchedules(force: true)
                return
            }
            let adjustedVisibleDays = applyShawwalTagResults(to: activeWindowSnapshot.visibleDays, timeZone: .current)
            if adjustedVisibleDays != activeWindowSnapshot.visibleDays {
                activeWindowSnapshot = ActiveAlarmWindowSnapshot(
                    generatedAt: activeWindowSnapshot.generatedAt,
                    visibleDays: adjustedVisibleDays,
                    scheduledDays: Array(adjustedVisibleDays.prefix(activeWindowSnapshot.scheduledHorizonDays)),
                    visibleHorizonDays: activeWindowSnapshot.visibleHorizonDays,
                    scheduledHorizonDays: activeWindowSnapshot.scheduledHorizonDays
                )
                schedules = activeWindowSnapshot.visibleDays.map(\.schedule)
                activeTagSelectionRevision = fastTagStore.currentRevision
                cacheStore.save(
                    ScheduleCacheStore.Cache(
                        lastScheduledDate: settingsStore.settings.lastScheduledDate,
                        lastUpdated: lastUpdated,
                        schedulingMode: schedulingMode,
                        schedules: schedules,
                        activeWindowSnapshot: activeWindowSnapshot,
                        tagSelectionRevision: activeTagSelectionRevision
                    )
                )
            }
            await refreshPermissionSummary()
            return
        }
        await refreshSchedules(force: true)
    }

    func enableFromUserAction(markConfigured: Bool = true) async -> Bool {
        lastEnableFailureMessage = nil

        let locationState = await permissionState(for: .location)
        if requiresLocationAuthorization && locationState != .authorized {
            if locationState == .notDetermined {
                _ = await requestPermission(.location)
            }
            lastEnableFailureMessage = Strings.LocationAccess.autoExplanation
            return false
        }

        let alarmState = await permissionState(for: .alarmKit)
        if alarmState == .notDetermined {
            _ = await requestPermission(.alarmKit)
        }

        let mode = await effectiveSchedulingChannel()
        let requiresNotifications = mode != .alarmKit

        if requiresNotifications {
            let notificationState = await permissionState(for: .notifications)
            if notificationState == .notDetermined {
                _ = await requestPermission(.notifications)
            }
            if await permissionState(for: .notifications) != .authorized {
                lastEnableFailureMessage = Strings.NotificationAccess.deniedExplanation
                return false
            }
        }

        settingsStore.update { draft in
            if markConfigured {
                draft.isConfigured = true
            }
            draft.isEnabled = true
            draft.reminderEnabledGlobal = true
            draft.atFajrEnabledGlobal = true
        }
        alarmConfigStore.defaults.defaultSuhoorTimeMode = .relativeToFajrMinusMinutes
        alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = settingsStore.settings.baseWakeOffsetMinutes
        alarmConfigStore.defaults.defaultReminderTimeMode = .beforeFajr
        alarmConfigStore.defaults.defaultReminderMinutesBeforeFajr = settingsStore.settings.reminderMinutesBeforeFajrGlobal
        alarmConfigStore.defaults.suhoorEnabledDefault = true
        alarmConfigStore.defaults.reminderEnabledDefault = true
        alarmConfigStore.defaults.fajrEnabledDefault = true

        await refreshSchedules(force: true)
        return true
    }

    func disableFromUserAction() async {
        lastEnableFailureMessage = nil
        settingsStore.update { draft in
            draft.isEnabled = false
            draft.reminderEnabledGlobal = false
            draft.atFajrEnabledGlobal = false
        }
        alarmConfigStore.defaults.suhoorEnabledDefault = false
        alarmConfigStore.defaults.reminderEnabledDefault = false
        alarmConfigStore.defaults.fajrEnabledDefault = false
        await refreshSchedules(force: true)
    }

    func refreshSchedules(force: Bool) async {
        let token = PerformanceTrace.begin("schedule.refresh", metadata: "force=\(force)")
        defer { PerformanceTrace.end(token) }
        invalidateExpandedMonthSnapshots(reason: "schedule_refresh")
        let settings = settingsStore.settings
        EventTimelineLog.shared.record(category: "schedule", message: "refreshSchedules(force=\(force))")
        let timeZone = TimeZone.current
        resetPastHijriAdjustmentsIfNeeded(timeZone: timeZone)

        let coordinate: ScheduleLocationSnapshot
        switch settings.locationMode {
        case .auto:
            guard isLocationAuthorized else {
                statusText = "Location permission required."
                schedulingMode = .none
                await refreshPermissionSummary()
                return
            }
            guard let autoCoord = locationService.lastLocation?.coordinate else {
                locationService.requestLocation()
                // Keep the last rendered rows while we wait for a fresh location fix.
                statusText = "Locating…"
                schedulingMode = .none
                await refreshPermissionSummary()
                return
            }
            coordinate = ScheduleLocationSnapshot(latitude: autoCoord.latitude, longitude: autoCoord.longitude)
        case .fixed:
            guard let fixed = settings.fixedLocation else {
                statusText = "Fixed location required."
                schedulingMode = .none
                await refreshPermissionSummary()
                return
            }
            coordinate = ScheduleLocationSnapshot(latitude: fixed.latitude, longitude: fixed.longitude)
        }

        let startDate = DateHelpers.startOfToday(in: timeZone)
        let mode = await effectiveSchedulingChannel()
        syncMorningPlanState()
        let resolvedEntries = PerformanceTrace.measure("active-window.resolve", metadata: "limit=\(visibleActiveDayLimit)") {
            resolvedEntriesForActiveWindow(
                from: startDate,
                limit: visibleActiveDayLimit,
                timeZone: timeZone
            )
        }
        let provenancesByDateKey = Dictionary(uniqueKeysWithValues: resolvedEntries.map { ($0.dateKey, $0.provenances) })
        let stateSnapshot = buildMorningStateSnapshot(
            settings: settings,
            coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
            timeZone: timeZone,
            locationDescription: "Based on your location",
            provenancesByDateKey: provenancesByDateKey
        )
        let input = ActiveWindowBuildInput(
            stateSnapshot: stateSnapshot,
            resolvedEntries: resolvedEntries,
            visibleHorizonDays: visibleActiveDayLimit,
            scheduledHorizonDays: scheduledActiveDayLimit
        )
        let result = await PerformanceTrace.measureAsync(
            "schedule.compute-window",
            metadata: "days=\(input.resolvedEntries.count)"
        ) {
            await Task.detached(priority: .userInitiated) {
                ActiveWindowBuilder.build(input: input)
            }.value
        }
        let adjustedVisibleDays = applyShawwalTagResults(to: result.visibleDays, timeZone: timeZone)
        let adjustedSnapshot: ActiveAlarmWindowSnapshot
        if adjustedVisibleDays != result.visibleDays {
            adjustedSnapshot = ActiveAlarmWindowSnapshot(
                generatedAt: result.generatedAt,
                visibleDays: adjustedVisibleDays,
                scheduledDays: Array(adjustedVisibleDays.prefix(scheduledActiveDayLimit)),
                visibleHorizonDays: result.visibleHorizonDays,
                scheduledHorizonDays: result.scheduledHorizonDays
            )
        } else {
            adjustedSnapshot = result
        }
        debugValidateActiveWindow(adjustedSnapshot, resolvedEntries: resolvedEntries)

        activeWindowSnapshot = adjustedSnapshot
        schedules = adjustedSnapshot.visibleDays.map(\.schedule)
        lastUpdated = Date()
        Logging.diagnostics.debug("[perf] active-window.visible-count \(result.visibleDays.count, privacy: .public)")
        Logging.diagnostics.debug("[perf] active-window.scheduled-count \(result.scheduledDays.count, privacy: .public)")

        let reconciliation = await SchedulingReconciler.reconcile(
            snapshot: adjustedSnapshot,
            settings: settings,
            requestedMode: mode,
            alarmScheduler: alarmScheduler,
            cancelAll: { [weak self] in
                await self?.cancelAll()
            },
            blockedMessage: { [weak self] in
                await self?.schedulingBlockedMessage() ?? "Unable to schedule"
            }
        )
        schedulingMode = reconciliation.schedulingMode
        statusText = reconciliation.statusText

        settingsStore.update { draft in
            draft.lastScheduledDate = Date()
            draft.lastSchedulingMode = schedulingMode
        }

        activeTagSelectionRevision = fastTagStore.currentRevision
        cacheStore.save(
            ScheduleCacheStore.Cache(
                lastScheduledDate: settingsStore.settings.lastScheduledDate,
                lastUpdated: lastUpdated,
                schedulingMode: schedulingMode,
                schedules: schedules,
                activeWindowSnapshot: activeWindowSnapshot,
                tagSelectionRevision: activeTagSelectionRevision
            )
        )

        await refreshPermissionSummary()
    }

    func rescheduleDay(_ date: Date) async {
        let timeZone = TimeZone.current
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)

        syncMorningPlanState()

        guard dateParticipatesInWakePlan(normalizedDate, timeZone: timeZone) else {
            await cancelDay(normalizedDate)
            activeWindowSnapshot = activeWindowSnapshot.removing(dateKey: key)
            schedules = activeWindowSnapshot.visibleDays.map(\.schedule)
            lastUpdated = Date()
            activeTagSelectionRevision = fastTagStore.currentRevision
            cacheStore.save(
                ScheduleCacheStore.Cache(
                    lastScheduledDate: settingsStore.settings.lastScheduledDate,
                    lastUpdated: lastUpdated,
                    schedulingMode: schedulingMode,
                    schedules: schedules,
                    activeWindowSnapshot: activeWindowSnapshot,
                    tagSelectionRevision: activeTagSelectionRevision
                )
            )
            updateBootstrapState()
            return
        }

        guard let updatedDay = buildActiveDayIfNeeded(for: normalizedDate, timeZone: timeZone) else {
            await refreshSchedules(force: true)
            return
        }

        if activeWindowSnapshot.byDateKey[key] == nil {
            await refreshSchedules(force: true)
            return
        }

        activeWindowSnapshot = activeWindowSnapshot.replacing(updatedDay)
        schedules = activeWindowSnapshot.visibleDays.map(\.schedule)

        let settings = settingsStore.settings
        let canUseAlarmKit = await alarmKitAvailableAndAuthorized()
        if activeWindowSnapshot.scheduledDays.contains(where: { $0.dateKey == key }) {
            Logging.diagnostics.debug(
                "[toggle] scheduleDay \(key, privacy: .public) suhoor=\(updatedDay.effectiveConfig.suhoorEnabled, privacy: .public) reminder=\(updatedDay.effectiveConfig.reminderEnabled, privacy: .public) fajr=\(updatedDay.effectiveConfig.fajrEnabled, privacy: .public)"
            )
            _ = await alarmScheduler.scheduleDay(
                schedule: updatedDay.schedule,
                config: updatedDay.effectiveConfig,
                settings: settings,
                canUseAlarmKit: canUseAlarmKit
            )
        } else {
            Logging.diagnostics.debug("[toggle] cancelDay \(key, privacy: .public) via schedule window")
            await alarmScheduler.cancelDay(schedule: updatedDay.schedule)
        }

        lastUpdated = Date()
        activeTagSelectionRevision = fastTagStore.currentRevision
        cacheStore.save(
            ScheduleCacheStore.Cache(
                lastScheduledDate: settingsStore.settings.lastScheduledDate,
                lastUpdated: lastUpdated,
                schedulingMode: schedulingMode,
                schedules: schedules,
                activeWindowSnapshot: activeWindowSnapshot,
                tagSelectionRevision: activeTagSelectionRevision
            )
        )
        updateBootstrapState()
    }

    func schedule(for date: Date) -> DaySchedule? {
        scheduleAndConfig(for: date)?.schedule
    }

    func scheduleTomorrowActivation() async -> ActivationScheduleResult {
        let timeZone = TimeZone.current
        let tomorrow = DateHelpers.startOfTomorrow(in: timeZone)
        guard let result = scheduleAndConfig(for: tomorrow) else {
            return ActivationScheduleResult(
                success: false,
                message: "Wake preview unavailable. Check location.",
                schedule: nil
            )
        }

        let alarmState = await permissionState(for: .alarmKit)
        let notificationState = await permissionState(for: .notifications)

        let canUseAlarmKit = alarmState == .authorized
        let canUseNotifications = notificationState == .authorized

        if canUseAlarmKit == false && alarmState != .unavailable {
            return ActivationScheduleResult(
                success: false,
                message: Strings.AlarmAccess.deniedExplanation,
                schedule: result.schedule
            )
        }

        if canUseAlarmKit == false && canUseNotifications == false {
            return ActivationScheduleResult(
                success: false,
                message: Strings.NotificationAccess.deniedExplanation,
                schedule: result.schedule
            )
        }

        let scheduled = await alarmScheduler.scheduleDay(
            schedule: result.schedule,
            config: result.config,
            settings: settingsStore.settings,
            canUseAlarmKit: canUseAlarmKit
        )

        return ActivationScheduleResult(
            success: scheduled,
            message: scheduled ? "Scheduled" : "Unable to schedule",
            schedule: result.schedule
        )
    }

    func cancelDay(_ date: Date) async {
        guard let schedule = scheduleForCancellation(on: date) else { return }
        let key = DateHelpers.dayIdentifier(for: schedule.date, timeZone: .current)
        Logging.diagnostics.debug("[toggle] cancelDay \(key, privacy: .public) via cancelDay()")
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

    func permissionState(for kind: AppPermissionKind) async -> AppPermissionState {
        switch kind {
        case .location:
            return requiresLocationAuthorization ? locationService.appPermissionState : .authorized
        case .alarmKit:
            #if targetEnvironment(simulator)
            return .unavailable
            #else
            if #available(iOS 26.0, *), let alarmKitScheduler {
                return alarmKitScheduler.appPermissionState
            }
            return .unavailable
            #endif
        case .notifications:
            return await notificationScheduler.appPermissionState()
        }
    }

    func permissionPresentation(for kind: AppPermissionKind) async -> PermissionPresentation {
        if let cached = permissionSnapshot.presentations[kind] {
            return cached
        }
        return await uncachedPermissionPresentation(for: kind)
    }

    private func uncachedPermissionPresentation(for kind: AppPermissionKind) async -> PermissionPresentation {
        let state = await permissionState(for: kind)
        let isBlocking = await shouldBlockOnboarding(on: kind)

        switch kind {
        case .location:
            return PermissionPresentation(
                kind: kind,
                state: state,
                title: Strings.LocationAccess.title,
                statusText: statusLabel(for: state),
                message: locationMessage(for: state),
                actionTitle: actionTitle(for: kind, state: state),
                secondaryActionTitle: nil,
                showsProgress: state == .needsFollowUp,
                showsSimulatorHint: state == .needsFollowUp && locationService.shouldShowSimulatorHint,
                isBlocking: isBlocking
            )
        case .alarmKit:
            return PermissionPresentation(
                kind: kind,
                state: state,
                title: Strings.AlarmAccess.title,
                statusText: statusLabel(for: state),
                message: alarmMessage(for: state),
                actionTitle: actionTitle(for: kind, state: state),
                secondaryActionTitle: nil,
                showsProgress: false,
                showsSimulatorHint: false,
                isBlocking: isBlocking
            )
        case .notifications:
            return PermissionPresentation(
                kind: kind,
                state: state,
                title: Strings.NotificationAccess.title,
                statusText: statusLabel(for: state),
                message: notificationMessage(for: state),
                actionTitle: actionTitle(for: kind, state: state),
                secondaryActionTitle: nil,
                showsProgress: false,
                showsSimulatorHint: false,
                isBlocking: isBlocking
            )
        }
    }

    func requestPermission(_ kind: AppPermissionKind) async -> Bool {
        let granted: Bool
        switch kind {
        case .location:
            locationService.requestAuthorization()
            granted = true
        case .alarmKit:
            granted = await requestAlarmAuthorization()
        case .notifications:
            granted = await requestNotificationAuthorization()
        }
        await refreshPermissionSummary()
        return granted
    }

    func shouldBlockOnboarding(on kind: AppPermissionKind) async -> Bool {
        let state = await permissionState(for: kind)
        switch kind {
        case .location:
            return requiresLocationAuthorization && state != .authorized
        case .alarmKit:
            return state == .notDetermined
        case .notifications:
            return state != .authorized
        }
    }

    func requiredOnboardingPermissions() async -> [AppPermissionKind] {
        [.location, .alarmKit, .notifications]
    }

    func effectiveSchedulingChannel() async -> SchedulingMode {
        if await permissionState(for: .alarmKit) == .authorized {
            return .alarmKit
        }
        if await permissionState(for: .notifications) == .authorized {
            return .notifications
        }
        return .none
    }

    func refreshPermissionSummary() async {
        let snapshot = await buildPermissionSnapshot()
        permissionSnapshot = snapshot
        permissionSummary = snapshot.summaryText
        alarmAuthorizationText = snapshot.alarmAuthorizationText
        notificationAuthorizationText = snapshot.notificationAuthorizationText
        updateBootstrapState()
        EventTimelineLog.shared.record(category: "permissions", message: "Permission summary: \(snapshot.summaryText)")
    }

    var canRequestAlarmKitAuthorization: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if #available(iOS 26.0, *), let alarmKitScheduler {
            return alarmKitScheduler.isRequestable
        }
        return false
        #endif
    }

    func notificationAuthorizationStatus() async -> UNAuthorizationStatus {
        await notificationScheduler.authorizationStatus()
    }

    func resetAll() async {
        refreshTask?.cancel()
        refreshTask = nil
        queuedRefresh = nil
        pendingDayRescheduleTasks.values.forEach { $0.cancel() }
        pendingDayRescheduleTasks.removeAll()
        await cancelAll()
        schedules = []
        schedulingMode = .none
        lastUpdated = nil
        permissionSummary = ""
        permissionSnapshot = .empty
        activeWindowSnapshot = .empty
        updateBootstrapState()
        cacheStore.clear()
        alarmConfigStore.resetScheduledDateSources()
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
        syncMorningPlanState()
        let settings = settingsStore.settings
        let timeZone = TimeZone.current
        let now = Date()
        let canUseAlarmKit = await alarmKitAvailableAndAuthorized()

        let snapshot = await schedulingAuditProvider.makeSchedulingAudit(
            dependencies: .init(
                settings: settings,
                coordinate: currentCoordinate(),
                canUseAlarmKit: canUseAlarmKit,
                now: now,
                timeZone: timeZone,
                dayLabel: { date in
                    self.dayLabel(for: date)
                },
                dateParticipatesInWakePlan: { date, timeZone in
                    self.dateParticipatesInWakePlan(date, timeZone: timeZone)
                },
                effectiveConfig: { date, timeZone in
                    let ruleEngine = RuleEngine(
                        settings: settings,
                        defaultConfig: self.alarmConfigStore.defaults,
                        overridesByDay: self.alarmConfigStore.overridesByDay,
                        timeZone: timeZone
                    )
                    return self.alarmConfigStore.effectiveConfig(
                        for: date,
                        ruleSummary: ruleEngine.ruleSummary(for: date),
                        settings: settings,
                        timeZone: timeZone
                    )
                },
                buildSchedule: { date, coordinate, timeZone, method, adjustmentMinutes, maghribAdjustmentMinutes, effectiveConfig, locationDescription in
                    self.buildSchedule(
                        for: date,
                        coordinate: coordinate,
                        timeZone: timeZone,
                        method: method,
                        adjustmentMinutes: adjustmentMinutes,
                        maghribAdjustmentMinutes: maghribAdjustmentMinutes,
                        effectiveConfig: effectiveConfig,
                        locationDescription: locationDescription
                    )
                },
                pendingRequests: { [notificationScheduler] in
                    await notificationScheduler.pendingRequests()
                },
                alarmKitItems: { [alarmKitScheduler] in
                    if #available(iOS 26.0, *), let alarmKitScheduler {
                        return alarmKitScheduler.fetchScheduledAlarms()
                    }
                    return []
                },
                buildAuditMismatches: { expectedEvents, notificationItems, alarmKitItems in
                    self.buildAuditMismatches(
                        expectedEvents: expectedEvents,
                        notificationItems: notificationItems,
                        alarmKitItems: alarmKitItems
                    )
                }
            )
        )

        Logging.scheduler.info("Scheduling audit: expected=\(snapshot.expectedEvents.count) notifications=\(snapshot.notificationItems.count) alarms=\(snapshot.alarmKitItems.count) mismatches=\(snapshot.mismatches.count)")
        EventTimelineLog.shared.record(category: "audit", message: "Audit expected=\(snapshot.expectedEvents.count) notifications=\(snapshot.notificationItems.count) alarms=\(snapshot.alarmKitItems.count) mismatches=\(snapshot.mismatches.count)")
        return snapshot
    }

    private var isLocationAuthorized: Bool {
        locationService.authorizationStatus == .authorizedAlways || locationService.authorizationStatus == .authorizedWhenInUse
    }

    private var requiresLocationAuthorization: Bool {
        settingsStore.settings.locationMode == .auto
    }

    private var hasAnyEnabledAlarms: Bool {
        alarmConfigStore.hasAnyEnabledDefaults || alarmConfigStore.hasAnyEnabledOverride()
    }

    private func resetPastHijriAdjustmentsIfNeeded(timeZone: TimeZone) {
        let today = DateHelpers.startOfToday(in: timeZone)
        let currentComponents = adjustedHijriCalendar.adjustedComponents(for: today, timeZone: timeZone) ?? {
            var fallbackCalendar = Calendar(identifier: .islamicUmmAlQura)
            fallbackCalendar.timeZone = timeZone
            let fallback = fallbackCalendar.dateComponents([.year, .month], from: today)
            guard
                let year = fallback.year,
                let monthValue = fallback.month,
                let month = HijriMonth(rawValue: monthValue)
            else {
                return nil
            }
            return AdjustedHijriDateComponents(
                hijriYear: year,
                month: month,
                day: 1,
                monthTitle: month.displayName,
                isDerivedFromBaseline: false
            )
        }()
        guard let currentComponents else { return }

        let currentYear = currentComponents.hijriYear
        let currentMonthValue = currentComponents.month.rawValue

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        if currentMonthValue > 1 {
            for monthValue in 1..<currentMonthValue {
                guard let month = HijriMonth(rawValue: monthValue) else { continue }
                guard let nextMonth = HijriMonth(rawValue: monthValue + 1) else { continue }
                let nextKey = HijriYearMonth(hijriYear: currentYear, month: nextMonth)
                guard let nextStart = adjustedHijriCalendar.gregorianDate(for: nextKey, dayOfMonth: 1, timeZone: timeZone) else {
                    continue
                }
                if calendar.startOfDay(for: today) >= calendar.startOfDay(for: nextStart) {
                    let key = HijriYearMonth(hijriYear: currentYear, month: month)
                    if hijriAdjustmentStore.readAdjustment(for: key) != 0 {
                        hijriAdjustmentStore.resetAdjustment(for: key)
                    }
                }
            }
        }

        let previousYear = currentYear - 1
        for month in HijriMonth.allCases {
            let key = HijriYearMonth(hijriYear: previousYear, month: month)
            if hijriAdjustmentStore.readAdjustment(for: key) != 0 {
                hijriAdjustmentStore.resetAdjustment(for: key)
            }
        }
    }

    private func resolveHijriSourceDates(
        _ sources: [ScheduledDateSource],
        timeZone: TimeZone
    ) -> [UUID: Date] {
        var results: [UUID: Date] = [:]
        for source in sources {
            guard case .hijriSingleDay(let hijri) = source.kind else { continue }
            let key = HijriYearMonth(hijriYear: hijri.hijriYear, month: hijri.month)
            guard let resolved = adjustedHijriCalendar.gregorianDate(for: key, dayOfMonth: hijri.day, timeZone: timeZone) else {
                continue
            }
            results[source.id] = resolved
        }
        return results
    }

    private func applyHijriAdjustmentShifts(
        sources: [ScheduledDateSource],
        oldResolved: [UUID: Date],
        newResolved: [UUID: Date],
        timeZone: TimeZone
    ) -> [HijriAdjustmentChange] {
        var changes: [HijriAdjustmentChange] = []

        for source in sources {
            guard case .hijriSingleDay(let hijri) = source.kind else { continue }
            guard let oldDate = oldResolved[source.id], let newDate = newResolved[source.id] else { continue }
            let oldKey = DateHelpers.dayIdentifier(for: oldDate, timeZone: timeZone)
            let newKey = DateHelpers.dayIdentifier(for: newDate, timeZone: timeZone)
            guard oldKey != newKey else { continue }

            if alarmConfigStore.isDeletedDate(on: oldDate, timeZone: timeZone) {
                alarmConfigStore.moveSuppression(from: oldDate, to: newDate, timeZone: timeZone)
            }

            if let oldOverride = alarmConfigStore.override(for: oldDate, timeZone: timeZone) {
                let merged = mergedOverride(
                    existing: alarmConfigStore.override(for: newDate, timeZone: timeZone),
                    incoming: oldOverride,
                    newDate: newDate,
                    timeZone: timeZone
                )
                alarmConfigStore.updateOverride(for: newDate, timeZone: timeZone) { override in
                    override.skipDay = merged.skipDay
                    override.suhoorEnabled = merged.suhoorEnabled
                    override.reminderEnabled = merged.reminderEnabled
                    override.fajrEnabled = merged.fajrEnabled
                    override.suhoorOffsetOverrideMinutes = merged.suhoorOffsetOverrideMinutes
                    override.reminderOffsetOverrideMinutes = merged.reminderOffsetOverrideMinutes
                    override.suhoorTimeOverrideMinutesFromMidnight = merged.suhoorTimeOverrideMinutesFromMidnight
                    override.reminderTimeOverrideMinutesFromMidnight = merged.reminderTimeOverrideMinutesFromMidnight
                    override.fajrSoundOverride = merged.fajrSoundOverride
                    override.notes = merged.notes
                }
                alarmConfigStore.removeOverride(for: oldDate, timeZone: timeZone)
            }

            if let oldSelection = fastTagStore.selection(for: oldDate, timeZone: timeZone) {
                if fastTagStore.selection(for: newDate, timeZone: timeZone) == nil {
                    fastTagStore.setSelection(oldSelection, for: newDate, timeZone: timeZone)
                }
                fastTagStore.removeSelection(for: oldDate, timeZone: timeZone)
            }

            changes.append(
                HijriAdjustmentChange(
                    id: UUID(),
                    hijriYear: hijri.hijriYear,
                    month: hijri.month,
                    day: hijri.day,
                    oldDateKey: oldKey,
                    newDateKey: newKey,
                    sourceLabel: source.origin.label,
                    timestamp: Date()
                )
            )
        }

        return changes
    }

    private func mergedOverride(
        existing: DailyAlarmOverride?,
        incoming: DailyAlarmOverride,
        newDate: Date,
        timeZone: TimeZone
    ) -> DailyAlarmOverride {
        var merged = existing ?? DailyAlarmOverride(date: newDate, timeZone: timeZone)
        merged.skipDay = merged.skipDay || incoming.skipDay

        if merged.suhoorEnabled == nil { merged.suhoorEnabled = incoming.suhoorEnabled }
        if merged.reminderEnabled == nil { merged.reminderEnabled = incoming.reminderEnabled }
        if merged.fajrEnabled == nil { merged.fajrEnabled = incoming.fajrEnabled }
        if merged.suhoorOffsetOverrideMinutes == nil { merged.suhoorOffsetOverrideMinutes = incoming.suhoorOffsetOverrideMinutes }
        if merged.reminderOffsetOverrideMinutes == nil { merged.reminderOffsetOverrideMinutes = incoming.reminderOffsetOverrideMinutes }
        if merged.suhoorTimeOverrideMinutesFromMidnight == nil {
            merged.suhoorTimeOverrideMinutesFromMidnight = incoming.suhoorTimeOverrideMinutesFromMidnight
        }
        if merged.reminderTimeOverrideMinutesFromMidnight == nil {
            merged.reminderTimeOverrideMinutesFromMidnight = incoming.reminderTimeOverrideMinutesFromMidnight
        }
        if merged.fajrSoundOverride == nil { merged.fajrSoundOverride = incoming.fajrSoundOverride }
        if (merged.notes == nil || merged.notes?.isEmpty == true) {
            merged.notes = incoming.notes
        }

        return merged
    }

    private func resolvedCurrentHijriYear(timeZone: TimeZone = .current) -> Int {
        var fallbackCalendar = Calendar(identifier: .islamicUmmAlQura)
        fallbackCalendar.timeZone = timeZone
        return adjustedHijriCalendar.adjustedComponents(for: Date(), timeZone: timeZone)?.hijriYear
            ?? fallbackCalendar.component(.year, from: Date())
    }

    private func currentCoordinate() -> CLLocationCoordinate2D? {
        switch settingsStore.settings.locationMode {
        case .auto:
            guard isLocationAuthorized else { return nil }
            return locationService.lastLocation?.coordinate
        case .fixed:
            guard let fixed = settingsStore.settings.fixedLocation else { return nil }
            return CLLocationCoordinate2D(latitude: fixed.latitude, longitude: fixed.longitude)
        }
    }

    private func syncMorningPlanState() {
        morningPlanStore.syncFromLegacy(
            legacySettings: settingsStore.settings,
            defaultConfig: alarmConfigStore.defaults
        )
    }

    private func dateParticipatesInWakePlan(
        _ date: Date,
        timeZone: TimeZone = .current
    ) -> Bool {
        morningPlanStore.usesDailyActivation || alarmConfigStore.isDefaultsActive(on: date, timeZone: timeZone)
    }

    private func defaultDailyPlanProvenance() -> ResolvedScheduledDateProvenance {
        let sourceID = DateHelpers.stableUUID(from: "suhoor.defaultDailyPlan")
        return ResolvedScheduledDateProvenance(
            sourceID: sourceID,
            groupID: nil,
            label: ScheduledDateSourceOrigin.defaultDailyPlan.label,
            stopSeriesLabel: ScheduledDateSourceOrigin.defaultDailyPlan.stopSeriesLabel,
            isExplicitOneOff: ScheduledDateSourceOrigin.defaultDailyPlan.isExplicitOneOff,
            sourceOrigin: .defaultDailyPlan
        )
    }

    private func mergedProvenances(
        for date: Date,
        timeZone: TimeZone = .current
    ) -> [ResolvedScheduledDateProvenance] {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        let legacy = alarmConfigStore.provenance(for: normalizedDate, timeZone: timeZone)
        guard morningPlanStore.usesDailyActivation else { return legacy }
        return [defaultDailyPlanProvenance()] + legacy.filter { $0.sourceOrigin != .defaultDailyPlan }
    }

    private func resolvedEntriesForActiveWindow(
        from startDate: Date,
        limit: Int,
        timeZone: TimeZone
    ) -> [ResolvedScheduledDateEntry] {
        if morningPlanStore.usesDailyActivation {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let normalizedStart = calendar.startOfDay(for: startDate)
            return DateHelpers.dates(startingFrom: normalizedStart, count: limit, calendar: calendar).map { date in
                ResolvedScheduledDateEntry(
                    date: date,
                    dateKey: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
                    provenances: mergedProvenances(for: date, timeZone: timeZone)
                )
            }
        }

        return alarmConfigStore.resolvedScheduledEntries(
            from: startDate,
            limit: limit,
            timeZone: timeZone
        )
    }

    private func resolvedEntriesForHijriMonth(
        _ key: HijriYearMonth,
        timeZone: TimeZone
    ) -> [ResolvedScheduledDateEntry] {
        guard morningPlanStore.usesDailyActivation else {
            return alarmConfigStore.resolvedScheduledEntries(forHijriMonth: key, timeZone: timeZone)
        }

        guard
            let start = adjustedHijriCalendar.gregorianDate(for: key, dayOfMonth: 1, timeZone: timeZone)
        else {
            return []
        }

        let nextMonthValue = key.month.rawValue == 12 ? 1 : key.month.rawValue + 1
        let nextYear = key.month.rawValue == 12 ? key.hijriYear + 1 : key.hijriYear
        guard
            let nextMonth = HijriMonth(rawValue: nextMonthValue),
            let endExclusive = adjustedHijriCalendar.gregorianDate(
                for: HijriYearMonth(hijriYear: nextYear, month: nextMonth),
                dayOfMonth: 1,
                timeZone: timeZone
            )
        else {
            return []
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return DateHelpers.dates(from: start, to: calendar.date(byAdding: .day, value: -1, to: endExclusive) ?? start, calendar: calendar).map { date in
            ResolvedScheduledDateEntry(
                date: date,
                dateKey: DateHelpers.dayIdentifier(for: date, timeZone: timeZone),
                provenances: mergedProvenances(for: date, timeZone: timeZone)
            )
        }
    }

    private func resolveActiveDay(
        for date: Date,
        provenances: [ResolvedScheduledDateProvenance],
        tagResult: TagComputationResult,
        coordinate: CLLocationCoordinate2D,
        settings: AppSettings,
        timeZone: TimeZone
    ) -> ActiveAlarmDay? {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
        let effectiveConfig = ActiveWindowBuilder.effectiveConfig(
            for: normalizedDate,
            settings: settings,
            defaultConfig: alarmConfigStore.defaults,
            overridesByDay: alarmConfigStore.overridesByDay,
            timeZone: timeZone
        )
        let stateSnapshot = buildMorningStateSnapshot(
            settings: settings,
            coordinate: coordinate,
            timeZone: timeZone,
            locationDescription: "Based on your location",
            provenancesByDateKey: [key: provenances]
        )
        guard let resolution = ResolvedDayPipeline.resolve(
            date: normalizedDate,
            dateKey: key,
            provenances: provenances,
            effectiveConfig: effectiveConfig,
            tagResult: tagResult,
            stateSnapshot: stateSnapshot,
            calculator: calculator
        ) else {
            return nil
        }

        return LegacyResolvedDayAdapter.makeActiveAlarmDay(
            snapshot: resolution,
            effectiveConfig: effectiveConfig,
            provenances: provenances,
            isImplicitRamadan: provenances.contains(where: { $0.sourceOrigin == .defaultRamadan }),
            isExplicitOneOff: !provenances.isEmpty && provenances.allSatisfy(\.isExplicitOneOff),
            tagResult: tagResult,
            sourceSummaryText: ActiveWindowBuilder.sourceSummary(from: provenances),
            settings: settings,
            locationDescription: stateSnapshot.locationDescription,
            timeZone: timeZone
        )
    }

    private func scheduleAndConfig(for date: Date) -> (schedule: DaySchedule, config: EffectiveDailyConfig)? {
        guard let coordinate = currentCoordinate() else { return nil }

        let settings = settingsStore.settings
        let timeZone = TimeZone.current
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        guard dateParticipatesInWakePlan(normalizedDate, timeZone: timeZone) else { return nil }
        let provenances = mergedProvenances(for: normalizedDate, timeZone: timeZone)
        let tagResult = tagPreviewResult(
            for: normalizedDate,
            defaultPrimaryIntent: provenances.defaultFastPrimaryIntent(),
            timeZone: timeZone
        )
        guard let activeDay = resolveActiveDay(
            for: normalizedDate,
            provenances: provenances,
            tagResult: tagResult,
            coordinate: coordinate,
            settings: settings,
            timeZone: timeZone
        ) else {
            return nil
        }

        return (schedule: activeDay.schedule, config: activeDay.effectiveConfig)
    }

    private func scheduleQueuedRefresh() {
        guard let request = queuedRefresh else { return }
        queuedRefresh = nil
        refreshTask = Task { [weak self] in
            guard let self else { return }
            let delay = request.reason.debounceDurationNanoseconds
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else {
                await MainActor.run {
                    self.refreshTask = nil
                    if self.queuedRefresh != nil {
                        self.scheduleQueuedRefresh()
                    }
                }
                return
            }
            await self.ensureScheduleWindow(reason: request.reason)
            await MainActor.run {
                self.refreshTask = nil
                if self.queuedRefresh != nil {
                    self.scheduleQueuedRefresh()
                }
            }
        }
    }

    private func statusLabel(for state: AppPermissionState) -> String {
        switch state {
        case .notDetermined:
            return "Not Set"
        case .authorized:
            return "Ready"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .unavailable:
            return "Unavailable"
        case .needsFollowUp:
            return "Waiting"
        }
    }

    private func actionTitle(for kind: AppPermissionKind, state: AppPermissionState) -> String? {
        switch (kind, state) {
        case (.location, .notDetermined):
            return Strings.LocationAccess.allowLocation
        case (.location, .denied), (.location, .restricted):
            return Strings.LocationAccess.openSettings
        case (.location, .needsFollowUp):
            return Strings.LocationAccess.tryAgain
        case (.alarmKit, .notDetermined):
            return Strings.AlarmAccess.allowAlarms
        case (.alarmKit, .denied), (.alarmKit, .restricted):
            return Strings.LocationAccess.openSettings
        case (.notifications, .notDetermined):
            return Strings.NotificationAccess.allowNotifications
        case (.notifications, .denied), (.notifications, .restricted):
            return Strings.LocationAccess.openSettings
        default:
            return nil
        }
    }

    private func locationMessage(for state: AppPermissionState) -> String {
        switch state {
        case .authorized:
            if settingsStore.settings.locationMode == .fixed {
                if let fixedName = fixedLocationDisplayName() {
                    return Strings.LocationAccess.fixedExplanation(fixedName)
                }
                return Strings.LocationAccess.fixedExplanationFallback
            }
            if !locationService.locationName.isEmpty {
                return Strings.LocationAccess.currentLocation(locationService.locationName)
            }
            return Strings.LocationAccess.autoExplanation
        case .denied, .restricted:
            return Strings.LocationAccess.deniedExplanation
        case .needsFollowUp:
            return Strings.LocationAccess.waitingForLocation
        case .notDetermined, .unavailable:
            return Strings.LocationAccess.autoExplanation
        }
    }

    private func fixedLocationDisplayName() -> String? {
        guard let fixed = settingsStore.settings.fixedLocation else { return nil }
        if let city = City.all.first(where: {
            abs($0.latitude - fixed.latitude) < 0.001 && abs($0.longitude - fixed.longitude) < 0.001
        }) {
            return city.name
        }
        if !locationService.locationName.isEmpty {
            return locationService.locationName
        }
        return nil
    }

    private func alarmMessage(for state: AppPermissionState) -> String {
        switch state {
        case .authorized, .notDetermined, .needsFollowUp:
            return Strings.AlarmAccess.explanation
        case .denied, .restricted:
            return Strings.AlarmAccess.deniedExplanation
        case .unavailable:
            return Strings.AlarmAccess.unavailableExplanation
        }
    }

    private func notificationMessage(for state: AppPermissionState) -> String {
        switch state {
        case .authorized, .notDetermined, .needsFollowUp, .unavailable:
            return Strings.NotificationAccess.explanation
        case .denied, .restricted:
            return Strings.NotificationAccess.deniedExplanation
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

    private func retagActiveWindow(reason: String = "tag_selection_changed") {
        guard !activeWindowSnapshot.visibleDays.isEmpty else { return }
        invalidateExpandedMonthSnapshots(reason: reason)
        let token = PerformanceTrace.begin("tags.compute-window", metadata: "visible=\(activeWindowSnapshot.visibleDays.count)")
        defer { PerformanceTrace.end(token) }

        let timeZone = TimeZone.current
        let seeds = activeWindowSnapshot.visibleDays.map(\.tagSeed)
        let tagResults = TagComputationEngine.results(
            seeds: seeds,
            selections: fastTagStore.selections,
            ruleset: .strict,
            timeZone: timeZone
        )
        let visibleDays = activeWindowSnapshot.visibleDays.map { day in
            replacingTagResult(day, with: tagResults[day.dateKey] ?? .empty)
        }
        let adjustedVisibleDays = applyShawwalTagResults(to: visibleDays, timeZone: timeZone)
        activeWindowSnapshot = ActiveAlarmWindowSnapshot(
            generatedAt: Date(),
            visibleDays: adjustedVisibleDays,
            scheduledDays: Array(adjustedVisibleDays.prefix(scheduledActiveDayLimit)),
            visibleHorizonDays: activeWindowSnapshot.visibleHorizonDays,
            scheduledHorizonDays: activeWindowSnapshot.scheduledHorizonDays
        )
        schedules = activeWindowSnapshot.visibleDays.map(\.schedule)
        activeTagSelectionRevision = fastTagStore.currentRevision
        cacheStore.save(
            ScheduleCacheStore.Cache(
                lastScheduledDate: settingsStore.settings.lastScheduledDate,
                lastUpdated: lastUpdated,
                schedulingMode: schedulingMode,
                schedules: schedules,
                activeWindowSnapshot: activeWindowSnapshot,
                tagSelectionRevision: activeTagSelectionRevision
            )
        )
    }

    private func buildActiveDayIfNeeded(
        for date: Date,
        timeZone: TimeZone = .current,
        preferCached: Bool = true
    ) -> ActiveAlarmDay? {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
        if preferCached, let cached = activeWindowSnapshot.byDateKey[key] {
            return cached
        }

        syncMorningPlanState()
        guard dateParticipatesInWakePlan(normalizedDate, timeZone: timeZone),
              let coordinate = currentCoordinate() else {
            return nil
        }
        let provenances = mergedProvenances(for: normalizedDate, timeZone: timeZone)

        let settings = settingsStore.settings
        let tagResult: TagComputationResult
        if let shawwalKey = shawwalMonthKey(for: normalizedDate, timeZone: timeZone) {
            let results = monthTagResults(for: shawwalKey, timeZone: timeZone)
            tagResult = results[key] ?? tagPreviewResult(
                for: normalizedDate,
                defaultPrimaryIntent: provenances.defaultFastPrimaryIntent(),
                timeZone: timeZone
            )
        } else {
            tagResult = tagPreviewResult(
                for: normalizedDate,
                defaultPrimaryIntent: provenances.defaultFastPrimaryIntent(),
                timeZone: timeZone
            )
        }

        return resolveActiveDay(
            for: normalizedDate,
            provenances: provenances,
            tagResult: tagResult,
            coordinate: coordinate,
            settings: settings,
            timeZone: timeZone
        )
    }

    private func activeDays(
        from resolvedEntries: [ResolvedScheduledDateEntry],
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone
    ) -> [ActiveAlarmDay] {
        guard !resolvedEntries.isEmpty else { return [] }

        syncMorningPlanState()
        let provenancesByDateKey = Dictionary(uniqueKeysWithValues: resolvedEntries.map { ($0.dateKey, $0.provenances) })
        let stateSnapshot = buildMorningStateSnapshot(
            settings: settingsStore.settings,
            coordinate: coordinate,
            timeZone: timeZone,
            locationDescription: "Based on your location",
            provenancesByDateKey: provenancesByDateKey
        )
        let input = ActiveWindowBuildInput(
            stateSnapshot: stateSnapshot,
            resolvedEntries: resolvedEntries,
            visibleHorizonDays: resolvedEntries.count,
            scheduledHorizonDays: resolvedEntries.count
        )

        return ActiveWindowBuilder.build(input: input).visibleDays
    }

    private func debugValidateActiveWindow(
        _ snapshot: ActiveAlarmWindowSnapshot,
        resolvedEntries: [ResolvedScheduledDateEntry]
    ) {
        #if DEBUG
        let expectedVisibleKeys = Array(resolvedEntries.prefix(snapshot.visibleHorizonDays)).map(\.dateKey)
        let actualVisibleKeys = snapshot.visibleDays.map(\.dateKey)
        if actualVisibleKeys != expectedVisibleKeys {
            assertionFailure("Visible snapshot keys diverged from resolved active entries.")
        }

        let expectedScheduledKeys = Array(actualVisibleKeys.prefix(snapshot.scheduledHorizonDays))
        let actualScheduledKeys = snapshot.scheduledDays.map(\.dateKey)
        if actualScheduledKeys != expectedScheduledKeys {
            assertionFailure("Scheduled snapshot keys diverged from visible prefix.")
        }

        if snapshot.visibleDays.contains(where: { $0.provenances.isEmpty }) {
            assertionFailure("Visible active day is missing provenance.")
        }

        if Set(actualVisibleKeys).count != actualVisibleKeys.count {
            assertionFailure("Visible active window contains duplicate date keys.")
        }
        #endif
    }

    private func alarmKitAvailableAndAuthorized() async -> Bool {
        await effectiveSchedulingChannel() == .alarmKit
    }

    private func buildPermissionSnapshot() async -> PermissionSnapshot {
        let location = await uncachedPermissionPresentation(for: .location)
        let alarms = await uncachedPermissionPresentation(for: .alarmKit)
        let notifications = await uncachedPermissionPresentation(for: .notifications)
        let mode = await effectiveSchedulingChannel()
        let modeText: String
        switch mode {
        case .alarmKit:
            modeText = "AlarmKit"
        case .notifications:
            modeText = "Notifications"
        case .none:
            modeText = "Blocked"
        }

        let summaryText = "\(location.title): \(location.statusText) · \(alarms.title): \(alarms.statusText) · \(notifications.title): \(notifications.statusText) · Mode: \(modeText)"
        return PermissionSnapshot(
            summaryText: summaryText,
            alarmAuthorizationText: await alarmAuthorizationStateText(),
            notificationAuthorizationText: await notificationAuthorizationStateText(),
            presentations: [
                .location: location,
                .alarmKit: alarms,
                .notifications: notifications
            ]
        )
    }

    private func permissionSummaryText() async -> String {
        let location = await uncachedPermissionPresentation(for: .location)
        let alarms = await uncachedPermissionPresentation(for: .alarmKit)
        let notifications = await uncachedPermissionPresentation(for: .notifications)
        let mode = await effectiveSchedulingChannel()
        let modeText: String
        switch mode {
        case .alarmKit:
            modeText = "AlarmKit"
        case .notifications:
            modeText = "Notifications"
        case .none:
            modeText = "Blocked"
        }
        return "\(location.title): \(location.statusText) · \(alarms.title): \(alarms.statusText) · \(notifications.title): \(notifications.statusText) · Mode: \(modeText)"
    }

    private func updateBootstrapState() {
        if settingsStore.settings.isConfigured,
           !permissionsLoaded,
           !activeWindowSnapshot.visibleDays.isEmpty {
            bootstrapState = .home
            return
        }

        bootstrapState = BootstrapEvaluator.evaluate(
            settings: settingsStore.settings,
            locationAuthorizationStatus: locationService.authorizationStatus,
            lastLocation: locationService.lastLocation?.timestamp,
            permissionSnapshot: permissionSnapshot
        )
    }

    static func resolveBootstrapState(
        settings: AppSettings,
        permissionStates: [AppPermissionKind: AppPermissionState],
        hasVisibleDays: Bool
    ) -> AppBootstrapState {
        if !settings.isConfigured {
            return .welcome
        }

        let locationReady = settings.locationMode == .fixed || permissionStates[.location] == .authorized
        let alarmState = permissionStates[.alarmKit] ?? .notDetermined
        let notificationsReady = permissionStates[.notifications] == .authorized
        let alarmReady = alarmState == .authorized || alarmState == .unavailable
        let schedulingReady = alarmState == .authorized || (alarmState == .unavailable && notificationsReady)
        _ = hasVisibleDays

        guard locationReady, alarmReady, schedulingReady else {
            return .permissions
        }

        return .home
    }

    private var permissionsLoaded: Bool {
        permissionSnapshot.presentations.count == AppPermissionKind.allCases.count
    }

    static func shouldReuseScheduleWindow(
        reason: ScheduleRefreshReason,
        lastScheduledDate: Date?,
        snapshot: ActiveAlarmWindowSnapshot,
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> Bool {
        guard reason == .foreground || reason == .appLaunch else {
            return false
        }
        guard DateHelpers.isSameDay(lastScheduledDate, now, in: timeZone) else {
            return false
        }
        guard !snapshot.visibleDays.isEmpty else {
            return false
        }
        return DateHelpers.isSameDay(snapshot.generatedAt, now, in: timeZone)
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

    private func schedulingBlockedMessage() async -> String {
        if await permissionState(for: .notifications) != .authorized {
            return Strings.NotificationAccess.deniedExplanation
        }
        return Strings.AlarmAccess.unavailableExplanation
    }

    private func alarmSoundName(for soundChoice: SoundChoice) -> String? {
        guard soundChoice == .adhanSoft else { return nil }
        if Bundle.main.url(forResource: "adhan_fajr", withExtension: "caf") != nil {
            return "adhan_fajr.caf"
        }
        return nil
    }

    private func cancelAll() async {
        await routineScheduler.cancelAllUpcoming(days: scheduledActiveDayLimit)
        alarmScheduler.resetReconciliationState()
        alarmRecordStore.clearAll()
        alarmStateStore.clear()
    }

    private func scheduleForCancellation(on date: Date) -> DaySchedule? {
        let timeZone = TimeZone.current
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let existing = activeWindowSnapshot.byDateKey[key]?.schedule {
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
        maghribAdjustmentMinutes: Int,
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
        guard let maghrib = calculator.maghribDate(
            for: day,
            location: coordinate,
            timeZone: timeZone,
            adjustmentMinutes: maghribAdjustmentMinutes
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
        let iftar = effectiveConfig.iftarEnabled ? maghrib : nil

        return DaySchedule(
            date: day,
            fajrDate: fajr,
            maghribDate: maghrib,
            wakeDate: wake,
            reminderDate: reminder,
            boundaryDate: boundary,
            iftarDate: iftar,
            fajrSoundChoice: fajrSoundChoice,
            iftarSoundChoice: effectiveConfig.iftarSoundChoice,
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
        maghribAdjustmentMinutes: Int,
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
                maghribAdjustmentMinutes: maghribAdjustmentMinutes,
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

    private func recentDateKeys(days: Int, timeZone: TimeZone = .current) -> [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: Date())
        return (0..<days).compactMap { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        }
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

    private func expandedMonthIdentifier(for key: HijriMonthKey) -> String {
        "\(key.year)-\(key.month)"
    }
}

enum ScheduleRefreshReason: Sendable {
    case appLaunch
    case foreground
    case settingsChanged
    case locationUpdated
    case manual
}

private struct PendingScheduleRefresh {
    let reason: ScheduleRefreshReason
    let force: Bool

    func merged(with other: PendingScheduleRefresh) -> PendingScheduleRefresh {
        PendingScheduleRefresh(reason: other.reason, force: force || other.force)
    }
}

struct PermissionSnapshot: Equatable, Sendable {
    let summaryText: String
    let alarmAuthorizationText: String
    let notificationAuthorizationText: String
    let presentations: [AppPermissionKind: PermissionPresentation]

    static let empty = PermissionSnapshot(
        summaryText: "",
        alarmAuthorizationText: "--",
        notificationAuthorizationText: "--",
        presentations: [:]
    )
}

struct ActivationScheduleResult {
    let success: Bool
    let message: String
    let schedule: DaySchedule?
}

enum AppBootstrapState: Equatable, Sendable {
    case welcome
    case permissions
    case home
}

enum DuplicateDateStatus {
    case available
    case active(provenances: [ResolvedScheduledDateProvenance], existingDay: ActiveAlarmDay)
}

struct NextWakeEventSummary: Equatable, Sendable {
    let day: ActiveAlarmDay
    let event: ScheduledEvent
    let priority: Int

    var relationText: String {
        let delta = day.decisionLog.resolvedDelta
        switch event.type {
        case .wakeAlarm:
            return relationText(for: delta, anchor: day.decisionLog.resolvedAnchor.type)
        case .wakeReminder:
            return "Reminder before the main wake."
        case .wakeFollowUp:
            return "Follow-up after the main wake."
        case .fajrBoundaryNotice:
            return "At the Fajr boundary."
        case .iftarReminder:
            return "At Maghrib."
        }
    }

    private func relationText(for delta: WakeDelta, anchor: WakeAnchorType) -> String {
        let anchorTitle: String
        switch anchor {
        case .fajrStart:
            anchorTitle = "Fajr"
        case .fajrEnd:
            anchorTitle = "Fajr ends"
        case .masjidFajr:
            anchorTitle = "masjid Fajr"
        }

        if delta.minutes == 0 {
            return "At \(anchorTitle)."
        }

        let unit = delta.minutes == 1 ? "minute" : "minutes"
        switch delta.relation {
        case .before:
            return "\(delta.minutes) \(unit) before \(anchorTitle)."
        case .after:
            return "\(delta.minutes) \(unit) after \(anchorTitle)."
        }
    }
}

struct ActiveAlarmDay: Codable, Equatable, Identifiable, Sendable {
    let date: Date
    let dateKey: String
    let schedule: DaySchedule
    let effectiveConfig: EffectiveDailyConfig
    let provenances: [ResolvedScheduledDateProvenance]
    let isImplicitRamadan: Bool
    let isExplicitOneOff: Bool
    let tagResult: TagComputationResult
    let primaryDisplay: PrimaryDisplay?
    let sourceSummaryText: String
    let resolvedDayContext: ResolvedDayContext
    let scheduledEvents: [ScheduledEvent]
    let decisionLog: RuleDecisionLog
    let dailyCompletion: DailyCompletionSnapshot

    var id: String { dateKey }

    init(
        date: Date,
        dateKey: String,
        schedule: DaySchedule,
        effectiveConfig: EffectiveDailyConfig,
        provenances: [ResolvedScheduledDateProvenance],
        isImplicitRamadan: Bool,
        isExplicitOneOff: Bool,
        tagResult: TagComputationResult,
        primaryDisplay: PrimaryDisplay?,
        sourceSummaryText: String,
        resolvedDayContext: ResolvedDayContext = .standard,
        scheduledEvents: [ScheduledEvent] = [],
        decisionLog: RuleDecisionLog? = nil,
        dailyCompletion: DailyCompletionSnapshot? = nil
    ) {
        self.date = date
        self.dateKey = dateKey
        self.schedule = schedule
        self.effectiveConfig = effectiveConfig
        self.provenances = provenances
        self.isImplicitRamadan = isImplicitRamadan
        self.isExplicitOneOff = isExplicitOneOff
        self.tagResult = tagResult
        self.primaryDisplay = primaryDisplay
        self.sourceSummaryText = sourceSummaryText
        self.resolvedDayContext = resolvedDayContext
        self.scheduledEvents = scheduledEvents
        self.decisionLog = decisionLog ?? RuleDecisionLog.compatibilityFallback(
            dateKey: dateKey,
            schedule: schedule,
            resolvedDayContext: resolvedDayContext,
            primaryDisplay: primaryDisplay
        )
        self.dailyCompletion = dailyCompletion ?? .empty(dateKey: dateKey)
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case dateKey
        case schedule
        case effectiveConfig
        case provenances
        case isImplicitRamadan
        case isExplicitOneOff
        case tagResult
        case primaryDisplay
        case sourceSummaryText
        case resolvedDayContext
        case scheduledEvents
        case decisionLog
        case dailyCompletion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let date = try container.decode(Date.self, forKey: .date)
        let dateKey = try container.decode(String.self, forKey: .dateKey)
        let schedule = try container.decode(DaySchedule.self, forKey: .schedule)
        let effectiveConfig = try container.decode(EffectiveDailyConfig.self, forKey: .effectiveConfig)
        let provenances = try container.decode([ResolvedScheduledDateProvenance].self, forKey: .provenances)
        let isImplicitRamadan = try container.decode(Bool.self, forKey: .isImplicitRamadan)
        let isExplicitOneOff = try container.decode(Bool.self, forKey: .isExplicitOneOff)
        let tagResult = try container.decode(TagComputationResult.self, forKey: .tagResult)
        let primaryDisplay = try container.decodeIfPresent(PrimaryDisplay.self, forKey: .primaryDisplay)
        let sourceSummaryText = try container.decode(String.self, forKey: .sourceSummaryText)
        let resolvedDayContext = try container.decodeIfPresent(ResolvedDayContext.self, forKey: .resolvedDayContext) ?? .standard
        let scheduledEvents = try container.decodeIfPresent([ScheduledEvent].self, forKey: .scheduledEvents) ?? []
        let decisionLog = try container.decodeIfPresent(RuleDecisionLog.self, forKey: .decisionLog)
        let dailyCompletion = try container.decodeIfPresent(DailyCompletionSnapshot.self, forKey: .dailyCompletion)
            ?? .empty(dateKey: dateKey)

        self.init(
            date: date,
            dateKey: dateKey,
            schedule: schedule,
            effectiveConfig: effectiveConfig,
            provenances: provenances,
            isImplicitRamadan: isImplicitRamadan,
            isExplicitOneOff: isExplicitOneOff,
            tagResult: tagResult,
            primaryDisplay: primaryDisplay,
            sourceSummaryText: sourceSummaryText,
            resolvedDayContext: resolvedDayContext,
            scheduledEvents: scheduledEvents,
            decisionLog: decisionLog,
            dailyCompletion: dailyCompletion
        )
    }

    var tagSeed: ActiveTagComputationSeed {
        ActiveTagComputationSeed(
            date: date,
            dateKey: dateKey,
            defaultPrimaryIntent: provenances.defaultFastPrimaryIntent()
        )
    }
}

struct ActiveAlarmWindowSnapshot: Codable, Equatable, Sendable {
    let generatedAt: Date
    let visibleDays: [ActiveAlarmDay]
    let scheduledDays: [ActiveAlarmDay]
    let visibleHorizonDays: Int
    let scheduledHorizonDays: Int

    static let empty = ActiveAlarmWindowSnapshot(
        generatedAt: .distantPast,
        visibleDays: [],
        scheduledDays: [],
        visibleHorizonDays: 60,
        scheduledHorizonDays: 30
    )

    var byDateKey: [String: ActiveAlarmDay] {
        Dictionary(uniqueKeysWithValues: visibleDays.map { ($0.dateKey, $0) })
    }

    func replacing(_ day: ActiveAlarmDay) -> ActiveAlarmWindowSnapshot {
        var updatedVisible = visibleDays
        if let index = updatedVisible.firstIndex(where: { $0.dateKey == day.dateKey }) {
            updatedVisible[index] = day
        } else {
            updatedVisible.append(day)
            updatedVisible.sort { $0.date < $1.date }
            updatedVisible = Array(updatedVisible.prefix(visibleHorizonDays))
        }
        return ActiveAlarmWindowSnapshot(
            generatedAt: Date(),
            visibleDays: updatedVisible,
            scheduledDays: Array(updatedVisible.prefix(scheduledHorizonDays)),
            visibleHorizonDays: visibleHorizonDays,
            scheduledHorizonDays: scheduledHorizonDays
        )
    }

    func removing(dateKey: String) -> ActiveAlarmWindowSnapshot {
        let updatedVisible = visibleDays.filter { $0.dateKey != dateKey }
        return ActiveAlarmWindowSnapshot(
            generatedAt: Date(),
            visibleDays: updatedVisible,
            scheduledDays: Array(updatedVisible.prefix(scheduledHorizonDays)),
            visibleHorizonDays: visibleHorizonDays,
            scheduledHorizonDays: scheduledHorizonDays
        )
    }
}

struct ExpandedMonthSnapshot: Equatable, Sendable {
    let key: HijriMonthKey
    let generatedAt: Date
    let invalidationToken: Int
    let tagSelectionRevision: Int
    let entries: [ActiveAlarmDay]
}

private struct MonthTagCache: Equatable, Sendable {
    let revision: Int
    let results: [String: TagComputationResult]
}

private struct ScheduleLocationSnapshot: Sendable {
    let latitude: Double
    let longitude: Double
}

private extension ScheduleManager {
    static func makeLegacySnapshot(
        schedules: [DaySchedule],
        settings: AppSettings,
        defaults: DefaultAlarmConfig,
        overridesByDay: [String: DailyAlarmOverride],
        provenanceProvider: (Date, TimeZone) -> [ResolvedScheduledDateProvenance],
        selections: [String: FastIntentSelection],
        visibleHorizonDays: Int,
        scheduledHorizonDays: Int,
        timeZone: TimeZone
    ) -> ActiveAlarmWindowSnapshot {
        guard !schedules.isEmpty else { return .empty }

        let seeds = schedules.map {
            ActiveTagComputationSeed(
                date: $0.date,
                dateKey: DateHelpers.dayIdentifier(for: $0.date, timeZone: timeZone),
                defaultPrimaryIntent: provenanceProvider($0.date, timeZone).defaultFastPrimaryIntent()
            )
        }
        let tagResults = TagComputationEngine.results(
            seeds: seeds,
            selections: selections,
            ruleset: .strict,
            timeZone: timeZone
        )

        let visibleDays = schedules.compactMap { schedule -> ActiveAlarmDay? in
            let dateKey = DateHelpers.dayIdentifier(for: schedule.date, timeZone: timeZone)
            let provenances = provenanceProvider(schedule.date, timeZone)
            guard !provenances.isEmpty else { return nil }
            let config = ActiveWindowBuilder.effectiveConfig(
                for: schedule.date,
                settings: settings,
                defaultConfig: defaults,
                overridesByDay: overridesByDay,
                timeZone: timeZone
            )
            let labels = provenances.map(\.label)
            let summary = Array(NSOrderedSet(array: labels)).compactMap { $0 as? String }.joined(separator: " • ")
            return ActiveAlarmDay(
                date: schedule.date,
                dateKey: dateKey,
                schedule: schedule,
                effectiveConfig: config,
                provenances: provenances,
                isImplicitRamadan: provenances.contains(where: { $0.sourceOrigin == .defaultRamadan }),
                isExplicitOneOff: !provenances.isEmpty && provenances.allSatisfy(\.isExplicitOneOff),
                tagResult: tagResults[dateKey] ?? .empty,
                primaryDisplay: config.primaryDisplay(schedule: schedule),
                sourceSummaryText: summary,
                dailyCompletion: .empty(dateKey: dateKey)
            )
        }

        return ActiveAlarmWindowSnapshot(
            generatedAt: Date(),
            visibleDays: Array(visibleDays.prefix(visibleHorizonDays)),
            scheduledDays: Array(visibleDays.prefix(scheduledHorizonDays)),
            visibleHorizonDays: visibleHorizonDays,
            scheduledHorizonDays: scheduledHorizonDays
        )
    }
}

private extension ScheduleRefreshReason {
    var debounceDurationNanoseconds: UInt64 {
        switch self {
        case .appLaunch, .foreground:
            return 0
        case .settingsChanged:
            return 200_000_000
        case .locationUpdated:
            return 100_000_000
        case .manual:
            return 0
        }
    }
}
