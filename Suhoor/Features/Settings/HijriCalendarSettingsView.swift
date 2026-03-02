import SwiftUI

struct HijriCalendarSettingsView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private let adjustableMonths: [HijriMonth] = HijriMonth.allCases

    var body: some View {
        Form {
            Section {
                Text(Strings.Settings.hijriCalendarHelper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                ForEach(adjustableMonths, id: \.self) { month in
                    NavigationLink {
                        HijriMonthAdjustmentDetailView(month: month)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(month.displayName)
                                    .foregroundStyle(.primary)
                                Text(effectText(for: month))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Text(adjustmentValueText(for: month))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text(Strings.Settings.hijriMonthCorrectionsTitle)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.Settings.hijriCalendarTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func adjustmentValueText(for month: HijriMonth) -> String {
        let value = scheduleManager.hijriAdjustment(for: month)
        switch value {
        case -1:
            return Strings.Settings.hijriMinusOneDay
        case 1:
            return Strings.Settings.hijriPlusOneDay
        default:
            return Strings.Settings.hijriNoChange
        }
    }

    private func effectText(for month: HijriMonth) -> String {
        Strings.SettingsHijri.genericEffect(month.displayName)
    }
}

private struct HijriMonthAdjustmentDetailView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    let month: HijriMonth

    var body: some View {
        Form {
            Section {
                Picker(month.displayName, selection: adjustmentBinding) {
                    Text(Strings.Settings.hijriMinusOneDay).tag(-1)
                    Text(Strings.Settings.hijriNoChange).tag(0)
                    Text(Strings.Settings.hijriPlusOneDay).tag(1)
                }
                .pickerStyle(.segmented)
            } footer: {
                Text(effectText)
            }

            Section {
                if !scheduleManager.hasHijriBaseline(for: month) {
                    Text(Strings.Settings.hijriPreviewUnavailable)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if let preview = scheduleManager.hijriMonthStartPreview(for: month) {
                    previewRow(title: Strings.Settings.hijriBuiltInStart, value: dateText(preview.baselineStart))
                    previewRow(title: Strings.Settings.hijriCorrectedStart, value: dateText(preview.adjustedStart))
                }
            } header: {
                Text(Strings.Settings.previewSection)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(month.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var adjustmentBinding: Binding<Int> {
        Binding(
            get: { scheduleManager.hijriAdjustment(for: month) },
            set: { newValue in
                Task {
                    await scheduleManager.setHijriMonthAdjustment(for: month, offsetDays: newValue)
                }
            }
        )
    }

    private var effectText: String {
        Strings.SettingsHijri.genericEffect(month.displayName)
    }

    private func previewRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func dateText(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }
}
