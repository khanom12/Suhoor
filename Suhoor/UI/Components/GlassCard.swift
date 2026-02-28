import SwiftUI

struct GlassCard<Content: View>: View {
    enum Style {
        case normal
        case header
    }

    let style: Style
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    init(style: Style = .normal, padding: CGFloat = DesignTokens.spacingL, @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(materialBackground)
            .overlay(strokeOverlay)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.glassCardRadius, style: .continuous))
            .shadow(color: Color.black.opacity(DesignTokens.shadowAmbient.opacity), radius: DesignTokens.shadowAmbient.blur, x: 0, y: DesignTokens.shadowAmbient.y)
            .shadow(color: Color.black.opacity(DesignTokens.shadowContact.opacity), radius: DesignTokens.shadowContact.blur, x: 0, y: DesignTokens.shadowContact.y)
    }

    private var materialBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.glassCardRadius, style: .continuous)
                .fill(style == .header ? .regularMaterial : .thinMaterial)
            RoundedRectangle(cornerRadius: DesignTokens.glassCardRadius, style: .continuous)
                .fill(DawnColor.glassWarmOverlay.opacity(style == .header ? 0.10 : 0.08))
        }
    }

    private var strokeOverlay: some View {
        RoundedRectangle(cornerRadius: DesignTokens.glassCardRadius, style: .continuous)
            .stroke(strokeColor, lineWidth: 1)
    }

    private var strokeColor: Color {
        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.25)
    }

    @Environment(\.colorScheme) private var colorScheme
}
