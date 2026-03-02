import SwiftUI

struct HijriCalendarSettingsView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        Form {
            Section {
                Text("Adjust Hijri month starts if your local mosque begins a month one day earlier or later. Nothing changes unless you enable these reminders or set an offset.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Hijri Special-Day Alarms") {
                Toggle("Hijri special-day alarms", isOn: hijriSpecialDaysEnabledBinding)

                if settingsStore.settings.hijriSpecialDaySettings.isEnabled {
                    Toggle("Ramadan daily alarms", isOn: ramadanDailyEnabledBinding)
                    Toggle("White days", isOn: whiteDaysEnabledBinding)
                    Toggle("Ashura", isOn: ashuraEnabledBinding)
                    Toggle("Arafah", isOn: arafahEnabledBinding)
                    Toggle("Eid al-Fitr", isOn: eidAlFitrEnabledBinding)
                    Toggle("Eid al-Adha", isOn: eidAlAdhaEnabledBinding)
                }

                Text("These dates use your existing alarm timing rules.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Hijri Month Adjustments") {
                Text("If your local mosque starts this Hijri month one day earlier or later than shown, adjust it here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                hijriMonthAdjustmentRow(.muharram)
                hijriMonthAdjustmentRow(.ramadan)
                hijriMonthAdjustmentRow(.shawwal)
                hijriMonthAdjustmentRow(.dhulHijjah)

                if !settingsStore.settings.hijriSpecialDaySettings.isEnabled {
                    Text("Adjustments are saved now and will apply when Hijri special-day alarms are enabled.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Hijri Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func hijriMonthAdjustmentRow(_ month: HijriMonth) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(month.displayName, selection: hijriAdjustmentBinding(for: month)) {
                Text("-1").tag(-1)
                Text("0").tag(0)
                Text("+1").tag(1)
            }
            .pickerStyle(.segmented)

            if !scheduleManager.hasHijriBaseline(for: month) {
                Text("Needs calendar data for this month")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var hijriSpecialDaysEnabledBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.hijriSpecialDaySettings.isEnabled },
            set: { newValue in
                Task {
                    await scheduleManager.updateHijriSpecialDaySettings { $0.isEnabled = newValue }
                }
            }
        )
    }

    private var ramadanDailyEnabledBinding: Binding<Bool> {
        hijriSpecialDayBinding(\.ramadanDailyEnabled)
    }

    private var whiteDaysEnabledBinding: Binding<Bool> {
        hijriSpecialDayBinding(\.whiteDaysEnabled)
    }

    private var ashuraEnabledBinding: Binding<Bool> {
        hijriSpecialDayBinding(\.ashuraEnabled)
    }

    private var arafahEnabledBinding: Binding<Bool> {
        hijriSpecialDayBinding(\.arafahEnabled)
    }

    private var eidAlFitrEnabledBinding: Binding<Bool> {
        hijriSpecialDayBinding(\.eidAlFitrEnabled)
    }

    private var eidAlAdhaEnabledBinding: Binding<Bool> {
        hijriSpecialDayBinding(\.eidAlAdhaEnabled)
    }

    private func hijriSpecialDayBinding(_ keyPath: WritableKeyPath<HijriSpecialDaySettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settingsStore.settings.hijriSpecialDaySettings[keyPath: keyPath] },
            set: { newValue in
                Task {
                    await scheduleManager.updateHijriSpecialDaySettings { $0[keyPath: keyPath] = newValue }
                }
            }
        )
    }

    private func hijriAdjustmentBinding(for month: HijriMonth) -> Binding<Int> {
        Binding(
            get: { scheduleManager.hijriAdjustment(for: month) },
            set: { newValue in
                Task {
                    await scheduleManager.setHijriMonthAdjustment(for: month, offsetDays: newValue)
                }
            }
        )
    }
}
