import SwiftUI

struct OffsetSelectionView: View {
    let title: String
    let stepperLabel: String
    @Binding var minutes: Int
    let presets: [Int]
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        Form {
            Section(Strings.Settings.presetsSection) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        Haptics.light()
                        minutes = preset
                    } label: {
                        HStack {
                            Text(Strings.Settings.offsetOptionMinutes(preset))
                                .foregroundStyle(.primary)
                            Spacer()
                            if minutes == preset {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DawnColor.accent)
                            }
                        }
                    }
                }
            }

            Section(Strings.Settings.customSection) {
                Stepper(value: $minutes, in: range, step: step) {
                    Text("\(stepperLabel): \(minutes) min")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
