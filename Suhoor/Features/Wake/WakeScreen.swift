import SwiftUI
import UIKit

struct WakeScreen: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewState = WakeListState()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                if let summary = scheduleManager.wakeSurfaceSnapshot.nextWakeEventSummary {
                    Button {
                        viewState.selectedSchedule = summary.day.schedule
                    } label: {
                        FeaturedTomorrowCard(
                            summary: summary,
                            hasOverride: scheduleManager.wakeSurfaceSnapshot.overrideDateKeys.contains(summary.day.dateKey)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    emptyStateView
                }

                ForEach(visibleSections) { section in
                    VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                        headerLabel(for: section)

                        if section.entries.isEmpty {
                            HStack(spacing: DesignTokens.spacingS) {
                                ProgressView()
                                Text("Loading upcoming mornings")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .task {
                                ensureMonthEntriesLoaded(for: section)
                            }
                        } else {
                            ForEach(section.entries) { entry in
                                WakeRowView(entry: entry) {
                                    viewState.selectedSchedule = entry.schedule
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, DesignTokens.spacingL)
        .padding(.vertical, DesignTokens.spacingL)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Wake")
        .navigationBarTitleDisplayMode(.large)
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

    private var visibleSections: [WakeMonthSection] {
        viewState.listSnapshot.sections.filter {
            !$0.entries.isEmpty || viewState.loadingSectionIDs.contains($0.id) || !$0.isLoaded
        }
    }

    private func refreshListSnapshot(animated: Bool) {
        let update = {
            let result = scheduleManager.wakeListSnapshot(tagFilter: WakeTagFilter(), pinnedEntryIDs: [], timeZone: .current)
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

    @ViewBuilder
    private func headerLabel(for section: WakeMonthSection) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                    Text(section.key.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer(minLength: DesignTokens.spacingS)
                    MonthWakeCountBadge(count: section.visibleAlarmCount)
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
            _ = await scheduleManager.monthEntries(for: section.key, timeZone: .current)
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

private struct FeaturedTomorrowCard: View {
    let summary: NextWakeEventSummary
    let hasOverride: Bool

    var body: some View {
        GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.18) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                Text("Tomorrow")
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(.secondary)

                Text(TimeFormatters.timeFormatter.string(from: summary.day.schedule.wakeDate))
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                Text(ProductSurfacePresentation.dayMeaningText(for: summary.day, style: .wakeRow))
                    .font(DesignTokens.cardTitleFont)

                VStack(alignment: .leading, spacing: 4) {
                    Text(ProductSurfacePresentation.wakeRelationText(
                        delta: summary.day.decisionLog.resolvedDelta,
                        anchor: summary.day.decisionLog.resolvedAnchor.type
                    ))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                    Text("Fajr at \(TimeFormatters.timeFormatter.string(from: summary.day.schedule.fajrDate))")
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
