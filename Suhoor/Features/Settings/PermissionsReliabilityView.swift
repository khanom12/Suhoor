import SwiftUI
import UIKit
import CoreLocation

struct PermissionsReliabilityView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        Form {
            Section {
                Text(modeSummaryTitle)
                    .font(.body.weight(.semibold))
                Text(modeSummaryMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
                Text(Strings.Settings.permissionsSection)
            }

            Section {
                NavigationLink {
                    AlarmInfoView()
                } label: {
                    SettingsSummaryRow(
                        title: Strings.Settings.alarmReliabilityTitle,
                        subtitle: Strings.Settings.alarmReliabilitySummary,
                        systemImage: "alarm.waves.left.and.right"
                    )
                }
            } header: {
                Text(Strings.Settings.alarmReliabilityTitle)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(presentation.title)
                    .font(.body.weight(.semibold))
                Spacer()
                SettingsStatusBadge(text: presentation.statusText, tone: badgeTone)
            }

            Text(presentation.message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle = presentation.actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 4)
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
