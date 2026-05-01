import SwiftUI

private enum AppCardGlassTheme {
    static let tintColor: Color = .black
    static let tintOpacityMultiplier: Double = 7.5
    static let forcedContentColorScheme: ColorScheme = .dark
}

enum AppGlassSurfaceVariant {
    case hero
    case standard
    case quiet
    case tinted
    case grouped
    case homeGrouped
}

enum AppGlassProminence {
    case regular
    case high
}

enum AppControlProminence {
    case primary
    case secondary
    case quiet
}

struct AppGlassStyle {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let fallbackMaterial: Material
    let baseOverlayOpacity: Double
    let warmOverlayOpacity: Double
    let tintOpacity: Double
    let strokeOpacityLight: Double
    let strokeOpacityDark: Double
    let ambientShadow: ShadowStyle
    let contactShadow: ShadowStyle
    let nativeGlassKind: NativeGlassKind

    enum NativeGlassKind {
        case clear
        case regular
    }

    static func make(
        variant: AppGlassSurfaceVariant,
        prominence: AppGlassProminence = .regular
    ) -> AppGlassStyle {
        switch (variant, prominence) {
        case (.hero, _), (_, .high):
            return baseStyle(cornerRadius: 26, padding: 16)
        case (.standard, _):
            return baseStyle(cornerRadius: 22, padding: 12)
        case (.quiet, _):
            return baseStyle(cornerRadius: 18, padding: 10)
        case (.tinted, _):
            return baseStyle(cornerRadius: 22, padding: 14)
        case (.grouped, _):
            return baseStyle(cornerRadius: 20, padding: 0)
        case (.homeGrouped, _):
            return homeGroupedStyle(cornerRadius: 20, padding: 0)
        }
    }

    private static func baseStyle(
        cornerRadius: CGFloat,
        padding: CGFloat,
        fallbackMaterial: Material = .thinMaterial,
        baseOverlayOpacity: Double = 0.012,
        tintOpacity: Double = 0.018,
        strokeOpacity: Double = 0.06,
        nativeGlassKind: NativeGlassKind = .clear
    ) -> AppGlassStyle {
        AppGlassStyle(
            cornerRadius: cornerRadius,
            padding: padding,
            fallbackMaterial: fallbackMaterial,
            baseOverlayOpacity: baseOverlayOpacity,
            warmOverlayOpacity: 0.0,
            tintOpacity: tintOpacity,
            strokeOpacityLight: strokeOpacity,
            strokeOpacityDark: strokeOpacity,
            ambientShadow: ShadowStyle(y: 4, blur: 8, opacity: 0.015),
            contactShadow: ShadowStyle(y: 1, blur: 3, opacity: 0.01),
            nativeGlassKind: nativeGlassKind
        )
    }

    private static func homeGroupedStyle(cornerRadius: CGFloat, padding: CGFloat) -> AppGlassStyle {
        baseStyle(cornerRadius: cornerRadius, padding: padding)
    }
}

struct AppGlassSurface<Content: View>: View {
    let variant: AppGlassSurfaceVariant
    let prominence: AppGlassProminence
    let cornerRadiusOverride: CGFloat?
    let tint: Color?
    let tintOpacityMultiplier: Double
    let contentPadding: CGFloat?
    let maxWidth: CGFloat?
    let alignment: Alignment
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        variant: AppGlassSurfaceVariant = .standard,
        prominence: AppGlassProminence = .regular,
        cornerRadius: CGFloat? = nil,
        tint: Color? = nil,
        tintOpacityMultiplier: Double = 1,
        contentPadding: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        alignment: Alignment = .leading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.variant = variant
        self.prominence = prominence
        self.cornerRadiusOverride = cornerRadius
        self.tint = tint
        self.tintOpacityMultiplier = tintOpacityMultiplier
        self.contentPadding = contentPadding
        self.maxWidth = maxWidth
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        let style = AppGlassStyle.make(variant: variant, prominence: prominence)
        let cornerRadius = cornerRadiusOverride ?? style.cornerRadius
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let padding = contentPadding ?? style.padding

        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer {
                    surfaceContent(padding: padding)
                }
                .frame(maxWidth: maxWidth ?? .infinity, alignment: alignment)
                .background(nativeBackground(shape: shape, style: style))
            } else {
                surfaceContent(padding: padding)
                    .frame(maxWidth: maxWidth ?? .infinity, alignment: alignment)
                    .background(fallbackBackground(shape: shape, style: style))
            }
        }
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(strokeColor(for: style), lineWidth: 1)
        }
        .shadow(
            color: Color.black.opacity(style.ambientShadow.opacity),
            radius: style.ambientShadow.blur,
            x: 0,
            y: style.ambientShadow.y
        )
        .shadow(
            color: Color.black.opacity(style.contactShadow.opacity),
            radius: style.contactShadow.blur,
            x: 0,
            y: style.contactShadow.y
        )
    }

    private func surfaceContent(padding: CGFloat) -> some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: alignment)
            .environment(\.colorScheme, AppCardGlassTheme.forcedContentColorScheme)
    }

    @available(iOS 26.0, *)
    private func nativeBackground(
        shape: RoundedRectangle,
        style: AppGlassStyle
    ) -> some View {
        shape
            .fill(.clear)
            .glassEffect(nativeGlass(for: style), in: shape)
            .overlay {
                shape.fill(surfaceOverlay(for: style))
            }
            .overlay {
                if let resolvedTint {
                    shape.fill(resolvedTint.opacity(resolvedTintOpacity(for: style)))
                }
            }
    }

    private func fallbackBackground(
        shape: RoundedRectangle,
        style: AppGlassStyle
    ) -> some View {
        shape
            .fill(style.fallbackMaterial)
            .overlay {
                shape.fill(surfaceOverlay(for: style))
            }
            .overlay {
                shape.fill(DawnColor.glassWarmOverlay.opacity(style.warmOverlayOpacity))
            }
            .overlay {
                if let resolvedTint {
                    shape.fill(resolvedTint.opacity(resolvedTintOpacity(for: style)))
                }
            }
    }

    private func surfaceOverlay(for style: AppGlassStyle) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(style.baseOverlayOpacity * 0.38)
        }
        return Color.white.opacity(style.baseOverlayOpacity)
    }

    private func strokeColor(for style: AppGlassStyle) -> Color {
        Color.white.opacity(colorScheme == .dark ? style.strokeOpacityDark : style.strokeOpacityLight)
    }

    @available(iOS 26.0, *)
    private func nativeGlass(for style: AppGlassStyle) -> Glass {
        let baseGlass: Glass
        switch style.nativeGlassKind {
        case .clear:
            baseGlass = .clear
        case .regular:
            baseGlass = .regular
        }

        var glass = baseGlass.interactive(false)
        if let resolvedTint {
            glass = glass.tint(resolvedTint.opacity(resolvedTintOpacity(for: style)))
        }
        return glass
    }

    private var resolvedTint: Color? {
        tint ?? AppCardGlassTheme.tintColor
    }

    private func resolvedTintOpacity(for style: AppGlassStyle) -> Double {
        let resolvedMultiplier = tint == nil ? AppCardGlassTheme.tintOpacityMultiplier : tintOpacityMultiplier
        return min(1, max(0, style.tintOpacity * resolvedMultiplier))
    }
}

struct AppPageBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Image("WakeScreenBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }
}

struct AppHomeContrastOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.25)

            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.68), location: 0.00),
                    .init(color: Color.black.opacity(0.42), location: 0.26),
                    .init(color: Color.black.opacity(0.18), location: 0.58),
                    .init(color: Color.black.opacity(0.06), location: 1.00)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct AppSectionHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let trailing: () -> Trailing

    init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                Text(title)
                    .appTextRole(.eyebrow)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: DesignTokens.spacingS)
            trailing()
        }
    }
}

struct AppHeroMetric: View {
    let value: String
    let title: String?
    let subtitle: String?

    @ScaledMetric(relativeTo: .largeTitle) private var heroMetricPointSize: CGFloat = DesignTokens.heroMetricPointSize

    init(
        value: String,
        title: String? = nil,
        subtitle: String? = nil
    ) {
        self.value = value
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.inlineSpacingMedium) {
            Text(value)
                .font(AppTypography.heroMetricFont(size: heroMetricPointSize))
                .monospacedDigit()
                .minimumScaleFactor(DesignTokens.heroMetricMinScaleFactor)

            if let title {
                Text(title)
                    .font(AppTypography.heroTitle)
            }

            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AppInsetGroup<Content: View>: View {
    let tint: Color?
    let tintOpacityMultiplier: Double
    @ViewBuilder let content: () -> Content

    init(
        tint: Color? = nil,
        tintOpacityMultiplier: Double = 1,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tint = tint
        self.tintOpacityMultiplier = tintOpacityMultiplier
        self.content = content
    }

    var body: some View {
        AppGlassSurface(
            variant: .grouped,
            tint: tint,
            tintOpacityMultiplier: tintOpacityMultiplier,
            contentPadding: 0
        ) {
            VStack(spacing: 0) {
                content()
            }
        }
    }
}

struct AppGroupDivider: View {
    var inset: CGFloat = DesignTokens.spacingL

    var body: some View {
        Divider()
            .overlay(Color.white.opacity(0.04))
            .padding(.leading, inset)
    }
}

extension View {
    func appPageBackground() -> some View {
        background(AppPageBackground().ignoresSafeArea())
    }

    @ViewBuilder
    func appScrollableChrome() -> some View {
        self
            .appPageBackground()
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
    }

    @ViewBuilder
    func appSettingsScrollableChrome() -> some View {
        self
            .background {
                ZStack {
                    AppPageBackground()
                    LinearGradient(
                        stops: [
                            .init(color: Color.black.opacity(0.78), location: 0.00),
                            .init(color: Color.black.opacity(0.64), location: 0.46),
                            .init(color: Color.black.opacity(0.54), location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
    }

    @ViewBuilder
    func appPresentedChrome() -> some View {
        if #available(iOS 16.4, *) {
            self
                .appPageBackground()
                .presentationBackground(.clear)
        } else {
            self.appPageBackground()
        }
    }

    @ViewBuilder
    func appSettingsPresentedChrome() -> some View {
        if #available(iOS 16.4, *) {
            self
                .presentationBackground(.clear)
                .preferredColorScheme(.dark)
        } else {
            self.preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    func appControlStyle(
        _ prominence: AppControlProminence,
        tint: Color? = nil
    ) -> some View {
        let resolvedTint = tint ?? Color.secondary

        switch prominence {
        case .primary:
            if #available(iOS 26.0, *) {
                self
                    .buttonStyle(.glassProminent)
                    .tint(resolvedTint)
            } else {
                self
                    .buttonStyle(.borderedProminent)
                    .tint(resolvedTint)
            }
        case .secondary:
            if #available(iOS 26.0, *) {
                if let tint {
                    self
                        .buttonStyle(.glass(.regular.tint(tint.opacity(0.12))))
                        .tint(tint)
                } else {
                    self
                        .buttonStyle(.glass(.regular))
                        .tint(resolvedTint)
                }
            } else {
                self
                    .buttonStyle(.bordered)
                    .tint(resolvedTint)
            }
        case .quiet:
            if #available(iOS 26.0, *) {
                self
                    .buttonStyle(.glass(.clear))
                    .tint(resolvedTint)
            } else {
                if let tint {
                    self
                        .buttonStyle(.plain)
                        .foregroundStyle(tint)
                } else {
                    self
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    func appToolbarButtonChrome() -> some View {
        if #available(iOS 26.0, *) {
            self
                .padding(6)
                .glassEffect(.clear, in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                }
        } else {
            self
                .padding(6)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.05), lineWidth: 1)
                        }
                )
        }
    }
}
