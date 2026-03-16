import SwiftUI

struct HijriCalendarSettingsView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        SettingsScrollPage {
            SettingsInfoBanner(
                title: Strings.Settings.hijriCalendarBannerTitle,
                message: Strings.Settings.hijriCalendarBannerBody,
                systemImage: "calendar.badge.clock"
            )

            SettingsGroup(
                title: Strings.Settings.hijriMonthCorrectionsTitle,
                supportingText: Strings.Settings.hijriCalendarHelper
            ) {
                ForEach(Array(rollingMonths.enumerated()), id: \.element.persistenceKey) { index, yearMonth in
                    NavigationLink {
                        HijriMonthAdjustmentDetailView(yearMonth: yearMonth)
                    } label: {
                        SettingsRow {
                            SettingsNavigationRow {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(titleText(for: yearMonth))
                                            .foregroundStyle(.primary)
                                        Text(effectText(for: yearMonth.month))
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Text(adjustmentValueText(for: yearMonth))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    if index < rollingMonths.count - 1 {
                        AppGroupDivider()
                    }
                }
            }
        }
        .navigationTitle(Strings.Settings.hijriCalendarTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var rollingMonths: [HijriYearMonth] {
        scheduleManager.rollingHijriMonths()
    }

    private func titleText(for yearMonth: HijriYearMonth) -> String {
        "\(yearMonth.month.displayName) \(yearMonth.hijriYear)"
    }

    private func adjustmentValueText(for yearMonth: HijriYearMonth) -> String {
        let value = scheduleManager.hijriAdjustment(for: yearMonth.month, hijriYear: yearMonth.hijriYear)
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

    let yearMonth: HijriYearMonth

    var body: some View {
        SettingsScrollPage {
            SettingsGroup(footer: effectText) {
                SettingsRow {
                    Picker(titleText, selection: adjustmentBinding) {
                        Text(Strings.Settings.hijriMinusOneDay).tag(-1)
                        Text(Strings.Settings.hijriNoChange).tag(0)
                        Text(Strings.Settings.hijriPlusOneDay).tag(1)
                    }
                    .pickerStyle(.segmented)
                }
            }

            SettingsGroup(title: Strings.Settings.previewSection) {
                if !scheduleManager.hasHijriBaseline(for: yearMonth.month, hijriYear: yearMonth.hijriYear) {
                    SettingsRow {
                        Text(Strings.Settings.hijriPreviewUnavailable)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if let preview = scheduleManager.hijriMonthStartPreview(for: yearMonth.month, hijriYear: yearMonth.hijriYear) {
                    SettingsRow {
                        previewRow(title: Strings.Settings.hijriBuiltInStart, value: dateText(preview.baselineStart))
                    }
                    AppGroupDivider()
                    SettingsRow {
                        previewRow(title: Strings.Settings.hijriCorrectedStart, value: dateText(preview.adjustedStart))
                    }
                }
            }
        }
        .navigationTitle(titleText)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var adjustmentBinding: Binding<Int> {
        Binding(
            get: { scheduleManager.hijriAdjustment(for: yearMonth.month, hijriYear: yearMonth.hijriYear) },
            set: { newValue in
                Task {
                    await scheduleManager.setHijriMonthAdjustment(for: yearMonth.month, hijriYear: yearMonth.hijriYear, offsetDays: newValue)
                }
            }
        )
    }

    private var titleText: String {
        "\(yearMonth.month.displayName) \(yearMonth.hijriYear)"
    }

    private var effectText: String {
        Strings.SettingsHijri.genericEffect(yearMonth.month.displayName)
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
