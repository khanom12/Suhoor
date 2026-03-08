import SwiftUI
import UIKit
import CoreLocation
import os

struct AlarmsHomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedSchedule: DaySchedule?
    @State private var showTagFilterSheet = false
    @State private var editMode: EditMode = .inactive
    @State private var sectionCollapseOverrides: [String: Bool] = [:]
    @State private var loadingSectionIDs: Set<String> = []
    @State private var listSnapshot: AlarmListSnapshot = .empty
    @State private var tagFilter = AlarmTagFilter()
    @State private var pendingSeriesDeleteEntry: AlarmRowEntry?
    @State private var pendingRamadanEntry: AlarmRowEntry?
    @State private var pinnedNextAlarmEntryIDs: [String] = []
    @State private var animatePinnedNextAlarmUpdates = false

    var body: some View {
        List {
            Section(Strings.AlarmsTab.nextAlarmSectionTitle) {
                if listSnapshot.nextAlarmEntries.isEmpty == false {
                    ForEach(listSnapshot.nextAlarmEntries) { entry in
                        alarmRow(for: entry, isPinnedNextAlarm: true)
                            .deleteDisabled(entry.deleteCapability == .ramadan)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    .onDelete { offsets in
                        withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
                            deleteEntries(in: listSnapshot.nextAlarmEntries, at: offsets)
                        }
                    }
                } else {
                    if listSnapshot.sections.isEmpty {
                        emptyStateView
                    } else {
                        Text(Strings.AlarmList.notSetUp)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, DesignTokens.spacingS)
                    }
                }
            }
            .textCase(nil)

            if tagFilter.isActive {
                Section {
                    activeFilterBar
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }

            if !listSnapshot.sections.isEmpty {
                ForEach(listSnapshot.sections) { section in
                    Section {
                        if !isSectionCollapsed(section) {
                            Group {
                                if section.entries.isEmpty {
                                    if loadingSectionIDs.contains(section.id) {
                                        HStack {
                                            ProgressView()
                                            Text("Loading month")
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, DesignTokens.spacingS)
                                    } else {
                                        Text(monthEmptyStateText)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .padding(.vertical, DesignTokens.spacingS)
                                    }
                                } else {
                                    ForEach(section.entries) { entry in
                                        alarmRow(for: entry)
                                        .deleteDisabled(entry.deleteCapability == .ramadan)
                                    }
                                    .onDelete { offsets in
                                        withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
                                            deleteEntries(in: section.entries, at: offsets)
                                        }
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    } header: {
                        Button {
                            toggleSectionCollapse(section)
                        } label: {
                            headerLabel(for: section)
                        }
                        .buttonStyle(.plain)
                        .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Wake")
        .navigationBarTitleDisplayMode(.large)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(editMode.isEditing ? "Done" : "Edit") {
                    editMode = editMode.isEditing ? .inactive : .active
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if showsAddButton {
                    Button {
                        NotificationCenter.default.post(name: .openPlanHome, object: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                Button {
                    showTagFilterSheet = true
                } label: {
                    Image(systemName: tagFilter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .confirmationDialog(
            "Remove scheduled morning",
            isPresented: Binding(
                get: { pendingSeriesDeleteEntry != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingSeriesDeleteEntry = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let entry = pendingSeriesDeleteEntry {
                let excludable = entry.excludableProvenances
                if excludable.count == 1, let provenance = excludable.first {
                    Button("Remove this morning only") {
                        Task {
                            await deleteDayOnly(entry: entry, provenance: provenance)
                            await MainActor.run { pendingSeriesDeleteEntry = nil }
                        }
                    }
                } else {
                    Button("Remove this morning from all plans", role: .destructive) {
                        Task {
                            await deleteDayFromAllSchedules(entry: entry, provenances: excludable)
                            await MainActor.run { pendingSeriesDeleteEntry = nil }
                        }
                    }
                    ForEach(excludable, id: \.id) { provenance in
                        Button("Remove this morning from \(provenance.label)") {
                            Task {
                                await deleteDayOnly(entry: entry, provenance: provenance)
                                await MainActor.run { pendingSeriesDeleteEntry = nil }
                            }
                        }
                    }
                }

                ForEach(entry.stoppableProvenances, id: \.id) { provenance in
                    let title = provenance.stopSeriesLabel ?? "Remove schedule"
                    Button(title, role: .destructive) {
                        Task {
                            await scheduleManager.stopSeries(for: provenance)
                            await MainActor.run { pendingSeriesDeleteEntry = nil }
                        }
                    }
                }

                Button(Strings.Settings.cancel, role: .cancel) {}
            }
        }
        .alert(
            "Ramadan mornings can't be deleted",
            isPresented: Binding(
                get: { pendingRamadanEntry != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingRamadanEntry = nil
                    }
                }
            )
        ) {
            Button("Turn off for this day") {
                if let entry = pendingRamadanEntry {
                    alarmConfigStore.setDayEnabled(false, for: entry.schedule.date, timeZone: .current)
                    scheduleManager.requestRescheduleDay(entry.schedule.date)
                }
                pendingRamadanEntry = nil
            }
            Button(Strings.Settings.cancel, role: .cancel) {
                pendingRamadanEntry = nil
            }
        } message: {
            Text("This date is part of Ramadan. You can still turn it off for the day.")
        }
        .navigationDestination(isPresented: navigationIsActiveBinding) {
            if let schedule = selectedSchedule {
                AlarmDayDetailView(schedule: schedule)
            }
        }
        .task {
            refreshListSnapshot(animated: false)
        }
        .onChange(of: scheduleManager.currentRevision) { _, _ in
            refreshListSnapshot(animated: false)
        }
        .onChange(of: alarmConfigStore.currentRevision) { _, _ in
            refreshListSnapshot(animated: false)
        }
        .onChange(of: fastTagStore.currentRevision) { _, _ in
            refreshListSnapshot(animated: false)
        }
        .onChange(of: tagFilter) { _, _ in
            refreshListSnapshot(animated: true)
        }
        .sheet(isPresented: $showTagFilterSheet) {
            AlarmTagFilterSheet(filter: $tagFilter)
        }
    }

    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            Text(Strings.AlarmsTab.emptyTitle)
                .font(.headline.weight(.semibold))
            Text(emptyStateDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            PermissionStackView(
                kinds: [.location, .alarmKit, .notifications],
                refreshKey: permissionRefreshKey,
                showOnlyBlocking: true,
                onOpenSettings: openAppSettings
            )
            .environmentObject(scheduleManager)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignTokens.spacingL)
    }

    private var emptyStateDetail: String {
        if !scheduleManager.statusText.isEmpty {
            return scheduleManager.statusText
        }
        return Strings.AlarmsTab.emptySubtitle
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var permissionRefreshKey: String {
        "\(locationService.authorizationStatus.rawValue)-\(locationService.lastLocation != nil)-\(scheduleManager.alarmAuthorizationText)-\(scheduleManager.notificationAuthorizationText)"
    }

    private var monthEmptyStateText: String {
        tagFilter.isActive ? Strings.AlarmsTab.emptyFilteredMonth : Strings.AlarmsTab.emptyMonth
    }

    private func alarmRow(for entry: AlarmRowEntry, isPinnedNextAlarm: Bool = false) -> some View {
        AlarmRowView(
            entry: entry,
            deleteCapability: entry.deleteCapability,
            onToggleChanged: { isOn in
                guard isPinnedNextAlarm else { return }
                handlePinnedNextAlarmToggleChange(for: entry, isOn: isOn)
            },
            onSelect: {
                selectedSchedule = entry.schedule
            },
            onRequestRamadanDisable: {
                pendingRamadanEntry = entry
            }
        )
    }

    private func rebuildListSnapshot() {
        let token = PerformanceTrace.begin("alarms.home.snapshot", metadata: "visible=\(scheduleManager.activeWindowSnapshot.visibleDays.count)")
        defer { PerformanceTrace.end(token) }

        let timeZone = TimeZone.current
        let nearTermEntries = scheduleManager.activeWindowSnapshot.visibleDays.map(AlarmRowEntry.init)
        var totalCountCache: [HijriMonthKey: Int] = [:]

        func totalCount(for key: HijriMonthKey) -> Int {
            if let cached = totalCountCache[key] {
                return cached
            }
            let count = totalScheduledCount(for: key, timeZone: timeZone)
            totalCountCache[key] = count
            return count
        }

        let sanitizedPinnedNextAlarmEntryIDs = AlarmListSelection.sanitizedPinnedEntryIDs(
            pinnedEntryIDs: pinnedNextAlarmEntryIDs,
            availableEntries: nearTermEntries
        )
        if sanitizedPinnedNextAlarmEntryIDs != pinnedNextAlarmEntryIDs {
            pinnedNextAlarmEntryIDs = sanitizedPinnedNextAlarmEntryIDs
        }

        let nextAlarmEntries = AlarmListSelection.nextAlarmEntries(
            from: nearTermEntries,
            pinnedEntryIDs: sanitizedPinnedNextAlarmEntryIDs
        )
        guard nextAlarmEntries.isEmpty == false else {
            sectionCollapseOverrides = [:]
            loadingSectionIDs = []
            listSnapshot = AlarmListSnapshot(
                nextAlarmEntries: [],
                sections: [],
                defaultExpandedSectionID: nil
            )
            return
        }

        let nextAlarmEntryIDs = Set(nextAlarmEntries.map(\.id))
        var nearTermGrouped: [HijriMonthKey: [AlarmRowEntry]] = [:]
        for entry in nearTermEntries {
            guard nextAlarmEntryIDs.contains(entry.id) == false else { continue }
            guard let key = FastIntentEngine.hijriMonthKey(for: entry.schedule.date, timeZone: timeZone) else { continue }
            nearTermGrouped[key, default: []].append(entry)
        }

        let previewMonths = scheduleManager.rollingHijriMonths(count: 12, timeZone: timeZone)
        var sections: [HijriMonthSection] = []
        let pinnedNextAlarmCountsByMonth = Dictionary(
            grouping: nextAlarmEntries.compactMap { entry in
                FastIntentEngine.hijriMonthKey(for: entry.schedule.date, timeZone: timeZone)
            },
            by: { $0 }
        ).mapValues(\.count)

        for yearMonth in previewMonths {
            let key = HijriMonthKey(
                year: yearMonth.hijriYear,
                month: yearMonth.month.rawValue,
                title: "\(yearMonth.month.displayName) \(yearMonth.hijriYear)"
            )
            let totalCount = totalCount(for: key)
            guard totalCount > 0 else { continue }
            let pinnedCount = pinnedNextAlarmCountsByMonth[key, default: 0]
            guard totalCount > pinnedCount else { continue }
            guard let preview = scheduleManager.hijriMonthStartPreview(
                for: yearMonth.month,
                hijriYear: yearMonth.hijriYear,
                timeZone: timeZone
            ) else { continue }
            let previewInfo = HijriMonthPreview(key: key, startDate: preview.adjustedStart, offsetDays: preview.offsetDays)

            let cachedEntries = scheduleManager.cachedMonthEntries(for: key)?.map(AlarmRowEntry.init)
            let unfilteredEntries = cachedEntries ?? nearTermGrouped[key] ?? []
            let entries = unfilteredEntries.filter { entry in
                entry.matches(filter: tagFilter)
            }
            let isLoaded = cachedEntries != nil || !unfilteredEntries.isEmpty
            let visibleAlarmCount = tagFilter.isActive ? entries.count : max(totalCount - pinnedCount, 0)
            sections.append(
                HijriMonthSection(
                    key: key,
                    entries: entries,
                    preview: previewInfo,
                    isLoaded: isLoaded,
                    visibleAlarmCount: visibleAlarmCount,
                    totalAlarmCount: totalCount
                )
            )
        }

        let extraSectionKeys = Set(nearTermGrouped.keys)
            .union(scheduleManager.activeWindowSnapshot.visibleDays.compactMap {
                FastIntentEngine.hijriMonthKey(for: $0.schedule.date, timeZone: timeZone)
            })
        let extraSections: [HijriMonthSection] = extraSectionKeys
            .filter { key in
                sections.contains(where: { $0.key == key }) == false
            }
            .sorted { lhs, rhs in
                (nearTermGrouped[lhs]?.first?.schedule.date ?? .distantPast) < (nearTermGrouped[rhs]?.first?.schedule.date ?? .distantPast)
            }
            .compactMap { key -> HijriMonthSection? in
                let totalCount = totalCount(for: key)
                let pinnedCount = pinnedNextAlarmCountsByMonth[key, default: 0]
                guard totalCount > 0 else { return nil }
                guard totalCount > pinnedCount else { return nil }
                let filteredEntries = (nearTermGrouped[key] ?? []).filter { entry in
                    entry.matches(filter: tagFilter)
                }
                return HijriMonthSection(
                    key: key,
                    entries: filteredEntries,
                    preview: nil,
                    isLoaded: true,
                    visibleAlarmCount: tagFilter.isActive ? filteredEntries.count : max(totalCount - pinnedCount, 0),
                    totalAlarmCount: totalCount
                )
            }

        let combinedSections = sections + extraSections
        let resolvedSections: [HijriMonthSection] = combinedSections.sorted {
            ($0.preview?.startDate ?? $0.entries.first?.schedule.date ?? .distantPast) <
            ($1.preview?.startDate ?? $1.entries.first?.schedule.date ?? .distantPast)
        }
        let sectionIdentifiers = Set(resolvedSections.map { $0.id })
        sectionCollapseOverrides = sectionCollapseOverrides.filter { sectionIdentifiers.contains($0.key) }
        loadingSectionIDs = loadingSectionIDs.filter { sectionIdentifiers.contains($0) }
        listSnapshot = AlarmListSnapshot(
            nextAlarmEntries: nextAlarmEntries,
            sections: resolvedSections,
            defaultExpandedSectionID: nil
        )
    }

    private func totalScheduledCount(for key: HijriMonthKey, timeZone: TimeZone) -> Int {
        guard let month = HijriMonth(rawValue: key.month) else { return 0 }
        return alarmConfigStore.resolvedScheduledEntries(
            forHijriMonth: HijriYearMonth(hijriYear: key.year, month: month),
            timeZone: timeZone
        ).count
    }

    private func refreshListSnapshot(animated: Bool) {
        let shouldAnimate = animated || animatePinnedNextAlarmUpdates
        animatePinnedNextAlarmUpdates = false
        let update = {
            rebuildListSnapshot()
            ensureExpandedSectionsLoaded()
        }
        if shouldAnimate {
            withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
                update()
            }
        } else {
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                update()
            }
        }
    }

    private var showsAddButton: Bool {
        !editMode.isEditing
    }

    private func deleteEntries(in entries: [AlarmRowEntry], at offsets: IndexSet) {
        var pending: AlarmRowEntry?
        for index in offsets {
            guard entries.indices.contains(index) else { continue }
            let entry = entries[index]
            pinnedNextAlarmEntryIDs.removeAll { $0 == entry.id }
            switch entry.deleteCapability {
            case .explicitOneOff:
                deleteOneOff(entry)
            case .series, .mixed:
                if pending == nil {
                    pending = entry
                }
            case .ramadan:
                break
            }
        }
        if let pending {
            pendingSeriesDeleteEntry = pending
        }
    }

    private func deleteOneOff(_ entry: AlarmRowEntry) {
        let date = entry.schedule.date
        Task { await scheduleManager.deleteExplicitScheduledDate(date) }
    }

    private func deleteDayOnly(entry: AlarmRowEntry, provenance: ResolvedScheduledDateProvenance) async {
        await scheduleManager.deleteDayAndSuppress(
            entry.schedule.date,
            scopes: [suppressionScope(for: provenance)],
            deleteExplicit: entry.hasExplicitOneOff
        )
    }

    private func deleteDayFromAllSchedules(
        entry: AlarmRowEntry,
        provenances: [ResolvedScheduledDateProvenance]
    ) async {
        let scopes = provenances.map { suppressionScope(for: $0) }
        await scheduleManager.deleteDayAndSuppress(
            entry.schedule.date,
            scopes: scopes,
            deleteExplicit: entry.hasExplicitOneOff
        )
    }

    private func isSectionCollapsed(_ section: HijriMonthSection) -> Bool {
        let identifier = sectionIdentifier(section.key)
        return sectionCollapseOverrides[identifier] ?? listSnapshot.defaultCollapsedState(for: identifier)
    }

    private func toggleSectionCollapse(_ section: HijriMonthSection) {
        let identifier = sectionIdentifier(section.key)
        let currentState = isSectionCollapsed(section)
        withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
            sectionCollapseOverrides[identifier] = !currentState
        }
        guard currentState else { return }
        ensureMonthEntriesLoaded(for: section)
    }

    private func sectionIdentifier(_ key: HijriMonthKey) -> String {
        "\(key.year)-\(key.month)"
    }

    private func shortDate(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }

    private func adjustmentTag(for offsetDays: Int) -> String? {
        switch offsetDays {
        case -1:
            return Strings.Settings.hijriAdjustedMinusOneDay
        case 1:
            return Strings.Settings.hijriAdjustedPlusOneDay
        default:
            return nil
        }
    }

    private func monthStartLabel(for date: Date, currentDate: Date = Date(), timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfToday = calendar.startOfDay(for: currentDate)
        let startOfMonth = calendar.startOfDay(for: date)
        if startOfMonth < startOfToday {
            return Strings.AlarmsTab.hijriMonthStarted(shortDate(date))
        }
        return Strings.AlarmsTab.hijriMonthStarts(shortDate(date))
    }

    private func dateFromDayIdentifier(_ identifier: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: identifier)
    }

    @ViewBuilder
    private func headerLabel(for section: HijriMonthSection) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                    Text(section.key.title)
                        .foregroundStyle(.primary)
                    Spacer(minLength: DesignTokens.spacingS)
                    MonthAlarmCountBadge(count: section.visibleAlarmCount)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isSectionCollapsed(section) ? 0 : 90))
                }
                if let preview = section.preview {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(monthStartLabel(for: preview.startDate))
                        if let adjustment = adjustmentTag(for: preview.offsetDays) {
                            Text("(\(adjustment))")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var activeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.spacingS) {
                Text(Strings.AlarmsTab.filteringLabel)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(tagFilter.selectedItems) { item in
                    HomeTagCapsule(
                        style: item.style,
                        prominence: item.isPrimary ? .strong : .subtle,
                        isDisabled: false,
                        showsTitle: true,
                        isCompact: false
                    )
                }

                Button(Strings.AlarmsTab.filterClear) {
                    tagFilter.clear()
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, 4)
        }
    }

    private func ensureExpandedSectionsLoaded() {
        for section in listSnapshot.sections where !isSectionCollapsed(section) {
            ensureMonthEntriesLoaded(for: section)
        }
    }

    private func ensureMonthEntriesLoaded(for section: HijriMonthSection) {
        guard section.isLoaded == false else { return }
        guard loadingSectionIDs.contains(section.id) == false else { return }

        loadingSectionIDs.insert(section.id)
        Task {
            _ = await scheduleManager.monthEntries(for: section.key, timeZone: .current)
            await MainActor.run {
                loadingSectionIDs.remove(section.id)
                refreshListSnapshot(animated: false)
            }
        }
    }

    private func handlePinnedNextAlarmToggleChange(for entry: AlarmRowEntry, isOn: Bool) {
        let updatedPinnedEntryIDs = AlarmListSelection.pinnedEntryIDs(
            afterToggling: entry.id,
            isOn: isOn,
            currentPinnedEntryIDs: pinnedNextAlarmEntryIDs
        )
        guard updatedPinnedEntryIDs != pinnedNextAlarmEntryIDs else { return }
        animatePinnedNextAlarmUpdates = true
        pinnedNextAlarmEntryIDs = updatedPinnedEntryIDs
    }
}

private struct AlarmListSnapshot {
    let nextAlarmEntries: [AlarmRowEntry]
    let sections: [HijriMonthSection]
    let defaultExpandedSectionID: String?

    static let empty = AlarmListSnapshot(nextAlarmEntries: [], sections: [], defaultExpandedSectionID: nil)

    func defaultCollapsedState(for identifier: String) -> Bool {
        guard let defaultExpandedSectionID else { return true }
        return identifier != defaultExpandedSectionID
    }
}

enum AlarmRowPresentation {
    private static let adjustedHijriCalendar = AdjustedHijriCalendar.shared

    static func secondaryTags(for result: TagComputationResult) -> [FastSecondaryVirtueTag] {
        FastIntentEngine.displaySecondaryTags(result.computedSecondaryTags)
    }

    static func showsTags(
        primaryIntent: FastPrimaryIntent,
        secondaryTags: [FastSecondaryVirtueTag],
        warnings: [FastWarning]
    ) -> Bool {
        !(primaryIntent == .other && secondaryTags.isEmpty && warnings.isEmpty)
    }

    static func dateLabel(
        for date: Date,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> String {
        if isToday(date, currentDate: currentDate, timeZone: timeZone) {
            return Strings.AlarmsTab.todayLabel
        }
        if isTomorrow(date, currentDate: currentDate, timeZone: timeZone) {
            return Strings.AlarmsTab.tomorrowLabel
        }
        if let ramadanLabel = ramadanLabel(for: date, timeZone: timeZone, weekdayFormatter: fullWeekdayFormatter) {
            return ramadanLabel
        }
        return dateLabelFormatter.string(from: date)
    }

    static func accessibilityDateLabel(
        for date: Date,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> String {
        let isTodayValue = isToday(date, currentDate: currentDate, timeZone: timeZone)
        let isTomorrowValue = isTomorrow(date, currentDate: currentDate, timeZone: timeZone)
        if isTodayValue {
            return "\(Strings.AlarmsTab.todayLabel), \(accessibilityDateLabelFormatter.string(from: date))"
        }
        if isTomorrowValue {
            return "\(Strings.AlarmsTab.tomorrowLabel), \(accessibilityDateLabelFormatter.string(from: date))"
        }
        if let ramadanLabel = ramadanLabel(for: date, timeZone: timeZone, weekdayFormatter: accessibilityWeekdayFormatter) {
            return ramadanLabel
        }
        return accessibilityDateLabelFormatter.string(from: date)
    }

    private static func isToday(_ date: Date, currentDate: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.isDate(date, inSameDayAs: calendar.startOfDay(for: currentDate))
    }

    private static func isTomorrow(_ date: Date, currentDate: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfToday = calendar.startOfDay(for: currentDate)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        return calendar.isDate(date, inSameDayAs: startOfTomorrow)
    }

    private static let dateLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static let fullWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static let accessibilityDateLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static let accessibilityWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static func ramadanLabel(
        for date: Date,
        timeZone: TimeZone,
        weekdayFormatter: DateFormatter
    ) -> String? {
        guard adjustedHijriCalendar.isRamadan(date: date, timeZone: timeZone) else { return nil }
        guard let components = adjustedHijriCalendar.adjustedComponents(for: date, timeZone: timeZone) else { return nil }
        return "\(weekdayFormatter.string(from: date)), \(components.day) Ramadan"
    }
}

struct AlarmRowEntry: Identifiable {
    let activeDay: ActiveAlarmDay
    let secondaryTags: [FastSecondaryVirtueTag]
    let warnings: [FastWarning]
    let showsTags: Bool
    let deleteCapability: AlarmRowDeleteCapability
    let stoppableProvenances: [ResolvedScheduledDateProvenance]
    let excludableProvenances: [ResolvedScheduledDateProvenance]
    let hasExplicitOneOff: Bool

    init(activeDay: ActiveAlarmDay) {
        let secondaryTags = AlarmRowPresentation.secondaryTags(for: activeDay.tagResult)
        let warnings = FastIntentEngine.warnings(for: activeDay.schedule.date, timeZone: .current)
        self.activeDay = activeDay
        self.secondaryTags = secondaryTags
        self.warnings = warnings
        self.showsTags = AlarmRowPresentation.showsTags(
            primaryIntent: activeDay.tagResult.computedPrimaryIntent,
            secondaryTags: secondaryTags,
            warnings: warnings
        )
        let provenances = activeDay.provenances
        let isRamadan = activeDay.isImplicitRamadan
        let hasExplicit = provenances.contains(where: \.isExplicitOneOff)
        let nonExplicit = provenances.filter { !$0.isExplicitOneOff }
        self.hasExplicitOneOff = hasExplicit
        self.excludableProvenances = nonExplicit
        self.stoppableProvenances = AlarmRowEntry.uniqueStoppableProvenances(from: provenances)
        if isRamadan {
            self.deleteCapability = .ramadan
        } else if activeDay.isExplicitOneOff && nonExplicit.isEmpty {
            self.deleteCapability = .explicitOneOff
        } else if hasExplicit && !nonExplicit.isEmpty {
            self.deleteCapability = .mixed
        } else {
            self.deleteCapability = .series
        }
    }

    var schedule: DaySchedule { activeDay.schedule }
    var config: EffectiveDailyConfig { activeDay.effectiveConfig }
    var primary: PrimaryDisplay? { activeDay.primaryDisplay }
    var isOneOff: Bool { activeDay.isExplicitOneOff }
    var primaryIntent: FastPrimaryIntent { activeDay.tagResult.computedPrimaryIntent }
    var isEnabled: Bool { !config.skipDay && config.hasAnyEnabled }
    var primaryTimeDate: Date { primary?.time ?? schedule.wakeDate }
    var id: String { activeDay.dateKey }

    func matches(filter: AlarmTagFilter) -> Bool {
        guard filter.isActive else { return true }
        return filter.matches(
            entryPrimaryIntent: primaryIntent,
            entrySecondaryTags: secondaryTags
        )
    }

    private static func uniqueStoppableProvenances(
        from provenances: [ResolvedScheduledDateProvenance]
    ) -> [ResolvedScheduledDateProvenance] {
        var seen = Set<String>()
        return provenances.filter { provenance in
            guard provenance.canStopSeries else { return false }
            let key = "\(provenance.groupID?.uuidString ?? provenance.sourceID.uuidString)-\(provenance.stopSeriesLabel ?? "")"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
}

enum AlarmRowDeleteCapability: Equatable {
    case ramadan
    case explicitOneOff
    case series
    case mixed
}

private struct HijriMonthSection: Identifiable {
    let key: HijriMonthKey
    let entries: [AlarmRowEntry]
    let preview: HijriMonthPreview?
    let isLoaded: Bool
    let visibleAlarmCount: Int
    let totalAlarmCount: Int

    var id: String { "\(key.year)-\(key.month)" }
}

private struct HijriMonthPreview {
    let key: HijriMonthKey
    let startDate: Date
    let offsetDays: Int
}

private struct AlarmRowView: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.editMode) private var editMode

    private let editAccessoryWidth: CGFloat = 40

    let entry: AlarmRowEntry
    let deleteCapability: AlarmRowDeleteCapability
    let onToggleChanged: (Bool) -> Void
    let onSelect: () -> Void
    let onRequestRamadanDisable: () -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize: CGFloat = 46
    @State private var localIsOn: Bool

    private static let timeMainFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static let timeSuffixFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    init(
        entry: AlarmRowEntry,
        deleteCapability: AlarmRowDeleteCapability,
        onToggleChanged: @escaping (Bool) -> Void = { _ in },
        onSelect: @escaping () -> Void,
        onRequestRamadanDisable: @escaping () -> Void
    ) {
        self.entry = entry
        self.deleteCapability = deleteCapability
        self.onToggleChanged = onToggleChanged
        self.onSelect = onSelect
        self.onRequestRamadanDisable = onRequestRamadanDisable
        _localIsOn = State(initialValue: AlarmRowView.isEnabled(config: entry.config))
    }

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
            if showsRamadanEditAccessory {
                Button(action: onRequestRamadanDisable) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.gray)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .frame(width: editAccessoryWidth)
                .accessibilityLabel("Ramadan alarms can't be deleted")
                .accessibilityHint("Turn this day off instead")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(dateLabel)
                    .font(.footnote)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(primaryTimeMain)
                        .font(.system(size: timeFontSize, weight: .regular, design: .default))
                        .monospacedDigit()
                        .foregroundStyle(isDisabled ? .tertiary : .primary)
                        .minimumScaleFactor(0.8)

                    if let primaryTimeSuffix {
                        Text(primaryTimeSuffix)
                            .font(.system(size: timeFontSize * 0.55, weight: .regular, design: .default))
                            .monospacedDigit()
                            .foregroundStyle(isDisabled ? .tertiary : .secondary)
                            .baselineOffset(1)
                    }
                }

                Text("\(rowPresentation.relationText) • Fajr \(fajrTimeText)")
                    .font(.callout)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)
                    .monospacedDigit()

                HStack(spacing: DesignTokens.spacingXS) {
                    ScheduleContextChip(
                        title: rowPresentation.primaryContextTitle,
                        prominence: .primary,
                        isDisabled: isDisabled
                    )

                    ForEach(rowPresentation.secondaryContextTitles, id: \.self) { title in
                        ScheduleContextChip(
                            title: title,
                            prominence: .secondary,
                            isDisabled: isDisabled
                        )
                    }
                }

                if let provenanceText = rowPresentation.provenanceText {
                    Text(provenanceText)
                        .font(.footnote)
                        .foregroundStyle(isDisabled ? .tertiary : .secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
            .onTapGesture {
                guard editMode?.wrappedValue.isEditing != true else { return }
                onSelect()
            }

        VStack(alignment: .trailing, spacing: 10) {
            if editMode?.wrappedValue.isEditing != true {
                Button("Adjust") {
                    onSelect()
                }
                .buttonStyle(.borderless)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DawnColor.accent)
                .accessibilityLabel("Open one-day override")
            }

            Toggle("", isOn: dayActiveBinding)
                .labelsHidden()
                .tint(DawnColor.accent)
                .accessibilityLabel("Keep this morning active")
                .frame(minWidth: 51, alignment: .trailing)
        }
        .frame(minWidth: 74, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .onChange(of: entry.config) { _, newValue in
            localIsOn = AlarmRowView.isEnabled(config: newValue)
        }
    }

    private var showsRamadanEditAccessory: Bool {
        editMode?.wrappedValue.isEditing == true && deleteCapability == .ramadan
    }

    private var fajrTimeText: String {
        TimeFormatters.timeFormatter.string(from: schedule.fajrDate)
    }

    private var primaryTimeDate: Date {
        schedule.wakeDate
    }

    private var primaryTimeMain: String {
        AlarmRowView.timeMainFormatter.string(from: primaryTimeDate)
    }

    private var primaryTimeSuffix: String? {
        AlarmRowView.timeSuffixFormatter.string(from: primaryTimeDate)
    }

    private var rowPresentation: ScheduleRowPresentation {
        ProductSurfacePresentation.scheduleRowPresentation(
            for: entry.activeDay,
            hasDayOverride: alarmConfigStore.override(for: schedule.date, timeZone: .current) != nil
        )
    }

    private var dateLabel: String {
        AlarmRowPresentation.dateLabel(for: schedule.date)
    }

    private var dayActiveBinding: Binding<Bool> {
        Binding(get: {
            localIsOn
        }, set: { isOn in
            localIsOn = isOn
            onToggleChanged(isOn)
            let timeZone = TimeZone.current
            alarmConfigStore.setDayEnabled(isOn, for: schedule.date, timeZone: timeZone)
            scheduleManager.requestRescheduleDay(schedule.date)
        })
    }

    private var accessibilitySummary: String {
        var summary = "\(dateLabelWithPrefix). Wake at \(primaryTimeText). \(rowPresentation.relationText). \(rowPresentation.primaryContextTitle)."
        if rowPresentation.secondaryContextTitles.isEmpty == false {
            summary += " \(rowPresentation.secondaryContextTitles.joined(separator: ", "))."
        }
        if let provenanceText = rowPresentation.provenanceText {
            summary += " \(provenanceText)."
        }
        return summary
    }

    private var isDisabled: Bool {
        !localIsOn
    }

    private var dateLabelWithPrefix: String {
        AlarmRowPresentation.accessibilityDateLabel(for: schedule.date)
    }

    private static func isEnabled(config: EffectiveDailyConfig) -> Bool {
        !config.skipDay && config.hasAnyEnabled
    }

    private var schedule: DaySchedule {
        entry.schedule
    }

    private var primaryTimeText: String {
        TimeFormatters.timeFormatter.string(from: primaryTimeDate)
    }
}

private struct ScheduleContextChip: View {
    enum Prominence {
        case primary
        case secondary
    }

    let title: String
    let prominence: Prominence
    let isDisabled: Bool

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(prominence == .primary ? DawnColor.accent : Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        prominence == .primary
                            ? DawnColor.accent.opacity(0.14)
                            : Color(.secondarySystemGroupedBackground)
                    )
            )
            .opacity(isDisabled ? 0.55 : 1.0)
    }
}

private extension AlarmsHomeView {
    var navigationIsActiveBinding: Binding<Bool> {
        Binding(get: {
            selectedSchedule != nil
        }, set: { isActive in
            if !isActive {
                selectedSchedule = nil
            }
        })
    }
}

private func suppressionScope(for provenance: ResolvedScheduledDateProvenance) -> SuppressionScope {
    if let groupID = provenance.groupID {
        return .groupID(groupID)
    }
    return .sourceID(provenance.sourceID)
}

private struct HomeTagCapsuleRow: View {
    let primaryIntent: FastPrimaryIntent
    let secondaryTags: [FastSecondaryVirtueTag]
    let warnings: [FastWarning]
    let showPrimaryIntent: Bool
    let isDisabled: Bool
    let showsTitle: Bool
    let isCompact: Bool

    var body: some View {
        FlowLayout(spacing: isCompact ? 4 : 6) {
            ForEach(warnings, id: \.self) { warning in
                HomeWarningCapsule(
                    warning: warning,
                    isDisabled: isDisabled,
                    showsTitle: showsTitle,
                    isCompact: isCompact
                )
            }
            if showPrimaryIntent {
                HomeTagCapsule(
                    style: primaryIntent.style,
                    prominence: .strong,
                    isDisabled: isDisabled,
                    showsTitle: showsTitle,
                    isCompact: isCompact
                )
            }
            ForEach(secondaryTags, id: \.self) { tag in
                HomeTagCapsule(
                    style: tag.style,
                    prominence: .subtle,
                    isDisabled: isDisabled,
                    showsTitle: showsTitle,
                    isCompact: isCompact
                )
            }
        }
        .accessibilityHidden(true)
    }
}

private struct HomeTagCapsule: View {
    enum Prominence {
        case strong
        case subtle
    }

    let style: FastTagStyle
    let prominence: Prominence
    let isDisabled: Bool
    let showsTitle: Bool
    let isCompact: Bool

    var body: some View {
        let base = style.color
        let fillOpacity = prominence == .strong ? 0.18 : 0.10
        let strokeOpacity = prominence == .strong ? 0.35 : 0.22

        HStack(spacing: isCompact ? 4 : 5) {
            if let systemImage = style.systemImage {
                Image(systemName: systemImage)
            }
            if showsTitle {
                Text(style.shortTitle)
                    .lineLimit(1)
            }
        }
            .font((isCompact ? Font.caption2 : Font.caption).weight(.semibold))
            .foregroundStyle(base)
            .padding(.vertical, isCompact ? 3 : 4)
            .padding(.horizontal, isCompact ? 6 : 8)
            .background(
                Capsule()
                    .fill(base.opacity(fillOpacity))
            )
            .overlay(
                Capsule()
                    .stroke(base.opacity(strokeOpacity), lineWidth: 0.8)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
            .accessibilityHidden(true)
    }
}

private struct MonthAlarmCountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(count == 0 ? .secondary : DawnColor.accent)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(count == 0 ? Color.secondary.opacity(0.12) : DawnColor.accent.opacity(0.14))
            )
            .accessibilityLabel(Strings.AlarmsTab.alarmCountAccessibility(count))
    }
}

private struct HomeWarningCapsule: View {
    let warning: FastWarning
    let isDisabled: Bool
    let showsTitle: Bool
    let isCompact: Bool

    var body: some View {
        let base = Color.red
        let fillOpacity: Double = 0.08
        let strokeOpacity: Double = 0.35

        HStack(spacing: isCompact ? 4 : 5) {
            Image(systemName: warning.systemImage)
            if showsTitle {
                Text(warning.title)
                    .lineLimit(1)
            }
        }
            .font((isCompact ? Font.caption2 : Font.caption).weight(.semibold))
            .foregroundStyle(base)
            .padding(.vertical, isCompact ? 3 : 4)
            .padding(.horizontal, isCompact ? 6 : 8)
            .background(
                Capsule()
                    .fill(base.opacity(fillOpacity))
            )
            .overlay(
                Capsule()
                    .stroke(base.opacity(strokeOpacity), lineWidth: 0.8)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
            .accessibilityHidden(true)
    }
}

enum AlarmListSelection {
    static func sanitizedPinnedEntryIDs(
        pinnedEntryIDs: [String],
        availableEntries: [AlarmRowEntry]
    ) -> [String] {
        let availableEntryIDs = Set(availableEntries.map(\.id))
        return pinnedEntryIDs.filter { availableEntryIDs.contains($0) }
    }

    static func pinnedEntryIDs(
        afterToggling entryID: String,
        isOn: Bool,
        currentPinnedEntryIDs: [String]
    ) -> [String] {
        if isOn {
            guard let index = currentPinnedEntryIDs.firstIndex(of: entryID) else {
                return currentPinnedEntryIDs
            }
            return Array(currentPinnedEntryIDs.prefix(index + 1))
        }

        guard currentPinnedEntryIDs.contains(entryID) == false else {
            return currentPinnedEntryIDs
        }
        return currentPinnedEntryIDs + [entryID]
    }

    static func nextAlarmEntries(
        from entries: [AlarmRowEntry],
        pinnedEntryIDs: [String],
        now: Date = Date()
    ) -> [AlarmRowEntry] {
        let sanitizedPinnedEntryIDs = sanitizedPinnedEntryIDs(
            pinnedEntryIDs: pinnedEntryIDs,
            availableEntries: entries
        )
        let entriesByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        let pinnedEntries = sanitizedPinnedEntryIDs.compactMap { entriesByID[$0] }

        if pinnedEntries.contains(where: \.isEnabled) {
            return pinnedEntries
        }

        let pinnedEntryIDSet = Set(sanitizedPinnedEntryIDs)
        let remainingEntries = entries.filter { pinnedEntryIDSet.contains($0.id) == false }
        guard let nextEntry = nextAlarmEntry(from: remainingEntries, now: now) else {
            return pinnedEntries
        }
        return pinnedEntries + [nextEntry]
    }

    static func nextAlarmEntry(from entries: [AlarmRowEntry], now: Date = Date()) -> AlarmRowEntry? {
        let enabledEntries = entries.filter(\.isEnabled)
        if let upcoming = enabledEntries.first(where: { $0.primaryTimeDate >= now }) {
            return upcoming
        }
        return enabledEntries.first
    }
}
