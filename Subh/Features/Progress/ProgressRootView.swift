import SwiftUI

struct ProgressRootView: View {
    @EnvironmentObject private var completionSurfaceStore: CompletionSurfaceStore

    var body: some View {
        let snapshot = completionSurfaceStore.state.progressSnapshot

        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                ProgressSummaryCard(snapshot: snapshot)

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    AppSectionHeader("Fajr", subtitle: Strings.ProgressSurface.fajrFooter)

                    NavigationLink {
                        FajrHistoryView()
                    } label: {
                        ProgressHistoryCard(
                            eyebrow: "Fajr",
                            title: snapshot.fajrTodaySummary,
                            summary: snapshot.fajrSummary
                        )
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    AppSectionHeader(snapshot.fastSectionTitle, subtitle: Strings.ProgressSurface.fastFooter)

                    NavigationLink {
                        FastHistoryView()
                    } label: {
                        ProgressHistoryCard(
                            eyebrow: snapshot.fastSectionTitle,
                            title: snapshot.fastTodaySummary,
                            summary: snapshot.fastSummary
                        )
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    AppSectionHeader("Qada Progress", subtitle: Strings.ProgressSurface.qadaFooter)

                    AppGlassSurface(
                        variant: snapshot.qadaProgress.baselineOwed > 0 ? .standard : .quiet,
                        tint: nil
                    ) {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                                    Text(snapshot.qadaProgress.baselineOwed > 0 ? "Qada progress" : "Qada tracking")
                                        .font(AppTypography.cardTitle)
                                    Text(snapshot.qadaProgress.baselineOwed > 0
                                         ? "Completed Qada fasts reduce what remains."
                                         : Strings.ProgressSurface.qadaEnablePrompt)
                                        .font(AppTypography.cardBody)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "checklist")
                                    .font(AppTypography.cardSymbol)
                                    .foregroundStyle(FastPrimaryIntent.qadaMakeup.style.color)
                            }

                            AppInsetGroup {
                                ProgressMetricRow(
                                    label: "Completed",
                                    value: "\(snapshot.qadaProgress.completed)",
                                    valueColor: FastPrimaryIntent.qadaMakeup.style.color
                                )
                                AppGroupDivider(inset: 0)
                                ProgressMetricRow(
                                    label: "Remaining",
                                    value: "\(snapshot.qadaProgress.remaining)",
                                    valueColor: FastPrimaryIntent.qadaMakeup.style.color
                                )
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    AppSectionHeader("Morning Follow-Through", subtitle: Strings.ProgressSurface.wakeFooter)

                    AppGlassSurface(variant: .quiet) {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                            if let summaryTitle = snapshot.wakeProgress.summaryTitle {
                                Text(summaryTitle)
                                    .font(AppTypography.cardTitle)

                                if let summaryDetail = snapshot.wakeProgress.summaryDetail {
                                    Text(summaryDetail)
                                        .font(AppTypography.cardBody)
                                        .foregroundStyle(.secondary)
                                }

                                if !snapshot.wakeProgress.recentActivityLines.isEmpty {
                                    AppInsetGroup {
                                        ForEach(Array(snapshot.wakeProgress.recentActivityLines.enumerated()), id: \.offset) { index, line in
                                            Text(line)
                                                .font(AppTypography.rowBody)
                                                .foregroundStyle(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.horizontal, DesignTokens.spacingM)
                                                .padding(.vertical, DesignTokens.rowVerticalPadding)

                                            if index < snapshot.wakeProgress.recentActivityLines.count - 1 {
                                                AppGroupDivider(inset: DesignTokens.spacingM)
                                            }
                                        }
                                    }
                                }
                            } else if let emptyStateText = snapshot.wakeProgress.emptyStateText {
                                Text(emptyStateText)
                                    .font(AppTypography.cardBody)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, DesignTokens.spacingL)
        }
        .appScrollableChrome()
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct ProgressSummaryCard: View {
    let snapshot: ProgressSurfaceSnapshot

    var body: some View {
        AppGlassSurface(
            variant: snapshot.headlineText == nil ? .standard : .hero,
            prominence: snapshot.headlineText == nil ? .regular : .high
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                Text("Progress summary")
                    .appTextRole(.eyebrow)

                if let headlineText = snapshot.headlineText {
                    Text(headlineText)
                        .font(AppTypography.heroTitle)
                }

                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    ProgressSummaryMetric(title: "Fajr", value: snapshot.fajrTodaySummary)
                    ProgressSummaryMetric(title: snapshot.fastSectionTitle, value: snapshot.fastTodaySummary)
                    ProgressSummaryMetric(title: "Qada", value: "\(snapshot.qadaProgress.remaining) left")
                }
            }
        }
    }
}

private struct ProgressSummaryMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
            Text(title)
                .font(AppTypography.badge)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(AppTypography.summaryMetricValue)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProgressHistoryCard: View {
    let eyebrow: String
    let title: String
    let summary: String

    var body: some View {
        AppGlassSurface(variant: .standard) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                Text(eyebrow)
                    .appTextRole(.eyebrow)

                AppInsetGroup {
                    ProgressMetricRow(label: "Today", value: title)
                    AppGroupDivider(inset: 0)
                    ProgressMetricRow(
                        label: eyebrow == "Fajr" ? "Last 30 mornings" : "Last 30 days",
                        value: summary
                    )
                }
            }
        }
    }
}

private struct ProgressMetricRow: View {
    let label: String
    let value: String
    var valueColor: Color? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
            Text(label)
                .font(AppTypography.metricLabel)
                .foregroundStyle(.secondary)

            Spacer(minLength: DesignTokens.spacingM)

            Text(value)
                .font(AppTypography.metricValue)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(valueColor ?? Color.primary)
        }
        .padding(.horizontal, DesignTokens.spacingM)
        .padding(.vertical, DesignTokens.rowVerticalPadding)
    }
}
