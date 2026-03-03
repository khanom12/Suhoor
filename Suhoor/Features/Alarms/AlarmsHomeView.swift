import SwiftUI
import UIKit
import CoreLocation
import os

struct AlarmsHomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore

    @State private var selectedSchedule: DaySchedule?
    @State private var showSettingsSheet = false
    @State private var showAddDaySheet = false
    @State private var editMode: EditMode = .inactive
    @State private var sectionCollapseOverrides: [String: Bool] = [:]
    @State private var loadingSectionIDs: Set<String> = []
    @State private var listSnapshot: AlarmListSnapshot = .empty
    @State private var pendingFocusDateKey: String?
    @State private var pendingSeriesDeleteEntry: AlarmRowEntry?
    @State private var pendingRamadanEntry: AlarmRowEntry?

    var body: some View {
        NavigationStack {
            List {
                if listSnapshot.sections.isEmpty {
                    Section {
                        emptyStateView
                    }
                } else {
                    ForEach(listSnapshot.sections) { section in
                        Section {
                            if !isSectionCollapsed(section) {
                                if section.entries.isEmpty {
                                    if loadingSectionIDs.contains(section.id) {
                                        HStack {
                                            ProgressView()
                                            Text("Loading month")
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, DesignTokens.spacingS)
                                    } else {
                                        Text("No alarms in this month yet.")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .padding(.vertical, DesignTokens.spacingS)
                                    }
                                } else {
                                    ForEach(section.entries) { entry in
                                        AlarmRowView(
                                            schedule: entry.schedule,
                                            config: entry.config,
                                            primaryDisplay: entry.primary,
                                            primaryIntent: entry.primaryIntent,
                                            secondaryTags: entry.secondaryTags,
                                            warnings: entry.warnings,
                                            showsTags: entry.showsTags,
                                            deleteCapability: entry.deleteCapability,
                                            onSelect: {
                                                selectedSchedule = entry.schedule
                                            },
                                            onRequestRamadanDisable: {
                                                pendingRamadanEntry = entry
                                            }
                                        )
                                        .deleteDisabled(entry.deleteCapability == .ramadan)
                                    }
                                    .onDelete { offsets in
                                        deleteEntries(in: section.entries, at: offsets)
                                    }
                                }
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
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.inline)
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
                            showAddDaySheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .confirmationDialog(
                "Delete alarm",
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
                        Button("Remove this day only") {
                            Task {
                                await deleteDayOnly(entry: entry, provenance: provenance)
                                await MainActor.run { pendingSeriesDeleteEntry = nil }
                            }
                        }
                    } else {
                        Button("Remove this day from all schedules", role: .destructive) {
                            Task {
                                await deleteDayFromAllSchedules(entry: entry, provenances: excludable)
                                await MainActor.run { pendingSeriesDeleteEntry = nil }
                            }
                        }
                        ForEach(excludable, id: \.id) { provenance in
                            Button("Remove this day from \(provenance.label)") {
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
                "Ramadan alarms can’t be deleted",
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
                Text("This date is part of Ramadan. You can turn it off for the day instead.")
            }
            .navigationDestination(isPresented: navigationIsActiveBinding) {
                if let schedule = selectedSchedule {
                    AlarmDayDetailView(schedule: schedule)
                }
            }
            .task {
                rebuildListSnapshot()
                ensureExpandedSectionsLoaded()
            }
            .onAppear {
                rebuildListSnapshot()
                ensureExpandedSectionsLoaded()
            }
            .onChange(of: scheduleManager.activeWindowSnapshot) { _, _ in
                rebuildListSnapshot()
                ensureExpandedSectionsLoaded()
            }
            .onChange(of: alarmConfigStore.overridesByDay) { _, _ in
                rebuildListSnapshot()
                ensureExpandedSectionsLoaded()
            }
            .onChange(of: alarmConfigStore.defaults) { _, _ in
                rebuildListSnapshot()
                ensureExpandedSectionsLoaded()
            }
            .sheet(isPresented: $showSettingsSheet) {
                NavigationStack {
                    SettingsRootView()
                }
            }
            .sheet(isPresented: $showAddDaySheet) {
                NavigationStack {
                    AddScheduleSheet(isPresented: $showAddDaySheet) { date in
                        pendingFocusDateKey = DateHelpers.dayIdentifier(for: date, timeZone: .current)
                        showAddDaySheet = false
                    }
                }
            }
            .onChange(of: showAddDaySheet) { _, isPresented in
                guard !isPresented, let pendingFocusDateKey else { return }
                if let existing = scheduleManager.activeWindowSnapshot.byDateKey[pendingFocusDateKey] {
                    selectedSchedule = existing.schedule
                } else if let normalizedDate = dateFromDayIdentifier(pendingFocusDateKey) {
                    selectedSchedule = scheduleManager.activeDay(for: normalizedDate)?.schedule
                }
                self.pendingFocusDateKey = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchToSettingsTab)) { _ in
                showSettingsSheet = true
            }
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

    private func rebuildListSnapshot() {
        let token = PerformanceTrace.begin("alarms.home.snapshot", metadata: "visible=\(scheduleManager.activeWindowSnapshot.visibleDays.count)")
        defer { PerformanceTrace.end(token) }

        let timeZone = TimeZone.current
        let nearTermEntries = scheduleManager.activeWindowSnapshot.visibleDays.map { day in
            let refreshedDay = scheduleManager.refreshedActiveDay(for: day.date, timeZone: timeZone) ?? day
            return AlarmRowEntry(activeDay: refreshedDay)
        }

        var nearTermGrouped: [HijriMonthKey: [AlarmRowEntry]] = [:]
        for entry in nearTermEntries {
            guard let key = FastIntentEngine.hijriMonthKey(for: entry.schedule.date, timeZone: timeZone) else { continue }
            nearTermGrouped[key, default: []].append(entry)
        }

        let previewMonths = scheduleManager.rollingHijriMonths(
            count: scheduleManager.hasRecurringIslamicSchedules() ? 12 : 4,
            timeZone: timeZone
        )
        var sections: [HijriMonthSection] = []
        let defaultExpandedSectionID = previewMonths.first.map { "\( $0.hijriYear)-\($0.month.rawValue)" }

        for yearMonth in previewMonths {
            let key = HijriMonthKey(
                year: yearMonth.hijriYear,
                month: yearMonth.month.rawValue,
                title: "\(yearMonth.month.displayName) \(yearMonth.hijriYear)"
            )
            guard let preview = scheduleManager.hijriMonthStartPreview(
                for: yearMonth.month,
                hijriYear: yearMonth.hijriYear,
                timeZone: timeZone
            ) else { continue }
            let previewInfo = HijriMonthPreview(key: key, startDate: preview.adjustedStart, offsetDays: preview.offsetDays)

            let cachedEntries = scheduleManager.cachedMonthEntries(for: key)?.map(AlarmRowEntry.init)
            let entries = cachedEntries ?? nearTermGrouped[key] ?? []
            let isLoaded = cachedEntries != nil || !entries.isEmpty
            sections.append(
                HijriMonthSection(
                    key: key,
                    entries: entries,
                    preview: previewInfo,
                    isLoaded: isLoaded
                )
            )
        }

        let extraSections = nearTermGrouped.keys
            .filter { key in
                sections.contains(where: { $0.key == key }) == false
            }
            .sorted { lhs, rhs in
                (nearTermGrouped[lhs]?.first?.schedule.date ?? .distantPast) < (nearTermGrouped[rhs]?.first?.schedule.date ?? .distantPast)
            }
            .map { key in
                HijriMonthSection(
                    key: key,
                    entries: nearTermGrouped[key] ?? [],
                    preview: nil,
                    isLoaded: true
                )
            }

        let resolvedSections = (sections + extraSections).sorted {
            ($0.preview?.startDate ?? $0.entries.first?.schedule.date ?? .distantPast) <
            ($1.preview?.startDate ?? $1.entries.first?.schedule.date ?? .distantPast)
        }
        let sectionIdentifiers = Set(resolvedSections.map(\.id))
        sectionCollapseOverrides = sectionCollapseOverrides.filter { sectionIdentifiers.contains($0.key) }
        loadingSectionIDs = loadingSectionIDs.filter { sectionIdentifiers.contains($0) }
        listSnapshot = AlarmListSnapshot(
            sections: resolvedSections,
            defaultExpandedSectionID: defaultExpandedSectionID ?? resolvedSections.first?.id
        )
    }

    private var showsAddButton: Bool {
        !editMode.isEditing
    }

    private func deleteEntries(in entries: [AlarmRowEntry], at offsets: IndexSet) {
        var pending: AlarmRowEntry?
        for index in offsets {
            guard entries.indices.contains(index) else { continue }
            let entry = entries[index]
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
        sectionCollapseOverrides[identifier] = !currentState
        guard currentState else { return }
        ensureMonthEntriesLoaded(for: section)
    }

    private func sectionIdentifier(_ key: HijriMonthKey) -> String {
        "\(key.year)-\(key.month)"
    }

    private func previewHeader(_ preview: HijriMonthPreview) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(preview.key.title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(adjustmentTag(for: preview.offsetDays))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text(Strings.AlarmsTab.hijriMonthStarts(shortDate(preview.startDate)))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
    }

    private func shortDate(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }

    private func adjustmentTag(for offsetDays: Int) -> String {
        switch offsetDays {
        case -1:
            return Strings.Settings.hijriMinusOneDay
        case 1:
            return Strings.Settings.hijriPlusOneDay
        default:
            return Strings.Settings.hijriNoChange
        }
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
                HStack {
                    Text(section.key.title)
                        .foregroundStyle(.primary)
                    Spacer()
                    if let preview = section.preview {
                        Text(adjustmentTag(for: preview.offsetDays))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                if let preview = section.preview {
                    Text(Strings.AlarmsTab.hijriMonthStarts(shortDate(preview.startDate)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isSectionCollapsed(section) ? 0 : 90))
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
                rebuildListSnapshot()
            }
        }
    }
}

private struct AlarmListSnapshot {
    let sections: [HijriMonthSection]
    let defaultExpandedSectionID: String?

    static let empty = AlarmListSnapshot(sections: [], defaultExpandedSectionID: nil)

    func defaultCollapsedState(for identifier: String) -> Bool {
        guard let defaultExpandedSectionID else { return true }
        return identifier != defaultExpandedSectionID
    }
}

enum AlarmRowPresentation {
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
        timeZone: TimeZone = .current,
        separator: String = " • "
    ) -> String {
        var parts: [String] = []
        let isTodayValue = isToday(date, currentDate: currentDate, timeZone: timeZone)
        let isTomorrowValue = isTomorrow(date, currentDate: currentDate, timeZone: timeZone)
        if isTodayValue {
            parts.append(Strings.AlarmsTab.todayLabel)
        } else if isTomorrowValue {
            parts.append(Strings.AlarmsTab.tomorrowLabel)
        }
        let gregorianLabel = (isTodayValue || isTomorrowValue)
            ? dateShortLabelFormatter.string(from: date)
            : dateLabelFormatter.string(from: date)
        parts.append(gregorianLabel)
        parts.append(HijriDateFormatter.shared.shortString(from: date))
        return parts.joined(separator: separator)
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
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static let dateShortLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()
}

private struct AlarmRowEntry: Identifiable {
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
    var id: String { activeDay.dateKey }

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

private enum AlarmRowDeleteCapability: Equatable {
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

    let schedule: DaySchedule
    let config: EffectiveDailyConfig
    let primaryDisplay: PrimaryDisplay?
    let primaryIntent: FastPrimaryIntent
    let secondaryTags: [FastSecondaryVirtueTag]
    let warnings: [FastWarning]
    let showsTags: Bool
    let deleteCapability: AlarmRowDeleteCapability
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
        schedule: DaySchedule,
        config: EffectiveDailyConfig,
        primaryDisplay: PrimaryDisplay?,
        primaryIntent: FastPrimaryIntent,
        secondaryTags: [FastSecondaryVirtueTag],
        warnings: [FastWarning],
        showsTags: Bool,
        deleteCapability: AlarmRowDeleteCapability,
        onSelect: @escaping () -> Void,
        onRequestRamadanDisable: @escaping () -> Void
    ) {
        self.schedule = schedule
        self.config = config
        self.primaryDisplay = primaryDisplay
        self.primaryIntent = primaryIntent
        self.secondaryTags = secondaryTags
        self.warnings = warnings
        self.showsTags = showsTags
        self.deleteCapability = deleteCapability
        self.onSelect = onSelect
        self.onRequestRamadanDisable = onRequestRamadanDisable
        _localIsOn = State(initialValue: AlarmRowView.isEnabled(config: config))
    }

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
            Button {
                onSelect()
            } label: {
                VStack(alignment: .leading, spacing: 10) {
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

                        Text(fajrLineText)
                            .font(.callout)
                            .foregroundStyle(isDisabled ? .tertiary : .secondary)
                            .monospacedDigit()
                    }

                    if showsTags {
                        HomeTagCapsuleRow(
                            primaryIntent: primaryIntent,
                            secondaryTags: secondaryTags,
                            warnings: warnings,
                            showPrimaryIntent: showPrimaryIntent,
                            isDisabled: isDisabled
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilitySummary)
            }
            .buttonStyle(.plain)
            .disabled(editMode?.wrappedValue.isEditing == true)

            Toggle("", isOn: dayActiveBinding)
                .labelsHidden()
                .tint(DawnColor.accent)
                .accessibilityLabel("\(primaryLabelText) alarm")
        }
        .padding(.vertical, 6)
        .overlay(alignment: .leading) {
            if editMode?.wrappedValue.isEditing == true, deleteCapability == .ramadan {
                Button(action: onRequestRamadanDisable) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .padding(.leading, -16)
                .accessibilityLabel("Turn off Ramadan alarm")
            }
        }
        .onChange(of: config) { _, newValue in
            localIsOn = AlarmRowView.isEnabled(config: newValue)
        }
    }

    private var fajrTimeText: String {
        TimeFormatters.timeFormatter.string(from: schedule.fajrDate)
    }

    private var primaryTimeText: String {
        if let primaryDisplay {
            return TimeFormatters.timeFormatter.string(from: primaryDisplay.time)
        }
        return TimeFormatters.timeFormatter.string(from: schedule.wakeDate)
    }

    private var primaryTimeDate: Date {
        primaryDisplay?.time ?? schedule.wakeDate
    }

    private var primaryTimeMain: String {
        AlarmRowView.timeMainFormatter.string(from: primaryTimeDate)
    }

    private var primaryTimeSuffix: String? {
        AlarmRowView.timeSuffixFormatter.string(from: primaryTimeDate)
    }

    private var fajrLineText: String {
        if config.iftarEnabled {
            let iftarTime = TimeFormatters.timeFormatter.string(from: schedule.iftarDate ?? schedule.maghribDate)
            return "Fajr \(fajrTimeText) • Iftar \(iftarTime)"
        }
        return "Fajr \(fajrTimeText)"
    }

    private var dateLabel: String {
        AlarmRowPresentation.dateLabel(for: schedule.date, separator: " • ")
    }

    private var dayActiveBinding: Binding<Bool> {
        Binding(get: {
            localIsOn
        }, set: { isOn in
            localIsOn = isOn
            let timeZone = TimeZone.current
            alarmConfigStore.setDayEnabled(isOn, for: schedule.date, timeZone: timeZone)
            scheduleManager.requestRescheduleDay(schedule.date)
        })
    }

    private var accessibilitySummary: String {
        var summary = "\(dateLabelWithPrefix). \(primaryLabelText) alarm. \(primaryTimeText). Fajr \(fajrTimeText)."
        if config.iftarEnabled {
            let iftarTime = TimeFormatters.timeFormatter.string(from: schedule.iftarDate ?? schedule.maghribDate)
            summary += " Iftar \(iftarTime)."
        }
        if let tagAccessibilityText {
            summary += " \(tagAccessibilityText)"
        }
        return summary
    }

    private var primaryLabelText: String {
        switch primaryDisplay?.kind ?? .suhoor {
        case .suhoor:
            return "Suhoor"
        case .reminder:
            return "Reminder"
        case .fajr:
            return "Fajr"
        case .iftar:
            return "Iftar"
        }
    }

    private var isDisabled: Bool {
        !localIsOn
    }

    private var dateLabelWithPrefix: String {
        AlarmRowPresentation.dateLabel(for: schedule.date, separator: ", ")
    }

    private var tagAccessibilityText: String? {
        guard showsTags else { return nil }
        var titles: [String] = []
        titles.append(contentsOf: warnings.map(\.title))
        if showPrimaryIntent {
            titles.append(primaryIntent.style.title)
        }
        titles.append(contentsOf: secondaryTags.map { $0.title })
        return "Tags: \(titles.joined(separator: ", "))."
    }

    private var showPrimaryIntent: Bool {
        primaryIntent != .other || !secondaryTags.isEmpty
    }

    private static func isEnabled(config: EffectiveDailyConfig) -> Bool {
        !config.skipDay && config.hasAnyEnabled
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

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(warnings, id: \.self) { warning in
                HomeWarningCapsule(warning: warning, isDisabled: isDisabled)
            }
            if showPrimaryIntent {
                HomeTagCapsule(style: primaryIntent.style, prominence: .strong, isDisabled: isDisabled)
            }
            ForEach(secondaryTags, id: \.self) { tag in
                HomeTagCapsule(style: tag.style, prominence: .subtle, isDisabled: isDisabled)
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

    var body: some View {
        let base = style.color
        let fillOpacity = prominence == .strong ? 0.18 : 0.10
        let strokeOpacity = prominence == .strong ? 0.35 : 0.22

        HStack(spacing: 5) {
            if let systemImage = style.systemImage {
                Image(systemName: systemImage)
            }
            Text(style.shortTitle)
                .lineLimit(1)
        }
            .font(.caption.weight(.semibold))
            .foregroundStyle(base)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
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

private struct HomeWarningCapsule: View {
    let warning: FastWarning
    let isDisabled: Bool

    var body: some View {
        let base = Color.red
        let fillOpacity: Double = 0.08
        let strokeOpacity: Double = 0.35

        HStack(spacing: 5) {
            Image(systemName: warning.systemImage)
            Text(warning.title)
                .lineLimit(1)
        }
            .font(.caption.weight(.semibold))
            .foregroundStyle(base)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
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
