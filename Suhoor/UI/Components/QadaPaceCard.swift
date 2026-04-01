import SwiftUI

struct QadaPaceCard: View {
    let pace: QadaPlanPace
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    Text(pace.title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(.primary)
                    Text(pace.description)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                    Text(pace.differentiatorLine)
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppTypography.cardSymbol)
                        .foregroundStyle(DawnColor.accent)
                }
            }
            .padding(DesignTokens.dashboardCardPadding)
            .background(cardBackground)
            .overlay(cardBorder)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.dashboardCardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: DesignTokens.dashboardCardRadius, style: .continuous)
            .fill(isSelected ? Color.secondary.opacity(0.10) : Color(.secondarySystemGroupedBackground))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: DesignTokens.dashboardCardRadius, style: .continuous)
            .stroke(isSelected ? DawnColor.accent.opacity(0.55) : Color(.separator).opacity(0.6), lineWidth: isSelected ? 1.2 : 1)
    }
}
