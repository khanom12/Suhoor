import SwiftUI

struct QuietPeriodSettingsView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore

    var body: some View {
        SettingsScrollPage {
            SettingsInfoBanner(
                title: Strings.QuietPeriod.title,
                message: Strings.QuietPeriod.body,
                systemImage: "moon.circle"
            )

            SettingsGroup(footer: Strings.QuietPeriod.footer) {
                SettingsRow {
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
                }

                AppGroupDivider()

                SettingsRow {
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
                }

                AppGroupDivider()

                SettingsRow {
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
                }
            }
        }
        .navigationTitle(Strings.QuietPeriod.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
