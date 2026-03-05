import SwiftUI

struct OffsetPickerView: View {
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
            if dynamicTypeSize.isAccessibilitySize {
                let columns = [GridItem(.flexible(minimum: 120)), GridItem(.flexible(minimum: 120))]
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(presetMinutes, id: \.self) { minutes in
                        presetButton(minutes: minutes)
                    }
                    customButton
                }
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(presetMinutes, id: \.self) { minutes in
                        presetButton(minutes: minutes)
                    }
                    customButton
                }
            }

            if let sentenceText {
                Text(sentenceText(baseMinutes))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isCustomSelected || !presetMinutes.contains(baseMinutes) {
                Stepper(value: $baseMinutes, in: range, step: step) {
                    Text("Custom: \(baseMinutes) min")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .onChange(of: baseMinutes) { _, _ in
                    Haptics.light()
                }
                .accessibilityLabel("Custom offset \(baseMinutes) minutes")
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
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? DawnColor.accent.opacity(0.14) : Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? DawnColor.accent : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
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
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(isSelected ? DawnColor.accent.opacity(0.14) : Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? DawnColor.accent : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
                }
        }
        .buttonStyle(OffsetTileButtonStyle())
        .accessibilityLabel("Custom minutes")
        .modifier(OffsetSelectedAccessibility(isSelected: isSelected))
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
