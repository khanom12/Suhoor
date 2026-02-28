import SwiftUI
import MediaPlayer

struct TimeText: View {
    let text: String
    let font: Font
    var isEnabled: Bool = true

    var body: some View {
        Text(text)
            .font(font)
            .monospacedDigit()
            .foregroundStyle(isEnabled ? .primary : .secondary)
    }
}

struct RuleBadgeView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            if let message = message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(.footnote.weight(.semibold))
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct TwoLineTitleView: View {
    let titleLine: String
    let dateLine: String

    var body: some View {
        VStack(spacing: 2) {
            Text(titleLine)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
            Text(dateLine)
                .font(.subheadline)
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
            .font(.headline.weight(.semibold))
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

            VStack(spacing: 2) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.black.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .opacity(subtitleOpacity)
                }
                if let tertiary {
                    Text(tertiary)
                        .font(.footnote.weight(.semibold))
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
