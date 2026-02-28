import SwiftUI

struct ActionRowView: View {
    let title: String
    let systemImage: String
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: DesignTokens.spacingM) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DawnColor.accent)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(DawnColor.glassWarmOverlay.opacity(0.14))
                )

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}
