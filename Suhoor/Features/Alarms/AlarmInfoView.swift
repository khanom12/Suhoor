import SwiftUI
import UIKit

struct AlarmInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• \(Strings.AboutAlarms.bullet1)")
                    Text("• \(Strings.AboutAlarms.bullet2)")
                    Text("• \(Strings.AboutAlarms.bullet3)")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section {
                Button(Strings.AboutAlarms.openSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
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
