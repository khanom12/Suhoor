import SwiftUI

struct ActionRowView: View {
    let title: String
    let systemImage: String
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: DesignTokens.spacingM) {
            Image(systemName: systemImage)
                .font(AppTypography.toolbarIcon)
                .foregroundStyle(DawnColor.accent)
                .frame(width: DesignTokens.smallControlFrame, height: DesignTokens.smallControlFrame)
                .background(
                    Circle()
                        .fill(DawnColor.glassWarmOverlay.opacity(0.14))
                )

            Text(title)
                .font(AppTypography.rowTitle)
                .foregroundStyle(.primary)

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(AppTypography.navAccessory)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}
