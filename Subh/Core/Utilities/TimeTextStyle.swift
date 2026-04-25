import SwiftUI

struct TimeTextStyle: ViewModifier {
    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize: CGFloat = DesignTokens.timeDisplayProminentPointSize

    func body(content: Content) -> some View {
        content
            .font(AppTypography.timeDisplayFont(size: timeFontSize, weight: .light))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(DesignTokens.timeDisplayMinScaleFactor)
            .allowsTightening(true)
            .layoutPriority(2)
    }
}

extension View {
    func timeTextStyle() -> some View {
        modifier(TimeTextStyle())
    }
}
