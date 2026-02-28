import SwiftUI

struct PillBadge: View {
    enum Style {
        case `default`
        case custom
        case off
    }

    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(DesignTokens.badgeFont)
            .foregroundStyle(.primary)
            .padding(.horizontal, DesignTokens.spacingS)
            .padding(.vertical, DesignTokens.spacingXS)
            .background(background)
            .clipShape(Capsule(style: .continuous))
    }

    private var background: some View {
        switch style {
        case .default:
            return AnyView(DawnColor.gold100.opacity(0.65))
        case .custom:
            return AnyView(DawnColor.lightApricot200.opacity(0.65))
        case .off:
            return AnyView(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(DawnColor.glassWarmOverlay.opacity(0.08))
            )
        }
    }
}
