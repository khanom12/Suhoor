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
                    TodayDateContextBlock(snapshot: snapshot)

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
                .padding(.horizontal, DesignTokens.spacingXL)
                .padding(.top, DesignTokens.spacingXS)
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
                            .padding(7)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .overlay {
                                        Circle()
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    }
                            )
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
        switch presentation {
        case .blockingIssue:
            return true
        case .fajrCompletionPrompt, .forbiddenFastNotice, .fasting:
            return false
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
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
            Text(snapshot.gregorianText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text(snapshot.hijriText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DesignTokens.space2)
        .padding(.bottom, DesignTokens.space4)
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
    @Environment(\.colorScheme) private var colorScheme

    let summary: NextWakeEventSummary?
    let label: String?
    let subline: String?

    var body: some View {
        AppGlassSurface(
            variant: .hero,
            prominence: .high,
            tint: DawnColor.lightGold100,
            contentPadding: 20
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Text(label ?? Strings.HomeSurface.heroTitle)
                    .appTextRole(.eyebrow)

                if let summary {
                    VStack(alignment: .leading, spacing: 0) {
                        HeroWakeTimeLockup(date: summary.day.schedule.wakeDate)
                            .padding(.top, DesignTokens.space10)

                        Text(subline ?? heroLine(for: summary))
                            .font(.body.weight(.medium))
                            .foregroundStyle(
                                colorScheme == .dark
                                ? Color.white.opacity(0.82)
                                : Color.primary.opacity(0.78)
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, DesignTokens.space12)

                        Button(Strings.HomeSurface.heroAction) {
                            appNavigator.switchToWake()
                        }
                        .appControlStyle(.primary, tint: DawnColor.accent)
                        .padding(.top, 20)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(Strings.HomeSurface.heroEmptyTitle)
                            .font(AppTypography.heroTitle)
                            .padding(.top, DesignTokens.space10)

                        Text(Strings.HomeSurface.heroEmptyBody)
                            .font(AppTypography.cardBody)
                            .foregroundStyle(.secondary)
                            .padding(.top, DesignTokens.space10)

                        Button(Strings.HomeSurface.heroEmptyAction) {
                            appNavigator.openDefaultMorningPlan()
                        }
                        .appControlStyle(.primary, tint: DawnColor.accent)
                        .padding(.top, 18)
                    }
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.18 : 0.34),
                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(
            color: DawnColor.accent.opacity(colorScheme == .dark ? 0.06 : 0.10),
            radius: 20,
            x: 0,
            y: 10
        )
    }

    private func heroLine(for summary: NextWakeEventSummary) -> String {
        ProductSurfacePresentation.homeHeroSubline(for: summary.day)
    }
}

private struct HeroWakeTimeLockup: View {
    let date: Date

    @ScaledMetric(relativeTo: .largeTitle) private var timePointSize: CGFloat = 46

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(Self.timeMainFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: timePointSize, weight: .light))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .minimumScaleFactor(DesignTokens.heroMetricMinScaleFactor)

            Text(Self.timeSuffixFormatter.string(from: date))
                .font(AppTypography.timeDisplayFont(size: timePointSize * 0.48, weight: .regular))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .baselineOffset(2)
        }
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
