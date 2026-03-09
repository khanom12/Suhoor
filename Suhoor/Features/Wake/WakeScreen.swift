import CoreLocation
import SwiftUI
import UIKit

struct WakeScreen: View {
    @EnvironmentObject private var appNavigator: AppNavigator
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewState = WakeListState()

    var body: some View {
        List {
            Section(Strings.AlarmsTab.nextAlarmSectionTitle) {
                if !viewState.listSnapshot.nextWakeEntries.isEmpty {
                    ForEach(viewState.listSnapshot.nextWakeEntries) { entry in
                        wakeRow(for: entry, isPinnedNextWake: true)
                            .deleteDisabled(entry.deleteCapability == .ramadan)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    .onDelete { offsets in
                        withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
                            deleteEntries(in: viewState.listSnapshot.nextWakeEntries, at: offsets)
                        }
                    }
                } else if viewState.listSnapshot.sections.isEmpty {
                    emptyStateView
                } else {
                    Text(Strings.AlarmList.notSetUp)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, DesignTokens.spacingS)
                }
            }
            .textCase(nil)

            if viewState.tagFilter.isActive {
                Section {
                    activeFilterBar
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }

            if !viewState.listSnapshot.sections.isEmpty {
                ForEach(viewState.listSnapshot.sections) { section in
                    Section {
                        if !isSectionCollapsed(section) {
                            Group {
                                if section.entries.isEmpty {
                                    if viewState.loadingSectionIDs.contains(section.id) {
                                        HStack {
                                            ProgressView()
                                            Text("Loading")
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
                                        wakeRow(for: entry)
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
        .environment(\.editMode, Binding(
            get: { viewState.editMode },
            set: { viewState.editMode = $0 }
        ))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(viewState.editMode.isEditing ? "Done" : "Edit") {
                    viewState.editMode = viewState.editMode.isEditing ? .inactive : .active
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !viewState.editMode.isEditing {
                    Button {
                        appNavigator.switchToPlans()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                Button {
                    handle(.openFilter)
                } label: {
                    Image(systemName: viewState.tagFilter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .confirmationDialog(
            "Remove scheduled morning",
            isPresented: Binding(
                get: { viewState.pendingSeriesDeleteEntry != nil },
                set: { if !$0 { viewState.pendingSeriesDeleteEntry = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let entry = viewState.pendingSeriesDeleteEntry {
                let excludable = entry.excludableProvenances
                if excludable.count == 1, let provenance = excludable.first {
                    Button("Remove this morning only") {
                        Task {
                            await deleteDayOnly(entry: entry, provenance: provenance)
                            await MainActor.run { viewState.pendingSeriesDeleteEntry = nil }
                        }
                    }
                } else {
                    Button("Remove this morning from all plans", role: .destructive) {
                        Task {
                            await deleteDayFromAllSchedules(entry: entry, provenances: excludable)
                            await MainActor.run { viewState.pendingSeriesDeleteEntry = nil }
                        }
                    }
                    ForEach(excludable, id: \.id) { provenance in
                        Button("Remove this morning from \(provenance.label)") {
                            Task {
                                await deleteDayOnly(entry: entry, provenance: provenance)
                                await MainActor.run { viewState.pendingSeriesDeleteEntry = nil }
                            }
                        }
                    }
                }

                ForEach(entry.stoppableProvenances, id: \.id) { provenance in
                    let title = provenance.stopSeriesLabel ?? "Remove schedule"
                    Button(title, role: .destructive) {
                        Task {
                            await scheduleManager.stopSeries(for: provenance)
                            await MainActor.run { viewState.pendingSeriesDeleteEntry = nil }
                        }
                    }
                }

                Button(Strings.Settings.cancel, role: .cancel) {}
            }
        }
        .alert(
            "Ramadan mornings can't be deleted",
            isPresented: Binding(
                get: { viewState.pendingRamadanEntry != nil },
                set: { if !$0 { viewState.pendingRamadanEntry = nil } }
            )
        ) {
            Button("Turn off for this day") {
                if let entry = viewState.pendingRamadanEntry {
                    alarmConfigStore.setDayEnabled(false, for: entry.schedule.date, timeZone: .current)
                    scheduleManager.requestRescheduleDay(entry.schedule.date)
                }
                viewState.pendingRamadanEntry = nil
            }
            Button(Strings.Settings.cancel, role: .cancel) {
                viewState.pendingRamadanEntry = nil
            }
        } message: {
            Text("This date is part of Ramadan. You can still turn it off for the day.")
        }
        .navigationDestination(isPresented: navigationIsActiveBinding) {
            if let schedule = viewState.selectedSchedule {
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
        .onChange(of: viewState.tagFilter) { _, _ in
            refreshListSnapshot(animated: true)
        }
        .sheet(isPresented: Binding(
            get: { viewState.showTagFilterSheet },
            set: { viewState.showTagFilterSheet = $0 }
        )) {
            WakeTagFilterSheet(filter: Binding(
                get: { viewState.tagFilter },
                set: { viewState.tagFilter = $0 }
            ))
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
        viewState.tagFilter.isActive ? Strings.AlarmsTab.emptyFilteredMonth : Strings.AlarmsTab.emptyMonth
    }

    private func wakeRow(for entry: WakeRowEntry, isPinnedNextWake: Bool = false) -> some View {
        WakeRowView(
            entry: entry,
            deleteCapability: entry.deleteCapability,
            onToggleChanged: { isOn in
                handle(.toggleDayEnabled(dateKey: entry.id, enabled: isOn))
                guard isPinnedNextWake else { return }
                handlePinnedNextWakeToggleChange(for: entry, isOn: isOn)
            },
            onSelect: {
                handle(isPinnedNextWake ? .adjustDay(dateKey: entry.id) : .openDay(dateKey: entry.id))
            },
            onRequestRamadanDisable: {
                viewState.pendingRamadanEntry = entry
            }
        )
    }

    private func refreshListSnapshot(animated: Bool) {
        let shouldAnimate = animated || viewState.animatePinnedNextWakeUpdates
        viewState.animatePinnedNextWakeUpdates = false
        let update = {
            let result = scheduleManager.wakeListSnapshot(
                tagFilter: viewState.tagFilter,
                pinnedEntryIDs: viewState.pinnedNextWakeEntryIDs,
                timeZone: .current
            )
            viewState.pinnedNextWakeEntryIDs = result.pinnedEntryIDs
            let sectionIdentifiers = Set(result.snapshot.sections.map(\.id))
            viewState.sectionCollapseOverrides = viewState.sectionCollapseOverrides.filter { sectionIdentifiers.contains($0.key) }
            viewState.loadingSectionIDs = viewState.loadingSectionIDs.filter { sectionIdentifiers.contains($0) }
            viewState.listSnapshot = result.snapshot
            if result.snapshot.nextWakeEntries.isEmpty {
                viewState.sectionCollapseOverrides = [:]
                viewState.loadingSectionIDs = []
            }
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

    private func deleteEntries(in entries: [WakeRowEntry], at offsets: IndexSet) {
        var pending: WakeRowEntry?
        for index in offsets {
            guard entries.indices.contains(index) else { continue }
            let entry = entries[index]
            viewState.pinnedNextWakeEntryIDs.removeAll { $0 == entry.id }
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
            viewState.pendingSeriesDeleteEntry = pending
        }
    }

    private func deleteOneOff(_ entry: WakeRowEntry) {
        let date = entry.schedule.date
        Task { await scheduleManager.deleteExplicitScheduledDate(date) }
    }

    private func deleteDayOnly(entry: WakeRowEntry, provenance: ResolvedScheduledDateProvenance) async {
        await scheduleManager.deleteDayAndSuppress(
            entry.schedule.date,
            scopes: [WakeRowActionResolver.suppressionScope(for: provenance)],
            deleteExplicit: entry.hasExplicitOneOff
        )
    }

    private func deleteDayFromAllSchedules(
        entry: WakeRowEntry,
        provenances: [ResolvedScheduledDateProvenance]
    ) async {
        let scopes = provenances.map { WakeRowActionResolver.suppressionScope(for: $0) }
        await scheduleManager.deleteDayAndSuppress(
            entry.schedule.date,
            scopes: scopes,
            deleteExplicit: entry.hasExplicitOneOff
        )
    }

    private func isSectionCollapsed(_ section: WakeMonthSection) -> Bool {
        viewState.sectionCollapseOverrides[section.id] ?? viewState.listSnapshot.defaultCollapsedState(for: section.id)
    }

    private func toggleSectionCollapse(_ section: WakeMonthSection) {
        let currentState = isSectionCollapsed(section)
        withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
            viewState.sectionCollapseOverrides[section.id] = !currentState
        }
        guard currentState else { return }
        handle(.expandMonth(monthKey: section.key))
    }

    @ViewBuilder
    private func headerLabel(for section: WakeMonthSection) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                    Text(section.key.title)
                        .foregroundStyle(.primary)
                    Spacer(minLength: DesignTokens.spacingS)
                    MonthWakeCountBadge(count: section.visibleAlarmCount)
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

                ForEach(viewState.tagFilter.selectedItems) { item in
                    WakeFilterChip(
                        style: item.style,
                        prominence: item.isPrimary ? .strong : .subtle,
                        isDisabled: false,
                        showsTitle: true,
                        isCompact: false
                    )
                }

                Button(Strings.AlarmsTab.filterClear) {
                    viewState.tagFilter.clear()
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, 4)
        }
    }

    private func ensureExpandedSectionsLoaded() {
        for section in viewState.listSnapshot.sections where !isSectionCollapsed(section) {
            ensureMonthEntriesLoaded(for: section)
        }
    }

    private func ensureMonthEntriesLoaded(for section: WakeMonthSection) {
        guard !section.isLoaded else { return }
        guard !viewState.loadingSectionIDs.contains(section.id) else { return }

        viewState.loadingSectionIDs.insert(section.id)
        Task {
            _ = await scheduleManager.monthEntries(for: section.key, timeZone: .current)
            await MainActor.run {
                viewState.loadingSectionIDs.remove(section.id)
                refreshListSnapshot(animated: false)
            }
        }
    }

    private func handlePinnedNextWakeToggleChange(for entry: WakeRowEntry, isOn: Bool) {
        let updatedPinnedEntryIDs = WakeListSelection.pinnedEntryIDs(
            afterToggling: entry.id,
            isOn: isOn,
            currentPinnedEntryIDs: viewState.pinnedNextWakeEntryIDs
        )
        guard updatedPinnedEntryIDs != viewState.pinnedNextWakeEntryIDs else { return }
        viewState.animatePinnedNextWakeUpdates = true
        viewState.pinnedNextWakeEntryIDs = updatedPinnedEntryIDs
    }

    private func handle(_ intent: WakeIntent) {
        switch intent {
        case .openDay(let dateKey), .adjustDay(let dateKey):
            viewState.selectedSchedule = scheduleForDateKey(dateKey)
        case .toggleDayEnabled(let dateKey, let enabled):
            guard let schedule = scheduleForDateKey(dateKey) else { return }
            alarmConfigStore.setDayEnabled(enabled, for: schedule.date, timeZone: .current)
            scheduleManager.requestRescheduleDay(schedule.date)
        case .openFilter:
            viewState.showTagFilterSheet = true
        case .expandMonth(let monthKey):
            if let section = viewState.listSnapshot.sections.first(where: { $0.key == monthKey }) {
                ensureMonthEntriesLoaded(for: section)
            }
        case .deleteDay:
            break
        }
    }

    private func scheduleForDateKey(_ dateKey: String) -> DaySchedule? {
        if let entry = viewState.listSnapshot.nextWakeEntries.first(where: { $0.id == dateKey }) {
            return entry.schedule
        }
        for section in viewState.listSnapshot.sections {
            if let entry = section.entries.first(where: { $0.id == dateKey }) {
                return entry.schedule
            }
        }
        return scheduleManager.activeWindowSnapshot.byDateKey[dateKey]?.schedule
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

    private func shortDate(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }

    private var navigationIsActiveBinding: Binding<Bool> {
        Binding(
            get: { viewState.selectedSchedule != nil },
            set: { if !$0 { viewState.selectedSchedule = nil } }
        )
    }
}
