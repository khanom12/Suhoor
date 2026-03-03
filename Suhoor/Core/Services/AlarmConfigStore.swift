import Foundation
import Combine

@MainActor
final class AlarmConfigStore: ObservableObject {
    private static let latestMigrationVersion = 3

    @Published var defaults: DefaultAlarmConfig {
        didSet {
            guard !isPersistenceSuspended else { return }
            persistDefaults()
        }
    }

    @Published var overridesByDay: [String: DailyAlarmOverride] {
        didSet {
            guard !isPersistenceSuspended else { return }
            persistOverrides()
        }
    }

    private let defaultsKey = "Suhoor.DefaultAlarmConfig"
    private let overridesKey = "Suhoor.DailyAlarmOverrides"
    private let migrationKey = "Suhoor.AlarmConfigMigrationVersion"
    private let defaultsStore: UserDefaults
    private let scheduledDateSourceStore: ScheduledDateSourceStore
    private let suppressedScheduledDateStore: SuppressedScheduledDateStore
    private let scheduledDateSourceResolver: ScheduledDateSourceResolver
    private let islamicQuickAddGenerator: IslamicQuickAddGenerator
    private let adjustedHijriCalendar: AdjustedHijriCalendar
    private let defaultsPersistence = DebouncedPersistenceController(
        label: "com.suhoor.app.alarm-config-defaults",
        delay: 0.2
    )
    private let overridesPersistence = DebouncedPersistenceController(
        label: "com.suhoor.app.alarm-config-overrides",
        delay: 0.2
    )
    private var isPersistenceSuspended = false

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
        self.adjustedHijriCalendar = adjustedHijriCalendar
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
        if current.hasOverrides {
            overridesByDay[key] = current
        } else {
            overridesByDay.removeValue(forKey: key)
        }
    }

    func removeOverride(for date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        overridesByDay.removeValue(forKey: key)
    }

    func setDayEnabled(_ isEnabled: Bool, for date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        var current = overridesByDay[key] ?? DailyAlarmOverride(date: date, timeZone: timeZone)

        if isEnabled {
            current.skipDay = false

            let defaultsActive = isDefaultsActive(on: date, timeZone: timeZone)
            let suhoorEnabled = current.suhoorEnabled ?? (defaultsActive ? defaults.suhoorEnabledDefault : false)
            let reminderEnabled = current.reminderEnabled ?? (defaultsActive ? defaults.reminderEnabledDefault : false)
            let fajrEnabled = current.fajrEnabled ?? (defaultsActive ? defaults.fajrEnabledDefault : false)
            let iftarEnabled = current.iftarEnabled ?? (defaultsActive ? defaults.iftarEnabledDefault : false)

            if !suhoorEnabled && !reminderEnabled && !fajrEnabled && !iftarEnabled {
                current.suhoorEnabled = nil
                current.reminderEnabled = nil
                current.fajrEnabled = nil
                current.iftarEnabled = nil
            }
        } else {
            current.skipDay = true
        }

        if current.hasOverrides {
            overridesByDay[key] = current
        } else {
            overridesByDay.removeValue(forKey: key)
        }
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
        return suppressedScheduledDateStore.hasAnySuppression(key)
    }

    func addDeletedDate(_ date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        suppressedScheduledDateStore.insert(key, scope: .global)
    }

    func removeDeletedDate(_ date: Date, timeZone: TimeZone = .current) {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        suppressedScheduledDateStore.remove(key)
    }

    func moveSuppression(from oldDate: Date, to newDate: Date, timeZone: TimeZone = .current) {
        let oldKey = DateHelpers.dayIdentifier(for: oldDate, timeZone: timeZone)
        let newKey = DateHelpers.dayIdentifier(for: newDate, timeZone: timeZone)
        suppressedScheduledDateStore.moveEntry(from: oldKey, to: newKey)
    }

    func resolvedScheduledEntries(
        from startDate: Date = DateHelpers.startOfToday(),
        limit: Int = 60,
        timeZone: TimeZone = .current
    ) -> [ResolvedScheduledDateEntry] {
        scheduledDateSourceResolver.resolvedEntries(from: startDate, limit: limit, timeZone: timeZone)
    }

    func resolvedScheduledEntries(
        in interval: DateInterval,
        timeZone: TimeZone = .current
    ) -> [ResolvedScheduledDateEntry] {
        scheduledDateSourceResolver.resolvedEntries(in: interval, timeZone: timeZone)
    }

    func resolvedScheduledEntries(
        forHijriMonth key: HijriYearMonth,
        timeZone: TimeZone = .current
    ) -> [ResolvedScheduledDateEntry] {
        scheduledDateSourceResolver.resolvedEntries(forHijriMonth: key, timeZone: timeZone)
    }

    func provenance(for date: Date, timeZone: TimeZone = .current) -> [ResolvedScheduledDateProvenance] {
        scheduledDateSourceResolver.provenance(for: date, timeZone: timeZone)
    }

    func provenanceByDate(
        for dates: [Date],
        timeZone: TimeZone = .current
    ) -> [String: [ResolvedScheduledDateProvenance]] {
        scheduledDateSourceResolver.provenanceByDate(for: dates, timeZone: timeZone)
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

    func addHijriSingleDaySource(
        _ hijriSource: HijriSingleDaySource,
        origin: ScheduledDateSourceOrigin,
        groupID: UUID? = nil,
        timeZone: TimeZone = .current
    ) {
        objectWillChange.send()
        guard scheduledDateSourceStore.sources.contains(where: { source in
            guard case .hijriSingleDay(let existing) = source.kind else { return false }
            return existing == hijriSource && source.groupID == groupID && source.origin == origin
        }) == false else {
            if let resolved = adjustedHijriCalendar.gregorianDate(
                for: HijriYearMonth(hijriYear: hijriSource.hijriYear, month: hijriSource.month),
                dayOfMonth: hijriSource.day,
                timeZone: timeZone
            ) {
                let key = DateHelpers.dayIdentifier(for: resolved, timeZone: timeZone)
                suppressedScheduledDateStore.remove(key)
            }
            return
        }

        scheduledDateSourceStore.add(
            ScheduledDateSource(
                id: UUID(),
                kind: .hijriSingleDay(hijriSource),
                createdAt: Date(),
                isEnabled: true,
                origin: origin,
                groupID: groupID
            )
        )

        if let resolved = adjustedHijriCalendar.gregorianDate(
            for: HijriYearMonth(hijriYear: hijriSource.hijriYear, month: hijriSource.month),
            dayOfMonth: hijriSource.day,
            timeZone: timeZone
        ) {
            let key = DateHelpers.dayIdentifier(for: resolved, timeZone: timeZone)
            suppressedScheduledDateStore.remove(key)
        }
    }

    func hijriSingleDaySources(for key: HijriYearMonth) -> [ScheduledDateSource] {
        scheduledDateSourceStore.sources.filter { source in
            guard source.isEnabled else { return false }
            guard case .hijriSingleDay(let hijri) = source.kind else { return false }
            return hijri.hijriYear == key.hijriYear && hijri.month == key.month
        }
    }

    func previewGregorianRangeAdd(
        startDate: Date,
        endDate: Date,
        timeZone: TimeZone = .current
    ) -> AddScheduledDatesResult {
        let range = GregorianRangeSource(startDate: startDate, endDate: endDate, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dates = DateHelpers.dates(from: range.startDate, to: range.endDate, calendar: calendar)
        let provenanceByKey = scheduledDateSourceResolver.provenanceByDate(for: dates, timeZone: timeZone)

        var addedDates: [Date] = []
        var skippedDates: [Date] = []
        for date in dates {
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            if (provenanceByKey[key] ?? []).isEmpty {
                addedDates.append(date)
            } else {
                skippedDates.append(date)
            }
        }

        return AddScheduledDatesResult(addedDates: addedDates, skippedActiveDates: skippedDates)
    }

    @discardableResult
    func addGregorianRangeSource(
        startDate: Date,
        endDate: Date,
        timeZone: TimeZone = .current
    ) -> AddScheduledDatesResult {
        let preview = previewGregorianRangeAdd(startDate: startDate, endDate: endDate, timeZone: timeZone)
        guard !preview.addedDates.isEmpty else { return preview }

        objectWillChange.send()
        let ranges = contiguousRanges(from: preview.addedDates, timeZone: timeZone)
        let groupID = ranges.count > 1 ? UUID() : nil

        for range in ranges {
            scheduledDateSourceStore.add(
                ScheduledDateSource(
                    id: UUID(),
                    kind: .gregorianRange(range),
                    createdAt: Date(),
                    isEnabled: true,
                    origin: .manualGregorianRange,
                    groupID: groupID
                )
            )
        }

        for date in preview.addedDates {
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            suppressedScheduledDateStore.remove(key)
        }
        return preview
    }

    func hasRecurringIslamicSource(_ rule: RecurringIslamicRule) -> Bool {
        scheduledDateSourceStore.sources.contains { source in
            guard source.isEnabled else { return false }
            guard case .recurringIslamic(let recurring) = source.kind else { return false }
            return recurring.rule == rule
        }
    }

    func hasAnyRecurringIslamicSource() -> Bool {
        scheduledDateSourceStore.sources.contains { source in
            guard source.isEnabled else { return false }
            guard case .recurringIslamic = source.kind else { return false }
            return true
        }
    }

    @discardableResult
    func addRecurringIslamicSource(
        _ rule: RecurringIslamicRule,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> Bool {
        guard !hasRecurringIslamicSource(rule) else { return false }
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
        return true
    }

    @discardableResult
    func addIslamicQuickAdd(
        _ kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> AddScheduledDatesResult {
        let availability = islamicQuickAddAvailability(kind, startDate: startDate, timeZone: timeZone)
        guard !availability.addResult.addedDates.isEmpty else { return availability.addResult }

        objectWillChange.send()
        let dates = availability.addResult.addedDates
        let groupID = dates.count > 1 ? UUID() : nil
        for date in dates {
            if kind.isHijriBased,
               let components = adjustedHijriCalendar.adjustedComponents(for: date, timeZone: timeZone) {
                let hijriSource = HijriSingleDaySource(
                    hijriYear: components.hijriYear,
                    month: components.month,
                    day: components.day
                )
                addHijriSingleDaySource(
                    hijriSource,
                    origin: .islamicQuickAdd(kind),
                    groupID: groupID,
                    timeZone: timeZone
                )
            } else {
                addSingleDaySource(date, origin: .islamicQuickAdd(kind), groupID: groupID, timeZone: timeZone)
            }
        }
        return availability.addResult
    }

    func previewIslamicQuickAdd(
        _ kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> IslamicQuickAddPreview? {
        islamicQuickAddGenerator.preview(for: kind, startDate: startDate, timeZone: timeZone)
    }

    func previewAshuraQuickAdd(
        _ pattern: AshuraQuickAddPattern,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> AshuraQuickAddPreview? {
        islamicQuickAddGenerator.previewAshuraQuickAdd(for: pattern, startDate: startDate, timeZone: timeZone)
    }

    func recommendedAshuraQuickAddPattern(
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> AshuraQuickAddPattern {
        islamicQuickAddGenerator.recommendedAshuraPattern(startDate: startDate, timeZone: timeZone)
    }

    func islamicQuickAddAvailability(
        _ kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> IslamicQuickAddAvailability {
        let dates = islamicQuickAddGenerator.dates(for: kind, startDate: startDate, timeZone: timeZone)
        let preview = dates.isEmpty ? nil : islamicQuickAddGenerator.preview(for: kind, startDate: startDate, timeZone: timeZone)
        let provenanceByKey = scheduledDateSourceResolver.provenanceByDate(for: dates, timeZone: timeZone)

        var addedDates: [Date] = []
        var skippedDates: [Date] = []
        for date in dates {
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            if (provenanceByKey[key] ?? []).isEmpty {
                addedDates.append(date)
            } else {
                skippedDates.append(date)
            }
        }

        let addResult = AddScheduledDatesResult(addedDates: addedDates, skippedActiveDates: skippedDates)
        let reasonText: String?
        if preview == nil {
            reasonText = Strings.AddSchedule.previewUnavailable
        } else if addResult.addedDates.isEmpty {
            reasonText = Strings.AddSchedule.allMatchingDatesActive
        } else if !addResult.skippedActiveDates.isEmpty {
            reasonText = "\(addResult.skippedActiveDates.count) date\(addResult.skippedActiveDates.count == 1 ? "" : "s") already active."
        } else {
            reasonText = nil
        }

        return IslamicQuickAddAvailability(
            kind: kind,
            preview: preview,
            addResult: addResult,
            reasonText: reasonText
        )
    }

    func ashuraQuickAddAvailability(
        _ pattern: AshuraQuickAddPattern,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> AshuraQuickAddAvailability {
        let preview = previewAshuraQuickAdd(pattern, startDate: startDate, timeZone: timeZone)
        let dates = preview?.dates ?? []
        let provenanceByKey = scheduledDateSourceResolver.provenanceByDate(for: dates, timeZone: timeZone)

        var addedDates: [Date] = []
        var skippedDates: [Date] = []
        for date in dates {
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            if (provenanceByKey[key] ?? []).isEmpty {
                addedDates.append(date)
            } else {
                skippedDates.append(date)
            }
        }

        let addResult = AddScheduledDatesResult(addedDates: addedDates, skippedActiveDates: skippedDates)
        let reasonText: String?
        if preview == nil {
            reasonText = Strings.AddSchedule.previewUnavailable
        } else if addResult.addedDates.isEmpty {
            reasonText = Strings.AddSchedule.allMatchingDatesActive
        } else if !addResult.skippedActiveDates.isEmpty {
            reasonText = "\(addResult.skippedActiveDates.count) date\(addResult.skippedActiveDates.count == 1 ? "" : "s") already active."
        } else {
            reasonText = nil
        }

        return AshuraQuickAddAvailability(
            pattern: pattern,
            preview: preview,
            addResult: addResult,
            reasonText: reasonText,
            isRecommended: pattern == recommendedAshuraQuickAddPattern(startDate: startDate, timeZone: timeZone)
        )
    }

    @discardableResult
    func addAshuraQuickAdd(
        _ pattern: AshuraQuickAddPattern,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> AddScheduledDatesResult {
        let availability = ashuraQuickAddAvailability(pattern, startDate: startDate, timeZone: timeZone)
        guard !availability.addResult.addedDates.isEmpty else { return availability.addResult }

        objectWillChange.send()
        let dates = availability.addResult.addedDates
        let groupID = dates.count > 1 ? UUID() : nil
        for date in dates {
            if let components = adjustedHijriCalendar.adjustedComponents(for: date, timeZone: timeZone) {
                let hijriSource = HijriSingleDaySource(
                    hijriYear: components.hijriYear,
                    month: components.month,
                    day: components.day
                )
                addHijriSingleDaySource(
                    hijriSource,
                    origin: .islamicQuickAdd(.nextAshura),
                    groupID: groupID,
                    timeZone: timeZone
                )
            } else {
                addSingleDaySource(date, origin: .islamicQuickAdd(.nextAshura), groupID: groupID, timeZone: timeZone)
            }
        }
        return availability.addResult
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

    func suppressScheduledDate(
        _ date: Date,
        scope: SuppressionScope = .global,
        timeZone: TimeZone = .current
    ) {
        objectWillChange.send()
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        suppressedScheduledDateStore.insert(key, scope: scope)
    }

    func stopSeries(for provenance: ResolvedScheduledDateProvenance) {
        objectWillChange.send()
        if let groupID = provenance.groupID {
            scheduledDateSourceStore.remove(groupID: groupID)
        } else {
            scheduledDateSourceStore.remove(id: provenance.sourceID)
        }
        suppressedScheduledDateStore.clearScopes(for: provenance)
    }

    func clearSuppressionScopes(for provenance: ResolvedScheduledDateProvenance) {
        objectWillChange.send()
        suppressedScheduledDateStore.clearScopes(for: provenance)
    }

    func resetScheduledDateSources() {
        objectWillChange.send()
        scheduledDateSourceStore.reset()
        suppressedScheduledDateStore.reset()
    }

    private func contiguousRanges(
        from dates: [Date],
        timeZone: TimeZone
    ) -> [GregorianRangeSource] {
        guard !dates.isEmpty else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let sortedDates = dates.sorted()
        var ranges: [GregorianRangeSource] = []
        var currentStart = sortedDates[0]
        var currentEnd = sortedDates[0]

        for date in sortedDates.dropFirst() {
            let expectedNext = calendar.date(byAdding: .day, value: 1, to: currentEnd) ?? currentEnd
            if calendar.isDate(date, inSameDayAs: expectedNext) {
                currentEnd = date
                continue
            }

            ranges.append(GregorianRangeSource(startDate: currentStart, endDate: currentEnd, timeZone: timeZone))
            currentStart = date
            currentEnd = date
        }

        ranges.append(GregorianRangeSource(startDate: currentStart, endDate: currentEnd, timeZone: timeZone))
        return ranges
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
        let baseIftarEnabled = defaultsActive ? defaults.iftarEnabledDefault : false

        var suhoorEnabled = override?.suhoorEnabled
            ?? (override?.hasSuhoorCustomization == true ? true : baseSuhoorEnabled)
        var reminderEnabled = override?.reminderEnabled
            ?? (override?.hasReminderCustomization == true ? true : baseReminderEnabled)
        var fajrEnabled = override?.fajrEnabled
            ?? (override?.hasFajrCustomization == true ? true : baseFajrEnabled)
        var iftarEnabled = override?.iftarEnabled
            ?? (override?.hasIftarCustomization == true ? true : baseIftarEnabled)

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
            iftarEnabled = false
        }

        let fajrSoundChoice = override?.fajrSoundOverride ?? settings.atFajrSoundSelectionGlobal
        let iftarDelivery = (override?.iftarDeliveryOverride ?? defaults.defaultIftarDelivery).normalized()
        let iftarSoundChoice = override?.iftarSoundOverride ?? defaults.defaultIftarSoundChoice
        let hasOverrides = override?.hasOverrides ?? false

        return EffectiveDailyConfig(
            date: date,
            defaultsActive: defaultsActive,
            skipDay: skipDay,
            suhoorEnabled: suhoorEnabled,
            reminderEnabled: reminderEnabled,
            fajrEnabled: fajrEnabled,
            iftarEnabled: iftarEnabled,
            suhoorTimeMode: defaults.defaultSuhoorTimeMode,
            suhoorOffsetMinutes: suhoorOffset,
            reminderTimeMode: reminderTimeMode,
            reminderMinutesBeforeFajr: reminderOffset,
            reminderFixedTimeMinutes: defaults.defaultReminderFixedTimeMinutes,
            suhoorTimeOverrideMinutesFromMidnight: suhoorTimeOverride,
            reminderTimeOverrideMinutesFromMidnight: reminderTimeOverride,
            fajrSoundChoice: fajrSoundChoice,
            iftarDelivery: iftarDelivery,
            iftarSoundChoice: iftarSoundChoice,
            hasOverrides: hasOverrides
        )
    }

    var hasAnyEnabledDefaults: Bool {
        defaults.suhoorEnabledDefault || defaults.reminderEnabledDefault || defaults.fajrEnabledDefault || defaults.iftarEnabledDefault
    }

    func hasAnyEnabledOverride() -> Bool {
        overridesByDay.values.contains { override in
            if override.skipDay { return false }
            return override.suhoorEnabled == true
                || override.reminderEnabled == true
                || override.fajrEnabled == true
                || override.iftarEnabled == true
        }
    }

    private func performMigrationIfNeeded(legacySettings: AppSettings?) {
        var currentVersion = defaultsStore.integer(forKey: migrationKey)

        if currentVersion < 1 {
            if let legacySettings {
                let hasStoredDefaults = defaultsStore.data(forKey: defaultsKey) != nil
                let hasStoredOverrides = defaultsStore.data(forKey: overridesKey) != nil

                if !hasStoredDefaults && !hasStoredOverrides {
                    defaults = DefaultAlarmConfig(
                        suhoorEnabledDefault: legacySettings.isEnabled,
                        reminderEnabledDefault: legacySettings.reminderEnabledGlobal,
                        fajrEnabledDefault: legacySettings.atFajrEnabledGlobal,
                        iftarEnabledDefault: true,
                        defaultSuhoorTimeMode: .relativeToFajrMinusMinutes,
                        defaultSuhoorOffsetMinutes: legacySettings.baseWakeOffsetMinutes,
                        defaultReminderTimeMode: .beforeFajr,
                        defaultReminderMinutesBeforeFajr: max(legacySettings.reminderMinutesBeforeFajrGlobal, 10),
                        defaultReminderFixedTimeMinutes: 0,
                        defaultIftarDelivery: .notificationOnly,
                        defaultIftarSoundChoice: .adhanSoft,
                        activationMode: .alwaysOn,
                        activeStartDate: nil,
                        activeEndDate: nil,
                        scheduleWindowDays: DefaultAlarmConfig.default.scheduleWindowDays
                    )
                }
            }

            currentVersion = 1
        }

        if currentVersion < 2 {
            defaults.suhoorEnabledDefault = true
            defaults.reminderEnabledDefault = true
            defaults.fajrEnabledDefault = true
            currentVersion = 2
        }

        if currentVersion < 3 {
            defaults.iftarEnabledDefault = true
            defaults.defaultIftarDelivery = .notificationOnly
            defaults.defaultIftarSoundChoice = .adhanSoft
            currentVersion = 3
        }

        defaultsStore.set(max(currentVersion, Self.latestMigrationVersion), forKey: migrationKey)
    }

    private func persistDefaults() {
        let snapshot = defaults
        defaultsPersistence.schedule { [defaultsStore, defaultsKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaultsStore.set(data, forKey: defaultsKey)
        }
    }

    private func persistOverrides() {
        let snapshot = overridesByDay
        overridesPersistence.schedule { [defaultsStore, overridesKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaultsStore.set(data, forKey: overridesKey)
        }
    }
}
