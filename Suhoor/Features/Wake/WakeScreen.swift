import SwiftUI
import UIKit

private enum WakeDestination: Identifiable, Hashable {
    case fajrWindow
    case day(DaySchedule)

    var id: String {
        switch self {
        case .fajrWindow:
            return "fajr-window"
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewState = WakeListState()
    @State private var destination: WakeDestination?
    @State private var compactFajrWindowSnapshot: FajrWindowCompactSnapshot?
    @State private var lastRefreshContext: FajrWindowRefreshContext?

    var body: some View {
        let wakeSnapshot = scheduleManager.wakeSurfaceSnapshot

        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                VStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                    if let compactFajrWindowSnapshot {
                        FajrWindowCompactCard(snapshot: compactFajrWindowSnapshot) {
                            destination = .fajrWindow
                        }
                    }

                    if let summary = wakeSnapshot.nextWakeEventSummary {
                        Button {
                            destination = .day(summary.day.schedule)
                        } label: {
                            FeaturedTomorrowCard(
                                summary: summary,
                                hasOverride: wakeSnapshot.overrideDateKeys.contains(summary.day.dateKey)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        emptyStateView
                    }
                }

                if !visibleSections.isEmpty {
                    AppSectionHeader(
                        "Upcoming mornings",
                        subtitle: "Your next stretch of mornings, with each day ready for edits."
                    )
                }

                ForEach(visibleSections) { section in
                    VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                        headerLabel(for: section)

                        AppInsetGroup {
                            if section.entries.isEmpty {
                                HStack(spacing: DesignTokens.spacingS) {
                                    ProgressView()
                                    Text("Loading more mornings")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, DesignTokens.spacingL)
                                .padding(.vertical, DesignTokens.spacingL)
                                .task {
                                    ensureMonthEntriesLoaded(for: section)
                                }
                            } else {
                                ForEach(Array(section.entries.enumerated()), id: \.element.id) { index, entry in
                                    WakeRowView(entry: entry) {
                                        destination = .day(entry.schedule)
                                    }
                                    .padding(.horizontal, DesignTokens.spacingL)
                                    .padding(.vertical, 10)

                                    if index < section.entries.count - 1 {
                                        AppGroupDivider()
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, DesignTokens.spacingL)
        }
        .appScrollableChrome()
        .navigationTitle("Wake")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $destination) { destination in
            switch destination {
            case .fajrWindow:
                FajrWindowDetailView(initialPeriod: .sevenDays)
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
            Text("No mornings are ready yet")
                .font(.headline.weight(.semibold))
            Text(emptyStateDetail)
                .font(.subheadline)
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
        return "Shape your daily morning plan in Plans and Suhoor will bring the next wake here."
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var visibleSections: [WakeMonthSection] {
        viewState.listSnapshot.sections.filter {
            !$0.entries.isEmpty || viewState.loadingSectionIDs.contains($0.id) || !$0.isLoaded
        }
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
        refreshCompactFajrWindowSnapshot()
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

    private func refreshCompactFajrWindowSnapshot() {
        let snapshot = scheduleManager.fajrWindowCompactSnapshot(timeZone: currentTimeZone)
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            compactFajrWindowSnapshot = snapshot
        }
    }

    @ViewBuilder
    private func headerLabel(for section: WakeMonthSection) -> some View {
        AppSectionHeader(section.key.title, subtitle: previewText(for: section)) {
            MonthWakeCountBadge(count: section.visibleAlarmCount)
        }
    }

    private func previewText(for section: WakeMonthSection) -> String? {
        guard let preview = section.preview else { return nil }

        if let adjustment = adjustmentTag(for: preview.offsetDays) {
            return "\(monthStartLabel(for: preview.startDate)) · \(adjustment)"
        }

        return monthStartLabel(for: preview.startDate)
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

    private func monthStartLabel(
        for date: Date,
        currentDate: Date = Date(),
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> String {
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

}

private struct FeaturedTomorrowCard: View {
    let summary: NextWakeEventSummary
    let hasOverride: Bool

    var body: some View {
        AppGlassSurface(variant: .standard, prominence: .high) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                Text("Next morning")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.4)

                AppHeroMetric(
                    value: TimeFormatters.timeFormatter.string(from: summary.day.schedule.wakeDate),
                    title: ProductSurfacePresentation.dayMeaningText(for: summary.day, style: .wakeRow)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(ProductSurfacePresentation.wakeRelationText(
                        delta: summary.day.decisionLog.resolvedDelta,
                        anchor: summary.day.decisionLog.resolvedAnchor.type
                    ))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                    Text("Fajr begins at \(TimeFormatters.timeFormatter.string(from: summary.day.schedule.fajrDate))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    if hasOverride {
                        Text("Adjusted for this date")
                            .font(.footnote)
                            .foregroundStyle(DawnColor.accent)
                    }
                }
            }
        }
    }
}
