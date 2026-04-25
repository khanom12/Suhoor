import SwiftUI
import MediaPlayer

struct TimeText: View {
    let text: String
    let font: Font
    var isEnabled: Bool = true
    private let amPmScale: CGFloat = 0.6

    var body: some View {
        if let parts = timeParts {
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.textSpacingTight) {
                Text(parts.main)
                    .font(font)
                    .monospacedDigit()
                    .foregroundStyle(isEnabled ? .primary : .secondary)
                Text(parts.suffix)
                    .font(font)
                    .scaleEffect(amPmScale, anchor: .bottomLeading)
                    .foregroundStyle(isEnabled ? .primary : .secondary)
            }
        } else {
            Text(text)
                .font(font)
                .monospacedDigit()
                .foregroundStyle(isEnabled ? .primary : .secondary)
        }
    }

    private var timeParts: (main: String, suffix: String)? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let (main, suffix) = splitTimeSuffix(from: trimmed) else { return nil }
        return (main, suffix)
    }

    private func splitTimeSuffix(from value: String) -> (String, String)? {
        guard !value.isEmpty else { return nil }
        let scalars = Array(value.unicodeScalars)
        var suffixStartIndex = scalars.count
        var sawLetter = false

        for idx in scalars.indices.reversed() {
            let scalar = scalars[idx]
            if CharacterSet.letters.contains(scalar) || scalar == "." {
                sawLetter = sawLetter || CharacterSet.letters.contains(scalar)
                suffixStartIndex = idx
                continue
            }
            break
        }

        guard sawLetter, suffixStartIndex < scalars.count else { return nil }
        let suffixScalars = scalars[suffixStartIndex...]
        let suffix = String(String.UnicodeScalarView(suffixScalars))
        let mainScalars = scalars[..<suffixStartIndex]
        let main = String(String.UnicodeScalarView(mainScalars))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\u{00A0}"))
        guard !main.isEmpty else { return nil }
        return (main, suffix)
    }
}

struct RuleBadgeView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTypography.badge)
            .padding(.horizontal, DesignTokens.badgeHorizontalPadding)
            .padding(.vertical, DesignTokens.badgeVerticalPadding)
            .foregroundStyle(.secondary)
            .background(
                Capsule(style: .continuous)
                    .fill(.quaternary)
            )
    }
}

struct MaterialBannerView: View {
    let title: String
    let message: String?
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
            Text(title)
                .font(AppTypography.rowTitle)
                .foregroundStyle(.primary)

            if let message = message {
                Text(message)
                    .font(AppTypography.cardBody)
                    .foregroundStyle(.secondary)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(AppTypography.metricLabel)
            }
        }
        .padding(DesignTokens.rowVerticalPadding)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct TwoLineTitleView: View {
    let titleLine: String
    let dateLine: String

    var body: some View {
        VStack(spacing: DesignTokens.textSpacingMicro) {
            Text(titleLine)
                .font(AppTypography.cardTitle)
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
            Text(dateLine)
                .font(AppTypography.metricValue)
                .foregroundStyle(Color.black.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
        }
        .padding(.top, -4)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }
}

struct SingleLineTitleView: View {
    let titleLine: String

    var body: some View {
        Text(titleLine)
            .font(AppTypography.cardTitle)
            .foregroundStyle(Color.black)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .allowsTightening(true)
            .padding(.top, -4)
            .multilineTextAlignment(.center)
            .accessibilityLabel(titleLine)
    }
}

struct CollapsingHeaderView: View {
    let title: String
    let subtitle: String?
    let tertiary: String?
    let progress: CGFloat
    let topInset: CGFloat

    var body: some View {
        let maxHeight = DesignTokens.headerMaxHeight
        let minHeight = DesignTokens.headerMinHeight
        let height = maxHeight - (maxHeight - minHeight) * progress
        let subtitleOpacity = max(0.0, 1.0 - progress * 1.2)
        let tertiaryOpacity = max(0.0, 1.0 - progress * 1.6)

        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(DawnColor.glassWarmOverlay.opacity(0.10))
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )

            VStack(spacing: DesignTokens.textSpacingMicro) {
                Text(title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.metricValue)
                        .foregroundStyle(Color.black.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .opacity(subtitleOpacity)
                }
                if let tertiary {
                    Text(tertiary)
                        .font(AppTypography.metricLabel)
                        .foregroundStyle(Color.black.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .opacity(tertiaryOpacity)
                }
            }
            .padding(.bottom, DesignTokens.spacingS)
        }
        .frame(height: height + topInset)
        .ignoresSafeArea(edges: .top)
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct VolumeSliderView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView()
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

extension View {
    @ViewBuilder
    func sheetMaterialBackground() -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(.ultraThinMaterial)
        } else {
            self
        }
    }

    @ViewBuilder
    func readTopSafeAreaInset(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        self.background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { onChange(proxy.safeAreaInsets.top) }
                    .onChange(of: proxy.safeAreaInsets.top) { _, newValue in
                        onChange(newValue)
                    }
            }
        )
    }
}
