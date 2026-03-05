import SwiftUI

struct QadaPaceCard: View {
    let pace: QadaPlanPace
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassCard(tintColor: isSelected ? DawnColor.accent : DawnColor.lightGold200, tintOpacity: isSelected ? 0.24 : 0.12) {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(pace.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(pace.description)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isSelected ? DawnColor.accent : .secondary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.dashboardCardRadius, style: .continuous)
                    .stroke(isSelected ? DawnColor.accent.opacity(0.9) : Color.white.opacity(0.06), lineWidth: isSelected ? 1.4 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
