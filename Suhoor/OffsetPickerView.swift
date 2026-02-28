import SwiftUI

struct OffsetPickerView: View {
    @Binding var baseMinutes: Int
    let presetMinutes: [Int]
    let range: ClosedRange<Int>
    let step: Int
    let sentenceText: (Int) -> String

    @State private var isCustomSelected: Bool = false

    init(
        baseMinutes: Binding<Int>,
        presetMinutes: [Int] = [15, 30, 45, 60, 90],
        range: ClosedRange<Int> = 5...240,
        step: Int = 5,
        sentenceText: @escaping (Int) -> String = { "Wake me \($0) min before Fajr." }
    ) {
        _baseMinutes = baseMinutes
        self.presetMinutes = presetMinutes
        self.range = range
        self.step = step
        self.sentenceText = sentenceText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            FlowLayout(spacing: 8) {
                ForEach(presetMinutes, id: \.self) { minutes in
                    Button {
                        Haptics.light()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isCustomSelected = false
                            baseMinutes = minutes
                        }
                    } label: {
                        Text("\(minutes)")
                            .pillChipStyle(isSelected: !isCustomSelected && baseMinutes == minutes)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(minutes) minutes")
                }

                Button {
                    Haptics.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCustomSelected = true
                    }
                } label: {
                    Text("Custom")
                        .pillChipStyle(isSelected: isCustomSelected || !presetMinutes.contains(baseMinutes))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Custom minutes")
            }

            Text(sentenceText(baseMinutes))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

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
