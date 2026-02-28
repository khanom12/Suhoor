import SwiftUI

struct PressableRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                    .fill(DawnColor.glassWarmOverlay.opacity(configuration.isPressed ? 0.12 : 0.0))
            )
    }
}
