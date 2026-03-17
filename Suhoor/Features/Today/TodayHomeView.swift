import SwiftUI

struct TodayHomeView: View {
    @EnvironmentObject private var appNavigator: AppNavigator
    @EnvironmentObject private var completionSurfaceStore: CompletionSurfaceStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var dismissalStore = TodayCardDismissalStore()

    var body: some View {
        let _ = dismissalStore.revision

        TimelineView(.periodic(from: Date(), by: 60)) { context in
            let now = context.date
            let snapshot = completionSurfaceStore.homeSurfaceSnapshot(
                now: now,
                dismissedWarnings: dismissedWarnings(on: now)
            )

            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                    TodayDateBlock(snapshot: snapshot)

                    TodayNextWakeHeroCard(
                        summary: snapshot.nextWakeEventSummary,
                        label: snapshot.heroLabel,
                        subline: snapshot.heroSubline
                    )

                    if let supportDecision = snapshot.supportDecision,
                       supportCardShouldBeVisible(supportDecision.presentation, now: now) {
                        supportCardView(
                            for: supportDecision.presentation,
                            now: now
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.top, DesignTokens.spacingL)
                .padding(.bottom, DesignTokens.spacingXL)
            }
            .appScrollableChrome()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appNavigator.openSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(AppTypography.toolbarIcon)
                            .appToolbarButtonChrome()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open Settings")
                }
            }
        }
    }

    private func supportCardShouldBeVisible(
        _ presentation: HomeSupportCardPresentation,
        now: Date
    ) -> Bool {
        guard let dismissalKey = presentation.dismissalKey else { return true }
        return !dismissalStore.isSupportCardDismissed(dismissalKey, on: now)
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
            if let presentation = completionSurfaceStore.homeContext.permissionSnapshot.presentations[permissionKind] {
                TodayBlockingIssueCard(presentation: presentation)
            }
        case .fajrCompletionPrompt(let presentation):
            TodayFajrCheckInCard(
                presentation: presentation,
                onLater: {
                    if let dismissalKey = HomeSupportCardPresentation.fajrCompletionPrompt(presentation).dismissalKey {
                        withAnimation(Motion.fade(reduceMotion: reduceMotion)) {
                            dismissalStore.dismissSupportCard(dismissalKey, on: now)
                        }
                    }
                }
            )
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
            TodayFastCheckInCard(
                presentation: presentation,
                onLater: {
                    if let dismissalKey = HomeSupportCardPresentation.fasting(presentation).dismissalKey {
                        withAnimation(Motion.fade(reduceMotion: reduceMotion)) {
                            dismissalStore.dismissSupportCard(dismissalKey, on: now)
                        }
                    }
                }
            )
        }
    }
}

private struct TodayDateBlock: View {
    let snapshot: HomeSurfaceSnapshot

    var body: some View {
        AppGlassSurface(
            variant: .quiet,
            contentPadding: 0,
            maxWidth: 320,
            alignment: .leading
        ) {
            HStack(spacing: DesignTokens.spacingS) {
                Image(systemName: "calendar")
                    .font(AppTypography.navAccessory)
                    .foregroundStyle(.secondary)
                    .frame(width: DesignTokens.smallControlFrame, height: DesignTokens.smallControlFrame)
                    .background(
                        Circle()
                            .fill(Color.secondary.opacity(0.10))
                            .overlay {
                                Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
                            }
                    )

                VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                    Text(snapshot.gregorianText)
                        .font(AppTypography.rowTitle)
                        .foregroundStyle(.primary)
                    Text(snapshot.hijriText)
                        .font(AppTypography.rowBody)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, DesignTokens.spacingM)
            .padding(.vertical, DesignTokens.rowVerticalPadding)
        }
    }
}

private struct TodayBlockingIssueCard: View {
    @EnvironmentObject private var appNavigator: AppNavigator

    let presentation: PermissionPresentation

    var body: some View {
        AppGlassSurface(variant: .tinted, tint: .orange) {
            VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                Text(presentation.title)
                    .font(AppTypography.cardTitle)

                Text(presentation.message)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)

                Button(presentation.actionTitle ?? "Open Settings") {
                    appNavigator.openSettings()
                }
                .appControlStyle(.primary, tint: .orange)
            }
        }
    }
}

private struct TodayNextWakeHeroCard: View {
    @EnvironmentObject private var appNavigator: AppNavigator

    let summary: NextWakeEventSummary?
    let label: String?
    let subline: String?

    var body: some View {
        AppGlassSurface(
            variant: .hero,
            prominence: .high
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                Text(label ?? Strings.HomeSurface.heroTitle)
                    .appTextRole(.eyebrow)

                if let summary {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        AppHeroMetric(
                            value: TimeFormatters.timeFormatter.string(from: summary.day.schedule.wakeDate),
                            title: subline ?? heroLine(for: summary)
                        )

                        Button(Strings.HomeSurface.heroAction) {
                            appNavigator.switchToWake()
                        }
                        .appControlStyle(.primary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        Text(Strings.HomeSurface.heroEmptyTitle)
                            .font(AppTypography.heroTitle)
                        Text(Strings.HomeSurface.heroEmptyBody)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(.secondary)

                        Button(Strings.HomeSurface.heroEmptyAction) {
                            appNavigator.openDefaultMorningPlan()
                        }
                        .appControlStyle(.primary)
                    }
                }
            }
        }
    }

    private func heroLine(for summary: NextWakeEventSummary) -> String {
        ProductSurfacePresentation.homeHeroSubline(for: summary.day)
    }
}
