import SwiftUI

struct PrayerTimeSettingsView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        SettingsScrollPage {
            SettingsGroup(
                title: Strings.Settings.prayerTimeCalculationSection,
                supportingText: Strings.Settings.prayerTimesHelper,
                footer: Strings.Settings.fajrAdjustmentHelper
            ) {
                NavigationLink {
                    CalculationMethodSelectionView()
                } label: {
                    SettingsRow {
                        SettingsNavigationRow {
                            SettingsValueRow(
                                title: Strings.Settings.calculationMethodTitle,
                                value: settingsStore.settings.calculationMethod.displayName
                            )
                        }
                    }
                }

                AppGroupDivider()

                SettingsRow {
                    RelativeOffsetControl(
                        label: Strings.Settings.fajrAdjustment,
                        detail: Strings.Settings.fajrAdjustmentHelper,
                        value: fajrAdjustmentBinding,
                        range: -30...30,
                        step: 1
                    )
                }

                AppGroupDivider()

                SettingsRow {
                    RelativeOffsetControl(
                        label: "Maghrib adjustment",
                        detail: "Adjust sunset/Maghrib earlier or later.",
                        value: maghribAdjustmentBinding,
                        range: -30...30,
                        step: 1
                    )
                }
            }
        }
        .navigationTitle(Strings.Settings.prayerTimesTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var fajrAdjustmentBinding: Binding<Int> {
        Binding(
            get: { settingsStore.settings.fajrAdjustmentMinutes },
            set: { newValue in
                settingsStore.settings.fajrAdjustmentMinutes = newValue
                scheduleManager.requestRefresh(reason: .settingsChanged)
            }
        )
    }

    private var maghribAdjustmentBinding: Binding<Int> {
        Binding(
            get: { settingsStore.settings.maghribAdjustmentMinutes },
            set: { newValue in
                settingsStore.settings.maghribAdjustmentMinutes = newValue
                scheduleManager.requestRefresh(reason: .settingsChanged)
            }
        )
    }
}

struct CalculationMethodSelectionView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        SettingsScrollPage {
            SettingsGroup {
                ForEach(Array(CalculationMethod.allCases.enumerated()), id: \.element.id) { index, method in
                    Button {
                        settingsStore.update { draft in
                            draft.calculationMethod = method
                        }
                        scheduleManager.requestRefresh(reason: .settingsChanged)
                    } label: {
                        SettingsRow {
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
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    if index < CalculationMethod.allCases.count - 1 {
                        AppGroupDivider()
                    }
                }
            }
        }
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
