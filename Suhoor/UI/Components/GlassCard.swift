import SwiftUI

struct GlassCard<Content: View>: View {
    enum Style {
        case normal
        case header
    }

    let style: Style
    let padding: CGFloat
    let tintColor: Color?
    let tintOpacity: Double
    let tintOpacityMultiplier: Double
    @ViewBuilder let content: () -> Content

    init(
        style: Style = .normal,
        padding: CGFloat = DesignTokens.dashboardCardPadding,
        tintColor: Color? = nil,
        tintOpacity: Double = 0.18,
        tintOpacityMultiplier: Double = 1,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.tintColor = tintColor
        self.tintOpacity = tintOpacity
        self.tintOpacityMultiplier = tintOpacityMultiplier
        self.content = content
    }

    var body: some View {
        AppGlassSurface(
            variant: variant,
            prominence: prominence,
            tint: tintColor,
            tintOpacityMultiplier: tintOpacityMultiplier,
            contentPadding: padding
        ) {
            content()
        }
    }

    private var variant: AppGlassSurfaceVariant {
        switch style {
        case .normal:
            return tintColor == nil ? .standard : .tinted
        case .header:
            return .hero
        }
    }

    private var prominence: AppGlassProminence {
        style == .header ? .high : .regular
    }
}
