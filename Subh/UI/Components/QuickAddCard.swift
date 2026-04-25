import SwiftUI

struct QuickAddCard<LeadingAccessory: View, Action: View>: View {
    let title: String
    let description: String
    let previewLine: String?
    let statusLine: String?
    let detailLine: String?
    @ViewBuilder let leadingAccessory: () -> LeadingAccessory
    @ViewBuilder let action: () -> Action

    init(
        title: String,
        description: String,
        previewLine: String? = nil,
        statusLine: String? = nil,
        detailLine: String? = nil,
        @ViewBuilder leadingAccessory: @escaping () -> LeadingAccessory = { EmptyView() },
        @ViewBuilder action: @escaping () -> Action
    ) {
        self.title = title
        self.description = description
        self.previewLine = previewLine
        self.statusLine = statusLine
        self.detailLine = detailLine
        self.leadingAccessory = leadingAccessory
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingMedium) {
            HStack(alignment: .top, spacing: DesignTokens.space12) {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    HStack(spacing: DesignTokens.inlineSpacingMedium) {
                        Text(title)
                            .font(AppTypography.rowTitle)
                        leadingAccessory()
                    }
                    Text(description)
                        .font(AppTypography.rowBody)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                action()
            }

            if let previewLine {
                Text(previewLine)
                    .font(AppTypography.rowBody)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let statusLine {
                Text(statusLine)
                    .font(AppTypography.rowBody)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let detailLine {
                DisclosureGroup(Strings.AddSchedule.detailsTitle) {
                    Text(detailLine)
                        .font(AppTypography.rowBody)
                        .foregroundStyle(.secondary)
                        .padding(.top, DesignTokens.textSpacingTight)
                }
                .font(AppTypography.metricLabel)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.spacingM)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
