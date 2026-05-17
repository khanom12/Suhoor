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

                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: band.filamentBlurRadius))
                    drawFilaments(band, in: &layer)
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

    private func drawFilaments(_ band: AtmosphericCloudBand, in context: inout GraphicsContext) {
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

            for filament in band.filaments {
                var path = Path()
                path.move(
                    to: CGPoint(
                        x: patternOriginX + patternWidth * filament.start.xRatio,
                        y: bandCenterY + bandHeight * filament.start.yRatio
                    )
                )
                path.addCurve(
                    to: CGPoint(
                        x: patternOriginX + patternWidth * filament.end.xRatio,
                        y: bandCenterY + bandHeight * filament.end.yRatio
                    ),
                    control1: CGPoint(
                        x: patternOriginX + patternWidth * filament.control1.xRatio,
                        y: bandCenterY + bandHeight * filament.control1.yRatio
                    ),
                    control2: CGPoint(
                        x: patternOriginX + patternWidth * filament.control2.xRatio,
                        y: bandCenterY + bandHeight * filament.control2.yRatio
                    )
                )

                context.stroke(
                    path,
                    with: .color(Color.white.opacity(min(0.78, band.opacity * 1.35 * filament.opacity))),
                    style: StrokeStyle(
                        lineWidth: max(1.4, bandHeight * filament.lineWidthRatio * band.scale),
                        lineCap: .round,
                        lineJoin: .round
                    )
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
            centerYRatio: 0.22,
            heightRatio: 0.20,
            patternWidthMultiplier: 1.36,
            speed: 5.2,
            phase: 0.18,
            opacity: 0.72,
            scale: 1.02,
            blurRadius: 12,
            filamentBlurRadius: 1.5,
            color: .white,
            shapes: [
                .init(xRatio: 0.04, yRatio: -0.16, widthRatio: 0.42, heightRatio: 0.30, opacity: 0.42),
                .init(xRatio: 0.18, yRatio: -0.04, widthRatio: 0.68, heightRatio: 0.27, opacity: 0.76),
                .init(xRatio: 0.36, yRatio: 0.10, widthRatio: 0.56, heightRatio: 0.20, opacity: 0.56),
                .init(xRatio: 0.57, yRatio: -0.12, widthRatio: 0.82, heightRatio: 0.24, opacity: 0.68),
                .init(xRatio: 0.78, yRatio: 0.04, widthRatio: 0.54, heightRatio: 0.18, opacity: 0.52),
                .init(xRatio: 0.96, yRatio: -0.08, widthRatio: 0.36, heightRatio: 0.16, opacity: 0.38)
            ],
            filaments: [
                .init(start: .init(xRatio: -0.04, yRatio: -0.06), control1: .init(xRatio: 0.13, yRatio: -0.22), control2: .init(xRatio: 0.34, yRatio: 0.10), end: .init(xRatio: 0.56, yRatio: -0.06), lineWidthRatio: 0.028, opacity: 0.74),
                .init(start: .init(xRatio: 0.22, yRatio: 0.08), control1: .init(xRatio: 0.42, yRatio: -0.08), control2: .init(xRatio: 0.66, yRatio: 0.20), end: .init(xRatio: 0.88, yRatio: -0.02), lineWidthRatio: 0.022, opacity: 0.58),
                .init(start: .init(xRatio: 0.58, yRatio: -0.14), control1: .init(xRatio: 0.76, yRatio: -0.26), control2: .init(xRatio: 0.96, yRatio: 0.02), end: .init(xRatio: 1.10, yRatio: -0.12), lineWidthRatio: 0.018, opacity: 0.48)
            ]
        ),
        AtmosphericCloudBand(
            centerYRatio: 0.36,
            heightRatio: 0.24,
            patternWidthMultiplier: 1.56,
            speed: -3.85,
            phase: 0.58,
            opacity: 0.58,
            scale: 1.12,
            blurRadius: 15,
            filamentBlurRadius: 2.5,
            color: DawnColor.lightApricot50,
            shapes: [
                .init(xRatio: 0.02, yRatio: 0.08, widthRatio: 0.34, heightRatio: 0.18, opacity: 0.38),
                .init(xRatio: 0.17, yRatio: -0.04, widthRatio: 0.74, heightRatio: 0.26, opacity: 0.70),
                .init(xRatio: 0.34, yRatio: 0.13, widthRatio: 0.58, heightRatio: 0.17, opacity: 0.48),
                .init(xRatio: 0.52, yRatio: -0.09, widthRatio: 0.92, heightRatio: 0.28, opacity: 0.78),
                .init(xRatio: 0.72, yRatio: 0.08, widthRatio: 0.62, heightRatio: 0.19, opacity: 0.54),
                .init(xRatio: 0.92, yRatio: -0.04, widthRatio: 0.44, heightRatio: 0.16, opacity: 0.40)
            ],
            filaments: [
                .init(start: .init(xRatio: -0.02, yRatio: 0.02), control1: .init(xRatio: 0.18, yRatio: -0.18), control2: .init(xRatio: 0.38, yRatio: 0.14), end: .init(xRatio: 0.62, yRatio: -0.04), lineWidthRatio: 0.024, opacity: 0.66),
                .init(start: .init(xRatio: 0.26, yRatio: -0.10), control1: .init(xRatio: 0.46, yRatio: 0.06), control2: .init(xRatio: 0.66, yRatio: -0.20), end: .init(xRatio: 0.96, yRatio: 0.04), lineWidthRatio: 0.020, opacity: 0.56),
                .init(start: .init(xRatio: 0.54, yRatio: 0.16), control1: .init(xRatio: 0.72, yRatio: 0.00), control2: .init(xRatio: 0.92, yRatio: 0.18), end: .init(xRatio: 1.12, yRatio: 0.04), lineWidthRatio: 0.016, opacity: 0.44)
            ]
        ),
        AtmosphericCloudBand(
            centerYRatio: 0.58,
            heightRatio: 0.22,
            patternWidthMultiplier: 1.42,
            speed: 2.55,
            phase: 0.36,
            opacity: 0.28,
            scale: 1.24,
            blurRadius: 20,
            filamentBlurRadius: 4,
            color: .white,
            shapes: [
                .init(xRatio: 0.08, yRatio: -0.02, widthRatio: 0.54, heightRatio: 0.18, opacity: 0.38),
                .init(xRatio: 0.24, yRatio: 0.10, widthRatio: 0.82, heightRatio: 0.22, opacity: 0.58),
                .init(xRatio: 0.46, yRatio: -0.08, widthRatio: 0.64, heightRatio: 0.18, opacity: 0.42),
                .init(xRatio: 0.68, yRatio: 0.04, widthRatio: 0.88, heightRatio: 0.23, opacity: 0.64),
                .init(xRatio: 0.90, yRatio: -0.10, widthRatio: 0.48, heightRatio: 0.16, opacity: 0.36)
            ],
            filaments: [
                .init(start: .init(xRatio: 0.02, yRatio: 0.04), control1: .init(xRatio: 0.20, yRatio: -0.10), control2: .init(xRatio: 0.42, yRatio: 0.14), end: .init(xRatio: 0.68, yRatio: 0.02), lineWidthRatio: 0.016, opacity: 0.48),
                .init(start: .init(xRatio: 0.38, yRatio: -0.08), control1: .init(xRatio: 0.58, yRatio: 0.10), control2: .init(xRatio: 0.78, yRatio: -0.16), end: .init(xRatio: 1.04, yRatio: -0.02), lineWidthRatio: 0.014, opacity: 0.38)
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
    let filamentBlurRadius: CGFloat
    let color: Color
    let shapes: [AtmosphericCloudShape]
    let filaments: [AtmosphericCloudFilament]
}

private struct AtmosphericCloudShape {
    let xRatio: CGFloat
    let yRatio: CGFloat
    let widthRatio: CGFloat
    let heightRatio: CGFloat
    let opacity: Double
}

private struct AtmosphericCloudFilament {
    let start: AtmosphericCloudPoint
    let control1: AtmosphericCloudPoint
    let control2: AtmosphericCloudPoint
    let end: AtmosphericCloudPoint
    let lineWidthRatio: CGFloat
    let opacity: Double
}

private struct AtmosphericCloudPoint {
    let xRatio: CGFloat
    let yRatio: CGFloat
}
