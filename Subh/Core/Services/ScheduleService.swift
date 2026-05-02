import Foundation
import CoreLocation
import Combine
import UserNotifications
import os
import AlarmKit

@MainActor
final class ScheduleManager: ObservableObject {
    @Published var schedules: [DaySchedule] = []
    @Published var schedulingMode: SchedulingMode = .none
    @Published var lastUpdated: Date?
    @Published var permissionSummary: String = ""
    @Published var statusText: String = ""
    @Published var lastEnableFailureMessage: String?
    @Published var alarmAuthorizationText: String = "--"
    @Published var notificationAuthorizationText: String = "--"
    @Published private(set) var currentRevision: Int = 0
    @Published private(set) var permissionSnapshot: PermissionSnapshot = .empty {
        didSet {
            refreshCurrentMorningHomeSnapshot()
        }
    }
    @Published private(set) var activeWindowSnapshot: ActiveAlarmWindowSnapshot = .empty {
        didSet {
            currentRevision += 1
            clearFajrWindowCaches()
            refreshCurrentMorningHomeSnapshot()
        }
    }
    @Published private(set) var currentMorningHomeSnapshot: MorningHomeSnapshot = .empty
    @Published private(set) var bootstrapState: AppBootstrapState = .welcome
    @Published private(set) var hijriAdjustmentChanges: [HijriAdjustmentChange] = []
    @Published private(set) var lastDeliveryReconciliationReport: DeliveryReconciliationReport?

    private let settingsStore: SuhoorSettingsStore
    private let alarmConfigStore: AlarmConfigStore
    private let morningPlanStore: MorningPlanStore
    private let locationService: LocationService
    private let fastTagStore: FastTagStore
    private let fastLogStore: FastLogStore
    private let fajrLogStore: FajrLogStore
    private let qadaBacklogStore: QadaBacklogStore
    private let qadaBatchStore: QadaBatchStore
    private let usesLegacyContexts: Bool
    private let cacheStore: ScheduleCacheStore
    private let timeProvider: any TimeProviding
    private let fajrWindowSurfaceProvider = FajrWindowSurfaceProvider()
    private let nextWakeEventResolver = NextWakeEventResolver()
    private let activeWindowSnapshotBuilder: ActiveWindowSnapshotBuilder
    private let calculator = PrayerTimeCalculator()
    private lazy var dayScheduleBuilder = DayScheduleBuilder(calculator: calculator)
    private let hijriAdjustmentStore: HijriMonthAdjustmentStore
    private let adjustedHijriCalendar: AdjustedHijriCalendar
    private let hijriAdjustmentChangeStore: HijriAdjustmentChangeStore
    private let alarmDeliveryLedger: AlarmDeliveryLedgerStore

    private var alarmKitScheduler: AlarmKitScheduler?
    private let notificationScheduler = NotificationScheduler()
    private let routineScheduler: RoutineScheduler
    private let alarmScheduler: AlarmScheduler
    private let alarmCoordinator: AlarmCoordinator?
    private let visibleActiveDayLimit = 60
    private let scheduledActiveDayLimit = 30
    private let monthTagResultLookup = MonthTagResultLookup()
    private var activeTagSelectionRevision: Int = -1
    private var pendingDayRescheduleTasks: [String: Task<Void, Never>] = [:]
    private var fajrWindowDatasetCache: [FajrWindowDatasetKey: FajrWindowDataset] = [:]
    private var fajrWindowOverlaySeriesCache: [FajrWindowOverlayCacheKey: FajrWindowOverlaySeries] = [:]
    private var cancellables: Set<AnyCancellable> = []
    private(set) var fajrWindowDatasetBuildCount: Int = 0
    private(set) var fajrWindowOverlayBuildCounts: [FajrWindowOverlay: Int] = [:]
    private lazy var activeDayResolver = ActiveDayResolver(
        alarmConfigStore: alarmConfigStore,
        morningPlanStore: morningPlanStore,
        fastTagStore: fastTagStore,
        fastLogStore: fastLogStore,
        fajrLogStore: fajrLogStore,
        qadaBacklogStore: qadaBacklogStore,
        qadaBatchStore: qadaBatchStore,
        usesLegacyContexts: usesLegacyContexts,
        adjustedHijriCalendar: adjustedHijriCalendar,
        calculator: calculator,
        dependencies: .init(
            settings: { [unowned self] in
                settingsStore.settings
            },
            currentCoordinate: { [unowned self] in
                currentCoordinate()
            },
            cachedActiveDay: { [unowned self] key in
                activeWindowSnapshot.byDateKey[key]
            },
            resolvedTagResult: { [monthTagResultLookup] date, dateKey, fallback, timeZone in
                monthTagResultLookup.resolve(
                    date: date,
                    dateKey: dateKey,
                    fallback: fallback,
                    timeZone: timeZone
                )
            },
            tagPreviewResult: { [unowned self] date, overrideSelection, defaultPrimaryIntent, timeZone in
                tagPreviewResult(
                    for: date,
                    overrideSelection: overrideSelection,
                    defaultPrimaryIntent: defaultPrimaryIntent,
                    timeZone: timeZone
                )
            }
        )
    )
    private lazy var wakeListDataProvider = WakeListDataProvider(
        alarmConfigStore: alarmConfigStore,
        adjustedHijriCalendar: adjustedHijriCalendar,
        fastTagStore: fastTagStore,
        dependencies: .init(
            currentCoordinate: { [unowned self] in
                currentCoordinate()
            },
            resolvedEntriesForHijriMonth: { [unowned self] key, timeZone in
                activeDayResolver.resolvedEntriesForHijriMonth(key, timeZone: timeZone)
            },
            buildSnapshot: { [unowned self] entries, coordinate, timeZone in
                buildActiveWindowSnapshot(
                    resolvedEntries: entries,
                    coordinate: coordinate,
                    timeZone: timeZone,
                    visibleHorizonDays: entries.count,
                    scheduledHorizonDays: entries.count
                )
            }
        )
    )
    private lazy var monthTagResultProvider = MonthTagResultProvider(
        dependencies: .init(
            currentRevision: { [unowned self] in
                fastTagStore.currentRevision
            },
            selections: { [unowned self] in
                fastTagStore.selections
            },
            resolvedEntriesForHijriMonth: { [unowned self] key, timeZone in
                activeDayResolver.resolvedEntriesForHijriMonth(key, timeZone: timeZone)
            },
            replaceActiveDayTagResult: { [unowned self] day, tagResult, timeZone in
                activeDayResolver.replacingTagResult(day, with: tagResult, timeZone: timeZone)
            }
        )
    )
    private lazy var refreshCoordinator = ScheduleRefreshCoordinator { [weak self] request in
        await self?.ensureScheduleWindow(reason: request.reason)
    }

    init(
        settingsStore: SuhoorSettingsStore,
        locationService: LocationService,
        alarmConfigStore: AlarmConfigStore,
        fastTagStore: FastTagStore? = nil,
        fastLogStore: FastLogStore? = nil,
        fajrLogStore: FajrLogStore? = nil,
        qadaBacklogStore: QadaBacklogStore? = nil,
        qadaBatchStore: QadaBatchStore? = nil,
        usesLegacyContexts: Bool = true,
        hijriAdjustmentStore: HijriMonthAdjustmentStore = HijriMonthAdjustmentStore(),
        hijriAdjustmentChangeStore: HijriAdjustmentChangeStore = HijriAdjustmentChangeStore(),
        cacheStore: ScheduleCacheStore = ScheduleCacheStore(),
        timeProvider: any TimeProviding = SystemTimeProvider(),
        alarmDeliveryLedger: AlarmDeliveryLedgerStore? = nil
    ) {
        let resolvedFastTagStore = fastTagStore ?? FastTagStore(loadPersistedData: usesLegacyContexts)
        let resolvedFastLogStore = fastLogStore ?? FastLogStore(loadPersistedData: usesLegacyContexts)
        let resolvedFajrLogStore = fajrLogStore ?? FajrLogStore(loadPersistedData: usesLegacyContexts)
        let resolvedQadaBacklogStore = qadaBacklogStore ?? QadaBacklogStore(loadPersistedData: usesLegacyContexts)
        let resolvedQadaBatchStore = qadaBatchStore ?? QadaBatchStore(loadPersistedData: usesLegacyContexts)

        self.settingsStore = settingsStore
        self.alarmConfigStore = alarmConfigStore
        self.timeProvider = timeProvider
        self.activeWindowSnapshotBuilder = ActiveWindowSnapshotBuilder(timeProvider: timeProvider)
        self.morningPlanStore = MorningPlanStore(
            defaults: alarmConfigStore.storageDefaults,
            legacySettings: settingsStore.settings,
            defaultConfig: alarmConfigStore.defaults,
            timeProvider: timeProvider
        )
        self.locationService = locationService
        self.fastTagStore = resolvedFastTagStore
        self.fastLogStore = resolvedFastLogStore
        self.fajrLogStore = resolvedFajrLogStore
        self.qadaBacklogStore = resolvedQadaBacklogStore
        self.qadaBatchStore = resolvedQadaBatchStore
        self.usesLegacyContexts = usesLegacyContexts
        self.hijriAdjustmentStore = hijriAdjustmentStore
        self.hijriAdjustmentChangeStore = hijriAdjustmentChangeStore
        self.cacheStore = cacheStore
        self.alarmDeliveryLedger = alarmDeliveryLedger ?? .shared
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
        var resolvedCoordinator: AlarmCoordinator?
        if FeatureFlags.useAlarmCoordinatorForScheduling, #available(iOS 26.0, *), let resolvedAlarmKit {
            resolvedCoordinator = AlarmCoordinator(
                alarmScheduler: resolvedAlarmKit
            )
        }
        self.alarmCoordinator = resolvedCoordinator
        self.routineScheduler = RoutineScheduler(
            notificationScheduler: notificationScheduler,
            alarmKitScheduler: resolvedAlarmKit,
            alarmCoordinator: resolvedCoordinator
        )
        self.alarmScheduler = AlarmScheduler(routineScheduler: routineScheduler)
        let cache = cacheStore.load()
        let expectedWakeRuleSignature = ScheduleCacheStore.wakeRuleSignature(for: alarmConfigStore.defaults)
        let expectedCalculationSignature = ScheduleCacheStore.calculationSignature(for: settingsStore.settings)
        let cacheMatchesResolutionInputs = cache.wakeRuleSignature == expectedWakeRuleSignature
            && cache.calculationSignature == expectedCalculationSignature
        let cachedActiveWindow = cacheMatchesResolutionInputs ? cache.activeWindowSnapshot : nil
        let cacheReusable = cachedActiveWindow.map {
            Self.shouldReuseScheduleWindow(
                reason: .appLaunch,
                lastScheduledDate: cache.lastScheduledDate,
                snapshot: $0,
                now: timeProvider.now(),
                timeZone: .current,
                requiresDailyWindow: morningPlanStore.usesDailyActivation
            )
        } ?? false
        if (!cacheMatchesResolutionInputs || !cacheReusable) && (cache.activeWindowSnapshot != nil || !cache.schedules.isEmpty) {
            cacheStore.clear()
        }
        let cachedSchedules = cacheReusable ? cache.schedules : []
        self.schedules = cachedSchedules
        self.schedulingMode = cacheReusable ? cache.schedulingMode : .none
        self.lastUpdated = cacheReusable ? cache.lastUpdated : nil
        self.activeWindowSnapshot = (cacheReusable ? cachedActiveWindow : nil)
            ?? Self.makeLegacySnapshot(
                schedules: cachedSchedules,
                settings: settingsStore.settings,
                defaults: alarmConfigStore.defaults,
                overridesByDay: alarmConfigStore.overridesByDay,
                provenanceProvider: { alarmConfigStore.provenance(for: $0, timeZone: $1) },
                selections: usesLegacyContexts ? resolvedFastTagStore.selections : [:],
                visibleHorizonDays: visibleActiveDayLimit,
                scheduledHorizonDays: scheduledActiveDayLimit,
                timeZone: .current
            )
        self.activeTagSelectionRevision = usesLegacyContexts ? (cache.tagSelectionRevision ?? -1) : -1
        self.schedules = activeWindowSnapshot.visibleDays.map(\.schedule)
        self.hijriAdjustmentChanges = hijriAdjustmentChangeStore.pendingChanges()

        if usesLegacyContexts {
            resolvedFastTagStore.$selections
                .dropFirst()
                .sink { [weak self] _ in
                    Task { @MainActor [weak self] in
                        self?.retagActiveWindow()
                    }
                }
                .store(in: &cancellables)

        }

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
        refreshCurrentMorningHomeSnapshot()
        monthTagResultLookup.handler = { [weak self] date, dateKey, fallback, timeZone in
            guard let self else { return fallback }
            return self.monthTagResultProvider.resolvedTagResult(
                for: date,
                dateKey: dateKey,
                fallback: fallback,
                timeZone: timeZone
            )
        }
    }

    var nextUpcomingSchedule: DaySchedule? {
        nextWakeEventSummary?.day.schedule
            ?? activeWindowSnapshot.visibleDays.first(where: { !$0.effectiveConfig.skipDay && $0.effectiveConfig.hasAnyEnabled })?.schedule
            ?? schedules.first
    }

    var currentDate: Date {
        timeProvider.now()
    }

    var currentPrayerLocationDisplayText: String {
        prayerLocationDisplayText()
    }

    var currentPrayerLocationIconName: String? {
        settingsStore.settings.locationMode == .auto ? "location.fill" : nil
    }

    var nextWakeEventSummary: NextWakeEventSummary? {
        nextWakeEventResolver.resolve(
            activeWindowSnapshot: activeWindowSnapshot,
            now: timeProvider.now()
        )
    }

    func fajrWindowSurfaceSnapshot(
        period: FajrWindowPeriod,
        overlay: FajrWindowOverlay = .myWake,
        selectedDateKey: String? = nil,
        timeZone: TimeZone = .current
    ) -> FajrWindowSurfaceSnapshot {
        let dataset = fajrWindowDataset(period: period, timeZone: timeZone)
        let overlaySeries = loadedFajrWindowOverlaySeries(
            for: period,
            requestedOverlay: overlay,
            timeZone: timeZone
        )
        return projectedFajrWindowSurfaceSnapshot(
            dataset: dataset,
            overlay: overlay,
            selectedDateKey: selectedDateKey,
            overlaySeries: overlaySeries,
            timeZone: timeZone
        )
    }

    func fajrWindowCompactSnapshot(
        anchorDateKey: String? = nil,
        focusedDateKey: String? = nil,
        liveWakeAdjustment: FajrWindowLiveWakeAdjustment? = nil,
        timeZone: TimeZone = .current
    ) -> FajrWindowCompactSnapshot {
        PerformanceTrace.measure("fajrcast.compact.build") {
            let anchorDate = weeklyFajrcastAnchorDate(
                anchorDateKey: anchorDateKey,
                timeZone: timeZone
            )
            let resolvedAnchorDateKey = DateHelpers.dayIdentifier(for: anchorDate, timeZone: timeZone)
            let activeDays = activeDaysForWeeklyFajrcast(
                centeredOn: anchorDate,
                timeZone: timeZone
            )
            let visibleDateKeys = Set(activeDays.map(\.dateKey))
            let resolvedFocusedDateKey = focusedDateKey.flatMap { visibleDateKeys.contains($0) ? $0 : nil }
                ?? resolvedAnchorDateKey
            let dataset = fajrWindowSurfaceProvider.buildDataset(
                period: .sevenDays,
                activeDays: activeDays,
                overrideDateKeys: Set(alarmConfigStore.overridesByDay.keys),
                timeZone: timeZone
            )
            return fajrWindowSurfaceProvider.compactSnapshot(
                dataset: dataset,
                anchorDateKey: resolvedAnchorDateKey,
                selectedDateKey: resolvedFocusedDateKey,
                liveWakeAdjustment: liveWakeAdjustment,
                now: timeProvider.now(),
                timeZone: timeZone
            )
        }
    }

    func fajrWindowDataset(
        period: FajrWindowPeriod,
        timeZone: TimeZone = .current
    ) -> FajrWindowDataset {
        let key = fajrWindowDatasetKey(period: period, timeZone: timeZone)
        if let cached = fajrWindowDatasetCache[key] {
            return cached
        }

        let days = activeDaysForFajrWindow(period: period, timeZone: timeZone)
        let dataset = fajrWindowSurfaceProvider.buildDataset(
            period: period,
            activeDays: days,
            overrideDateKeys: Set(alarmConfigStore.overridesByDay.keys),
            timeZone: timeZone
        )
        fajrWindowDatasetCache[key] = dataset
        fajrWindowDatasetBuildCount += 1
        return dataset
    }

    func fajrWindowOverlaySeries(
        period: FajrWindowPeriod,
        overlay: FajrWindowOverlay,
        timeZone: TimeZone = .current
    ) -> FajrWindowOverlaySeries? {
        guard overlay == .compareFasting || overlay == .compareTahajjud else {
            return nil
        }

        let cacheKey = FajrWindowOverlayCacheKey(
            datasetKey: fajrWindowDatasetKey(period: period, timeZone: timeZone),
            overlay: overlay
        )
        if let cached = fajrWindowOverlaySeriesCache[cacheKey] {
            return cached.isAvailable ? cached : nil
        }

        let days = activeDaysForFajrWindow(period: period, timeZone: timeZone)
        let series = fajrWindowSurfaceProvider.buildOverlaySeries(
            period: period,
            overlay: overlay,
            activeDays: days,
            comparisonDay: { [unowned self] day, requestedOverlay in
                comparisonPreviewDay(for: day, overlay: requestedOverlay, timeZone: timeZone)
            },
            timeZone: timeZone
        ) ?? FajrWindowOverlaySeries(overlay: overlay, valuesByDateKey: [:])

        fajrWindowOverlaySeriesCache[cacheKey] = series
        fajrWindowOverlayBuildCounts[overlay, default: 0] += 1
        return series.isAvailable ? series : nil
    }

    func projectedFajrWindowSurfaceSnapshot(
        dataset: FajrWindowDataset,
        overlay: FajrWindowOverlay = .myWake,
        selectedDateKey: String? = nil,
        overlaySeries: [FajrWindowOverlaySeries] = [],
        timeZone: TimeZone = .current,
        now: Date = Date()
    ) -> FajrWindowSurfaceSnapshot {
        let resolvedOverlaySeries = overlaySeries.isEmpty
            ? loadedFajrWindowOverlaySeries(
                for: dataset.period,
                requestedOverlay: overlay,
                timeZone: timeZone
            )
            : overlaySeries

        return fajrWindowSurfaceProvider.surfaceSnapshot(
            dataset: dataset,
            requestedOverlay: overlay,
            selectedDateKey: selectedDateKey,
            overlaySeries: resolvedOverlaySeries,
            now: now,
            timeZone: timeZone
        )
    }

    func morningHomeSnapshot(timeZone: TimeZone = .current) -> MorningHomeSnapshot {
        buildMorningHomeSnapshot(timeZone: timeZone)
    }

    private func refreshCurrentMorningHomeSnapshot(timeZone: TimeZone = .current) {
        currentMorningHomeSnapshot = PerformanceTrace.measure("home.snapshot.build") {
            buildMorningHomeSnapshot(timeZone: timeZone)
        }
    }

    private func buildMorningHomeSnapshot(timeZone: TimeZone = .current) -> MorningHomeSnapshot {
        let overrideDateKeys = Set(alarmConfigStore.overridesByDay.keys)
        let now = timeProvider.now()
        let today = DateHelpers.startOfToday(in: timeZone, now: now)
        let todayKey = DateHelpers.dayIdentifier(for: today, timeZone: timeZone)
        let todayDay = activeWindowSnapshot.byDateKey[todayKey]
        let tomorrow = DateHelpers.startOfTomorrow(in: timeZone, now: now)
        let tomorrowKey = DateHelpers.dayIdentifier(for: tomorrow, timeZone: timeZone)
        let targetMorning: ActiveAlarmDay?
        if let todayDay, now <= todayDay.schedule.wakeDate {
            targetMorning = todayDay
        } else {
            targetMorning = activeWindowSnapshot.byDateKey[tomorrowKey]
        }
        let tomorrowDay = targetMorning
            ?? activeWindowSnapshot.visibleDays.first
        let tomorrowEntry = tomorrowDay.map {
            WakeRowActionResolver.makeEntry(activeDay: $0, overrideDateKeys: overrideDateKeys)
        }
        let allMorningEntries = activeWindowSnapshot.visibleDays
            .map { WakeRowActionResolver.makeEntry(activeDay: $0, overrideDateKeys: overrideDateKeys) }
        let morningcast = Array(
            MorningHomeSnapshot.morningcastEntries(
                from: allMorningEntries,
                currentDate: now,
                timeZone: timeZone
            )
            .prefix(MorningHomeSnapshot.maximumMorningcastCount)
        )

        return MorningHomeSnapshot(
            tomorrow: tomorrowEntry,
            weeklyFajrcast: fajrWindowCompactSnapshot(
                timeZone: timeZone
            ),
            morningcast: morningcast,
            permissionState: permissionSnapshot,
            contextFlags: MorningHomeContextFlag.flags(for: tomorrowDay?.resolvedDayContext ?? .standard)
        )
    }

    var currentHijriAdjustmentYear: Int {
        resolvedCurrentHijriYear()
    }

    var lastUpdatedText: String {
        guard let date = lastUpdated else { return "--" }
        return TimeFormatters.shortDateTime.string(from: date)
    }

    var deliveryReconciliationSummaryText: String {
        lastDeliveryReconciliationReport?.summaryText ?? "Not checked"
    }

    var deliveryDiagnosticsText: String {
        [
            lastDeliveryReconciliationReport?.diagnosticsText ?? "Delivery check: not checked",
            alarmDeliveryLedger.diagnosticsText()
        ].joined(separator: "\n")
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
        SurfaceDateLabelFormatter.dayLabel(for: date)
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
        wakeListDataProvider.hijriMonthStartPreview(
            for: month,
            hijriYear: currentHijriAdjustmentYear,
            timeZone: timeZone
        )
    }

    func hijriMonthStartPreview(for month: HijriMonth, hijriYear: Int, timeZone: TimeZone = .current) -> HijriMonthStartPreview? {
        wakeListDataProvider.hijriMonthStartPreview(
            for: month,
            hijriYear: hijriYear,
            timeZone: timeZone
        )
    }

    func acknowledgeHijriAdjustmentChanges() {
        hijriAdjustmentChangeStore.acknowledgeAll()
        hijriAdjustmentChanges = []
    }

    func currentHijriYearMonth(timeZone: TimeZone = .current, date: Date? = nil) -> HijriYearMonth? {
        wakeListDataProvider.currentHijriYearMonth(timeZone: timeZone, date: date ?? timeProvider.now())
    }

    func rollingHijriMonths(count: Int = 12, timeZone: TimeZone = .current, date: Date? = nil) -> [HijriYearMonth] {
        wakeListDataProvider.rollingHijriMonths(count: count, timeZone: timeZone, date: date ?? timeProvider.now())
    }

    func hasRecurringIslamicSchedules() -> Bool {
        alarmConfigStore.hasAnyRecurringIslamicSource()
    }

    func cachedMonthEntries(for key: HijriMonthKey) -> [ActiveAlarmDay]? {
        wakeListDataProvider.cachedMonthEntries(for: key)
    }

    func monthEntries(for key: HijriMonthKey, timeZone: TimeZone = .current) async -> [ActiveAlarmDay] {
        wakeListDataProvider.monthEntries(for: key, timeZone: timeZone)
    }

    func invalidateExpandedMonthSnapshots(reason: String? = nil) {
        wakeListDataProvider.invalidate(reason: reason)
        monthTagResultProvider.invalidate()
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
        return activeDayResolver.resolvedEntriesForActiveWindow(
            from: DateHelpers.startOfToday(in: timeZone, now: timeProvider.now()),
            limit: limit,
            timeZone: timeZone
        )
    }

    func provenance(for date: Date, timeZone: TimeZone = .current) -> [ResolvedScheduledDateProvenance] {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let cached = activeWindowSnapshot.byDateKey[key] {
            return cached.provenances
        }
        activeDayResolver.syncMorningPlanState()
        return activeDayResolver.mergedProvenances(for: date, timeZone: timeZone)
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

    func tagPreviewResult(
        for date: Date,
        overrideSelection: FastIntentSelection? = nil,
        defaultPrimaryIntent: FastPrimaryIntent? = nil,
        timeZone: TimeZone = .current
    ) -> TagComputationResult {
        guard usesLegacyContexts else { return .empty }
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if overrideSelection == nil,
           alarmConfigStore.provenance(for: date, timeZone: timeZone).isEmpty == false,
           let monthResult = monthTagResultProvider.shawwalMonthKey(for: date, timeZone: timeZone)
            .flatMap({ monthTagResultProvider.monthTagResults(for: $0, timeZone: timeZone)[key] }) {
            return monthResult
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

    private func fajrWindowDatasetKey(
        period: FajrWindowPeriod,
        timeZone: TimeZone
    ) -> FajrWindowDatasetKey {
        FajrWindowDatasetKey(
            revision: currentRevision,
            period: period,
            timeZoneIdentifier: timeZone.identifier
        )
    }

    private func loadedFajrWindowOverlaySeries(
        for period: FajrWindowPeriod,
        requestedOverlay: FajrWindowOverlay,
        timeZone: TimeZone
    ) -> [FajrWindowOverlaySeries] {
        guard usesLegacyContexts else { return [] }
        var overlays: [FajrWindowOverlaySeries] = []

        if let cachedFasting = fajrWindowOverlaySeriesCache[
            FajrWindowOverlayCacheKey(
                datasetKey: fajrWindowDatasetKey(period: period, timeZone: timeZone),
                overlay: .compareFasting
            )
        ], cachedFasting.isAvailable {
            overlays.append(cachedFasting)
        } else if requestedOverlay == .compareFasting,
                  let fasting = fajrWindowOverlaySeries(period: period, overlay: .compareFasting, timeZone: timeZone) {
            overlays.append(fasting)
        }

        if let cachedTahajjud = fajrWindowOverlaySeriesCache[
            FajrWindowOverlayCacheKey(
                datasetKey: fajrWindowDatasetKey(period: period, timeZone: timeZone),
                overlay: .compareTahajjud
            )
        ], cachedTahajjud.isAvailable {
            overlays.append(cachedTahajjud)
        } else if requestedOverlay == .compareTahajjud,
                  let tahajjud = fajrWindowOverlaySeries(period: period, overlay: .compareTahajjud, timeZone: timeZone) {
            overlays.append(tahajjud)
        }

        return overlays
    }

    private func activeDaysForFajrWindow(
        period: FajrWindowPeriod,
        timeZone: TimeZone
    ) -> [ActiveAlarmDay] {
        let count = period.dayCount
        if activeWindowSnapshot.visibleDays.count >= count {
            return Array(activeWindowSnapshot.visibleDays.prefix(count))
        }

        guard let coordinate = currentCoordinate() else {
            return Array(activeWindowSnapshot.visibleDays.prefix(count))
        }

        let resolvedEntries = activeDayResolver.resolvedEntriesForActiveWindow(
            from: DateHelpers.startOfToday(in: timeZone, now: timeProvider.now()),
            limit: count,
            timeZone: timeZone
        )

        return buildActiveWindowSnapshot(
            resolvedEntries: resolvedEntries,
            coordinate: coordinate,
            timeZone: timeZone,
            visibleHorizonDays: count,
            scheduledHorizonDays: count
        ).visibleDays
    }

    private func weeklyFajrcastAnchorDate(
        anchorDateKey: String?,
        timeZone: TimeZone
    ) -> Date {
        if let anchorDateKey,
           let anchorDate = DateHelpers.date(fromDayIdentifier: anchorDateKey, timeZone: timeZone) {
            return DateHelpers.startOfDay(anchorDate, in: timeZone)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let now = timeProvider.now()
        let today = DateHelpers.startOfDay(now, in: timeZone)
        let todayKey = DateHelpers.dayIdentifier(for: today, timeZone: timeZone)
        if let todayDay = activeWindowSnapshot.byDateKey[todayKey],
           now <= todayDay.schedule.wakeDate {
            return today
        }

        return calendar.date(byAdding: .day, value: 1, to: today) ?? today
    }

    private func activeDaysForWeeklyFajrcast(
        centeredOn selectedDate: Date,
        timeZone: TimeZone
    ) -> [ActiveAlarmDay] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let selectedStart = DateHelpers.startOfDay(selectedDate, in: timeZone)
        let windowStart = calendar.date(byAdding: .day, value: -3, to: selectedStart) ?? selectedStart

        guard let coordinate = currentCoordinate() else {
            let windowDates = DateHelpers.dates(
                startingFrom: windowStart,
                count: 7,
                calendar: calendar
            )
            let windowKeys = Set(windowDates.map { DateHelpers.dayIdentifier(for: $0, timeZone: timeZone) })
            return activeWindowSnapshot.visibleDays
                .filter { windowKeys.contains($0.dateKey) }
                .sorted { $0.date < $1.date }
        }

        let resolvedEntries = activeDayResolver.resolvedEntriesForActiveWindow(
            from: windowStart,
            limit: 7,
            timeZone: timeZone
        )

        return buildActiveWindowSnapshot(
            resolvedEntries: resolvedEntries,
            coordinate: coordinate,
            timeZone: timeZone,
            visibleHorizonDays: 7,
            scheduledHorizonDays: 7
        ).visibleDays
    }

    private func comparisonPreviewDay(
        for day: ActiveAlarmDay,
        overlay: FajrWindowOverlay,
        timeZone: TimeZone
    ) -> ActiveAlarmDay? {
        switch overlay {
        case .myWake, .compareSafe:
            return nil
        case .compareFasting:
            return previewComparisonDay(
                for: day,
                overrideSelection: FastIntentSelection(primaryIntent: .voluntary, secondaryTags: []),
                timeZone: timeZone
            )
        case .compareTahajjud:
            return nil
        }
    }

    private func previewComparisonDay(
        for day: ActiveAlarmDay,
        overrideSelection: FastIntentSelection,
        timeZone: TimeZone
    ) -> ActiveAlarmDay? {
        guard let coordinate = currentCoordinate() else { return nil }

        let tagResult = tagPreviewResult(
            for: day.date,
            overrideSelection: overrideSelection,
            defaultPrimaryIntent: day.provenances.defaultFastPrimaryIntent(),
            timeZone: timeZone
        )

        return activeDayResolver.resolveActiveDay(
            for: day.date,
            provenances: day.provenances,
            tagResult: tagResult,
            coordinate: coordinate,
            settings: settingsStore.settings,
            timeZone: timeZone
        )
    }

    private func clearFajrWindowCaches() {
        fajrWindowDatasetCache.removeAll(keepingCapacity: true)
        fajrWindowOverlaySeriesCache.removeAll(keepingCapacity: true)
    }

    func recurringRuleStatus(_ rule: RecurringIslamicRule) -> RecurringRuleStatus {
        let isAdded = alarmConfigStore.hasRecurringIslamicSource(rule)
        return RecurringRuleStatus(rule: rule, isAdded: isAdded, detailText: nil)
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
        startDate: Date? = nil,
        timeZone: TimeZone = .current
    ) async -> AddScheduledDatesResult {
        let result = alarmConfigStore.addIslamicQuickAdd(kind, startDate: startDate ?? timeProvider.now(), timeZone: timeZone)
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
        startDate: Date? = nil,
        timeZone: TimeZone = .current
    ) async -> AddScheduledDatesResult {
        let result = alarmConfigStore.addAshuraQuickAdd(pattern, startDate: startDate ?? timeProvider.now(), timeZone: timeZone)
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
        startDate: Date? = nil,
        timeZone: TimeZone = .current
    ) async -> Bool {
        let added = alarmConfigStore.addRecurringIslamicSource(rule, startDate: startDate ?? timeProvider.now(), timeZone: timeZone)
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
        refreshCoordinator.requestRefresh(reason: reason, force: force)
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
        ActiveDayResolver.sourceSummary(from: provenances)
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
        let now = timeProvider.now()
        if Self.shouldReuseScheduleWindow(
            reason: reason,
            lastScheduledDate: settingsStore.settings.lastScheduledDate,
            snapshot: activeWindowSnapshot,
            now: now,
            timeZone: .current,
            requiresDailyWindow: morningPlanStore.usesDailyActivation
        ) {
            guard usesLegacyContexts else {
                await reconcileCachedScheduleWindow(reason: reason, now: now)
                await refreshPermissionSummary()
                return
            }
            if activeTagSelectionRevision != fastTagStore.currentRevision {
                if !activeWindowSnapshot.visibleDays.isEmpty {
                    retagActiveWindow(reason: "tag_selection_revision_mismatch")
                    await refreshPermissionSummary()
                    return
                }
                await refreshSchedules(force: true, reason: reason)
                return
            }
            let adjustedVisibleDays = monthTagResultProvider.applyShawwalTagResults(
                to: activeWindowSnapshot.visibleDays,
                timeZone: .current
            )
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
                        tagSelectionRevision: activeTagSelectionRevision,
                        wakeRuleSignature: ScheduleCacheStore.wakeRuleSignature(for: alarmConfigStore.defaults),
                        calculationSignature: ScheduleCacheStore.calculationSignature(for: settingsStore.settings)
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

    private func reconcileCachedScheduleWindow(
        reason: ScheduleRefreshReason,
        now: Date
    ) async {
        let settings = settingsStore.settings
        let mode = await effectiveSchedulingChannel()
        EventTimelineLog.shared.record(
            category: "schedule",
            message: "reconcileCachedScheduleWindow(reason=\(reason.diagnosticLabel))"
        )

        let reconciliation = await SchedulingReconciler.reconcile(
            snapshot: activeWindowSnapshot,
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
        lastUpdated = now

        await runAlarmPipelineDiagnostics(
            snapshot: activeWindowSnapshot,
            settings: settings,
            mode: schedulingMode,
            schedulingStatus: reconciliation.statusText,
            now: now,
            reason: reason.diagnosticLabel
        )

        settingsStore.update { draft in
            draft.lastScheduledDate = now
            draft.lastSchedulingMode = schedulingMode
        }
        cacheStore.save(
            ScheduleCacheStore.Cache(
                lastScheduledDate: settingsStore.settings.lastScheduledDate,
                lastUpdated: lastUpdated,
                schedulingMode: schedulingMode,
                schedules: schedules,
                activeWindowSnapshot: activeWindowSnapshot,
                tagSelectionRevision: activeTagSelectionRevision,
                wakeRuleSignature: ScheduleCacheStore.wakeRuleSignature(for: alarmConfigStore.defaults),
                calculationSignature: ScheduleCacheStore.calculationSignature(for: settingsStore.settings)
            )
        )
    }

    func refreshSchedules(force: Bool, reason: ScheduleRefreshReason? = nil) async {
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

        let now = timeProvider.now()
        let startDate = DateHelpers.startOfToday(in: timeZone, now: now)
        let mode = await effectiveSchedulingChannel()
        let resolvedEntries = PerformanceTrace.measure("active-window.resolve", metadata: "limit=\(visibleActiveDayLimit)") {
            activeDayResolver.resolvedEntriesForActiveWindow(
                from: startDate,
                limit: visibleActiveDayLimit,
                timeZone: timeZone
            )
        }
        let input = makeActiveWindowBuildInput(
            resolvedEntries: resolvedEntries,
            coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
            timeZone: timeZone,
            visibleHorizonDays: visibleActiveDayLimit,
            scheduledHorizonDays: scheduledActiveDayLimit
        )
        let result = await PerformanceTrace.measureAsync(
            "schedule.compute-window",
            metadata: "days=\(resolvedEntries.count)"
        ) {
            activeWindowSnapshotBuilder.build(input: input)
        }
        let adjustedSnapshot: ActiveAlarmWindowSnapshot
        if usesLegacyContexts {
            let adjustedVisibleDays = monthTagResultProvider.applyShawwalTagResults(
                to: result.visibleDays,
                timeZone: timeZone
            )
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
        } else {
            adjustedSnapshot = result
        }
        debugValidateActiveWindow(adjustedSnapshot, resolvedEntries: resolvedEntries)

        let refreshCompletedAt = timeProvider.now()
        activeWindowSnapshot = adjustedSnapshot
        schedules = adjustedSnapshot.visibleDays.map(\.schedule)
        lastUpdated = refreshCompletedAt
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
        await runAlarmPipelineDiagnostics(
            snapshot: adjustedSnapshot,
            settings: settings,
            mode: schedulingMode,
            schedulingStatus: reconciliation.statusText,
            now: refreshCompletedAt,
            reason: reason?.diagnosticLabel ?? "refreshSchedules"
        )

        settingsStore.update { draft in
            draft.lastScheduledDate = refreshCompletedAt
            draft.lastSchedulingMode = schedulingMode
        }

        activeTagSelectionRevision = usesLegacyContexts ? fastTagStore.currentRevision : -1
        cacheStore.save(
            ScheduleCacheStore.Cache(
                lastScheduledDate: settingsStore.settings.lastScheduledDate,
                lastUpdated: lastUpdated,
                schedulingMode: schedulingMode,
                schedules: schedules,
                activeWindowSnapshot: activeWindowSnapshot,
                tagSelectionRevision: activeTagSelectionRevision,
                wakeRuleSignature: ScheduleCacheStore.wakeRuleSignature(for: alarmConfigStore.defaults),
                calculationSignature: ScheduleCacheStore.calculationSignature(for: settingsStore.settings)
            )
        )

        await refreshPermissionSummary()
    }

    func rescheduleDay(_ date: Date, preferCached: Bool = true) async {
        let timeZone = TimeZone.current
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)

        activeDayResolver.syncMorningPlanState()

        guard activeDayResolver.dateParticipatesInWakePlan(normalizedDate, timeZone: timeZone) else {
            await cancelDay(normalizedDate)
            recordCancellationLedger(dateKey: key, reason: "day_no_longer_participates", timestamp: timeProvider.now())
            activeWindowSnapshot = activeWindowSnapshot.removing(dateKey: key, generatedAt: timeProvider.now())
            schedules = activeWindowSnapshot.visibleDays.map(\.schedule)
            lastUpdated = timeProvider.now()
            activeTagSelectionRevision = usesLegacyContexts ? fastTagStore.currentRevision : -1
            cacheStore.save(
                ScheduleCacheStore.Cache(
                    lastScheduledDate: settingsStore.settings.lastScheduledDate,
                    lastUpdated: lastUpdated,
                    schedulingMode: schedulingMode,
                    schedules: schedules,
                    activeWindowSnapshot: activeWindowSnapshot,
                    tagSelectionRevision: activeTagSelectionRevision,
                    wakeRuleSignature: ScheduleCacheStore.wakeRuleSignature(for: alarmConfigStore.defaults),
                    calculationSignature: ScheduleCacheStore.calculationSignature(for: settingsStore.settings)
                )
            )
            updateBootstrapState()
            return
        }

        guard let updatedDay = activeDayResolver.buildActiveDayIfNeeded(
            for: normalizedDate,
            timeZone: timeZone,
            preferCached: preferCached
        ) else {
            await refreshSchedules(force: true)
            return
        }

        if activeWindowSnapshot.byDateKey[key] == nil {
            await refreshSchedules(force: true)
            return
        }

        activeWindowSnapshot = activeWindowSnapshot.replacing(updatedDay, generatedAt: timeProvider.now())
        schedules = activeWindowSnapshot.visibleDays.map(\.schedule)

        let settings = settingsStore.settings
        let canUseAlarmKit = await alarmKitAvailableAndAuthorized()
        if activeWindowSnapshot.scheduledDays.contains(where: { $0.dateKey == key }) {
            Logging.diagnostics.debug(
                "[toggle] scheduleDay \(key, privacy: .public) suhoor=\(updatedDay.effectiveConfig.suhoorEnabled, privacy: .public) reminder=\(updatedDay.effectiveConfig.reminderEnabled, privacy: .public) fajr=\(updatedDay.effectiveConfig.fajrEnabled, privacy: .public)"
            )
            _ = await alarmScheduler.scheduleDay(
                day: updatedDay,
                settings: settings,
                canUseAlarmKit: canUseAlarmKit
            )
        } else {
            Logging.diagnostics.debug("[toggle] cancelDay \(key, privacy: .public) via schedule window")
            await alarmScheduler.cancelDay(day: updatedDay)
        }

        lastUpdated = timeProvider.now()
        activeTagSelectionRevision = usesLegacyContexts ? fastTagStore.currentRevision : -1
        cacheStore.save(
            ScheduleCacheStore.Cache(
                lastScheduledDate: settingsStore.settings.lastScheduledDate,
                lastUpdated: lastUpdated,
                schedulingMode: schedulingMode,
                schedules: schedules,
                activeWindowSnapshot: activeWindowSnapshot,
                tagSelectionRevision: activeTagSelectionRevision,
                wakeRuleSignature: ScheduleCacheStore.wakeRuleSignature(for: alarmConfigStore.defaults),
                calculationSignature: ScheduleCacheStore.calculationSignature(for: settingsStore.settings)
            )
        )
        updateBootstrapState()
    }

    @discardableResult
    func commitHeroWakeAdjustment(for date: Date, wakeTime: Date, timeZone: TimeZone = .current) async -> Bool {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        guard let currentDay = activeDay(for: normalizedDate, timeZone: timeZone) else {
            return false
        }

        let window = currentDay.decisionLog.prayerWindow
        guard let fajrEnd = window.fajrEnd else {
            return false
        }

        let adjustmentWindow = heroWakeAdjustmentWindow(
            for: currentDay,
            proposedWakeTime: wakeTime,
            fallbackFajrEnd: fajrEnd,
            timeZone: timeZone
        )
        let clampedWakeTime = min(max(wakeTime, adjustmentWindow.minTime), adjustmentWindow.maxTime)
        guard clampedWakeTime >= adjustmentWindow.minTime, clampedWakeTime <= adjustmentWindow.maxTime else {
            return false
        }

        let minutesFromMidnight = Self.persistedHeroWakeAdjustmentMinutes(
            clampedWakeTime: clampedWakeTime,
            date: normalizedDate,
            minTime: adjustmentWindow.minTime,
            maxTime: adjustmentWindow.maxTime,
            timeZone: timeZone
        )
        alarmConfigStore.updateOverride(for: normalizedDate, timeZone: timeZone) { override in
            override.skipDay = false
            override.suhoorEnabled = true
            override.wakeStateOverride = .fixedWake
            override.wakeAnchorTypeOverride = nil
            override.wakeDeltaOverrideMinutes = nil
            override.fixedWakeTimeOverrideMinutesFromMidnight = minutesFromMidnight
            override.suhoorOffsetOverrideMinutes = nil
            override.suhoorTimeOverrideMinutesFromMidnight = nil
            override.bypassLatestWakeCap = true
        }

        await rescheduleDay(normalizedDate, preferCached: false)
        return true
    }

    @discardableResult
    func selectHeroWakeMode(for date: Date, mode: QuickWakeMode, timeZone: TimeZone = .current) async -> Bool {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        guard let day = activeDay(for: normalizedDate, timeZone: timeZone) else {
            return false
        }
        let isRamadan = Self.isRamadanAlarmDetailDay(day)

        alarmConfigStore.updateOverride(for: normalizedDate, timeZone: timeZone) { override in
            WakeStateSelectionResolver.apply(mode, to: &override)
            if mode == .fast {
                override.earlyWakePurposeOverride = .fast
                if isRamadan {
                    override.alarmDetailFastTypeOverride = nil
                    Self.applyAlarmDetailAudioPlan(.wakeAlarmAndFajrAdhan, to: &override, locksFajrAdhan: true)
                }
            }
            if mode == .fajr, isRamadan {
                override.fajrEnabled = true
            }
            if mode == .quiet, isRamadan {
                override.skipDay = false
                override.suhoorEnabled = false
                override.reminderEnabled = false
                override.fajrEnabled = true
                override.iftarEnabled = nil
                override.alarmDetailAudioPlanOverride = .fajrAdhan
            }
        }

        await rescheduleDay(normalizedDate, preferCached: false)
        return true
    }

    @discardableResult
    func selectAlarmDetailEarlyPurpose(
        for date: Date,
        purpose: EarlyWakePurposeOverride,
        timeZone: TimeZone = .current
    ) async -> Bool {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        guard let day = activeDay(for: normalizedDate, timeZone: timeZone) else {
            return false
        }
        let isRamadan = Self.isRamadanAlarmDetailDay(day)
        let normalizedPurpose: EarlyWakePurposeOverride = purpose == .tahajjud ? .tahajjud : .fast

        alarmConfigStore.updateOverride(for: normalizedDate, timeZone: timeZone) { override in
            WakeStateSelectionResolver.apply(.fast, to: &override)
            override.earlyWakePurposeOverride = isRamadan ? .fast : normalizedPurpose
            override.alarmDetailFastTypeOverride = normalizedPurpose == .fast ? override.alarmDetailFastTypeOverride : nil
            override.tahajjudRefinement = normalizedPurpose == .tahajjud
            Self.applyAlarmDetailAudioPlan(.wakeAlarmAndFajrAdhan, to: &override, locksFajrAdhan: isRamadan)
        }

        await rescheduleDay(normalizedDate, preferCached: false)
        return true
    }

    @discardableResult
    func selectAlarmDetailFastType(
        for date: Date,
        fastType: AlarmDetailFastTypeOverride?,
        timeZone: TimeZone = .current
    ) async -> Bool {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        guard let day = activeDay(for: normalizedDate, timeZone: timeZone),
              !Self.isRamadanAlarmDetailDay(day) else {
            return false
        }
        let normalizedFastType = fastType == .voluntary && Self.hasAlarmDetailFastingOpportunities(day)
            ? nil
            : fastType

        alarmConfigStore.updateOverride(for: normalizedDate, timeZone: timeZone) { override in
            WakeStateSelectionResolver.apply(.fast, to: &override)
            override.earlyWakePurposeOverride = .fast
            override.alarmDetailFastTypeOverride = normalizedFastType
            override.tahajjudRefinement = false
            Self.applyAlarmDetailAudioPlan(override.alarmDetailAudioPlanOverride ?? .wakeAlarmAndFajrAdhan, to: &override)
        }

        await rescheduleDay(normalizedDate, preferCached: false)
        return true
    }

    @discardableResult
    func selectAlarmDetailAudioPlan(
        for date: Date,
        audioPlan: AlarmDetailAudioPlan,
        timeZone: TimeZone = .current
    ) async -> Bool {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        guard let day = activeDay(for: normalizedDate, timeZone: timeZone) else {
            return false
        }
        let isRamadan = Self.isRamadanAlarmDetailDay(day)
        let mode = WakeStateSelectionResolver.selectedMode(for: day)
        guard mode != .quiet else { return false }

        alarmConfigStore.updateOverride(for: normalizedDate, timeZone: timeZone) { override in
            let resolvedPlan = isRamadan && audioPlan == .wakeAlarm ? .wakeAlarmAndFajrAdhan : audioPlan
            Self.applyAlarmDetailAudioPlan(resolvedPlan, to: &override, locksFajrAdhan: isRamadan)
        }

        await rescheduleDay(normalizedDate, preferCached: false)
        return true
    }

    @discardableResult
    func setAlarmDetailFajrAdhanAfterWake(
        for date: Date,
        isEnabled: Bool,
        timeZone: TimeZone = .current
    ) async -> Bool {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        guard let day = activeDay(for: normalizedDate, timeZone: timeZone),
              !Self.isRamadanAlarmDetailDay(day),
              WakeStateSelectionResolver.selectedMode(for: day) == .fast else {
            return false
        }

        alarmConfigStore.updateOverride(for: normalizedDate, timeZone: timeZone) { override in
            WakeStateSelectionResolver.apply(.fast, to: &override)
            override.earlyWakePurposeOverride = .fast
            override.tahajjudRefinement = false
            Self.applyAlarmDetailAudioPlan(isEnabled ? .wakeAlarmAndFajrAdhan : .wakeAlarm, to: &override)
        }

        await rescheduleDay(normalizedDate, preferCached: false)
        return true
    }

    @discardableResult
    func resetAlarmDetailOverride(for date: Date, timeZone: TimeZone = .current) async -> Bool {
        let normalizedDate = DateHelpers.startOfDay(date, in: timeZone)
        alarmConfigStore.removeOverride(for: normalizedDate, timeZone: timeZone)
        await rescheduleDay(normalizedDate, preferCached: false)
        return true
    }

    private static func applyAlarmDetailAudioPlan(
        _ plan: AlarmDetailAudioPlan,
        to override: inout DailyAlarmOverride,
        locksFajrAdhan: Bool = false
    ) {
        let resolvedPlan = locksFajrAdhan && plan == .wakeAlarm ? .wakeAlarmAndFajrAdhan : plan
        override.alarmDetailAudioPlanOverride = resolvedPlan

        switch resolvedPlan {
        case .fajrAdhan:
            override.suhoorEnabled = true
            override.reminderEnabled = false
            override.fajrEnabled = locksFajrAdhan
        case .wakeAlarm:
            override.suhoorEnabled = true
            override.reminderEnabled = true
            override.fajrEnabled = locksFajrAdhan
        case .wakeAlarmAndFajrAdhan:
            override.suhoorEnabled = true
            override.reminderEnabled = true
            override.fajrEnabled = true
        }
    }

    private static func isRamadanAlarmDetailDay(_ day: ActiveAlarmDay) -> Bool {
        day.isImplicitRamadan || day.resolvedDayContext.supportingTags.contains(.ramadan)
    }

    private static func hasAlarmDetailFastingOpportunities(_ day: ActiveAlarmDay) -> Bool {
        let tags = Set(day.resolvedDayContext.supportingTags)
        return tags.contains(.arafah)
            || tags.contains(.ashura)
            || tags.contains(.dhulHijjahFirstNine)
            || tags.contains(.whiteDays)
            || tags.contains(.shawwalSix)
            || tags.contains(.mondayThursday)
            || day.tagResult.computedSecondaryTags.isEmpty == false
    }

    private static func persistedHeroWakeAdjustmentMinutes(
        clampedWakeTime: Date,
        date: Date,
        minTime: Date,
        maxTime: Date,
        timeZone: TimeZone
    ) -> Int {
        var minutes = DateHelpers.minutesFromMidnight(for: clampedWakeTime, timeZone: timeZone)
        var resolvedWakeTime = DateHelpers.dateFromMidnight(for: date, minutes: minutes, timeZone: timeZone)

        while resolvedWakeTime < minTime, minutes < 1439 {
            minutes += 1
            resolvedWakeTime = DateHelpers.dateFromMidnight(for: date, minutes: minutes, timeZone: timeZone)
        }

        while resolvedWakeTime > maxTime, minutes > 0 {
            minutes -= 1
            resolvedWakeTime = DateHelpers.dateFromMidnight(for: date, minutes: minutes, timeZone: timeZone)
        }

        return minutes
    }

    private struct HeroWakeAdjustmentWindow {
        let minTime: Date
        let maxTime: Date
    }

    private func heroWakeAdjustmentWindow(
        for day: ActiveAlarmDay,
        proposedWakeTime: Date,
        fallbackFajrEnd: Date,
        timeZone: TimeZone
    ) -> HeroWakeAdjustmentWindow {
        let prayerWindow = day.decisionLog.prayerWindow
        let resolvedWakeState = MorningWakeResolutionService.resolve(for: day, timeZone: timeZone)
        if resolvedWakeState.underlyingWakeMode == .earlyWorship,
           proposedWakeTime <= prayerWindow.fajrStart,
           let minTime = resolvedWakeState.wakeBoundaryResolution.leftBoundaryTime,
           let maxTime = resolvedWakeState.wakeBoundaryResolution.rightBoundaryTime {
            return HeroWakeAdjustmentWindow(minTime: minTime, maxTime: maxTime)
        }

        return HeroWakeAdjustmentWindow(minTime: prayerWindow.fajrStart, maxTime: fallbackFajrEnd)
    }

    private func isEarlyWorshipMorning(_ day: ActiveAlarmDay) -> Bool {
        WakeStateSelectionResolver.isEarlyWorshipMorning(day)
    }

    func schedule(for date: Date) -> DaySchedule? {
        activeDayResolver.scheduleAndConfig(for: date, builder: dayScheduleBuilder)?.schedule
    }

    func defaultWakeValidation(timeZone: TimeZone = .current) -> DefaultWakeRuleValidationResult? {
        guard let coordinate = currentCoordinate() else { return nil }
        return DefaultWakeRuleValidator.validate(
            startDate: timeProvider.now(),
            timeZone: timeZone,
            coordinate: coordinate,
            settings: settingsStore.settings,
            defaultConfig: alarmConfigStore.defaults,
            calculator: calculator
        )
    }

    func scheduleTomorrowActivation() async -> ActivationScheduleResult {
        let timeZone = TimeZone.current
        let tomorrow = DateHelpers.startOfTomorrow(in: timeZone, now: timeProvider.now())
        guard let result = activeDayResolver.scheduleAndConfig(for: tomorrow, builder: dayScheduleBuilder, timeZone: timeZone) else {
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
            day: activeWindowSnapshot.byDateKey[result.schedule.id]
                ?? ActiveAlarmDay(
                    date: result.schedule.date,
                    dateKey: result.schedule.id,
                    schedule: result.schedule,
                    effectiveConfig: result.config,
                    provenances: [],
                    isImplicitRamadan: false,
                    isExplicitOneOff: false,
                    tagResult: .empty,
                    primaryDisplay: result.config.primaryDisplay(schedule: result.schedule),
                    sourceSummaryText: "",
                    resolvedDayContext: .standard,
                    scheduledEvents: RuleDecisionLog.compatibilityFallback(
                        dateKey: result.schedule.id,
                        schedule: result.schedule,
                        resolvedDayContext: .standard,
                        primaryDisplay: result.config.primaryDisplay(schedule: result.schedule)
                    ).materializedEvents
                ),
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
        guard let day = dayForCancellation(on: date) else { return }
        let key = DateHelpers.dayIdentifier(for: day.date, timeZone: .current)
        Logging.diagnostics.debug("[toggle] cancelDay \(key, privacy: .public) via cancelDay()")
        await alarmScheduler.cancelDay(day: day)
        recordCancellationLedger(dateKey: key, reason: "cancelDay", timestamp: timeProvider.now())
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
        refreshCoordinator.cancelAll()
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
        let today = DateHelpers.startOfToday(in: timeZone, now: timeProvider.now())
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
        let now = timeProvider.now()
        return adjustedHijriCalendar.adjustedComponents(for: now, timeZone: timeZone)?.hijriYear
            ?? fallbackCalendar.component(.year, from: now)
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

    private func prayerLocationDisplayText() -> String {
        switch settingsStore.settings.locationMode {
        case .auto:
            if !locationService.locationName.isEmpty {
                return locationService.locationName
            }
            if locationService.lastLocation != nil {
                return "Current location"
            }
            return "Location unavailable"
        case .fixed:
            return fixedLocationDisplayName() ?? (
                settingsStore.settings.fixedLocation == nil
                    ? "Choose location"
                    : Strings.Settings.locationCustom
            )
        }
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

    private func retagActiveWindow(reason: String = "tag_selection_changed") {
        guard usesLegacyContexts else { return }
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
            activeDayResolver.replacingTagResult(day, with: tagResults[day.dateKey] ?? .empty, timeZone: timeZone)
        }
        let adjustedVisibleDays = monthTagResultProvider.applyShawwalTagResults(
            to: visibleDays,
            timeZone: timeZone
        )
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
                tagSelectionRevision: activeTagSelectionRevision,
                wakeRuleSignature: ScheduleCacheStore.wakeRuleSignature(for: alarmConfigStore.defaults),
                calculationSignature: ScheduleCacheStore.calculationSignature(for: settingsStore.settings)
            )
        )
    }

    private func buildActiveDayIfNeeded(
        for date: Date,
        timeZone: TimeZone = .current,
        preferCached: Bool = true
    ) -> ActiveAlarmDay? {
        activeDayResolver.buildActiveDayIfNeeded(
            for: date,
            timeZone: timeZone,
            preferCached: preferCached
        )
    }

    private func buildActiveWindowSnapshot(
        resolvedEntries: [ResolvedScheduledDateEntry],
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        visibleHorizonDays: Int,
        scheduledHorizonDays: Int
    ) -> ActiveAlarmWindowSnapshot {
        activeWindowSnapshotBuilder.build(
            input: makeActiveWindowBuildInput(
                resolvedEntries: resolvedEntries,
                coordinate: coordinate,
                timeZone: timeZone,
                visibleHorizonDays: visibleHorizonDays,
                scheduledHorizonDays: scheduledHorizonDays
            )
        )
    }

    private func makeActiveWindowBuildInput(
        resolvedEntries: [ResolvedScheduledDateEntry],
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        visibleHorizonDays: Int,
        scheduledHorizonDays: Int
    ) -> ActiveWindowBuildInput {
        let provenancesByDateKey = Dictionary(uniqueKeysWithValues: resolvedEntries.map { ($0.dateKey, $0.provenances) })
        let stateSnapshot = activeDayResolver.buildMorningStateSnapshot(
            settings: settingsStore.settings,
            coordinate: coordinate,
            timeZone: timeZone,
            locationDescription: prayerLocationDisplayText(),
            provenancesByDateKey: provenancesByDateKey
        )
        return ActiveWindowBuildInput(
            stateSnapshot: stateSnapshot,
            resolvedEntries: resolvedEntries,
            visibleHorizonDays: visibleHorizonDays,
            scheduledHorizonDays: scheduledHorizonDays,
            usesLegacyContexts: usesLegacyContexts
        )
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

    private func updateBootstrapState() {
        #if DEBUG
        if UITestFixtureConfigurator.isMorningHeroFajrAdjusterFixtureRequested,
           settingsStore.settings.isConfigured,
           !activeWindowSnapshot.visibleDays.isEmpty {
            bootstrapState = .home
            return
        }
        #endif

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

    private func runAlarmPipelineDiagnostics(
        snapshot: ActiveAlarmWindowSnapshot,
        settings: AppSettings,
        mode: SchedulingMode,
        schedulingStatus: String,
        now: Date,
        reason: String
    ) async {
        let report = AlarmPipelineDiagnostics.report(
            snapshot: snapshot,
            settings: settings,
            mode: mode,
            now: now,
            pendingNotifications: await notificationScheduler.pendingDeliveries(),
            pendingAlarms: pendingAlarmKitDeliveries(for: mode)
        )
        lastDeliveryReconciliationReport = report.deliveryReport

        EventTimelineLog.shared.record(
            category: "schedule-diagnostics",
            message: "status=\(schedulingStatus) mode=\(mode.rawValue) expectedDeliveries=\(report.expectedDeliveryCount) futureVisibleEvents=\(report.futureVisibleEventCount) deliveryCheck=\(report.deliveryReport.summaryText)"
        )

        recordAlarmDeliveryLedger(
            report: report.deliveryReport,
            schedulingStatus: schedulingStatus,
            reason: reason,
            timestamp: now
        )

        guard report.shouldWarn else { return }

        Logging.scheduler.error("Alarm pipeline warning: \(report.deliveryReport.summaryText)")
        EventTimelineLog.shared.record(
            category: "schedule-diagnostics",
            message: "warning=\(report.warningCode)"
        )
    }

    private func pendingAlarmKitDeliveries(for mode: SchedulingMode) -> [ScheduledAlarmDelivery] {
        guard mode == .alarmKit else { return [] }
        #if targetEnvironment(simulator)
        return []
        #else
        if #available(iOS 26.0, *), let alarmKitScheduler {
            return alarmKitScheduler.scheduledAlarmDeliveries()
        }
        return []
        #endif
    }

    private func recordAlarmDeliveryLedger(
        report: DeliveryReconciliationReport,
        schedulingStatus: String,
        reason: String,
        timestamp: Date
    ) {
        let permissionMode = permissionSummary.isEmpty ? schedulingMode.rawValue : permissionSummary
        let wakeRuleSignature = ScheduleCacheStore.wakeRuleSignature(for: alarmConfigStore.defaults)
        let missingNotifications = Set(report.missingNotificationIdentifiers)
        let mismatchedNotifications = Set(report.mismatchedNotificationIdentifiers)
        let missingAlarms = Set(report.missingAlarmIdentifiers)
        let mismatchedAlarms = Set(report.mismatchedAlarmIdentifiers)
        let summaryEntry = AlarmDeliveryLedgerEntry(
            timestamp: timestamp,
            action: .reconciliation,
            dateKey: nil,
            eventID: nil,
            eventType: nil,
            deliveryKind: nil,
            fireDate: nil,
            channel: report.mode.rawValue,
            platformIdentifier: nil,
            permissionMode: permissionMode,
            wakeRuleSignature: wakeRuleSignature,
            refreshReason: reason,
            result: report.summaryText,
            message: "expected=\(report.expectedDeliveryCount) pendingNotifications=\(report.pendingNotificationCount) pendingAlarms=\(report.pendingAlarmCount)"
        )
        let entries = [summaryEntry] + report.expectedDeliveries.map { delivery in
            let platformIdentifier: String
            let result: String
            switch delivery.channel {
            case .notification:
                platformIdentifier = delivery.notificationIdentifier
                if missingNotifications.contains(delivery.notificationIdentifier) {
                    result = "missing_pending"
                } else if mismatchedNotifications.contains(delivery.notificationIdentifier) {
                    result = "time_mismatch"
                } else {
                    result = schedulingStatus
                }
            case .alarmKit:
                platformIdentifier = delivery.alarmIdentifier.uuidString
                if missingAlarms.contains(delivery.alarmIdentifier) {
                    result = "missing_pending"
                } else if mismatchedAlarms.contains(delivery.alarmIdentifier) {
                    result = "time_mismatch"
                } else {
                    result = schedulingStatus
                }
            }

            return AlarmDeliveryLedgerEntry(
                timestamp: timestamp,
                action: .scheduleDecision,
                dateKey: delivery.dateKey,
                eventID: delivery.eventID,
                eventType: delivery.eventType.rawValue,
                deliveryKind: delivery.deliveryKind.rawValue,
                fireDate: delivery.fireDate,
                channel: delivery.channel.rawValue,
                platformIdentifier: platformIdentifier,
                permissionMode: permissionMode,
                wakeRuleSignature: wakeRuleSignature,
                refreshReason: reason,
                result: result,
                message: report.hasWarnings ? report.summaryText : nil
            )
        }
        alarmDeliveryLedger.record(entries)
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

    nonisolated static func shouldReuseScheduleWindow(
        reason: ScheduleRefreshReason,
        lastScheduledDate: Date?,
        snapshot: ActiveAlarmWindowSnapshot,
        now: Date = Date(),
        timeZone: TimeZone = .current,
        requiresDailyWindow: Bool = false
    ) -> Bool {
        func calendar() -> Calendar {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            return calendar
        }

        func isSameDay(_ lhs: Date?, _ rhs: Date) -> Bool {
            guard let lhs else { return false }
            return calendar().isDate(lhs, inSameDayAs: rhs)
        }

        func dayIdentifier(for date: Date) -> String {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = timeZone
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }

        switch reason {
        case .foreground, .appLaunch:
            break
        default:
            return false
        }
        guard isSameDay(lastScheduledDate, now) else {
            return false
        }
        guard !snapshot.visibleDays.isEmpty else {
            return false
        }
        guard isSameDay(snapshot.generatedAt, now) else {
            return false
        }
        guard requiresDailyWindow else {
            return true
        }

        let resolvedCalendar = calendar()
        let today = resolvedCalendar.startOfDay(for: now)
        guard let tomorrow = resolvedCalendar.date(byAdding: .day, value: 1, to: today) else {
            return false
        }
        let requiredDateKeys = [
            dayIdentifier(for: today),
            dayIdentifier(for: tomorrow)
        ]
        let visibleDateKeys = Set(snapshot.visibleDays.map(\.dateKey))
        return requiredDateKeys.allSatisfy { visibleDateKeys.contains($0) }
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
        recordCancellationLedger(dateKey: nil, reason: "cancelAll", timestamp: timeProvider.now())
    }

    private func recordCancellationLedger(
        dateKey: String?,
        reason: String,
        timestamp: Date
    ) {
        alarmDeliveryLedger.record(
            AlarmDeliveryLedgerEntry(
                timestamp: timestamp,
                action: .cancelDecision,
                dateKey: dateKey,
                eventID: nil,
                eventType: nil,
                deliveryKind: nil,
                fireDate: nil,
                channel: schedulingMode.rawValue,
                platformIdentifier: nil,
                permissionMode: permissionSummary.isEmpty ? schedulingMode.rawValue : permissionSummary,
                wakeRuleSignature: ScheduleCacheStore.wakeRuleSignature(for: alarmConfigStore.defaults),
                refreshReason: reason,
                result: "cancelled"
            )
        )
    }

    private func dayForCancellation(on date: Date) -> ActiveAlarmDay? {
        let timeZone = TimeZone.current
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let existing = activeWindowSnapshot.byDateKey[key] {
            return existing
        }
        guard let result = activeDayResolver.scheduleAndConfig(for: date, builder: dayScheduleBuilder, timeZone: timeZone) else {
            return nil
        }
        return ActiveAlarmDay(
            date: result.schedule.date,
            dateKey: result.schedule.id,
            schedule: result.schedule,
            effectiveConfig: result.config,
            provenances: [],
            isImplicitRamadan: false,
            isExplicitOneOff: false,
            tagResult: .empty,
            primaryDisplay: result.config.primaryDisplay(schedule: result.schedule),
            sourceSummaryText: "",
            resolvedDayContext: .standard,
            scheduledEvents: RuleDecisionLog.compatibilityFallback(
                dateKey: result.schedule.id,
                schedule: result.schedule,
                resolvedDayContext: .standard,
                primaryDisplay: result.config.primaryDisplay(schedule: result.schedule)
            ).materializedEvents
        )
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

struct NextWakeEventSummary: Equatable, Sendable {
    let day: ActiveAlarmDay
    let event: ScheduledEvent
    let priority: Int

    var relationText: String {
        switch event.type {
        case .wakeAlarm:
            return ProductSurfacePresentation.wakeExplanationText(
                for: day,
                hasDayOverride: day.effectiveConfig.wakeRuleWasOverridden
            )
        case .wakeReminder:
            return "Reminder before the main wake."
        case .wakeFollowUp:
            return "Follow-up after the main wake."
        case .fajrBoundaryNotice:
            return event.fajrStartBehavior == .takeoverIfUnresolvedOtherwiseCue
                ? "Fajr-start checkpoint with takeover if the wake is still active."
                : "At the Fajr boundary."
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
        case .clockTime:
            return "Fixed wake."
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

struct AlarmPipelineDiagnosticsReport: Equatable {
    let expectedDeliveryCount: Int
    let futureVisibleEventCount: Int
    let deliveryReport: DeliveryReconciliationReport

    var shouldWarn: Bool {
        (expectedDeliveryCount == 0 && futureVisibleEventCount > 0) || deliveryReport.hasWarnings
    }

    var warningCode: String {
        if deliveryReport.hasWarnings {
            return "delivery_reconciliation_mismatch"
        }
        return "no_deliverable_future_events"
    }
}

enum AlarmPipelineDiagnostics {
    static func report(
        snapshot: ActiveAlarmWindowSnapshot,
        settings: AppSettings,
        mode: SchedulingMode,
        now: Date,
        pendingNotifications: [PendingNotificationDelivery] = [],
        pendingAlarms: [ScheduledAlarmDelivery] = []
    ) -> AlarmPipelineDiagnosticsReport {
        guard settings.isEnabled, mode != .none else {
            let deliveryReport = DeliveryReconciliation.report(
                mode: mode,
                generatedAt: now,
                expectedDeliveries: [],
                pendingNotifications: pendingNotifications,
                pendingAlarms: pendingAlarms
            )
            return AlarmPipelineDiagnosticsReport(
                expectedDeliveryCount: 0,
                futureVisibleEventCount: 0,
                deliveryReport: deliveryReport
            )
        }

        let futureVisibleEvents = snapshot.visibleDays
            .flatMap(\.scheduledEvents)
            .filter { $0.fireDate > now }

        let deliveryReport = DeliveryReconciliation.report(
            snapshot: snapshot,
            settings: settings,
            mode: mode,
            now: now,
            pendingNotifications: pendingNotifications,
            pendingAlarms: pendingAlarms
        )

        return AlarmPipelineDiagnosticsReport(
            expectedDeliveryCount: deliveryReport.expectedDeliveryCount,
            futureVisibleEventCount: futureVisibleEvents.count,
            deliveryReport: deliveryReport
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

    func replacing(_ day: ActiveAlarmDay, generatedAt: Date = Date()) -> ActiveAlarmWindowSnapshot {
        var updatedVisible = visibleDays
        if let index = updatedVisible.firstIndex(where: { $0.dateKey == day.dateKey }) {
            updatedVisible[index] = day
        } else {
            updatedVisible.append(day)
            updatedVisible.sort { $0.date < $1.date }
            updatedVisible = Array(updatedVisible.prefix(visibleHorizonDays))
        }
        return ActiveAlarmWindowSnapshot(
            generatedAt: generatedAt,
            visibleDays: updatedVisible,
            scheduledDays: Array(updatedVisible.prefix(scheduledHorizonDays)),
            visibleHorizonDays: visibleHorizonDays,
            scheduledHorizonDays: scheduledHorizonDays
        )
    }

    func removing(dateKey: String, generatedAt: Date = Date()) -> ActiveAlarmWindowSnapshot {
        let updatedVisible = visibleDays.filter { $0.dateKey != dateKey }
        return ActiveAlarmWindowSnapshot(
            generatedAt: generatedAt,
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

private struct ScheduleLocationSnapshot: Sendable {
    let latitude: Double
    let longitude: Double
}

private final class MonthTagResultLookup {
    var handler: ((Date, String, TagComputationResult, TimeZone) -> TagComputationResult)?

    func resolve(
        date: Date,
        dateKey: String,
        fallback: TagComputationResult,
        timeZone: TimeZone
    ) -> TagComputationResult {
        handler?(date, dateKey, fallback, timeZone) ?? fallback
    }
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
            let config = ActiveDayResolver.effectiveConfig(
                for: schedule.date,
                settings: settings,
                defaultConfig: defaults,
                overridesByDay: overridesByDay,
                additionalDefaultsActive: false,
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
