import SwiftUI

struct TodayFajrCheckInCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    let presentation: FajrHomeSupportPresentation
    var onLater: (() -> Void)? = nil

    var body: some View {
        AppGlassSurface(variant: .quiet) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                    Text(presentation.title)
                        .font(AppTypography.cardTitle)

                    Text(presentation.detail)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: DesignTokens.spacingS) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            scheduleManager.performCompletionEdit(
                                .setPrayerStatus(dateKey: presentation.dateKey, status: .completed),
                                source: .homeCard
                            )
                        }
                    } label: {
                        Text(Strings.HomeSurface.fajrPromptPrimary)
                            .frame(maxWidth: .infinity)
                    }
                    .appControlStyle(.primary, tint: .green)

                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            scheduleManager.performCompletionEdit(
                                .setPrayerStatus(dateKey: presentation.dateKey, status: .missed),
                                source: .homeCard
                            )
                        }
                    } label: {
                        Text(Strings.HomeSurface.fajrPromptSecondary)
                            .frame(maxWidth: .infinity)
                    }
                    .appControlStyle(.secondary, tint: .secondary)
                }

                if let onLater {
                    Button(Strings.HomeSurface.fajrPromptLater, action: onLater)
                        .font(AppTypography.metricLabel)
                        .appControlStyle(.quiet)
                }
            }
        }
    }
}
