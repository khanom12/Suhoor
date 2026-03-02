import SwiftUI
import UIKit
import CoreLocation

struct OnboardingView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @State private var step: Step = .welcome
    @State private var hasInitializedStep = false
    @State private var showHowItWorks = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 0)
                stepView
                Spacer(minLength: 0)
            }
            .padding(24)
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showHowItWorks) {
                HowItWorksView()
            }
            .task {
                initializeStepIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case .welcome:
            WelcomeStep(
                onGetStarted: { step = .permissions },
                onHowItWorks: { showHowItWorks = true }
            )
        case .permissions:
            PermissionsChecklistStep(
                refreshKey: permissionsRefreshKey,
                hasVisibleSchedule: !scheduleManager.activeWindowSnapshot.visibleDays.isEmpty,
                onOpenSettings: openAppSettings,
                onContinue: { step = .offset }
            )
            .environmentObject(scheduleManager)
        case .offset:
            OffsetStep(
                baseMinutes: $settingsStore.settings.baseWakeOffsetMinutes,
                onEnable: {
                    Task {
                        let enabled = await scheduleManager.enableFromUserAction(markConfigured: false)
                        guard enabled else { return }
                        withAnimation(.easeInOut) {
                            step = .confirmation
                        }
                    }
                }
            )
        case .confirmation:
            ConfirmationStep(
                nextAlarmText: nextAlarmText,
                onDone: {
                    settingsStore.update { draft in
                        draft.isConfigured = true
                    }
                }
            )
        }
    }

    private var nextAlarmText: String {
        guard let schedule = scheduleManager.schedules.first else {
            return "Next alarm: --"
        }
        let weekday = TimeFormatters.dayFormatter.string(from: schedule.wakeDate)
        let time = TimeFormatters.timeFormatter.string(from: schedule.wakeDate)
        return "Next alarm: \(weekday) \(time)"
    }

    private var permissionsRefreshKey: String {
        "\(locationService.authorizationStatus.rawValue)-\(locationService.lastLocation != nil)-\(scheduleManager.alarmAuthorizationText)-\(scheduleManager.notificationAuthorizationText)"
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func initializeStepIfNeeded() {
        guard !hasInitializedStep else { return }
        step = settingsStore.settings.isConfigured ? .permissions : .welcome
        hasInitializedStep = true
    }
}

private enum Step {
    case welcome
    case permissions
    case offset
    case confirmation
}

private struct WelcomeStep: View {
    let onGetStarted: () -> Void
    let onHowItWorks: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wake up before Fajr")
                .font(.largeTitle.weight(.bold))
            Text("Set it once. We’ll update your alarm daily.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Get started", action: onGetStarted)
                .buttonStyle(.borderedProminent)

            Button("How it works", action: onHowItWorks)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PermissionsChecklistStep: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    let refreshKey: String
    let hasVisibleSchedule: Bool
    let onOpenSettings: () -> Void
    let onContinue: () -> Void

    @State private var presentations: [PermissionPresentation] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set up permissions")
                .font(.title2.weight(.bold))

            Text("Suhoor requires location, alarms, and notifications before it can prepare your alarm schedule.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if isLoading && presentations.isEmpty {
                ProgressView()
            } else {
                ForEach(presentations) { presentation in
                    PermissionCardView(
                        presentation: presentation,
                        action: presentation.actionTitle == nil ? nil : {
                            Task { await handleAction(for: presentation) }
                        }
                    )
                }
            }

            Button("Continue", action: onContinue)
                .buttonStyle(.borderedProminent)
                .disabled(hasBlockingPermissions || !hasVisibleSchedule)

            if !hasBlockingPermissions && !hasVisibleSchedule {
                Text("Preparing your first alarm schedule…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await refresh()
        }
        .task(id: refreshKey) {
            await refresh()
        }
    }

    private var hasBlockingPermissions: Bool {
        presentations.contains(where: \.isBlocking)
    }

    private func handleAction(for presentation: PermissionPresentation) async {
        switch presentation.state {
        case .notDetermined, .needsFollowUp:
            _ = await scheduleManager.requestPermission(presentation.kind)
        case .denied, .restricted:
            onOpenSettings()
        case .authorized, .unavailable:
            break
        }
        await refresh()
    }

    private func refresh() async {
        isLoading = true
        let kinds = await scheduleManager.requiredOnboardingPermissions()
        var updated: [PermissionPresentation] = []
        for kind in kinds {
            updated.append(await scheduleManager.permissionPresentation(for: kind))
        }
        presentations = updated
        await scheduleManager.refreshPermissionSummary()
        isLoading = false
    }
}

private struct OffsetStep: View {
    @Binding var baseMinutes: Int
    let onEnable: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How early?")
                .font(.title2.weight(.bold))

            OffsetPickerView(baseMinutes: $baseMinutes)

            Text("Wake me \(baseMinutes) min before Fajr.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Continue", action: onEnable)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct ConfirmationStep: View {
    let nextAlarmText: String
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("All set", systemImage: "checkmark.circle.fill")
                .font(.title2.weight(.bold))

            Text(nextAlarmText)
                .font(.body)

            Text("We’ll keep this updated every day.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct HowItWorksView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How it works")
                        .font(.title2.weight(.bold))
                    Text("Suhoor calculates Fajr time for your location and updates your wake alarm every day.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .navigationTitle("How it works")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
