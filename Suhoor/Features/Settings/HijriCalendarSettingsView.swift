import SwiftUI

struct HijriCalendarSettingsView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        Form {
            Section {
                Text("These corrections affect Hijri dates shown in the app, date-based tags, and any Islamic-date schedules you add.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Local Hijri Calendar Correction") {
                Text("Use this if your community starts a Hijri month one day earlier or later than the app’s built-in calendar. This changes Hijri dates shown in the app and any related schedules.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                hijriMonthAdjustmentRow(.muharram)
                hijriMonthAdjustmentRow(.ramadan)
                hijriMonthAdjustmentRow(.shawwal)
                hijriMonthAdjustmentRow(.dhulHijjah)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Hijri Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func hijriMonthAdjustmentRow(_ month: HijriMonth) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(month.displayName)
                    .font(.body.weight(.medium))
                Text(effectText(for: month))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

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
            } else if let preview = scheduleManager.hijriMonthStartPreview(for: month) {
                Text("Built-in start: \(dateText(preview.baselineStart))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Your corrected start: \(dateText(preview.adjustedStart))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func effectText(for month: HijriMonth) -> String {
        switch month {
        case .muharram:
            return "Affects Ashura and Muharram dates."
        case .ramadan:
            return "Affects Ramadan dates and reminders."
        case .shawwal:
            return "Affects Eid al-Fitr and Shawwal dates."
        case .dhulHijjah:
            return "Affects Arafah, Eid al-Adha, and Dhul Hijjah dates."
        default:
            return ""
        }
    }

    private func dateText(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
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
