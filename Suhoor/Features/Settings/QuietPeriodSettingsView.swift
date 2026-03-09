import SwiftUI

struct QuietPeriodSettingsView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore

    var body: some View {
        Form {
            Section {
                SettingsInfoBanner(
                    title: Strings.QuietPeriod.title,
                    message: Strings.QuietPeriod.body,
                    systemImage: "moon.circle"
                )
            }

            Section {
                Toggle(
                    Strings.QuietPeriod.masterToggle,
                    isOn: Binding(
                        get: { settingsStore.settings.quietPeriodEnabled },
                        set: { isEnabled in
                            settingsStore.update { settings in
                                settings.quietPeriodEnabled = isEnabled
                                if isEnabled && !settings.pausePrayerPrompts && !settings.pauseFastingPrompts {
                                    settings.pausePrayerPrompts = true
                                    settings.pauseFastingPrompts = true
                                }
                            }
                        }
                    )
                )

                Toggle(
                    Strings.QuietPeriod.prayerToggle,
                    isOn: Binding(
                        get: { settingsStore.settings.pausePrayerPrompts },
                        set: { isEnabled in
                            settingsStore.update { settings in
                                settings.pausePrayerPrompts = isEnabled
                                if isEnabled {
                                    settings.quietPeriodEnabled = true
                                }
                            }
                        }
                    )
                )
                .disabled(!settingsStore.settings.quietPeriodEnabled)

                Toggle(
                    Strings.QuietPeriod.fastingToggle,
                    isOn: Binding(
                        get: { settingsStore.settings.pauseFastingPrompts },
                        set: { isEnabled in
                            settingsStore.update { settings in
                                settings.pauseFastingPrompts = isEnabled
                                if isEnabled {
                                    settings.quietPeriodEnabled = true
                                }
                            }
                        }
                    )
                )
                .disabled(!settingsStore.settings.quietPeriodEnabled)
            } footer: {
                Text(Strings.QuietPeriod.footer)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.QuietPeriod.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
