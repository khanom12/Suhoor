import Foundation
import Combine

@MainActor
final class AlarmConfigStore: ObservableObject {
    @Published var defaults: DefaultAlarmConfig {
        didSet { persistDefaults() }
    }

    @Published var overridesByDay: [String: DailyAlarmOverride] {
        didSet { persistOverrides() }
    }

    private let defaultsKey = "Suhoor.DefaultAlarmConfig"
    private let overridesKey = "Suhoor.DailyAlarmOverrides"
    private let migrationKey = "Suhoor.AlarmConfigMigrationVersion"
    private let defaultsStore: UserDefaults
    private let scheduledDateSourceStore: ScheduledDateSourceStore
    private let suppressedScheduledDateStore: SuppressedScheduledDateStore
    private let scheduledDateSourceResolver: ScheduledDateSourceResolver
    private let islamicQuickAddGenerator: IslamicQuickAddGenerator

    init(defaultsStore: UserDefaults = .standard, legacySettings: AppSettings? = nil) {
        self.defaultsStore = defaultsStore

        let storedDefaultsData = defaultsStore.data(forKey: defaultsKey)
        let defaultsValue: DefaultAlarmConfig
        if let data = storedDefaultsData,
           let decoded = try? JSONDecoder().decode(DefaultAlarmConfig.self, from: data) {
            defaultsValue = decoded
        } else {
            defaultsValue = .default
        }

        let overridesValue: [String: DailyAlarmOverride]
        if let data = defaultsStore.data(forKey: overridesKey),
           let decoded = try? JSONDecoder().decode([String: DailyAlarmOverride].self, from: data) {
            overridesValue = decoded
        } else {
            overridesValue = [:]
        }

        let shouldMigrateLegacySourceData = storedDefaultsData != nil
            || defaultsStore.data(forKey: "Suhoor.AppSettings") != nil
        let adjustedHijriCalendar = AdjustedHijriCalendar(
            calendarService: HijriCalendarService(
                adjustmentStore: HijriMonthAdjustmentStore(defaults: defaultsStore)
            )
        )
        self.scheduledDateSourceStore = ScheduledDateSourceStore(
            defaults: defaultsStore,
            legacyDefaults: defaultsValue,
            shouldMigrateLegacyData: shouldMigrateLegacySourceData
        )
        self.suppressedScheduledDateStore = SuppressedScheduledDateStore(
            defaults: defaultsStore,
            legacyDeletedDateKeys: defaultsValue.deletedDates,
            shouldMigrateLegacyData: shouldMigrateLegacySourceData
        )
        self.scheduledDateSourceResolver = ScheduledDateSourceResolver(
            sourceStore: scheduledDateSourceStore,
            suppressedDateStore: suppressedScheduledDateStore,
            adjustedHijriCalendar: adjustedHijriCalendar
        )
        self.islamicQuickAddGenerator = IslamicQuickAddGenerator(adjustedHijriCalendar: adjustedHijriCalendar)
        self.defaults = defaultsValue
        self.overridesByDay = overridesValue

        performMigrationIfNeeded(legacySettings: legacySettings)
    }

    func override(for date: Date, timeZone: TimeZone = .current) -> DailyAlarmOverride? {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        return overridesByDay[key]
    }

    func updateOverride(for date: Date, timeZone: TimeZone = .current, update: (inout DailyAlarmOverride) -> Void) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        var current = overridesByDay[key] ?? DailyAlarmOverride(date: date, timeZone: timeZone)
        update(&current)
        overridesByDay[key] = current
    }

    func removeOverride(for date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        overridesByDay.removeValue(forKey: key)
    }

    func isDefaultsActive(on date: Date, timeZone: TimeZone = .current) -> Bool {
        scheduledDateSourceResolver.isActive(on: date, timeZone: timeZone)
    }

    func isWithinActiveRange(on date: Date, timeZone: TimeZone = .current) -> Bool {
        isDefaultsActive(on: date, timeZone: timeZone)
    }

    func isDateInActiveRange(on date: Date, timeZone: TimeZone = .current) -> Bool {
        isDefaultsActive(on: date, timeZone: timeZone)
    }

    func isExtraOneOffDate(on date: Date, timeZone: TimeZone = .current) -> Bool {
        isExplicitSingleDaySource(on: date, timeZone: timeZone)
    }

    func addExtraOneOffDate(_ date: Date, timeZone: TimeZone = .current) {
        addSingleDaySource(date, timeZone: timeZone)
    }

    func removeExtraOneOffDate(_ date: Date, timeZone: TimeZone = .current) {
        deleteExplicitSources(on: date, timeZone: timeZone)
    }

    func isDeletedDate(on date: Date, timeZone: TimeZone = .current) -> Bool {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        return suppressedScheduledDateStore.contains(key)
    }

    func addDeletedDate(_ date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        suppressedScheduledDateStore.insert(key)
    }

    func removeDeletedDate(_ date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        suppressedScheduledDateStore.remove(key)
    }

    func resolvedScheduledEntries(
        from startDate: Date = DateHelpers.startOfToday(),
        limit: Int = 60,
        timeZone: TimeZone = .current
    ) -> [ResolvedScheduledDateEntry] {
        scheduledDateSourceResolver.resolvedEntries(from: startDate, limit: limit, timeZone: timeZone)
    }

    func provenance(for date: Date, timeZone: TimeZone = .current) -> [ResolvedScheduledDateProvenance] {
        scheduledDateSourceResolver.provenance(for: date, timeZone: timeZone)
    }

    func isExplicitSingleDaySource(on date: Date, timeZone: TimeZone = .current) -> Bool {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        return scheduledDateSourceStore.sources.contains { source in
            guard source.isEnabled else { return false }
            guard source.origin.isExplicitOneOff else { return false }
            guard case .singleDay(let singleDay) = source.kind else { return false }
            return singleDay.dateKey == key
        }
    }

    func addSingleDaySource(
        _ date: Date,
        origin: ScheduledDateSourceOrigin = .manualSingleDay,
        groupID: UUID? = nil,
        timeZone: TimeZone = .current
    ) {
        objectWillChange.send()
        let normalized = DateHelpers.startOfDay(date, in: timeZone)
        let key = DateHelpers.dayIdentifier(for: normalized, timeZone: timeZone)
        guard scheduledDateSourceStore.sources.contains(where: { source in
            guard case .singleDay(let singleDay) = source.kind else { return false }
            return singleDay.dateKey == key && source.groupID == groupID && source.origin == origin
        }) == false else {
            suppressedScheduledDateStore.remove(key)
            return
        }

        scheduledDateSourceStore.add(
            ScheduledDateSource(
                id: UUID(),
                kind: .singleDay(SingleDaySource(dateKey: key, date: normalized)),
                createdAt: Date(),
                isEnabled: true,
                origin: origin,
                groupID: groupID
            )
        )
        suppressedScheduledDateStore.remove(key)
    }

    func addGregorianRangeSource(startDate: Date, endDate: Date, timeZone: TimeZone = .current) {
        objectWillChange.send()
        let range = GregorianRangeSource(startDate: startDate, endDate: endDate, timeZone: timeZone)
        scheduledDateSourceStore.add(
            ScheduledDateSource(
                id: UUID(),
                kind: .gregorianRange(range),
                createdAt: Date(),
                isEnabled: true,
                origin: .manualGregorianRange,
                groupID: nil
            )
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        for date in DateHelpers.dates(from: range.startDate, to: range.endDate, calendar: calendar) {
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            suppressedScheduledDateStore.remove(key)
        }
    }

    func addRecurringIslamicSource(_ rule: RecurringIslamicRule, startDate: Date = Date(), timeZone: TimeZone = .current) {
        objectWillChange.send()
        let normalized = DateHelpers.startOfDay(startDate, in: timeZone)
        scheduledDateSourceStore.add(
            ScheduledDateSource(
                id: UUID(),
                kind: .recurringIslamic(RecurringIslamicSource(rule: rule, startDate: normalized)),
                createdAt: Date(),
                isEnabled: true,
                origin: .recurringIslamic(rule),
                groupID: nil
            )
        )
    }

    @discardableResult
    func addIslamicQuickAdd(
        _ kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> [Date] {
        objectWillChange.send()
        let dates = islamicQuickAddGenerator.dates(for: kind, startDate: startDate, timeZone: timeZone)
        guard !dates.isEmpty else { return [] }

        let groupID = dates.count > 1 ? UUID() : nil
        for date in dates {
            addSingleDaySource(date, origin: .islamicQuickAdd(kind), groupID: groupID, timeZone: timeZone)
        }
        return dates
    }

    func previewIslamicQuickAdd(
        _ kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> IslamicQuickAddPreview? {
        islamicQuickAddGenerator.preview(for: kind, startDate: startDate, timeZone: timeZone)
    }

    func deleteExplicitSources(on date: Date, timeZone: TimeZone = .current) {
        objectWillChange.send()
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        scheduledDateSourceStore.removeAll { source in
            guard source.origin.isExplicitOneOff else { return false }
            guard case .singleDay(let singleDay) = source.kind else { return false }
            return singleDay.dateKey == key
        }
    }

    func suppressScheduledDate(_ date: Date, timeZone: TimeZone = .current) {
        objectWillChange.send()
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        suppressedScheduledDateStore.insert(key)
    }

    func stopSeries(for provenance: ResolvedScheduledDateProvenance) {
        objectWillChange.send()
        if let groupID = provenance.groupID {
            scheduledDateSourceStore.remove(groupID: groupID)
        } else {
            scheduledDateSourceStore.remove(id: provenance.sourceID)
        }
    }

    func resetScheduledDateSources() {
        objectWillChange.send()
        scheduledDateSourceStore.reset()
        suppressedScheduledDateStore.reset()
    }

    func effectiveConfig(
        for date: Date,
        ruleSummary: RuleSummary,
        settings: AppSettings,
        timeZone: TimeZone = .current,
        additionalDefaultsActive: Bool = false
    ) -> EffectiveDailyConfig {
        let defaultsActive = isDefaultsActive(on: date, timeZone: timeZone) || additionalDefaultsActive
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        let override = overridesByDay[key]
        let skipDay = override?.skipDay ?? false

        let baseSuhoorEnabled = defaultsActive ? defaults.suhoorEnabledDefault : false
        let baseReminderEnabled = defaultsActive ? defaults.reminderEnabledDefault : false
        let baseFajrEnabled = defaultsActive ? defaults.fajrEnabledDefault : false

        var suhoorEnabled = override?.suhoorEnabled ?? baseSuhoorEnabled
        var reminderEnabled = override?.reminderEnabled ?? baseReminderEnabled
        var fajrEnabled = override?.fajrEnabled ?? baseFajrEnabled

        let reminderOffset = override?.reminderOffsetOverrideMinutes ?? defaults.defaultReminderMinutesBeforeFajr
        let reminderTimeMode: ReminderTimeMode
        if override?.reminderTimeOverrideMinutesFromMidnight != nil {
            reminderTimeMode = .fixedTime
        } else if override?.reminderOffsetOverrideMinutes != nil {
            reminderTimeMode = .beforeFajr
        } else {
            reminderTimeMode = defaults.defaultReminderTimeMode
        }
        let suhoorOffset = ruleSummary.finalOffsetMinutes
        let suhoorTimeOverride = override?.suhoorTimeOverrideMinutesFromMidnight
        let reminderTimeOverride = override?.reminderTimeOverrideMinutesFromMidnight

        if skipDay || ruleSummary.disabledForDay {
            suhoorEnabled = false
            reminderEnabled = false
            fajrEnabled = false
        }

        let fajrSoundChoice = override?.fajrSoundOverride ?? settings.atFajrSoundSelectionGlobal
        let hasOverrides = override?.hasOverrides ?? false

        return EffectiveDailyConfig(
            date: date,
            defaultsActive: defaultsActive,
            skipDay: skipDay,
            suhoorEnabled: suhoorEnabled,
            reminderEnabled: reminderEnabled,
            fajrEnabled: fajrEnabled,
            suhoorTimeMode: defaults.defaultSuhoorTimeMode,
            suhoorOffsetMinutes: suhoorOffset,
            reminderTimeMode: reminderTimeMode,
            reminderMinutesBeforeFajr: reminderOffset,
            reminderFixedTimeMinutes: defaults.defaultReminderFixedTimeMinutes,
            suhoorTimeOverrideMinutesFromMidnight: suhoorTimeOverride,
            reminderTimeOverrideMinutesFromMidnight: reminderTimeOverride,
            fajrSoundChoice: fajrSoundChoice,
            hasOverrides: hasOverrides
        )
    }

    var hasAnyEnabledDefaults: Bool {
        defaults.suhoorEnabledDefault || defaults.reminderEnabledDefault || defaults.fajrEnabledDefault
    }

    func hasAnyEnabledOverride() -> Bool {
        overridesByDay.values.contains { override in
            if override.skipDay { return false }
            return override.suhoorEnabled == true
                || override.reminderEnabled == true
                || override.fajrEnabled == true
        }
    }

    private func performMigrationIfNeeded(legacySettings: AppSettings?) {
        let currentVersion = defaultsStore.integer(forKey: migrationKey)
        guard currentVersion < 1 else { return }
        guard let legacySettings else {
            defaultsStore.set(1, forKey: migrationKey)
            return
        }

        let hasStoredDefaults = defaultsStore.data(forKey: defaultsKey) != nil
        let hasStoredOverrides = defaultsStore.data(forKey: overridesKey) != nil
        guard !hasStoredDefaults && !hasStoredOverrides else {
            defaultsStore.set(1, forKey: migrationKey)
            return
        }

        defaults = DefaultAlarmConfig(
            suhoorEnabledDefault: legacySettings.isEnabled,
            reminderEnabledDefault: legacySettings.reminderEnabledGlobal,
            fajrEnabledDefault: legacySettings.atFajrEnabledGlobal,
            defaultSuhoorTimeMode: .relativeToFajrMinusMinutes,
            defaultSuhoorOffsetMinutes: legacySettings.baseWakeOffsetMinutes,
            defaultReminderTimeMode: .beforeFajr,
            defaultReminderMinutesBeforeFajr: max(legacySettings.reminderMinutesBeforeFajrGlobal, 10),
            defaultReminderFixedTimeMinutes: 0,
            activationMode: .alwaysOn,
            activeStartDate: nil,
            activeEndDate: nil,
            scheduleWindowDays: legacySettings.schedulePreviewDays
        )

        if !legacySettings.perDayExceptions.isEmpty {
            var migrated: [String: DailyAlarmOverride] = [:]
            for (key, exception) in legacySettings.perDayExceptions {
                guard let date = dateFromKey(key) else { continue }
                var override = DailyAlarmOverride(date: date)
                override.skipDay = exception.disabledForDay
                override.suhoorOffsetOverrideMinutes = exception.wakeOffsetOverrideMinutes
                override.reminderEnabled = exception.reminderEnabledOverride
                override.reminderOffsetOverrideMinutes = exception.reminderMinutesOverride
                override.fajrEnabled = exception.atFajrEnabledOverride
                override.fajrSoundOverride = exception.atFajrSoundOverride
                migrated[key] = override
            }
            overridesByDay = migrated
        }

        defaultsStore.set(1, forKey: migrationKey)
    }

    private func dateFromKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }

    private func persistDefaults() {
        if let data = try? JSONEncoder().encode(defaults) {
            defaultsStore.set(data, forKey: defaultsKey)
        }
    }

    private func persistOverrides() {
        if let data = try? JSONEncoder().encode(overridesByDay) {
            defaultsStore.set(data, forKey: overridesKey)
        }
    }
}
