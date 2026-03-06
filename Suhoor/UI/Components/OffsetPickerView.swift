import SwiftUI

struct OffsetPickerView: View {
    private enum Layout {
        static let tileCornerRadius: CGFloat = 20
        static let tileMinHeight: CGFloat = 58
        static let gridSpacing: CGFloat = 10
    }

    @Binding var baseMinutes: Int
    let presetMinutes: [Int]
    let presetLabels: [Int: String]?
    let range: ClosedRange<Int>
    let step: Int
    let sentenceText: ((Int) -> String)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var isCustomSelected: Bool = false

    init(
        baseMinutes: Binding<Int>,
        presetMinutes: [Int] = [15, 30, 45, 60, 90],
        presetLabels: [Int: String]? = nil,
        range: ClosedRange<Int> = 5...240,
        step: Int = 5,
        sentenceText: ((Int) -> String)? = { "Wake me \($0) min before Fajr." }
    ) {
        _baseMinutes = baseMinutes
        self.presetMinutes = presetMinutes
        self.presetLabels = presetLabels
        self.range = range
        self.step = step
        self.sentenceText = sentenceText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: Layout.gridSpacing) {
                ForEach(presetMinutes, id: \.self) { minutes in
                    presetButton(minutes: minutes)
                }
                customButton
            }

            if let sentenceText {
                Text(sentenceText(baseMinutes))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isCustomSelected || !presetMinutes.contains(baseMinutes) {
                customStepper
            }
        }
        .onAppear {
            isCustomSelected = !presetMinutes.contains(baseMinutes)
        }
        .onChange(of: baseMinutes) { _, newValue in
            if !presetMinutes.contains(newValue) {
                isCustomSelected = true
            }
        }
    }

    private var gridColumns: [GridItem] {
        if dynamicTypeSize >= .accessibility1 {
            return [GridItem(.flexible(minimum: 120))]
        }
        if dynamicTypeSize >= .xxLarge {
            return [GridItem(.flexible(minimum: 120)), GridItem(.flexible(minimum: 120))]
        }
        return [
            GridItem(.flexible(minimum: 96)),
            GridItem(.flexible(minimum: 96)),
            GridItem(.flexible(minimum: 96))
        ]
    }

    private func presetButton(minutes: Int) -> some View {
        let isSelected = !isCustomSelected && baseMinutes == minutes
        return Button {
            Haptics.light()
            withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
                isCustomSelected = false
                baseMinutes = minutes
            }
        } label: {
            let subtitle = presetLabels?[minutes]
            VStack(spacing: 2) {
                Text("\(minutes) min")
                    .font(.callout.weight(.semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: tileHeight)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(tileFill(isSelected: isSelected), in: tileShape)
            .overlay {
                tileShape
                    .stroke(isSelected ? DawnColor.accent.opacity(0.9) : Color.primary.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(OffsetTileButtonStyle())
        .accessibilityLabel("\(minutes) minutes")
        .modifier(OffsetSelectedAccessibility(isSelected: isSelected))
    }

    private var customButton: some View {
        let isSelected = isCustomSelected || !presetMinutes.contains(baseMinutes)
        return Button {
            Haptics.light()
            withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
                isCustomSelected = true
            }
        } label: {
            Text("Custom")
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: tileHeight)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(tileFill(isSelected: isSelected), in: tileShape)
                .overlay {
                    tileShape
                        .stroke(isSelected ? DawnColor.accent.opacity(0.9) : Color.primary.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
                }
        }
        .buttonStyle(OffsetTileButtonStyle())
        .accessibilityLabel("Custom minutes")
        .modifier(OffsetSelectedAccessibility(isSelected: isSelected))
    }

    private var tileHeight: CGFloat {
        dynamicTypeSize >= .accessibility1 ? 64 : Layout.tileMinHeight
    }

    private var tileShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Layout.tileCornerRadius, style: .continuous)
    }

    private func tileFill(isSelected: Bool) -> Color {
        isSelected ? DawnColor.accent.opacity(0.22) : Color.primary.opacity(0.06)
    }

    private var customStepper: some View {
        HStack(spacing: Layout.gridSpacing) {
            stepButton(systemImage: "minus") {
                guard baseMinutes - step >= range.lowerBound else { return }
                baseMinutes -= step
                Haptics.light()
            }

            Text("\(baseMinutes) min")
                .font(.headline.weight(.semibold).monospacedDigit())
                .frame(minWidth: 92, minHeight: 44)

            stepButton(systemImage: "plus") {
                guard baseMinutes + step <= range.upperBound else { return }
                baseMinutes += step
                Haptics.light()
            }
        }
        .frame(maxWidth: 220)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Custom offset")
        .accessibilityValue("\(baseMinutes) minutes")
    }

    private func stepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(CustomStepButtonStyle())
    }
}

private struct OffsetTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct OffsetSelectedAccessibility: ViewModifier {
    let isSelected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isSelected {
            content
                .accessibilityAddTraits(.isSelected)
                .accessibilityValue("Selected")
        } else {
            content
                .accessibilityValue("Not selected")
        }
    }
}

private struct CustomStepButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? DawnColor.accent : .primary)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(configuration.isPressed ? DawnColor.accent.opacity(0.18) : Color.primary.opacity(0.06))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct OffsetPickerScreen: View {
    let title: String
    @Binding var baseMinutes: Int
    let range: ClosedRange<Int>
    let step: Int

    @Environment(\.dismiss) private var dismiss

    init(title: String, baseMinutes: Binding<Int>, range: ClosedRange<Int> = 5...240, step: Int = 5) {
        self.title = title
        _baseMinutes = baseMinutes
        self.range = range
        self.step = step
    }

    var body: some View {
        Form {
            OffsetPickerView(
                baseMinutes: $baseMinutes,
                presetMinutes: [15, 30, 45, 60, 90],
                range: range,
                step: step,
                sentenceText: sentenceText
            )
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func sentenceText(_ minutes: Int) -> String {
        if title == "Wake offset" {
            return "Wake me \(minutes) min before Fajr."
        }
        return "Earlier by \(minutes) min."
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Offset Tiles - Default") {
    @Previewable @State var minutes: Int = 45
    return OffsetPickerView(
        baseMinutes: $minutes,
        presetMinutes: [30, 45, 60, 75, 90],
        presetLabels: [30: "Quick Suhoor", 45: "Comfortable", 60: "Recommended", 75: "Unhurried", 90: "Relaxed"],
        sentenceText: nil
    )
    .padding()
}

@available(iOS 17.0, *)
#Preview("Offset Tiles - XXL") {
    @Previewable @State var minutes: Int = 60
    return OffsetPickerView(
        baseMinutes: $minutes,
        presetMinutes: [30, 45, 60, 75, 90],
        presetLabels: [30: "Quick Suhoor", 45: "Comfortable", 60: "Recommended", 75: "Unhurried", 90: "Relaxed"],
        sentenceText: nil
    )
    .environment(\.dynamicTypeSize, .xxLarge)
    .padding()
}

@available(iOS 17.0, *)
#Preview("Offset Tiles - Accessibility1") {
    @Previewable @State var minutes: Int = 75
    return OffsetPickerView(
        baseMinutes: $minutes,
        presetMinutes: [30, 45, 60, 75, 90],
        presetLabels: [30: "Quick Suhoor", 45: "Comfortable", 60: "Recommended", 75: "Unhurried", 90: "Relaxed"],
        sentenceText: nil
    )
    .environment(\.dynamicTypeSize, .accessibility1)
    .padding()
}
#endif
