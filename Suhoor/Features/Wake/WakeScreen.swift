import SwiftUI
import UIKit

private enum WakeDestination: Identifiable, Hashable {
    case day(DaySchedule)

    var id: String {
        switch self {
        case .day(let schedule):
            return "day-\(schedule.id)"
        }
    }

    static func == (lhs: WakeDestination, rhs: WakeDestination) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct WakeScreen: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewState = WakeListState()
    @State private var destination: WakeDestination?
    @State private var lastRefreshContext: FajrWindowRefreshContext?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                if featuredEntry == nil && monthSections.isEmpty {
                    emptyStateView
                } else {
                    if let featuredEntry {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                            AppSectionHeader("Next wake", subtitle: "Tomorrow stays calm here, and details open on tap.")

                            WakeFeaturedEntryCard(
                                entry: featuredEntry,
                                isEnabled: dayEnabledBinding(for: featuredEntry)
                            ) {
                                destination = .day(featuredEntry.schedule)
                            }
                        }
                    }

                    ForEach(monthSections) { section in
                        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                            WakeMonthSectionHeader(
                                title: section.key.title,
                                count: section.visibleAlarmCount
                            )

                            if section.entries.isEmpty {
                                AppGlassSurface(variant: .quiet) {
                                    Text("Upcoming mornings in this month load as soon as they are needed.")
                                        .font(AppTypography.rowBody)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                AppInsetGroup {
                                    ForEach(Array(section.entries.enumerated()), id: \.element.id) { index, entry in
                                        WakeRowView(
                                            entry: entry,
                                            isEnabled: dayEnabledBinding(for: entry)
                                        ) {
                                            destination = .day(entry.schedule)
                                        }
                                        .padding(.horizontal, DesignTokens.spacingM)
                                        .padding(.vertical, DesignTokens.space8)

                                        if index < section.entries.count - 1 {
                                            AppGroupDivider(inset: DesignTokens.spacingM)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.top, DesignTokens.spacingS)
            .padding(.bottom, DesignTokens.spacingL)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: DesignTokens.tabBarHeight + DesignTokens.spacingL)
        }
        .appScrollableChrome()
        .navigationTitle(Strings.AlarmsTab.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $destination) { destination in
            switch destination {
            case .day(let schedule):
                AlarmDayDetailView(schedule: schedule)
            }
        }
        .task {
            refreshWakeSurfaceIfNeeded(force: true)
        }
        .onChange(of: scheduleManager.currentRevision) { _, _ in
            refreshWakeSurfaceIfNeeded()
        }
        .onChange(of: alarmConfigStore.currentRevision) { _, _ in
            refreshWakeSurfaceIfNeeded(force: true)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refreshWakeSurfaceIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refreshWakeSurfaceIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshWakeSurfaceIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            refreshWakeSurfaceIfNeeded()
        }
    }

    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            Text(Strings.AlarmsTab.emptyTitle)
                .font(AppTypography.cardTitle)
            Text(emptyStateDetail)
                .font(AppTypography.rowBody)
                .foregroundStyle(.secondary)
            PermissionStackView(
                kinds: [.location, .alarmKit, .notifications],
                refreshKey: scheduleManager.permissionSummary,
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

    private var featuredEntry: WakeRowEntry? {
        viewState.listSnapshot.nextWakeEntries.first
    }

    private var monthSections: [WakeMonthSection] {
        viewState.listSnapshot.sections.filter { !$0.entries.isEmpty || !$0.isLoaded }
    }

    private var currentTimeZone: TimeZone {
        .autoupdatingCurrent
    }

    private var refreshContext: FajrWindowRefreshContext {
        FajrWindowRefreshContext.current(
            revision: scheduleManager.currentRevision,
            timeZone: currentTimeZone
        )
    }

    private func refreshWakeSurfaceIfNeeded(force: Bool = false) {
        let nextContext = refreshContext
        guard force || lastRefreshContext != nextContext else { return }
        lastRefreshContext = nextContext
        refreshListSnapshot(animated: false)
    }

    private func refreshListSnapshot(animated: Bool) {
        let update = {
            let result = scheduleManager.wakeListSnapshot(
                tagFilter: WakeTagFilter(),
                pinnedEntryIDs: [],
                timeZone: currentTimeZone
            )
            let sectionIdentifiers = Set(result.snapshot.sections.map(\.id))
            viewState.loadingSectionIDs = viewState.loadingSectionIDs.filter { sectionIdentifiers.contains($0) }
            viewState.listSnapshot = result.snapshot
            ensureVisibleSectionsLoaded()
        }

        if animated {
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

    private func ensureVisibleSectionsLoaded() {
        for section in viewState.listSnapshot.sections {
            ensureMonthEntriesLoaded(for: section)
        }
    }

    private func ensureMonthEntriesLoaded(for section: WakeMonthSection) {
        guard !section.isLoaded else { return }
        guard !viewState.loadingSectionIDs.contains(section.id) else { return }

        viewState.loadingSectionIDs.insert(section.id)
        Task {
            _ = await scheduleManager.monthEntries(for: section.key, timeZone: currentTimeZone)
            await MainActor.run {
                viewState.loadingSectionIDs.remove(section.id)
                refreshListSnapshot(animated: false)
            }
        }
    }

    private func dayEnabledBinding(for entry: WakeRowEntry) -> Binding<Bool> {
        Binding(
            get: {
                if let activeDay = scheduleManager.activeDay(for: entry.schedule.date, timeZone: currentTimeZone) {
                    return !activeDay.effectiveConfig.skipDay && activeDay.effectiveConfig.hasAnyEnabled
                }
                return entry.isEnabled
            },
            set: { newValue in
                alarmConfigStore.setDayEnabled(
                    newValue,
                    for: entry.schedule.date,
                    timeZone: currentTimeZone
                )
                scheduleManager.requestRescheduleDay(entry.schedule.date)
                refreshWakeSurfaceIfNeeded(force: true)
            }
        )
    }
}
