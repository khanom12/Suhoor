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
                RepeatingHeroCloudLayer(
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
    }

    private static func heroCloudHeight(for size: CGSize) -> CGFloat {
        min(max(size.height * 0.42, 320), 500)
    }

    private static let animationFrameInterval = 1.0 / 30.0
    private static let referenceDate = Date(timeIntervalSinceReferenceDate: 0)

    private static let layers: [HeroCloudLayer] = [
        HeroCloudLayer(
            assetName: "SubhDawnHeroCloudMist",
            duration: 290,
            opacity: 0.25,
            widthMultiplier: 1.45,
            phaseOffset: 0.08,
            yOffsetRatio: -0.06,
            blurRadius: 4
        ),
        HeroCloudLayer(
            assetName: "SubhDawnHeroCloudFar",
            duration: 235,
            opacity: 0.43,
            widthMultiplier: 1.52,
            phaseOffset: 0.31,
            yOffsetRatio: -0.05,
            blurRadius: 1.5
        ),
        HeroCloudLayer(
            assetName: "SubhDawnHeroCloudMid",
            duration: 168,
            opacity: 0.54,
            widthMultiplier: 1.58,
            phaseOffset: 0.57,
            yOffsetRatio: -0.02,
            blurRadius: 0.75
        ),
        HeroCloudLayer(
            assetName: "SubhDawnHeroCloudLow",
            duration: 116,
            opacity: 0.48,
            widthMultiplier: 1.66,
            phaseOffset: 0.19,
            yOffsetRatio: 0.03,
            blurRadius: 0.25
        ),
        HeroCloudLayer(
            assetName: "SubhDawnHeroCloudNear",
            duration: 78,
            opacity: 0.40,
            widthMultiplier: 1.74,
            phaseOffset: 0.73,
            yOffsetRatio: 0.06,
            blurRadius: 0
        )
    ]
}

private struct RepeatingHeroCloudLayer: View {
    let layer: HeroCloudLayer
    let containerWidth: CGFloat
    let containerHeight: CGFloat
    let seconds: TimeInterval
    let isMotionReduced: Bool

    var body: some View {
        let tileWidth = max(containerWidth * layer.widthMultiplier, containerWidth + 1)
        let animatedProgress = seconds.truncatingRemainder(dividingBy: layer.duration) / layer.duration
        let progress = isMotionReduced
            ? layer.phaseOffset
            : (animatedProgress + layer.phaseOffset).truncatingRemainder(dividingBy: 1)
        let xOffset = -tileWidth * CGFloat(progress)

        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { _ in
                cloudImage(tileWidth: tileWidth)
            }
        }
        .frame(width: tileWidth * 3, height: containerHeight, alignment: .leading)
        .offset(x: xOffset - tileWidth, y: containerHeight * layer.yOffsetRatio)
        .opacity(layer.opacity)
        .blur(radius: layer.blurRadius)
        .compositingGroup()
    }

    private func cloudImage(tileWidth: CGFloat) -> some View {
        Image(layer.assetName)
            .resizable()
            .scaledToFill()
            .frame(width: tileWidth, height: containerHeight, alignment: .top)
            .clipped()
    }
}

private struct HeroCloudLayer: Identifiable {
    let assetName: String
    let duration: TimeInterval
    let opacity: Double
    let widthMultiplier: CGFloat
    let phaseOffset: TimeInterval
    let yOffsetRatio: CGFloat
    let blurRadius: CGFloat

    var id: String { assetName }
}
