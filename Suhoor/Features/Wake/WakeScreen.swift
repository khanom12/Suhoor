import SwiftUI
import UIKit

private enum WakeDestination: Identifiable, Hashable {
    case day(DaySchedule)
    case fajrcast(selectedDateKey: String?)

    var id: String {
        switch self {
        case .day(let schedule):
            return "day-\(schedule.id)"
        case .fajrcast(let selectedDateKey):
            return "fajrcast-\(selectedDateKey ?? "default")"
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewState = WakeListState()
    @State private var destination: WakeDestination?
    @State private var weeklyFajrcastSnapshot: FajrWindowCompactSnapshot?
    @State private var lastRefreshContext: FajrWindowRefreshContext?
    @State private var isVisible = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                if featuredEntry == nil && monthSections.isEmpty {
                    emptyStateView
                } else {
                    if let weeklyFajrcastSnapshot {
                        WeeklyFajrcastCard(snapshot: weeklyFajrcastSnapshot) {
                            destination = .fajrcast(selectedDateKey: weeklyFajrcastSnapshot.selectedDay.dateKey)
                        }
                    }

                    if let featuredEntry {
                        WakeFeaturedEntryCard(
                            entry: featuredEntry
                        ) {
                            destination = .day(featuredEntry.schedule)
                        }
                    }

                    if !monthSections.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                            AppSectionHeader("Upcoming wakes")

                            ForEach(monthSections) { section in
                                VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                                    WakeMonthSectionHeader(
                                        title: section.key.title
                                    )

                                    if section.entries.isEmpty {
                                        WakeGlassCard(padding: 10) {
                                            Text("More mornings load here as you browse.")
                                                .font(AppTypography.rowBody)
                                                .foregroundStyle(WakeGlassTheme.secondaryText)
                                        }
                                    } else {
                                        AppInsetGroup {
                                            ForEach(Array(section.entries.enumerated()), id: \.element.id) { index, entry in
                                                WakeRowView(
                                                    entry: entry
                                                ) {
                                                    destination = .day(entry.schedule)
                                                }

                                                .padding(.horizontal, DesignTokens.spacingM)

                                                if index < section.entries.count - 1 {
                                                    AppGroupDivider(inset: DesignTokens.spacingM)
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .onAppear {
                                    ensureMonthEntriesLoaded(for: section)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacingM)
            .padding(.top, DesignTokens.spacingS)
            .padding(.bottom, DesignTokens.spacingL)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: DesignTokens.spacingXL)
        }
        .appScrollableChrome()
        .navigationTitle(Strings.AlarmsTab.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $destination) { destination in
            switch destination {
            case .day(let schedule):
                AlarmDayDetailView(schedule: schedule)
            case .fajrcast(let selectedDateKey):
                FajrWindowDetailView(
                    initialPeriod: .sevenDays,
                    initialSelectedDateKey: selectedDateKey
                )
            }
        }
        .onAppear {
            isVisible = true
            refreshWakeSurfaceIfNeeded(force: true)
        }
        .onDisappear {
            isVisible = false
        }
        .onChange(of: scheduleManager.currentRevision) { _, _ in
            guard isVisible else { return }
            refreshWakeSurfaceIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard isVisible, newPhase == .active else { return }
            refreshWakeSurfaceIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            guard isVisible else { return }
            refreshWakeSurfaceIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            guard isVisible else { return }
            refreshWakeSurfaceIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            guard isVisible else { return }
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
            weeklyFajrcastSnapshot = scheduleManager.fajrWindowCompactSnapshot(timeZone: currentTimeZone)
            let sectionIdentifiers = Set(result.snapshot.sections.map(\.id))
            viewState.loadingSectionIDs = viewState.loadingSectionIDs.filter { sectionIdentifiers.contains($0) }
            viewState.listSnapshot = result.snapshot
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
}
