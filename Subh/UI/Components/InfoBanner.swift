import SwiftUI

struct InfoBanner<Action: View>: View {
    let systemImage: String
    let text: String
    @ViewBuilder let action: () -> Action

    init(
        systemImage: String,
        text: String,
        @ViewBuilder action: @escaping () -> Action = { EmptyView() }
    ) {
        self.systemImage = systemImage
        self.text = text
        self.action = action
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacingM) {
            Image(systemName: systemImage)
                .font(AppTypography.bannerSymbol)
                .foregroundStyle(DawnColor.accent)
                .padding(.top, DesignTokens.accessoryInset)
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                Text(text)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
                action()
            }
            Spacer(minLength: 0)
        }
        .padding(DesignTokens.spacingM)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
