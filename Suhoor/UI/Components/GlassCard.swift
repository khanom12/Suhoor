import SwiftUI

struct GlassCard<Content: View>: View {
    enum Style {
        case normal
        case header
    }

    let style: Style
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    init(style: Style = .normal, padding: CGFloat = DesignTokens.dashboardCardPadding, @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(materialBackground)
            .overlay(strokeOverlay)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(ambientShadow.opacity), radius: ambientShadow.blur, x: 0, y: ambientShadow.y)
            .shadow(color: Color.black.opacity(contactShadow.opacity), radius: contactShadow.blur, x: 0, y: contactShadow.y)
    }

    private var materialBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(style == .header ? .regularMaterial : .thinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(DawnColor.glassWarmOverlay.opacity(style == .header ? 0.10 : 0.06))
        }
    }

    private var strokeOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(strokeColor, lineWidth: 1)
    }

    private var cornerRadius: CGFloat {
        DesignTokens.dashboardCardRadius
    }

    private var strokeColor: Color {
        Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18)
    }

    private var ambientShadow: ShadowStyle {
        style == .header ? ShadowStyle(y: 4, blur: 14, opacity: 0.06) : ShadowStyle(y: 0, blur: 0, opacity: 0)
    }

    private var contactShadow: ShadowStyle {
        style == .header ? ShadowStyle(y: 1, blur: 4, opacity: 0.04) : ShadowStyle(y: 0, blur: 0, opacity: 0)
    }

    @Environment(\.colorScheme) private var colorScheme
}
