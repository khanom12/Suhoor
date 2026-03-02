import SwiftUI
import CoreLocation
import UIKit

struct AdvancedSettingsView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @Environment(\.dismiss) private var dismiss
    // Ruleset is strict-only; no user selection.

    var body: some View {
        Form {
            Section("Location") {
                PermissionStackView(
                    kinds: [.location, .alarmKit, .notifications],
                    refreshKey: permissionRefreshKey,
                    showOnlyBlocking: false,
                    onOpenSettings: openAppSettings
                )
                .environmentObject(scheduleManager)
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

            Section("Hijri Month Adjustments") {
                Text("Use this if your community starts a Hijri month one day earlier or later than the app’s built-in calendar. This changes Hijri dates shown in the app and any related schedules.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                hijriMonthAdjustmentRow(.muharram)
                hijriMonthAdjustmentRow(.ramadan)
                hijriMonthAdjustmentRow(.shawwal)
                hijriMonthAdjustmentRow(.dhulHijjah)
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
        .formStyle(.grouped)
        .navigationTitle("Advanced")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
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

    private var permissionRefreshKey: String {
        "\(locationService.authorizationStatus.rawValue)-\(locationService.lastLocation != nil)-\(scheduleManager.alarmAuthorizationText)-\(scheduleManager.notificationAuthorizationText)"
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    @ViewBuilder
    private func hijriMonthAdjustmentRow(_ month: HijriMonth) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(month.displayName, selection: hijriAdjustmentBinding(for: month)) {
                Text("-1").tag(-1)
                Text("0").tag(0)
                Text("+1").tag(1)
            }
            .pickerStyle(.segmented)

            if !scheduleManager.hasHijriBaseline(for: month) {
                Text("Needs calendar data for this month")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if let preview = scheduleManager.hijriMonthStartPreview(for: month) {
                Text("Built-in start: \(DateFormatter.localizedString(from: preview.baselineStart, dateStyle: .medium, timeStyle: .none))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Your corrected start: \(DateFormatter.localizedString(from: preview.adjustedStart, dateStyle: .medium, timeStyle: .none))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func hijriAdjustmentBinding(for month: HijriMonth) -> Binding<Int> {
        Binding(
            get: { scheduleManager.hijriAdjustment(for: month) },
            set: { newValue in
                Task {
                    await scheduleManager.setHijriMonthAdjustment(for: month, offsetDays: newValue)
                }
            }
        )
    }
}
