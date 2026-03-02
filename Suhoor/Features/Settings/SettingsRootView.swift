import SwiftUI
import CoreLocation

struct SettingsRootView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    var body: some View {
        Form {
            if !issues.isEmpty {
                Section(Strings.Settings.needsAttentionSection) {
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
                }
            }

            Section {
                ForEach(SettingsDestination.allCases) { destination in
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
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.Settings.title)
        .navigationBarTitleDisplayMode(.large)
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
        case .defaultAlarms:
            return SettingsSummaryFormatter.defaultAlarmsSummary(config: alarmConfigStore.defaults)
        case .location:
            return SettingsSummaryFormatter.locationSummary(settings: settingsStore.settings, locationService: locationService)
        case .prayerTimes:
            return SettingsSummaryFormatter.prayerTimesSummary(settings: settingsStore.settings)
        case .permissionsReliability:
            return SettingsSummaryFormatter.permissionsSummary(
                settings: settingsStore.settings,
                schedulingMode: scheduleManager.schedulingMode,
                presentations: permissionPresentations
            )
        case .about:
            return SettingsSummaryFormatter.aboutSummary(version: appVersion)
        }
    }

    private func badgeText(for destination: SettingsDestination) -> String? {
        switch destination {
        case .defaultAlarms, .prayerTimes, .about:
            return nil
        case .location:
            guard hasLoadedPermissions else { return nil }
            if issues.contains(where: { $0.destination == .location }) {
                return issues.first(where: { $0.destination == .location })?.statusText
            }
            return nil
        case .permissionsReliability:
            guard hasLoadedPermissions else { return nil }
            if issues.contains(where: { $0.destination == .permissionsReliability }) {
                return issues.first(where: { $0.destination == .permissionsReliability })?.statusText
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
        case .defaultAlarms, .prayerTimes, .about:
            return .neutral
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
        case .defaultAlarms:
            DefaultAlarmsSettingsView()
        case .location:
            LocationSettingsView()
        case .prayerTimes:
            PrayerTimeSettingsView()
        case .permissionsReliability:
            PermissionsReliabilityView()
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
}
