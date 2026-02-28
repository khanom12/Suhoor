import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let meta: String?

    init(_ title: String, meta: String? = nil) {
        self.title = title
        self.meta = meta
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(DesignTokens.sectionHeaderFont)
            Spacer()
            if let meta {
                Text(meta)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, DesignTokens.spacingXS)
        .padding(.bottom, DesignTokens.spacingS)
        .padding(.horizontal, 2)
    }
}
