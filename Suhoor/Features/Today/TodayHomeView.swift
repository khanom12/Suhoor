import SwiftUI

struct TodayHomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var dismissalStore = TodayCardDismissalStore()

    var body: some View {
        let now = Date()
        let hijriComponents = AdjustedHijriCalendar.shared.adjustedComponents(for: now, timeZone: .current)
        let todayKey = DateHelpers.dayIdentifier(for: now, timeZone: .current)
        let currentDay = scheduleManager.activeWindowSnapshot.byDateKey[todayKey]
        let contextDay = scheduleManager.nextWakeEventSummary?.day ?? currentDay
        let supportCardKind = ProductSurfacePresentation.homeSupportCard(
            currentDay: currentDay,
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

                if let supportCardKind {
                    supportCardView(
                        for: supportCardKind,
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
        .onAppear { _ = scheduleManager.lastUpdated }
    }

    private func dismissedWarnings(on now: Date) -> Set<FastWarning> {
        Set(FastWarning.allCases.filter { dismissalStore.isDismissed($0, on: now) })
    }

    @ViewBuilder
    private func supportCardView(
        for kind: HomeSupportCardKind,
        now: Date
    ) -> some View {
        switch kind {
        case .blockingIssue(let permissionKind):
            if let presentation = scheduleManager.permissionSnapshot.presentations[permissionKind] {
                TodayBlockingIssueCard(presentation: presentation)
            }
        case .forbiddenFast(let warning):
            TodayForbiddenFastDayCard(
                kind: warning,
                mode: .live,
                onDismiss: {
                    withAnimation(Motion.fade(reduceMotion: reduceMotion)) {
                        dismissalStore.dismiss(warning, on: now)
                    }
                }
            )
        case .fastingCheckIn:
            TodayFastCheckInCard()
        case .observance(let observance):
            seasonalSupportCard(for: observance)
        }
    }

    @ViewBuilder
    private func seasonalSupportCard(for observance: HomeObservanceSupportKind) -> some View {
        switch observance {
        case .ramadan:
            TodayRamadanProgressCard(mode: .live)
        case .shawwalSix:
            TodayShawwalSixProgressCard(mode: .live)
        case .dhulHijjah:
            TodayDhulHijjahProgressCard(mode: .live)
        case .ashura:
            TodayAshuraProgressCard(mode: .live)
        case .whiteDays:
            TodayWhiteDaysProgressCard(mode: .live)
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
                Text("Next Wake Event")
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(.secondary)

                if let summary = scheduleManager.nextWakeEventSummary {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        Text(TimeFormatters.timeFormatter.string(from: summary.event.fireDate))
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                            .monospacedDigit()

                        Text(summaryLabel(for: summary))
                            .font(DesignTokens.cardTitleFont)

                        Text(summary.relationText)
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)

                        Text("Fajr \(TimeFormatters.timeFormatter.string(from: summary.day.schedule.fajrDate))")
                            .font(DesignTokens.cardMetaFont)
                            .foregroundStyle(.secondary)

                        Text(summary.day.resolvedDayContext.explanation.summary)
                            .font(DesignTokens.cardMetaFont)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        Text("No wake event is scheduled yet.")
                            .font(DesignTokens.cardTitleFont)
                        Text("Set your location and morning plan to compute your next wake around Fajr.")
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func summaryLabel(for summary: NextWakeEventSummary) -> String {
        let eventTitle: String
        switch summary.event.type {
        case .wakeReminder:
            eventTitle = "Wake reminder"
        case .wakeAlarm:
            eventTitle = "Main wake"
        case .wakeFollowUp:
            eventTitle = "Wake follow-up"
        case .fajrBoundaryNotice:
            eventTitle = "Fajr notice"
        case .iftarReminder:
            eventTitle = "Iftar reminder"
        }

        return "\(eventTitle) for \(scheduleManager.dayLabel(for: summary.day.date))"
    }
}
