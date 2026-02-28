import SwiftUI

struct TimeTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: DesignTokens.timeFontSize, weight: .semibold, design: .rounded))
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
