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
                .font(.headline)
                .foregroundStyle(DawnColor.accent)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 6) {
                Text(text)
                    .font(.footnote)
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
