import SwiftUI
import UIKit

struct PermissionsReliabilityView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        SettingsScrollPage {
            SettingsInfoBanner(
                title: modeSummaryTitle,
                message: modeSummaryMessage,
                systemImage: modeSystemImage
            )

            SettingsGroup(title: "Reliability summary") {
                reliabilityRow(title: "Wake delivery mode", value: wakeDeliveryModeText)
                AppGroupDivider()
                reliabilityRow(title: "Notification permission", value: notificationPermissionText)
                AppGroupDivider()
                reliabilityRow(title: "Next scheduled wake", value: nextScheduledWakeText)
                AppGroupDivider()
                reliabilityRow(title: "Last schedule update", value: scheduleManager.lastUpdatedText)
                AppGroupDivider()
                reliabilityRow(title: "Delivery check", value: scheduleManager.deliveryReconciliationSummaryText)
            }

            if scheduleManager.schedulingMode == .notifications {
                SettingsInfoBanner(
                    title: "Notification fallback",
                    message: "Notifications may be affected by Focus, Silent Mode, and notification settings.",
                    systemImage: "bell.badge"
                )
            }

            SettingsGroup(title: Strings.Settings.permissionsSection) {
                ForEach(Array(presentations.enumerated()), id: \.element.id) { index, presentation in
                    PermissionStatusRow(
                        presentation: presentation,
                        action: presentation.actionTitle == nil ? nil : {
                            Task { await handleAction(for: presentation) }
                        }
                    )

                    if index < presentations.count - 1 {
                        AppGroupDivider()
                    }
                }
            }

            SettingsGroup(title: Strings.Settings.alarmReliabilityTitle) {
                SettingsRow {
                    DisclosureGroup(Strings.SettingsReliability.educationTitle) {
                        Text(Strings.SettingsReliability.educationBody)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }

                AppGroupDivider()

                NavigationLink {
                    AlarmInfoView()
                } label: {
                    SettingsRow {
                        SettingsNavigationRow {
                            Text(Strings.Settings.alarmReliabilityLearnMore)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .navigationTitle(Strings.Settings.permissionsReliabilityTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var modeSummaryTitle: String {
        switch scheduleManager.schedulingMode {
        case .alarmKit:
            return Strings.SettingsReliability.alarmKitModeTitle
        case .mixed:
            return "Mixed delivery"
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
        case .mixed:
            return "Wake alarms use AlarmKit where available. Secondary cues use notifications."
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
        case .mixed:
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

    private var wakeDeliveryModeText: String {
        switch scheduleManager.schedulingMode {
        case .alarmKit:
            return "AlarmKit"
        case .mixed:
            return "Mixed"
        case .notifications:
            return "Notification fallback"
        case .none:
            return "Not ready"
        }
    }

    private var notificationPermissionText: String {
        scheduleManager.permissionSnapshot.presentations[.notifications]?.statusText ?? "Checking"
    }

    private var nextScheduledWakeText: String {
        guard let wakeDate = scheduleManager.nextUpcomingSchedule?.wakeDate else {
            return "--"
        }
        return TimeFormatters.shortDateTime.string(from: wakeDate)
    }

    @ViewBuilder
    private func reliabilityRow(title: String, value: String) -> some View {
        SettingsRow {
            SettingsValueRow(title: title, value: value)
        }
    }
}

private struct PermissionStatusRow: View {
    let presentation: PermissionPresentation
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            SettingsRow {
                HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(presentation.title)
                            .font(.body.weight(.semibold))
                        Text(presentation.message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: DesignTokens.spacingM)

                    SettingsStatusBadge(text: presentation.statusText, tone: badgeTone)
                }
            }

            if let actionTitle = presentation.actionTitle, let action {
                SettingsRow(verticalPadding: 0) {
                    Button(actionTitle, action: action)
                        .appControlStyle(.primary)
                }
                .padding(.bottom, DesignTokens.spacingM)
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
