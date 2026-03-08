import SwiftUI

struct TodayHomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fajrLogStore: FajrLogStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var dismissalStore = TodayCardDismissalStore()

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            let now = context.date
            let hijriComponents = AdjustedHijriCalendar.shared.adjustedComponents(for: now, timeZone: .current)
            let todayKey = DateHelpers.dayIdentifier(for: now, timeZone: .current)
            let todayStart = DateHelpers.startOfDay(now, in: .current)
            let currentDay = scheduleManager.activeWindowSnapshot.byDateKey[todayKey]
            let contextDay = scheduleManager.nextWakeEventSummary?.day ?? currentDay
            let todaySchedule = currentDay?.schedule ?? scheduleManager.schedule(for: todayStart)
            let supportCard = ProductSurfacePresentation.homeSupportCard(
                now: now,
                currentDay: currentDay,
                todaySchedule: todaySchedule,
                fajrStatus: fajrLogStore.status(for: todayKey),
                fastStatus: fastLogStore.status(for: todayKey),
                permissionSnapshot: scheduleManager.permissionSnapshot,
                hijriComponents: hijriComponents,
                dismissedWarnings: dismissedWarnings(on: now)
            )

            ScrollView {
                LazyVStack(spacing: DesignTokens.dashboardStackSpacing) {
                    TodayNextWakeHeroCard()

                    TodayDateContextStrip(
                        now: now,
                        contextDay: contextDay
                    )

                    if let supportCard {
                        supportCardView(
                            for: supportCard,
                            now: now
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.top, DesignTokens.spacingXS)
                .padding(.bottom, DesignTokens.spacingXL)
            }
            .background(
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            )
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Open Settings")
                }
            }
            .onAppear { _ = scheduleManager.lastUpdated }
        }
    }

    private func dismissedWarnings(on now: Date) -> Set<FastWarning> {
        Set(FastWarning.allCases.filter { dismissalStore.isDismissed($0, on: now) })
    }

    @ViewBuilder
    private func supportCardView(
        for presentation: HomeSupportCardPresentation,
        now: Date
    ) -> some View {
        switch presentation {
        case .blockingIssue(let permissionKind):
            if let presentation = scheduleManager.permissionSnapshot.presentations[permissionKind] {
                TodayBlockingIssueCard(presentation: presentation)
            }
        case .fajrCompletionPrompt(let presentation):
            TodayFajrCheckInCard(presentation: presentation)
        case .forbiddenFastNotice(let warning):
            TodayForbiddenFastDayCard(
                kind: warning,
                mode: .live,
                onDismiss: {
                    withAnimation(Motion.fade(reduceMotion: reduceMotion)) {
                        dismissalStore.dismiss(warning, on: now)
                    }
                }
            )
        case .fasting(let presentation):
            TodayFastCheckInCard(presentation: presentation)
        }
    }
}

private struct TodayDateContextStrip: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    let now: Date
    let contextDay: ActiveAlarmDay?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            VStack(alignment: .leading, spacing: 2) {
                Text(GregorianDateFormatter.shared.headerString(for: now))
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(.secondary)

                Text(HijriDateFormatter.shared.string(from: now))
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(.secondary)
            }

            if let contextDay {
                HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                    Text(scheduleManager.dayLabel(for: contextDay.date))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.spacingXS) {
                            ContextChip(
                                title: ProductSurfacePresentation.primaryContextTitle(
                                    contextDay.resolvedDayContext.primaryContext
                                ),
                                prominence: .primary
                            )

                            ForEach(
                                ProductSurfacePresentation.meaningfulSecondaryContextTitles(
                                    from: contextDay.resolvedDayContext
                                ),
                                id: \.self
                            ) { title in
                                ContextChip(title: title, prominence: .secondary)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ContextChip: View {
    enum Prominence {
        case primary
        case secondary
    }

    let title: String
    let prominence: Prominence

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(prominence == .primary ? DawnColor.accent : Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        prominence == .primary
                            ? DawnColor.accent.opacity(0.12)
                            : Color(.secondarySystemGroupedBackground)
                    )
            )
    }
}

private struct TodayBlockingIssueCard: View {
    let presentation: PermissionPresentation

    var body: some View {
        GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.2) {
            VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                Text(presentation.title)
                    .font(DesignTokens.cardTitleFont)

                Text(presentation.message)
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(.secondary)

                Button(presentation.actionTitle ?? "Open Settings") {
                    NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
                }
                .buttonStyle(.borderedProminent)
                .tint(DawnColor.accent)
            }
        }
    }
}

private struct TodayNextWakeHeroCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.18) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                Text("Next wake")
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(.secondary)

                if let summary = scheduleManager.nextWakeEventSummary {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        Text(TimeFormatters.timeFormatter.string(from: summary.event.fireDate))
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                            .monospacedDigit()

                        Text(summaryLabel(for: summary))
                            .font(DesignTokens.cardTitleFont)

                        Text("\(summary.relationText) · Fajr \(TimeFormatters.timeFormatter.string(from: summary.day.schedule.fajrDate))")
                            .font(DesignTokens.cardMetaFont)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        Text("No wake yet")
                            .font(DesignTokens.cardTitleFont)
                        Text("Set your morning plan.")
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)

                        Button("Set Morning Plan") {
                            NotificationCenter.default.post(name: .openPlanDefaultMorningPlan, object: nil)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DawnColor.accent)
                    }
                }
            }
        }
    }

    private func summaryLabel(for summary: NextWakeEventSummary) -> String {
        let eventTitle: String
        switch summary.event.type {
        case .wakeReminder:
            eventTitle = "Reminder"
        case .wakeAlarm:
            eventTitle = "Wake"
        case .wakeFollowUp:
            eventTitle = "Follow-up"
        case .fajrBoundaryNotice:
            eventTitle = "Fajr notice"
        case .iftarReminder:
            eventTitle = "Iftar reminder"
        }

        return "\(eventTitle) · \(scheduleManager.dayLabel(for: summary.day.date))"
    }
}
