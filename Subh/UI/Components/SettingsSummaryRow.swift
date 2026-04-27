import SwiftUI

struct SettingsSummaryRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let subtitle: String
    let systemImage: String
    var badgeText: String? = nil
    var badgeTone: SettingsBadgeTone = .neutral
    var showsDisclosureIndicator: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacingM) {
            Image(systemName: systemImage)
                .font(AppTypography.controlIcon)
                .foregroundStyle(.primary)
                .frame(width: DesignTokens.regularControlFrame, height: DesignTokens.regularControlFrame)
                .background(iconBackground)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingS) {
                        titleText
                        Spacer(minLength: DesignTokens.spacingS)
                        badge
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                        titleText
                        badge
                    }
                }

                Text(subtitle)
                    .font(AppTypography.rowBody)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 6 : 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: DesignTokens.spacingS)

            if showsDisclosureIndicator {
                Image(systemName: "chevron.right")
                    .font(AppTypography.navAccessory)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(minHeight: DesignTokens.settingsSummaryMinHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var titleText: some View {
        Text(title)
            .font(AppTypography.rowTitle)
            .foregroundStyle(.primary)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var badge: some View {
        if let badgeText {
            SettingsStatusBadge(text: badgeText, tone: badgeTone)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var iconBackground: some View {
        Circle()
            .fill(Color.secondary.opacity(0.10))
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
    }
}

enum SettingsBadgeTone {
    case neutral
    case warning
    case critical
    case success

    var foregroundStyle: Color {
        switch self {
        case .neutral:
            return .secondary
        case .warning:
            return .secondary
        case .critical:
            return .red
        case .success:
            return .green
        }
    }

    var backgroundStyle: Color {
        switch self {
        case .neutral:
            return Color.secondary.opacity(0.12)
        case .warning:
            return Color.secondary.opacity(0.16)
        case .critical:
            return Color.red.opacity(0.12)
        case .success:
            return Color.green.opacity(0.12)
        }
    }
}

struct SettingsStatusBadge: View {
    let text: String
    let tone: SettingsBadgeTone

    var body: some View {
        Text(text)
            .font(AppTypography.badge)
            .foregroundStyle(tone.foregroundStyle)
            .padding(.horizontal, DesignTokens.badgeHorizontalPadding)
            .padding(.vertical, DesignTokens.badgeVerticalPadding)
            .background(
                Capsule(style: .continuous)
                    .fill(tone.backgroundStyle)
            )
    }
}
