import SwiftUI

struct FajrWindowPeriodPicker: View {
    let selectedPeriod: FajrWindowPeriod
    let onSelect: (FajrWindowPeriod) -> Void

    var body: some View {
        HStack(spacing: DesignTokens.inlineSpacingMedium) {
            ForEach(FajrWindowPeriod.allCases) { period in
                Button(period.shortTitle) {
                    onSelect(period)
                }
                .buttonStyle(FajrWindowPickerButtonStyle(isSelected: period == selectedPeriod))
            }
        }
    }
}

struct FajrWindowOverlayPicker: View {
    let overlays: [FajrWindowOverlay]
    let selectedOverlay: FajrWindowOverlay
    var loadingOverlay: FajrWindowOverlay? = nil
    let onSelect: (FajrWindowOverlay) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.inlineSpacingMedium) {
                ForEach(overlays) { overlay in
                    Button {
                        onSelect(overlay)
                    }
                    label: {
                        HStack(spacing: DesignTokens.textSpacingCompact) {
                            Text(overlay.title)
                            if loadingOverlay == overlay {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .buttonStyle(FajrWindowPickerButtonStyle(isSelected: overlay == selectedOverlay))
                    .accessibilityLabel(overlay.title)
                    .accessibilityHint(overlay.accessibilityHint)
                    .accessibilityValue(accessibilityValue(for: overlay))
                }
            }
            .padding(.vertical, DesignTokens.accessoryInset)
        }
    }

    private func accessibilityValue(for overlay: FajrWindowOverlay) -> String {
        if loadingOverlay == overlay {
            return "Loading"
        }
        return overlay == selectedOverlay ? "Selected" : ""
    }
}

private struct FajrWindowPickerButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.badge)
            .foregroundStyle(isSelected ? Color.black : WakeGlassTheme.primaryText)
            .padding(.horizontal, DesignTokens.space12)
            .padding(.vertical, DesignTokens.space10)
            .background(
                Capsule()
                    .fill(isSelected ? DawnColor.lightGold200 : WakeGlassTheme.chipFill)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.0 : 0.12), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct FajrWindowSummaryBlock: View {
    let summary: FajrWindowSummarySnapshot

    var body: some View {
        WakeGlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
                    Text(summary.title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(WakeGlassTheme.primaryText)
                    Text(summary.body)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(WakeGlassTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !summary.metrics.isEmpty {
                    VStack(spacing: DesignTokens.spacingS) {
                        ForEach(summary.metrics) { metric in
                            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
                                Text(metric.label)
                                    .font(AppTypography.metricLabel)
                                    .foregroundStyle(WakeGlassTheme.secondaryText)
                                Spacer(minLength: DesignTokens.spacingS)
                                Text(metric.value)
                                    .font(AppTypography.metricValue)
                                    .foregroundStyle(WakeGlassTheme.primaryText)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct FajrWindowInsightList: View {
    let items: [FajrWindowInsightItem]

    var body: some View {
        WakeGlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                Text("What stands out")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(WakeGlassTheme.primaryText)

                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                        Text(item.title)
                            .font(AppTypography.rowTitle)
                            .foregroundStyle(WakeGlassTheme.primaryText)
                        Text(item.detail)
                            .font(AppTypography.rowBody)
                            .foregroundStyle(WakeGlassTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

struct FajrWindowActionRows: View {
    let items: [FajrWindowActionItem]
    let onSelect: (FajrWindowActionIntent) -> Void

    var body: some View {
        VStack(spacing: DesignTokens.spacingS) {
            ForEach(items) { item in
                Button {
                    onSelect(item.intent)
                } label: {
                    AppGlassSurface(
                        variant: .grouped,
                        contentPadding: DesignTokens.spacingM
                    ) {
                        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
                            VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                                Text(item.title)
                                    .font(AppTypography.rowTitle)
                                    .foregroundStyle(WakeGlassTheme.primaryText)
                                if let subtitle = item.subtitle {
                                    Text(subtitle)
                                        .font(AppTypography.rowBody)
                                        .foregroundStyle(WakeGlassTheme.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer(minLength: DesignTokens.spacingM)
                            Image(systemName: "chevron.right")
                                .font(AppTypography.navAccessory)
                                .foregroundStyle(WakeGlassTheme.secondaryText)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(item.title)
                .accessibilityValue(item.subtitle ?? "")
                .accessibilityHint(accessibilityHint(for: item.intent))
            }
        }
    }

    private func accessibilityHint(for intent: FajrWindowActionIntent) -> String {
        switch intent {
        case .openSelectedMorning:
            return "Opens this morning in day detail."
        }
    }
}

struct FajrWindowDayStepper: View {
    let selectedTitle: String
    let canMoveBackward: Bool
    let canMoveForward: Bool
    let onMoveBackward: () -> Void
    let onMoveForward: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.spacingS) {
            Button(action: onMoveBackward) {
                Label("Previous day", systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .disabled(!canMoveBackward)
            .accessibilityHint("Moves to the earlier day in this view.")

            Text(selectedTitle)
                .font(AppTypography.metricLabel)
                .foregroundStyle(WakeGlassTheme.secondaryText)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .accessibilityHidden(true)

            Button(action: onMoveForward) {
                Label("Next day", systemImage: "chevron.right")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .disabled(!canMoveForward)
            .accessibilityHint("Moves to the later day in this view.")
        }
        .font(AppTypography.metricValue)
        .accessibilityElement(children: .contain)
    }
}
