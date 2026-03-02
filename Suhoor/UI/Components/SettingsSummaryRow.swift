import SwiftUI

struct SettingsSummaryRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var badgeText: String? = nil
    var badgeTone: SettingsBadgeTone = .neutral

    var body: some View {
        HStack(spacing: DesignTokens.spacingM) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DawnColor.accent)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(DawnColor.glassWarmOverlay.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: DesignTokens.spacingS)

            if let badgeText {
                SettingsStatusBadge(text: badgeText, tone: badgeTone)
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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
            return .orange
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
            return Color.orange.opacity(0.12)
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
            .font(.caption.weight(.semibold))
            .foregroundStyle(tone.foregroundStyle)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(tone.backgroundStyle)
            )
    }
}
