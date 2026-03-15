import SwiftUI

struct FajrWindowSelectedDayCard: View {
    let snapshot: FajrWindowSelectedDaySnapshot

    var body: some View {
        GlassCard(tintColor: DawnColor.lightGold200, tintOpacity: 0.14) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected day")
                            .font(DesignTokens.cardMetaFont)
                            .foregroundStyle(.secondary)
                        Text(snapshot.title)
                            .font(.headline.weight(.semibold))
                    }

                    Spacer(minLength: DesignTokens.spacingS)

                    if let statusText = snapshot.statusText {
                        Text(statusText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DawnColor.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
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
                    Divider()

                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        ForEach(snapshot.secondaryItems) { item in
                            itemRow(item)
                        }
                    }
                }

                if let comparisonItem = snapshot.comparisonItem {
                    Divider()

                    itemRow(comparisonItem)
                }

                if !snapshot.contextTags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(snapshot.contextTags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                        }
                    }
                }

                Text(snapshot.explanationText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func itemRow(_ item: FajrWindowValueItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
            Text(item.label)
                .font(item.emphasis == .primary ? .subheadline.weight(.semibold) : .footnote)
                .foregroundStyle(labelColor(for: item.emphasis))

            Spacer(minLength: DesignTokens.spacingS)

            Text(item.value)
                .font(item.emphasis == .primary ? .subheadline.weight(.semibold) : .footnote.weight(.semibold))
                .foregroundStyle(valueColor(for: item.emphasis))
                .monospacedDigit()
        }
    }

    private func labelColor(for emphasis: FajrWindowValueItem.Emphasis) -> Color {
        switch emphasis {
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        case .comparison:
            return DawnColor.accent
        }
    }

    private func valueColor(for emphasis: FajrWindowValueItem.Emphasis) -> Color {
        switch emphasis {
        case .primary:
            return .primary
        case .secondary:
            return .primary
        case .comparison:
            return DawnColor.accent
        }
    }
}
