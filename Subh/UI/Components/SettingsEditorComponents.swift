import SwiftUI

struct SettingsInfoBanner<Action: View>: View {
    let title: String
    let message: String
    let systemImage: String
    @ViewBuilder let action: () -> Action

    init(
        title: String,
        message: String,
        systemImage: String = "info.circle",
        @ViewBuilder action: @escaping () -> Action = { EmptyView() }
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        AppGlassSurface(variant: .quiet) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                Image(systemName: systemImage)
                    .font(AppTypography.bannerSymbol)
                    .foregroundStyle(.secondary)
                    .padding(.top, DesignTokens.accessoryInset)

                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    Text(title)
                        .font(AppTypography.rowTitle)
                    Text(message)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    action()
                }

                Spacer(minLength: 0)
            }
        }
    }
}

struct RelativeOffsetControl: View {
    let label: String
    let detail: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    var isDisabled: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                Text(label)
                    .font(AppTypography.rowTitle)
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(AppTypography.rowBody)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: DesignTokens.inlineSpacingMedium) {
                Button {
                    value = max(range.lowerBound, value - step)
                } label: {
                    Image(systemName: "minus")
                        .font(AppTypography.compactControlIcon)
                        .frame(width: DesignTokens.smallControlFrame, height: DesignTokens.smallControlFrame)
                }
                .appControlStyle(.secondary)
                .disabled(isDisabled || value <= range.lowerBound)

                Text("\(value)")
                    .font(AppTypography.metricValue)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(minWidth: DesignTokens.smallControlFrame)

                Button {
                    value = min(range.upperBound, value + step)
                } label: {
                    Image(systemName: "plus")
                        .font(AppTypography.compactControlIcon)
                        .frame(width: DesignTokens.smallControlFrame, height: DesignTokens.smallControlFrame)
                }
                .appControlStyle(.secondary)
                .disabled(isDisabled || value >= range.upperBound)
            }
        }
    }
}
