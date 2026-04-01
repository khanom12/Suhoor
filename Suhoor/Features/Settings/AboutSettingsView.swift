import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        SettingsScrollPage {
            SettingsGroup {
                SettingsRow {
                    SettingsValueRow(title: Strings.Settings.version, value: appVersion)
                }
            }

            SettingsGroup {
                SettingsRow {
                    Text(Strings.Settings.aboutDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .navigationTitle(Strings.Settings.aboutSection)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "--"
    }
}
