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
        let wakeSnapshot = scheduleManager.wakeSurfaceSnapshot

        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                if upcomingEntries.isEmpty {
                    emptyStateView
                } else {
                    AppInsetGroup {
                        ForEach(Array(upcomingEntries.enumerated()), id: \.element.id) { index, entry in
                            WakeRowView(
                                entry: entry,
                                isEnabled: dayEnabledBinding(for: entry)
                            ) {
                                destination = .day(entry.schedule)
                            }
                            .padding(.horizontal, DesignTokens.spacingM)
                            .padding(.vertical, DesignTokens.space8)

                            if index < upcomingEntries.count - 1 {
                                AppGroupDivider(inset: DesignTokens.spacingM)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)

                    if additionalUpcomingCount > 0 {
                        Text("\(additionalUpcomingCount) more mornings coming up after this list.")
                            .font(AppTypography.rowBody)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, DesignTokens.spacingS)
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

    private var upcomingEntries: [WakeRowEntry] {
        Array(
            visibleAlarmEntries
            .prefix(7)
        )
    }

    private var additionalUpcomingCount: Int {
        max(visibleAlarmEntries.count - upcomingEntries.count, 0)
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

    private func wakeEntries(from snapshot: WakeSurfaceSnapshot) -> [WakeRowEntry] {
        snapshot.visibleDays.map {
            WakeRowActionResolver.makeEntry(
                activeDay: $0,
                overrideDateKeys: snapshot.overrideDateKeys
            )
        }
    }

    private var visibleAlarmEntries: [WakeRowEntry] {
        let now = Date()
        return wakeEntries(from: scheduleManager.wakeSurfaceSnapshot).filter {
            shouldShowOnAlarmScreen($0, now: now)
        }
    }

    private func shouldShowOnAlarmScreen(_ entry: WakeRowEntry, now: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = currentTimeZone

        let entryDay = calendar.startOfDay(for: entry.schedule.date)
        let today = calendar.startOfDay(for: now)

        if entryDay > today {
            return true
        }

        guard entryDay == today else {
            return false
        }

        let lastMorningAlarm = entry.activeDay.scheduledEvents
            .filter(\.isUserVisible)
            .filter { event in
                switch event.type {
                case .wakeReminder, .wakeAlarm, .wakeFollowUp, .fajrBoundaryNotice:
                    return true
                case .iftarReminder:
                    return false
                }
            }
            .map(\.fireDate)
            .max()

        guard let lastMorningAlarm else {
            return true
        }

        return lastMorningAlarm >= now
    }

    private func dayEnabledBinding(for entry: WakeRowEntry) -> Binding<Bool> {
        Binding(
            get: {
                wakeEntries(from: scheduleManager.wakeSurfaceSnapshot)
                    .first(where: { $0.id == entry.id })?
                    .isEnabled ?? entry.isEnabled
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
