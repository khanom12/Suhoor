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
                LazyVStack(alignment: .leading, spacing: DesignTokens.spacingL) {
                    TodayDateContextBlock(snapshot: snapshot)

                    TodayNextWakeHeroCard(
                        summary: snapshot.nextWakeEventSummary,
                        presentation: snapshot.heroPresentation
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
                .padding(.top, DesignTokens.spacingS)
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
                            .font(AppTypography.navAccessory)
                            .foregroundStyle(.secondary)
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
        guard shouldRenderSupportCardOnHome(presentation) else { return false }
        guard let dismissalKey = presentation.dismissalKey else { return true }
        return !dismissalStore.isSupportCardDismissed(dismissalKey, on: now)
    }

    private func shouldRenderSupportCardOnHome(_ presentation: HomeSupportCardPresentation) -> Bool {
        true
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

private struct TodayDateContextBlock: View {
    let snapshot: HomeSurfaceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
            Text(snapshot.gregorianText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text(snapshot.hijriText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignTokens.spacingXS)
    }
}

private struct TodayBlockingIssueCard: View {
    @EnvironmentObject private var appNavigator: AppNavigator

    let presentation: PermissionPresentation

    var body: some View {
        AppGlassSurface(variant: .tinted) {
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
    let presentation: HomeHeroPresentation?

    var body: some View {
        AppGlassSurface(
            variant: .hero,
            contentPadding: DesignTokens.spacingL
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingMedium) {
                Text(presentation?.label ?? Strings.HomeSurface.heroTitle)
                    .appTextRole(.eyebrow)

                if let summary {
                    heroContent(for: summary)
                } else {
                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingMedium) {
                        Text(Strings.HomeSurface.heroEmptyTitle)
                            .font(AppTypography.heroTitle)

                        Text(Strings.HomeSurface.heroEmptyBody)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(.secondary)

                        Button(Strings.HomeSurface.heroEmptyAction) {
                            appNavigator.openDefaultMorningPlan()
                        }
                        .appControlStyle(.primary, tint: DawnColor.accent)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func heroContent(for summary: NextWakeEventSummary) -> some View {
        let resolvedPresentation = presentation ?? ProductSurfacePresentation.homeHeroPresentation(for: summary.day)

        VStack(alignment: .leading, spacing: DesignTokens.textSpacingMedium) {
            HeroWakeTimeLockup(date: summary.day.schedule.wakeDate)

            VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                Text(resolvedPresentation.descriptorText)
                    .font(AppTypography.cardTitle)
                    .fixedSize(horizontal: false, vertical: true)

                Text(resolvedPresentation.explanationText)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let statusText = resolvedPresentation.statusText {
                    Text(statusText)
                        .appTextRole(.metricLabel, tone: .tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                appNavigator.switchToWake()
            } label: {
                Text(Strings.HomeSurface.heroAction)
                    .frame(minHeight: 44)
            }
            .appControlStyle(.secondary, tint: DawnColor.accent)
        }
    }
}

private struct HeroWakeTimeLockup: View {
    let date: Date

    @ScaledMetric(relativeTo: .largeTitle) private var timePointSize: CGFloat = 42

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.inlineSpacingSmall) {
            Text(Self.timeMainFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: timePointSize, weight: .light))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .minimumScaleFactor(DesignTokens.heroMetricMinScaleFactor)
                .lineLimit(1)

            Text(Self.timeSuffixFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: timePointSize * 0.48, weight: .regular))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .baselineOffset(2)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    private static let timeMainFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()

    private static let timeSuffixFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()
}
