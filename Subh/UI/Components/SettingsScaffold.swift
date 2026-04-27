import SwiftUI

struct SettingsScrollPage<Content: View>: View {
    let topSpacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        topSpacing: CGFloat = DesignTokens.spacingL,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.topSpacing = topSpacing
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                content()
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.top, topSpacing)
            .padding(.bottom, DesignTokens.spacingXL)
        }
        .appSettingsScrollableChrome()
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String?
    let supportingText: String?
    let footer: String?
    let tint: Color?
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        supportingText: String? = nil,
        footer: String? = nil,
        tint: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.supportingText = supportingText
        self.footer = footer
        self.tint = tint
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            if let title {
                AppSectionHeader(title, subtitle: supportingText)
            } else if let supportingText {
                Text(supportingText)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AppInsetGroup(tint: tint) {
                content()
            }

            if let footer {
                Text(footer)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, DesignTokens.accessoryInset)
            }
        }
    }
}

struct SettingsRow<Content: View>: View {
    let verticalPadding: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        verticalPadding: CGFloat = DesignTokens.settingsRowVerticalPadding,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.verticalPadding = verticalPadding
        self.content = content
    }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, verticalPadding)
    }
}

struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
            Text(title)
                .font(AppTypography.rowTitle)
                .foregroundStyle(.primary)

            Spacer(minLength: DesignTokens.spacingM)

            Text(value)
                .font(AppTypography.rowBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct SettingsNavigationRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
            content()
            Spacer(minLength: DesignTokens.spacingS)
            Image(systemName: "chevron.right")
                .font(AppTypography.navAccessory)
                .foregroundStyle(.tertiary)
        }
    }
}
