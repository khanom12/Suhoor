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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.body.weight(.semibold))
                        leadingAccessory()
                    }
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                action()
            }

            if let previewLine {
                Text(previewLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let statusLine {
                Text(statusLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let detailLine {
                DisclosureGroup(Strings.AddSchedule.detailsTitle) {
                    Text(detailLine)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .font(.footnote.weight(.semibold))
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
