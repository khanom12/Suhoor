import SwiftUI

struct SettingsSummaryRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var badgeText: String? = nil
    var badgeTone: SettingsBadgeTone = .neutral
    var showsDisclosureIndicator: Bool = false

    var body: some View {
        HStack(spacing: DesignTokens.spacingM) {
            Image(systemName: systemImage)
                .font(AppTypography.controlIcon)
                .foregroundStyle(.primary)
                .frame(width: DesignTokens.regularControlFrame, height: DesignTokens.regularControlFrame)
                .background(iconBackground)

            VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                Text(title)
                    .font(AppTypography.rowTitle)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(AppTypography.rowBody)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: DesignTokens.spacingS)

            if let badgeText {
                SettingsStatusBadge(text: badgeText, tone: badgeTone)
            }

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
