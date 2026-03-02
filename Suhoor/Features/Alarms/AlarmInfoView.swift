import SwiftUI
import UIKit
import CoreLocation

struct AlarmInfoView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService
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
                PermissionStackView(
                    kinds: [.alarmKit, .notifications],
                    refreshKey: permissionRefreshKey,
                    showOnlyBlocking: false,
                    onOpenSettings: openAppSettings
                )
                .environmentObject(scheduleManager)
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

    private var permissionRefreshKey: String {
        "\(locationService.authorizationStatus.rawValue)-\(locationService.lastLocation != nil)-\(scheduleManager.alarmAuthorizationText)-\(scheduleManager.notificationAuthorizationText)"
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
