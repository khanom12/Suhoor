import SwiftUI
import CoreLocation
import UIKit

struct AdvancedSettingsView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Text(locationStatusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Manage in Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                Section("Calculation") {
                    Picker("Method", selection: $settingsStore.settings.calculationMethod) {
                        ForEach(CalculationMethod.allCases) { method in
                            Text(method.displayName).tag(method)
                        }
                    }

                    Stepper(value: $settingsStore.settings.fajrAdjustmentMinutes, in: -30...30, step: 1) {
                        Text("Fajr adjustment: \(settingsStore.settings.fajrAdjustmentMinutes) min")
                    }

                    Text("If your local schedule differs slightly, adjust here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Diagnostics") {
                    Text("Last updated: \(lastUpdatedText)")
                    Text("Scheduling: \(schedulingText)")
                    Text(scheduleManager.permissionSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Reset") {
                    Button(role: .destructive) {
                        Task { await scheduleManager.resetAll() }
                    } label: {
                        Text("Reset setup")
                    }
                }
            }
            .navigationTitle("Advanced")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await scheduleManager.refreshPermissionSummary()
        }
    }

    private var lastUpdatedText: String {
        guard let date = scheduleManager.lastUpdated else { return "--" }
        return TimeFormatters.shortDateTime.string(from: date)
    }

    private var schedulingText: String {
        switch scheduleManager.schedulingMode {
        case .alarmKit: return "AlarmKit"
        case .notifications: return "Notifications"
        case .none: return "Off"
        }
    }

    private var locationStatusText: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Location access is allowed."
        case .denied:
            return "Location access is denied."
        case .restricted:
            return "Location access is restricted."
        case .notDetermined:
            return "Location access not determined yet."
        @unknown default:
            return "Location access status unknown."
        }
    }
}
