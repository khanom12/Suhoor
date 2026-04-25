import SwiftUI

struct FajrWindowSelectedDayCard: View {
    let snapshot: FajrWindowSelectedDaySnapshot

    var body: some View {
        WakeGlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                        Text("Selected day")
                            .appTextRole(.eyebrow)
                            .foregroundStyle(WakeGlassTheme.tertiaryText)
                        Text(snapshot.title)
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(WakeGlassTheme.primaryText)
                    }

                    Spacer(minLength: DesignTokens.spacingS)

                    if let statusText = snapshot.statusText {
                        Text(statusText)
                            .font(AppTypography.badge)
                            .foregroundStyle(DawnColor.accent)
                            .padding(.horizontal, DesignTokens.chipHorizontalPaddingCompact)
                            .padding(.vertical, DesignTokens.compactChipVerticalPadding)
                            .background(
                                Capsule()
                                    .fill(DawnColor.accent.opacity(0.12))
                            )
                    }
                }

                VStack(spacing: DesignTokens.spacingS) {
                    ForEach(snapshot.primaryItems) { item in
                        itemRow(item)
                    }
                }

                if !snapshot.secondaryItems.isEmpty {
                    cardDivider

                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        ForEach(snapshot.secondaryItems) { item in
                            itemRow(item)
                        }
                    }
                }

                if let comparisonItem = snapshot.comparisonItem {
                    cardDivider

                    itemRow(comparisonItem)
                }

                if !snapshot.contextTags.isEmpty {
                    HStack(spacing: DesignTokens.inlineSpacingMedium) {
                        ForEach(snapshot.contextTags, id: \.self) { tag in
                            Text(tag)
                                .font(AppTypography.badge)
                                .foregroundStyle(WakeGlassTheme.secondaryText)
                                .padding(.horizontal, DesignTokens.chipHorizontalPaddingCompact)
                                .padding(.vertical, DesignTokens.compactChipVerticalPadding)
                                .background(
                                    Capsule()
                                        .fill(WakeGlassTheme.chipFill)
                                )
                        }
                    }
                }

                Text(snapshot.explanationText)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(WakeGlassTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Selected morning")
        .accessibilityValue(snapshot.accessibilitySummary)
        .accessibilityHint("Shows how this morning sits inside the supported Fajr window.")
    }

    private func itemRow(_ item: FajrWindowValueItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
            Text(item.label)
                .font(item.emphasis == .primary ? AppTypography.rowTitle : AppTypography.metricLabel)
                .foregroundStyle(labelColor(for: item.emphasis))

            Spacer(minLength: DesignTokens.spacingS)

            Text(item.value)
                .font(item.emphasis == .primary ? AppTypography.summaryMetricValue : AppTypography.metricValue)
                .foregroundStyle(valueColor(for: item.emphasis))
                .monospacedDigit()
        }
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(WakeGlassTheme.divider)
            .frame(height: 1)
    }

    private func labelColor(for emphasis: FajrWindowValueItem.Emphasis) -> Color {
        switch emphasis {
        case .primary:
            return WakeGlassTheme.primaryText
        case .secondary:
            return WakeGlassTheme.secondaryText
        case .comparison:
            return DawnColor.accent
        }
    }

    private func valueColor(for emphasis: FajrWindowValueItem.Emphasis) -> Color {
        switch emphasis {
        case .primary:
            return WakeGlassTheme.primaryText
        case .secondary:
            return WakeGlassTheme.primaryText
        case .comparison:
            return DawnColor.accent
        }
    }
}
