import SwiftUI

struct AppAtmosphericCloudLayer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            if reduceMotion {
                AppAtmosphericCloudCanvas(
                    elapsedSeconds: 0,
                    motionScale: 0,
                    size: geometry.size
                )
            } else {
                TimelineView(.animation(minimumInterval: Self.animationFrameInterval)) { timeline in
                    AppAtmosphericCloudCanvas(
                        elapsedSeconds: timeline.date.timeIntervalSince(Self.referenceDate),
                        motionScale: 1,
                        size: geometry.size
                    )
                }
            }
        }
        .compositingGroup()
        .blendMode(.screen)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static let animationFrameInterval = 1.0 / 24.0
    private static let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
}

private struct AppAtmosphericCloudCanvas: View {
    let elapsedSeconds: TimeInterval
    let motionScale: CGFloat
    let size: CGSize

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: true) { context, _ in
            guard size.width > 1, size.height > 1 else { return }

            for band in Self.bands {
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: band.blurRadius))
                    drawBand(band, in: &layer)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func drawBand(_ band: AtmosphericCloudBand, in context: inout GraphicsContext) {
        let bandHeight = size.height * band.heightRatio
        let bandCenterY = size.height * band.centerYRatio
        let patternWidth = max(size.width * band.patternWidthMultiplier, 1)
        let travelWidth = patternWidth
        let baseOffset = positiveRemainder(
            CGFloat(elapsedSeconds) * band.speed * motionScale + patternWidth * band.phase,
            dividedBy: travelWidth
        )

        for repeatIndex in -1...1 {
            let patternOriginX = CGFloat(repeatIndex) * patternWidth - baseOffset

            for shape in band.shapes {
                let center = CGPoint(
                    x: patternOriginX + patternWidth * shape.xRatio,
                    y: bandCenterY + bandHeight * shape.yRatio
                )
                let rect = CGRect(
                    x: center.x - size.width * shape.widthRatio * band.scale / 2,
                    y: center.y - bandHeight * shape.heightRatio * band.scale / 2,
                    width: size.width * shape.widthRatio * band.scale,
                    height: bandHeight * shape.heightRatio * band.scale
                )

                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(band.color.opacity(band.opacity * shape.opacity))
                )
            }
        }
    }

    private func positiveRemainder(_ value: CGFloat, dividedBy divisor: CGFloat) -> CGFloat {
        guard divisor > 0 else { return 0 }

        let remainder = value.truncatingRemainder(dividingBy: divisor)
        return remainder >= 0 ? remainder : remainder + divisor
    }

    private static let bands: [AtmosphericCloudBand] = [
        AtmosphericCloudBand(
            centerYRatio: 0.18,
            heightRatio: 0.18,
            patternWidthMultiplier: 1.32,
            speed: 2.2,
            phase: 0.18,
            opacity: 0.13,
            scale: 0.92,
            blurRadius: 24,
            color: DawnColor.lightGold50,
            shapes: [
                .init(xRatio: 0.06, yRatio: -0.12, widthRatio: 0.34, heightRatio: 0.42, opacity: 0.48),
                .init(xRatio: 0.18, yRatio: -0.04, widthRatio: 0.52, heightRatio: 0.36, opacity: 0.72),
                .init(xRatio: 0.36, yRatio: 0.08, widthRatio: 0.44, heightRatio: 0.26, opacity: 0.54),
                .init(xRatio: 0.62, yRatio: -0.10, widthRatio: 0.58, heightRatio: 0.34, opacity: 0.62),
                .init(xRatio: 0.82, yRatio: 0.04, widthRatio: 0.42, heightRatio: 0.24, opacity: 0.45),
                .init(xRatio: 0.96, yRatio: -0.06, widthRatio: 0.28, heightRatio: 0.20, opacity: 0.34)
            ]
        ),
        AtmosphericCloudBand(
            centerYRatio: 0.39,
            heightRatio: 0.22,
            patternWidthMultiplier: 1.52,
            speed: -1.65,
            phase: 0.58,
            opacity: 0.115,
            scale: 1.08,
            blurRadius: 30,
            color: DawnColor.lightApricot50,
            shapes: [
                .init(xRatio: 0.02, yRatio: 0.06, widthRatio: 0.24, heightRatio: 0.24, opacity: 0.34),
                .init(xRatio: 0.16, yRatio: -0.02, widthRatio: 0.56, heightRatio: 0.32, opacity: 0.64),
                .init(xRatio: 0.32, yRatio: 0.12, widthRatio: 0.42, heightRatio: 0.22, opacity: 0.44),
                .init(xRatio: 0.52, yRatio: -0.08, widthRatio: 0.68, heightRatio: 0.36, opacity: 0.72),
                .init(xRatio: 0.72, yRatio: 0.08, widthRatio: 0.48, heightRatio: 0.25, opacity: 0.50),
                .init(xRatio: 0.90, yRatio: -0.04, widthRatio: 0.36, heightRatio: 0.20, opacity: 0.36)
            ]
        ),
        AtmosphericCloudBand(
            centerYRatio: 0.66,
            heightRatio: 0.20,
            patternWidthMultiplier: 1.42,
            speed: 1.2,
            phase: 0.36,
            opacity: 0.08,
            scale: 1.22,
            blurRadius: 34,
            color: .white,
            shapes: [
                .init(xRatio: 0.08, yRatio: -0.02, widthRatio: 0.44, heightRatio: 0.24, opacity: 0.36),
                .init(xRatio: 0.24, yRatio: 0.10, widthRatio: 0.62, heightRatio: 0.28, opacity: 0.56),
                .init(xRatio: 0.46, yRatio: -0.08, widthRatio: 0.50, heightRatio: 0.26, opacity: 0.42),
                .init(xRatio: 0.68, yRatio: 0.04, widthRatio: 0.70, heightRatio: 0.30, opacity: 0.62),
                .init(xRatio: 0.90, yRatio: -0.10, widthRatio: 0.38, heightRatio: 0.20, opacity: 0.34)
            ]
        )
    ]
}

private struct AtmosphericCloudBand {
    let centerYRatio: CGFloat
    let heightRatio: CGFloat
    let patternWidthMultiplier: CGFloat
    let speed: CGFloat
    let phase: CGFloat
    let opacity: Double
    let scale: CGFloat
    let blurRadius: CGFloat
    let color: Color
    let shapes: [AtmosphericCloudShape]
}

private struct AtmosphericCloudShape {
    let xRatio: CGFloat
    let yRatio: CGFloat
    let widthRatio: CGFloat
    let heightRatio: CGFloat
    let opacity: Double
}
