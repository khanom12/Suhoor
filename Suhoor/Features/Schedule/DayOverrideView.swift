import SwiftUI

struct DayOverrideSheet: View {
    @Binding var settings: AppSettings
    let day: DaySchedule

    @Environment(\.dismiss) private var dismiss

    @State private var overrideMinutes: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dayTitle)
                            .font(.headline)
                        Text(TimeFormatters.shortDate.string(from: day.date))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Applied") {
                    Text("Default: \(settings.baseWakeOffsetMinutes) min")
                    if overrideMinutes != nil {
                        Text("Applied: Custom override")
                    }
                    Text("Final: \(finalOffsetMinutes) min")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Use default") {
                        overrideMinutes = nil
                        saveOverride()
                        dismiss()
                    }
                }

                Section {
                    NavigationLink("Set wake offset for this day") {
                        DayOverrideOffsetView(overrideMinutes: $overrideMinutes, baseMinutes: settings.baseWakeOffsetMinutes) {
                            saveOverride()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Override")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                let key = DateHelpers.dayIdentifier(for: day.date, timeZone: .current)
                overrideMinutes = settings.perDayExceptions[key]?.wakeOffsetOverrideMinutes
            }
        }
        .presentationDetents([.medium])
    }

    private var ruleEngine: RuleEngine {
        RuleEngine(settings: settings, timeZone: .current)
    }

    private var dayTitle: String {
        TimeFormatters.dayFormatter.string(from: day.date)
    }

    private var finalOffsetMinutes: Int {
        if let overrideMinutes {
            return overrideMinutes
        }
        return ruleEngine.effectiveWakeOffsetMinutes(for: day.date)
    }

    private func saveOverride() {
        let key = DateHelpers.dayIdentifier(for: day.date, timeZone: .current)
        if let overrideMinutes {
            settings.perDayExceptions[key] = DayException(
                disabledForDay: false,
                wakeOffsetOverrideMinutes: overrideMinutes,
                reminderEnabledOverride: nil,
                atFajrEnabledOverride: nil,
                reminderMinutesOverride: nil,
                atFajrSoundOverride: nil,
                iftarEnabledOverride: nil
            )
        } else {
            settings.perDayExceptions.removeValue(forKey: key)
        }
    }
}

private struct DayOverrideOffsetView: View {
    @Binding var overrideMinutes: Int?
    let baseMinutes: Int
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var workingMinutes: Int

    init(overrideMinutes: Binding<Int?>, baseMinutes: Int, onDone: @escaping () -> Void) {
        _overrideMinutes = overrideMinutes
        self.baseMinutes = baseMinutes
        self.onDone = onDone
        _workingMinutes = State(initialValue: overrideMinutes.wrappedValue ?? baseMinutes)
    }

    var body: some View {
        Form {
            OffsetPickerView(baseMinutes: $workingMinutes)
        }
        .navigationTitle("Wake offset")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    overrideMinutes = workingMinutes
                    onDone()
                    dismiss()
                }
            }
        }
    }
}
