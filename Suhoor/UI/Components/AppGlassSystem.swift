import SwiftUI

enum AppGlassSurfaceVariant {
    case hero
    case standard
    case quiet
    case tinted
    case grouped
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
            return AppGlassStyle(
                cornerRadius: 26,
                padding: 16,
                fallbackMaterial: .regularMaterial,
                baseOverlayOpacity: 0.10,
                warmOverlayOpacity: 0.0,
                tintOpacity: 0.035,
                strokeOpacityLight: 0.12,
                strokeOpacityDark: 0.09,
                ambientShadow: ShadowStyle(y: 6, blur: 14, opacity: 0.04),
                contactShadow: ShadowStyle(y: 1, blur: 4, opacity: 0.03),
                nativeGlassKind: .regular
            )
        case (.standard, _):
            return AppGlassStyle(
                cornerRadius: 22,
                padding: 12,
                fallbackMaterial: .thinMaterial,
                baseOverlayOpacity: 0.08,
                warmOverlayOpacity: 0.0,
                tintOpacity: 0.025,
                strokeOpacityLight: 0.09,
                strokeOpacityDark: 0.07,
                ambientShadow: ShadowStyle(y: 4, blur: 10, opacity: 0.028),
                contactShadow: ShadowStyle(y: 1, blur: 3, opacity: 0.02),
                nativeGlassKind: .regular
            )
        case (.quiet, _):
            return AppGlassStyle(
                cornerRadius: 18,
                padding: 10,
                fallbackMaterial: .thinMaterial,
                baseOverlayOpacity: 0.06,
                warmOverlayOpacity: 0.0,
                tintOpacity: 0.018,
                strokeOpacityLight: 0.07,
                strokeOpacityDark: 0.06,
                ambientShadow: ShadowStyle(y: 2, blur: 6, opacity: 0.015),
                contactShadow: ShadowStyle(y: 1, blur: 2, opacity: 0.01),
                nativeGlassKind: .clear
            )
        case (.tinted, _):
            return AppGlassStyle(
                cornerRadius: 22,
                padding: 14,
                fallbackMaterial: .regularMaterial,
                baseOverlayOpacity: 0.09,
                warmOverlayOpacity: 0.0,
                tintOpacity: 0.05,
                strokeOpacityLight: 0.09,
                strokeOpacityDark: 0.08,
                ambientShadow: ShadowStyle(y: 4, blur: 10, opacity: 0.03),
                contactShadow: ShadowStyle(y: 1, blur: 3, opacity: 0.02),
                nativeGlassKind: .regular
            )
        case (.grouped, _):
            return AppGlassStyle(
                cornerRadius: 20,
                padding: 0,
                fallbackMaterial: .thinMaterial,
                baseOverlayOpacity: 0.08,
                warmOverlayOpacity: 0.0,
                tintOpacity: 0.022,
                strokeOpacityLight: 0.08,
                strokeOpacityDark: 0.08,
                ambientShadow: ShadowStyle(y: 4, blur: 8, opacity: 0.02),
                contactShadow: ShadowStyle(y: 1, blur: 3, opacity: 0.015),
                nativeGlassKind: .clear
            )
        }
    }
}

struct AppGlassSurface<Content: View>: View {
    let variant: AppGlassSurfaceVariant
    let prominence: AppGlassProminence
    let tint: Color?
    let contentPadding: CGFloat?
    let maxWidth: CGFloat?
    let alignment: Alignment
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        variant: AppGlassSurfaceVariant = .standard,
        prominence: AppGlassProminence = .regular,
        tint: Color? = nil,
        contentPadding: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        alignment: Alignment = .leading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.variant = variant
        self.prominence = prominence
        self.tint = tint
        self.contentPadding = contentPadding
        self.maxWidth = maxWidth
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        let style = AppGlassStyle.make(variant: variant, prominence: prominence)
        let cornerRadius = style.cornerRadius
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
                if let tint {
                    shape.fill(tint.opacity(style.tintOpacity))
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
                if let tint {
                    shape.fill(tint.opacity(style.tintOpacity))
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
        if let tint {
            glass = glass.tint(tint.opacity(style.tintOpacity))
        }
        return glass
    }
}

struct AppPageBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            baseColor

            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.32))
                .frame(width: 320, height: 320)
                .blur(radius: 66)
                .offset(x: -150, y: -230)

            Circle()
                .fill(
                    colorScheme == .dark
                    ? Color.white.opacity(0.02)
                    : Color.black.opacity(0.03)
                )
                .frame(width: 360, height: 360)
                .blur(radius: 70)
                .offset(x: 170, y: 300)

            Rectangle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.02 : 0.08))
                .blendMode(.softLight)
        }
    }

    private var baseColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.07, green: 0.08, blue: 0.10)
        }
        return Color(red: 0.97, green: 0.973, blue: 0.98)
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.11, green: 0.12, blue: 0.14),
                Color(red: 0.08, green: 0.09, blue: 0.11),
                Color(red: 0.05, green: 0.06, blue: 0.08)
            ]
        }

        return [
            Color.white,
            Color(red: 0.965, green: 0.969, blue: 0.976),
            Color(red: 0.952, green: 0.956, blue: 0.965)
        ]
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
    @ViewBuilder let content: () -> Content

    init(
        tint: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tint = tint
        self.content = content
    }

    var body: some View {
        AppGlassSurface(variant: .grouped, tint: tint, contentPadding: 0) {
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
            .toolbarBackground(.clear, for: .navigationBar, .tabBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar, .tabBar)
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
