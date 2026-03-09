import SwiftUI

struct TodayHomeView: View {
    @EnvironmentObject private var appNavigator: AppNavigator
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var dismissalStore = TodayCardDismissalStore()

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            let now = context.date
            let snapshot = scheduleManager.homeSurfaceSnapshot(
                now: now,
                dismissedWarnings: dismissedWarnings(on: now)
            )

            ScrollView {
                LazyVStack(spacing: DesignTokens.dashboardStackSpacing) {
                    TodayNextWakeHeroCard(summary: snapshot.nextWakeEventSummary)

                    TodayDateContextStrip(snapshot: snapshot)

                    if let supportDecision = snapshot.supportDecision {
                        supportCardView(
                            for: supportDecision.presentation,
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
                        appNavigator.openSettings()
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
    let snapshot: HomeSurfaceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.gregorianText)
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(.secondary)

                Text(snapshot.hijriText)
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(.secondary)
            }

            if let contextSummaryText = snapshot.contextSummaryText {
                VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                    Text(contextSummaryText)
                        .font(.subheadline.weight(.semibold))
                    if !snapshot.secondaryContextTitles.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignTokens.spacingXS) {
                                ForEach(snapshot.secondaryContextTitles, id: \.self) { title in
                                    ContextChip(title: title)
                                }
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
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

private struct TodayBlockingIssueCard: View {
    @EnvironmentObject private var appNavigator: AppNavigator

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
                    appNavigator.openSettings()
                }
                .buttonStyle(.borderedProminent)
                .tint(DawnColor.accent)
            }
        }
    }
}

private struct TodayNextWakeHeroCard: View {
    @EnvironmentObject private var appNavigator: AppNavigator

    let summary: NextWakeEventSummary?

    var body: some View {
        GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.18) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                Text(Strings.HomeSurface.heroTitle)
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(.secondary)

                if let summary {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        Text(TimeFormatters.timeFormatter.string(from: summary.day.schedule.wakeDate))
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                            .monospacedDigit()

                        Text(heroLine(for: summary))
                            .font(DesignTokens.cardTitleFont)

                        Button(Strings.HomeSurface.heroAction) {
                            appNavigator.switchToWake()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DawnColor.accent)
                    }
                } else {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        Text(Strings.HomeSurface.heroEmptyTitle)
                            .font(DesignTokens.cardTitleFont)
                        Text(Strings.HomeSurface.heroEmptyBody)
                            .font(DesignTokens.cardMetaFont)
                            .foregroundStyle(.secondary)

                        Button(Strings.HomeSurface.heroEmptyAction) {
                            appNavigator.openDefaultMorningPlan()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DawnColor.accent)
                    }
                }
            }
        }
    }

    private func heroLine(for summary: NextWakeEventSummary) -> String {
        let fajrText = "Fajr at \(TimeFormatters.timeFormatter.string(from: summary.day.schedule.fajrDate))"
        if let meaning = ProductSurfacePresentation.homeHeroMeaningText(for: summary.day) {
            return "\(meaning) • \(fajrText)"
        }
        return "For \(fajrText)"
    }
}
