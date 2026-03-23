import SwiftUI

struct TodaySeasonalBadge: View {
    let text: String
    let accent: Color?

    var body: some View {
        Text(text)
            .font(AppTypography.badge)
            .foregroundStyle(accent ?? .secondary)
            .padding(.horizontal, DesignTokens.spacingS)
            .padding(.vertical, DesignTokens.compactChipVerticalPadding)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

struct TodayDiscreteProgressBars: View {
    let totalCount: Int
    let completedCount: Int
    let hasPending: Bool
    let color: Color
    let pulsePending: Bool
    let celebrate: Bool

    var body: some View {
        HStack(spacing: DesignTokens.spacingXS) {
            ForEach(0..<totalCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fillColor(for: index))
                    .frame(maxWidth: .infinity)
                    .frame(height: 18)
                    .scaleEffect(x: 1.0, y: celebrate ? 1.05 : 1.0)
                    .opacity(barOpacity(for: index))
            }
        }
    }

    private func fillColor(for index: Int) -> Color {
        if index < completedCount {
            return color
        }
        if hasPending && index == completedCount {
            return color.opacity(0.5)
        }
        return Color(.secondarySystemGroupedBackground)
    }

    private func barOpacity(for index: Int) -> Double {
        if hasPending && index == completedCount {
            return pulsePending ? 1.0 : 0.65
        }
        return 1.0
    }
}

struct TodayOpenScheduleButton: View {
    @EnvironmentObject private var appNavigator: AppNavigator
    let accent: Color?

    var body: some View {
        Button {
            appNavigator.switchToWake()
        } label: {
            Image(systemName: "calendar.badge.clock")
                .font(AppTypography.controlIcon)
                .foregroundStyle(accent ?? DawnColor.accent)
                .frame(width: DesignTokens.regularControlFrame, height: DesignTokens.regularControlFrame)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Strings.AlarmsTab.openAlarm)
    }
}
