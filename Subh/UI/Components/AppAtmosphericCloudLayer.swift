import SwiftUI

struct AppAtmosphericCloudLayer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            if reduceMotion {
                cloudStack(
                    in: geometry.size,
                    seconds: 0,
                    isMotionReduced: true
                )
            } else {
                TimelineView(.animation(minimumInterval: Self.animationFrameInterval)) { timeline in
                    cloudStack(
                        in: geometry.size,
                        seconds: timeline.date.timeIntervalSince(Self.referenceDate),
                        isMotionReduced: false
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func cloudStack(
        in size: CGSize,
        seconds: TimeInterval,
        isMotionReduced: Bool
    ) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Self.bands) { band in
                RepeatingCloudBand(
                    band: band,
                    containerSize: size,
                    seconds: seconds,
                    isMotionReduced: isMotionReduced
                )
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    private static let animationFrameInterval = 1.0 / 30.0
    private static let referenceDate = Date(timeIntervalSinceReferenceDate: 0)

    private static let bands: [AtmosphericCloudBand] = [
        AtmosphericCloudBand(
            assetName: "SubhDawnMistVeil",
            canvasHeight: 250,
            verticalOffsetRatio: 0.10,
            opacity: 0.18,
            loopDuration: 260,
            direction: -1,
            phaseOffset: 0.12,
            tileWidthMultiplier: 1.70,
            blurRadius: 2.5
        ),
        AtmosphericCloudBand(
            assetName: "SubhDawnCloudWispFar",
            canvasHeight: 170,
            verticalOffsetRatio: 0.04,
            opacity: 0.32,
            loopDuration: 220,
            direction: -1,
            phaseOffset: 0.34,
            tileWidthMultiplier: 1.65,
            blurRadius: 2
        ),
        AtmosphericCloudBand(
            assetName: "SubhDawnCloudWispMid",
            canvasHeight: 190,
            verticalOffsetRatio: 0.16,
            opacity: 0.36,
            loopDuration: 155,
            direction: -1,
            phaseOffset: 0.58,
            tileWidthMultiplier: 1.70,
            blurRadius: 1.25
        ),
        AtmosphericCloudBand(
            assetName: "SubhDawnCloudWispLow",
            canvasHeight: 220,
            verticalOffsetRatio: 0.34,
            opacity: 0.26,
            loopDuration: 110,
            direction: -1,
            phaseOffset: 0.21,
            tileWidthMultiplier: 1.80,
            blurRadius: 1
        ),
        AtmosphericCloudBand(
            assetName: "SubhDawnCloudWispNear",
            canvasHeight: 235,
            verticalOffsetRatio: 0.42,
            opacity: 0.20,
            loopDuration: 76,
            direction: -1,
            phaseOffset: 0.73,
            tileWidthMultiplier: 1.95,
            blurRadius: 0.75
        )
    ]
}

private struct RepeatingCloudBand: View {
    let band: AtmosphericCloudBand
    let containerSize: CGSize
    let seconds: TimeInterval
    let isMotionReduced: Bool

    var body: some View {
        let tileWidth = max(containerSize.width * band.tileWidthMultiplier, 1)
        let animatedProgress = CGFloat(seconds.truncatingRemainder(dividingBy: band.loopDuration) / band.loopDuration)
        let progress = isMotionReduced ? band.phaseOffset : (animatedProgress + band.phaseOffset).truncatingRemainder(dividingBy: 1)
        let phase = progress * tileWidth * band.direction

        HStack(spacing: 0) {
            cloudImage(tileWidth: tileWidth)
            cloudImage(tileWidth: tileWidth)
            cloudImage(tileWidth: tileWidth)
        }
        .frame(width: tileWidth * 3, height: band.canvasHeight, alignment: .leading)
        .offset(x: -tileWidth + phase)
        .offset(y: containerSize.height * band.verticalOffsetRatio)
        .opacity(band.opacity)
        .blur(radius: band.blurRadius)
        .blendMode(.screen)
    }

    private func cloudImage(tileWidth: CGFloat) -> some View {
        Image(band.assetName)
            .resizable()
            .scaledToFill()
            .frame(width: tileWidth, height: band.canvasHeight)
            .clipped()
    }
}

private struct AtmosphericCloudBand: Identifiable {
    let assetName: String
    let canvasHeight: CGFloat
    let verticalOffsetRatio: CGFloat
    let opacity: Double
    let loopDuration: TimeInterval
    let direction: CGFloat
    let phaseOffset: CGFloat
    let tileWidthMultiplier: CGFloat
    let blurRadius: CGFloat

    var id: String { assetName }
}
