import SwiftUI
import UIKit

struct ProfileRootView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @State private var showingCopiedAlert = false

    var body: some View {
        List {
            Section {
                NavigationLink {
                    SettingsRootView()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }

            Section {
                Button {
                    openFeedbackEmail()
                } label: {
                    Label("Send Feedback", systemImage: "envelope")
                }

                Button {
                    UIPasteboard.general.string = diagnosticsText
                    showingCopiedAlert = true
                } label: {
                    Label("Copy Diagnostics", systemImage: "doc.on.doc")
                }
            } header: {
                Text("Feedback")
            } footer: {
                Text("Diagnostics do not include precise location or personal data unless you paste it yourself.")
            }

            Section {
                LabeledContent("Version", value: appVersionText)
                LabeledContent("Build", value: buildNumberText)
            } header: {
                Text("About")
            }

            Section {
                Label("Stats (Coming soon)", systemImage: "chart.bar")
                Label("Badges (Coming soon)", systemImage: "seal")
                Label("Export/Import (Coming soon)", systemImage: "square.and.arrow.up")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .alert("Copied", isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Diagnostics copied to clipboard.")
        }
    }

    private var appVersionText: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var buildNumberText: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private var diagnosticsText: String {
        let device = UIDevice.current
        let timeZone = TimeZone.current.identifier
        let locale = Locale.current.identifier
        return """
        Suhoor Diagnostics
        - Version: \(appVersionText) (\(buildNumberText))
        - Device: \(device.model) (\(device.systemName) \(device.systemVersion))
        - Time Zone: \(timeZone)
        - Locale: \(locale)
        - Permissions: \(scheduleManager.permissionSummary)
        """
    }

    private func openFeedbackEmail() {
        let subject = "Suhoor Feedback"
        let body = diagnosticsText + "\n\nWhat happened?\n"
        guard let url = mailtoURL(subject: subject, body: body) else { return }
        UIApplication.shared.open(url)
    }

    private func mailtoURL(subject: String, body: String) -> URL? {
        // `urlQueryAllowed` includes "&" and "=", which would break our query string.
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=?+")

        func encode(_ value: String) -> String {
            value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
        }

        let urlString = "mailto:?subject=\(encode(subject))&body=\(encode(body))"
        return URL(string: urlString)
    }
}
