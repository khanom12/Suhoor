import SwiftUI

struct AppAtmosphericCloudLayer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let heroCloudHeight = Self.heroCloudHeight(for: geometry.size)

            VStack(spacing: 0) {
                if reduceMotion {
                    cloudStack(
                        containerWidth: geometry.size.width,
                        containerHeight: heroCloudHeight,
                        seconds: 0,
                        isMotionReduced: true
                    )
                } else {
                    TimelineView(.animation(minimumInterval: Self.animationFrameInterval)) { timeline in
                        cloudStack(
                            containerWidth: geometry.size.width,
                            containerHeight: heroCloudHeight,
                            seconds: timeline.date.timeIntervalSince(Self.referenceDate),
                            isMotionReduced: false
                        )
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func cloudStack(
        containerWidth: CGFloat,
        containerHeight: CGFloat,
        seconds: TimeInterval,
        isMotionReduced: Bool
    ) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Self.layers) { layer in
                SeamlessHeroCloudLayer(
                    layer: layer,
                    containerWidth: containerWidth,
                    containerHeight: containerHeight,
                    seconds: seconds,
                    isMotionReduced: isMotionReduced
                )
            }
        }
        .frame(width: containerWidth, height: containerHeight, alignment: .top)
        .clipped()
        .mask(alignment: .top) {
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.95), location: 0.00),
                    .init(color: .white, location: 0.62),
                    .init(color: .white.opacity(0.00), location: 1.00)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .mask {
            HorizontalFeatherMask(
                leadingOpaqueLocation: 0.04,
                trailingOpaqueLocation: 0.96,
                edgeOpacity: 0.72
            )
        }
    }

    private static func heroCloudHeight(for size: CGSize) -> CGFloat {
        min(max(size.height * 0.42, 320), 500)
    }

    private static let animationFrameInterval = 1.0 / 30.0
    private static let referenceDate = Date(timeIntervalSinceReferenceDate: 0)

    private static let layers: [HeroCloudLayer] = [
        HeroCloudLayer(
            assetName: "SubhDawnHeroCloudMist",
            duration: 116,
            opacity: 0.25,
            phaseOffset: 0.08,
            yOffsetRatio: -0.06,
            blurRadius: 4,
            horizontalFeatherFraction: 0.16
        ),
        HeroCloudLayer(
            assetName: "SubhDawnHeroCloudFar",
            duration: 94,
            opacity: 0.43,
            phaseOffset: 0.31,
            yOffsetRatio: -0.05,
            blurRadius: 1.5,
            horizontalFeatherFraction: 0.16
        ),
        HeroCloudLayer(
            assetName: "SubhDawnHeroCloudMid",
            duration: 67.2,
            opacity: 0.54,
            phaseOffset: 0.57,
            yOffsetRatio: -0.02,
            blurRadius: 0.75,
            horizontalFeatherFraction: 0.18
        ),
        HeroCloudLayer(
            assetName: "SubhDawnHeroCloudLow",
            duration: 46.4,
            opacity: 0.48,
            phaseOffset: 0.19,
            yOffsetRatio: 0.03,
            blurRadius: 0.25,
            horizontalFeatherFraction: 0.20
        ),
        HeroCloudLayer(
            assetName: "SubhDawnHeroCloudNear",
            duration: 31.2,
            opacity: 0.40,
            phaseOffset: 0.73,
            yOffsetRatio: 0.06,
            blurRadius: 0,
            horizontalFeatherFraction: 0.22
        )
    ]
}

private struct SeamlessHeroCloudLayer: View {
    let layer: HeroCloudLayer
    let containerWidth: CGFloat
    let containerHeight: CGFloat
    let seconds: TimeInterval
    let isMotionReduced: Bool

    var body: some View {
        let tileWidth = containerHeight * Self.assetAspectRatio
        let featherWidth = tileWidth * layer.horizontalFeatherFraction
        let tileStride = max(tileWidth - featherWidth, 1)
        let leadingOverscan = tileWidth + tileStride
        let trailingOverscan = tileWidth + tileStride
        let copyCount = Self.copyCount(
            containerWidth: containerWidth,
            leadingOverscan: leadingOverscan,
            trailingOverscan: trailingOverscan,
            tileStride: tileStride
        )
        let animatedProgress = seconds.truncatingRemainder(dividingBy: layer.duration) / layer.duration
        let progress = isMotionReduced
            ? layer.phaseOffset
            : (animatedProgress + layer.phaseOffset).truncatingRemainder(dividingBy: 1)
        let xOffset = tileStride * CGFloat(progress)
        let trackStart = -leadingOverscan - xOffset

        ZStack(alignment: .topLeading) {
            ForEach(0..<copyCount, id: \.self) { index in
                FeatheredCloudTile(
                    assetName: layer.assetName,
                    tileWidth: tileWidth,
                    tileHeight: containerHeight,
                    featherFraction: layer.horizontalFeatherFraction
                )
                .offset(x: trackStart + (CGFloat(index) * tileStride))
            }
        }
        .frame(width: containerWidth, height: containerHeight, alignment: .topLeading)
        .clipped()
        .offset(y: containerHeight * layer.yOffsetRatio)
        .opacity(layer.opacity)
        .blur(radius: layer.blurRadius)
        .compositingGroup()
    }

    private static let assetAspectRatio: CGFloat = 2

    private static func copyCount(
        containerWidth: CGFloat,
        leadingOverscan: CGFloat,
        trailingOverscan: CGFloat,
        tileStride: CGFloat
    ) -> Int {
        let coverageWidth = containerWidth + leadingOverscan + trailingOverscan + tileStride
        return max(4, Int(ceil(coverageWidth / tileStride)) + 1)
    }
}

private struct FeatheredCloudTile: View {
    let assetName: String
    let tileWidth: CGFloat
    let tileHeight: CGFloat
    let featherFraction: CGFloat

    var body: some View {
        Image(assetName)
            .resizable()
            .aspectRatio(Self.assetAspectRatio, contentMode: .fit)
            .frame(width: tileWidth, height: tileHeight, alignment: .center)
            .mask {
                HorizontalFeatherMask(
                    leadingOpaqueLocation: featherFraction,
                    trailingOpaqueLocation: 1 - featherFraction
                )
            }
    }

    private static let assetAspectRatio: CGFloat = 2
}

private struct HorizontalFeatherMask: View {
    let leadingOpaqueLocation: CGFloat
    let trailingOpaqueLocation: CGFloat
    var edgeOpacity: Double = 0

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(edgeOpacity), location: 0.00),
                .init(color: .white, location: leadingOpaqueLocation),
                .init(color: .white, location: trailingOpaqueLocation),
                .init(color: .white.opacity(edgeOpacity), location: 1.00)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

private struct HeroCloudLayer: Identifiable {
    let assetName: String
    let duration: TimeInterval
    let opacity: Double
    let phaseOffset: TimeInterval
    let yOffsetRatio: CGFloat
    let blurRadius: CGFloat
    let horizontalFeatherFraction: CGFloat

    var id: String { assetName }
}
