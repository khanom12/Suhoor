import SwiftUI

struct FajrWindowPeriodPicker: View {
    let selectedPeriod: FajrWindowPeriod
    let onSelect: (FajrWindowPeriod) -> Void

    var body: some View {
        HStack(spacing: 8) {
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
            HStack(spacing: 8) {
                ForEach(overlays) { overlay in
                    Button {
                        onSelect(overlay)
                    }
                    label: {
                        HStack(spacing: 6) {
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
            .padding(.vertical, 2)
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
            .font(.footnote.weight(.semibold))
            .foregroundStyle(isSelected ? Color.black : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? DawnColor.lightGold200 : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.0 : 0.2), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct FajrWindowSummaryBlock: View {
    let summary: FajrWindowSummarySnapshot
    var tintColor: Color = DawnColor.lightGold200
    var tintOpacity: Double = 0.12

    var body: some View {
        GlassCard(tintColor: tintColor, tintOpacity: tintOpacity) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(summary.title)
                        .font(.headline.weight(.semibold))
                    Text(summary.body)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !summary.metrics.isEmpty {
                    VStack(spacing: DesignTokens.spacingS) {
                        ForEach(summary.metrics) { metric in
                            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacingM) {
                                Text(metric.label)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: DesignTokens.spacingS)
                                Text(metric.value)
                                    .font(.footnote.weight(.semibold))
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
        GlassCard(tintColor: DawnColor.accent, tintOpacity: 0.08) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                Text("What stands out")
                    .font(.headline.weight(.semibold))

                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                        Text(item.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
                    HStack(alignment: .center, spacing: DesignTokens.spacingM) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            if let subtitle = item.subtitle {
                                Text(subtitle)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer(minLength: DesignTokens.spacingM)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DesignTokens.spacingM)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.innerCardRadius, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
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
        case .openDefaultMorningPlan:
            return "Opens the default morning plan."
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
            .tint(.secondary)
            .disabled(!canMoveBackward)
            .accessibilityHint("Moves to the earlier day in this view.")

            Text(selectedTitle)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .accessibilityHidden(true)

            Button(action: onMoveForward) {
                Label("Next day", systemImage: "chevron.right")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .disabled(!canMoveForward)
            .accessibilityHint("Moves to the later day in this view.")
        }
        .font(.footnote)
        .accessibilityElement(children: .contain)
    }
}
