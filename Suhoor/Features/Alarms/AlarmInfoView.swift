import SwiftUI

struct AlarmInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                SettingsInfoBanner(
                    title: Strings.AboutAlarms.title,
                    message: Strings.SettingsReliability.educationBody,
                    systemImage: "alarm.waves.left.and.right"
                )
            }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("• \(Strings.AboutAlarms.bullet1)")
                    Text("• \(Strings.AboutAlarms.bullet2)")
                    Text("• \(Strings.AboutAlarms.bullet3)")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(Strings.AboutAlarms.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
