import SwiftUI
import UIKit

struct SettingsRootView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService
    @State private var showingCopiedAlert = false

    var body: some View {
        Form {
            if !issues.isEmpty {
                Section {
                    ForEach(issues) { issue in
                        NavigationLink {
                            destinationView(for: issue.destination)
                        } label: {
                            SettingsSummaryRow(
                                title: issue.title,
                                subtitle: issue.message,
                                systemImage: issue.systemImage,
                                badgeText: issue.statusText,
                                badgeTone: badgeTone(for: issue.tone)
                            )
                        }
                    }
                } header: {
                    SettingsSectionHeader(title: Strings.Settings.needsAttentionSection)
                }
            }

            ForEach(SettingsDestinationGroup.allCases) { group in
                Section {
                    ForEach(group.destinations) { destination in
                        NavigationLink {
                            destinationView(for: destination)
                        } label: {
                            SettingsSummaryRow(
                                title: destination.title,
                                subtitle: summary(for: destination),
                                systemImage: destination.systemImage,
                                badgeText: badgeText(for: destination),
                                badgeTone: badgeTone(for: destination)
                            )
                        }
                    }
                } header: {
                    SettingsSectionHeader(title: group.title)
                }
            }

            Section {
                Button {
                    openFeedbackEmail()
                } label: {
                    SettingsSummaryRow(
                        title: "Send Feedback",
                        subtitle: "Share feedback or report a problem.",
                        systemImage: "envelope",
                        badgeText: nil,
                        badgeTone: .neutral
                    )
                }
                .buttonStyle(.plain)

                Button {
                    UIPasteboard.general.string = diagnosticsText
                    showingCopiedAlert = true
                } label: {
                    SettingsSummaryRow(
                        title: "Copy Diagnostics",
                        subtitle: "Version, device, locale, and permission summary.",
                        systemImage: "doc.on.doc",
                        badgeText: nil,
                        badgeTone: .neutral
                    )
                }
                .buttonStyle(.plain)
            } header: {
                SettingsSectionHeader(title: "Support")
            } footer: {
                Text("Diagnostics leave out precise location unless you add it yourself.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.Settings.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Copied", isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Diagnostics copied to clipboard.")
        }
    }

    private var issues: [SettingsIssue] {
        SettingsSummaryFormatter.issues(
            settings: settingsStore.settings,
            schedulingMode: scheduleManager.schedulingMode,
            presentations: permissionPresentations
        )
    }

    private func summary(for destination: SettingsDestination) -> String {
        switch destination {
        case .location:
            return SettingsSummaryFormatter.locationSummary(settings: settingsStore.settings, locationService: locationService)
        case .prayerTimes:
            return SettingsSummaryFormatter.prayerTimesSummary(settings: settingsStore.settings)
        case .hijriCalendarCorrections:
            return SettingsSummaryFormatter.hijriCorrectionsSummary(scheduleManager: scheduleManager)
        case .permissionsReliability:
            return SettingsSummaryFormatter.permissionsSummary(
                settings: settingsStore.settings,
                schedulingMode: scheduleManager.schedulingMode,
                presentations: permissionPresentations
            )
        case .quietPeriod:
            if !settingsStore.settings.quietPeriodEnabled {
                return Strings.QuietPeriod.summaryOff
            }
            if settingsStore.settings.pausePrayerPrompts && settingsStore.settings.pauseFastingPrompts {
                return Strings.QuietPeriod.summaryOn
            }
            return Strings.QuietPeriod.summaryPartial
        case .about:
            return SettingsSummaryFormatter.aboutSummary(version: appVersion)
        }
    }

    private func badgeText(for destination: SettingsDestination) -> String? {
        switch destination {
        case .prayerTimes, .hijriCalendarCorrections, .about:
            return nil
        case .quietPeriod:
            return settingsStore.settings.quietPeriodEnabled ? "On" : nil
        case .location:
            guard hasLoadedPermissions else { return nil }
            if issues.contains(where: { $0.destination == .location }) {
                return issues.first(where: { $0.destination == .location })?.statusText
            }
            return nil
        case .permissionsReliability:
            guard hasLoadedPermissions else { return nil }
            if issues.contains(where: { $0.destination == .permissionsReliability }) {
                return nil
            }
            if scheduleManager.schedulingMode == .notifications {
                return Strings.Settings.badgeUsingFallback
            }
            return Strings.Settings.badgeReady
        }
    }

    private func badgeTone(for destination: SettingsDestination) -> SettingsBadgeTone {
        switch destination {
        case .permissionsReliability:
            guard hasLoadedPermissions else { return .neutral }
            let permissionIssues = issues.filter { $0.destination == .permissionsReliability }
            if permissionIssues.contains(where: { $0.tone == .critical }) {
                return .critical
            }
            if !permissionIssues.isEmpty {
                return .warning
            }
            return scheduleManager.schedulingMode == .notifications ? .warning : .success
        case .location:
            guard hasLoadedPermissions else { return .neutral }
            if let issue = issues.first(where: { $0.destination == .location }) {
                return badgeTone(for: issue.tone)
            }
            return .neutral
        case .prayerTimes, .hijriCalendarCorrections, .about:
            return .neutral
        case .quietPeriod:
            return settingsStore.settings.quietPeriodEnabled ? .warning : .neutral
        }
    }

    private func badgeTone(for tone: SettingsIssue.Tone) -> SettingsBadgeTone {
        switch tone {
        case .warning:
            return .warning
        case .critical:
            return .critical
        }
    }

    @ViewBuilder
    private func destinationView(for destination: SettingsDestination) -> some View {
        switch destination {
        case .location:
            LocationSettingsView()
        case .prayerTimes:
            PrayerTimeSettingsView()
        case .hijriCalendarCorrections:
            HijriCalendarSettingsView()
        case .permissionsReliability:
            PermissionsReliabilityView()
        case .quietPeriod:
            QuietPeriodSettingsView()
        case .about:
            AboutSettingsView()
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "--"
    }

    private var permissionPresentations: [AppPermissionKind: PermissionPresentation] {
        scheduleManager.permissionSnapshot.presentations
    }

    private var hasLoadedPermissions: Bool {
        SettingsSummaryFormatter.hasLoadedPermissions(permissionPresentations)
    }

    private var diagnosticsText: String {
        let device = UIDevice.current
        let timeZone = TimeZone.current.identifier
        let locale = Locale.current.identifier
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "--"

        return """
        Suhoor Diagnostics
        - Version: \(appVersion) (\(buildNumber))
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
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=?+")

        func encode(_ value: String) -> String {
            value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
        }

        let urlString = "mailto:?subject=\(encode(subject))&body=\(encode(body))"
        return URL(string: urlString)
    }
}
