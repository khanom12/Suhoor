import SwiftUI

struct PrayerTimeSettingsView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    CalculationMethodSelectionView()
                } label: {
                    valueRow(
                        title: Strings.Settings.calculationMethodTitle,
                        value: settingsStore.settings.calculationMethod.displayName
                    )
                }

                Stepper(value: $settingsStore.settings.fajrAdjustmentMinutes, in: -30...30, step: 1) {
                    valueRow(
                        title: Strings.Settings.fajrAdjustment,
                        value: SettingsSummaryFormatter.adjustmentText(settingsStore.settings.fajrAdjustmentMinutes)
                    )
                }
                .onChange(of: settingsStore.settings.fajrAdjustmentMinutes) { _, _ in
                    scheduleManager.requestRefresh(reason: .settingsChanged)
                }
            } header: {
                Text(Strings.Settings.prayerTimeCalculationSection)
            } footer: {
                Text(Strings.Settings.fajrAdjustmentHelper)
            }

            Section {
                NavigationLink {
                    HijriCalendarSettingsView()
                } label: {
                    valueRow(
                        title: Strings.Settings.hijriMonthCorrectionsTitle,
                        value: hijriSummary
                    )
                }
            } header: {
                Text(Strings.Settings.hijriCalendarTitle)
            } footer: {
                Text(Strings.Settings.hijriCalendarHelper)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.Settings.prayerTimesTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func valueRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private var hijriSummary: String {
        let months: [HijriMonth] = [.muharram, .ramadan, .shawwal, .dhulHijjah]
        let changed = months.filter { scheduleManager.hijriAdjustment(for: $0) != 0 }.count
        if changed == 0 {
            return Strings.Settings.hijriNoChanges
        }
        return Strings.Settings.hijriAdjustedMonths(changed)
    }
}

private struct CalculationMethodSelectionView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        List {
            ForEach(CalculationMethod.allCases) { method in
                Button {
                    settingsStore.update { draft in
                        draft.calculationMethod = method
                    }
                    scheduleManager.requestRefresh(reason: .settingsChanged)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(method.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if settingsStore.settings.calculationMethod == method {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DawnColor.accent)
                            }
                        }

                        Text(method.settingsDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Strings.Settings.calculationMethodTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension CalculationMethod {
    var settingsDescription: String {
        switch self {
        case .muslimWorldLeague:
            return Strings.SettingsCalculation.muslimWorldLeague
        case .egyptian:
            return Strings.SettingsCalculation.egyptian
        case .karachi:
            return Strings.SettingsCalculation.karachi
        case .northAmerica:
            return Strings.SettingsCalculation.northAmerica
        case .makkah:
            return Strings.SettingsCalculation.makkah
        }
    }
}
