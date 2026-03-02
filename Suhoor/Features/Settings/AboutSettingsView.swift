import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Text(Strings.Settings.version)
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text(Strings.Settings.aboutDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.Settings.aboutSection)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "--"
    }
}
