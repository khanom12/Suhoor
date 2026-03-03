import SwiftUI

struct TimeTextStyle: ViewModifier {
    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize: CGFloat = DesignTokens.dashboardTimeFontSize

    func body(content: Content) -> some View {
        content
            .font(.system(size: timeFontSize, weight: .regular, design: .default))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .allowsTightening(true)
            .layoutPriority(2)
    }
}

extension View {
    func timeTextStyle() -> some View {
        modifier(TimeTextStyle())
    }
}
