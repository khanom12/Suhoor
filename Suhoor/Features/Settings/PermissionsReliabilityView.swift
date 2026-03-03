import SwiftUI
import UIKit

struct PermissionsReliabilityView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        Form {
            Section {
                SettingsInfoBanner(
                    title: modeSummaryTitle,
                    message: modeSummaryMessage,
                    systemImage: modeSystemImage
                )
            }

            Section {
                ForEach(presentations) { presentation in
                    PermissionStatusRow(
                        presentation: presentation,
                        action: presentation.actionTitle == nil ? nil : {
                            Task { await handleAction(for: presentation) }
                        }
                    )
                }
            } header: {
                SettingsSectionHeader(title: Strings.Settings.permissionsSection)
            }

            Section {
                DisclosureGroup(Strings.SettingsReliability.educationTitle) {
                    Text(Strings.SettingsReliability.educationBody)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                NavigationLink(Strings.Settings.alarmReliabilityLearnMore) {
                    AlarmInfoView()
                }
                .font(.footnote.weight(.semibold))
            } header: {
                SettingsSectionHeader(title: Strings.Settings.alarmReliabilityTitle)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.Settings.permissionsReliabilityTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var modeSummaryTitle: String {
        switch scheduleManager.schedulingMode {
        case .alarmKit:
            return Strings.SettingsReliability.alarmKitModeTitle
        case .notifications:
            return Strings.SettingsReliability.notificationsModeTitle
        case .none:
            return Strings.SettingsReliability.blockedModeTitle
        }
    }

    private var modeSummaryMessage: String {
        switch scheduleManager.schedulingMode {
        case .alarmKit:
            return Strings.SettingsReliability.alarmKitModeMessage
        case .notifications:
            return Strings.SettingsReliability.notificationsModeMessage
        case .none:
            return Strings.SettingsReliability.blockedModeMessage
        }
    }

    private var modeSystemImage: String {
        switch scheduleManager.schedulingMode {
        case .alarmKit:
            return "alarm.waves.left.and.right"
        case .notifications:
            return "bell.badge"
        case .none:
            return "exclamationmark.triangle"
        }
    }

    private func handleAction(for presentation: PermissionPresentation) async {
        switch presentation.state {
        case .notDetermined, .needsFollowUp:
            _ = await scheduleManager.requestPermission(presentation.kind)
        case .denied, .restricted:
            openAppSettings()
        case .authorized, .unavailable:
            break
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var presentations: [PermissionPresentation] {
        AppPermissionKind.allCases.compactMap { scheduleManager.permissionSnapshot.presentations[$0] }
    }
}

private struct PermissionStatusRow: View {
    let presentation: PermissionPresentation
    let action: (() -> Void)?

    var body: some View {
        SettingsEditorCard(
            title: presentation.title,
            subtitle: presentation.message,
            trailing: AnyView(
                SettingsStatusBadge(text: presentation.statusText, tone: badgeTone)
            )
        ) {
            if let actionTitle = presentation.actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var badgeTone: SettingsBadgeTone {
        switch presentation.state {
        case .authorized:
            return .success
        case .denied, .restricted:
            return .critical
        case .notDetermined, .needsFollowUp:
            return .warning
        case .unavailable:
            return .neutral
        }
    }
}
