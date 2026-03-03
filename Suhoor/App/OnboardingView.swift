import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showHowItWorks = false
    @State private var showLocationSearch = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                OnboardingProgressView(
                    stepIndex: viewModel.progressIndex,
                    stepCount: viewModel.progressCount
                )
                .padding(.top, 4)
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
            .sheet(isPresented: $showLocationSearch) {
                NavigationStack {
                    LocationSearchView(
                        selectedName: viewModel.locationName,
                        onSelectCity: viewModel.chooseCity,
                        onSelectMapItem: viewModel.chooseMapItem
                    )
                }
            }
            .task {
                viewModel.bind(
                    scheduleManager: scheduleManager,
                    locationService: locationService,
                    settingsStore: settingsStore
                )
                await viewModel.load()
            }
            .onChange(of: scheduleManager.permissionSnapshot) { _, _ in
                viewModel.updateFromSnapshot()
            }
            .onChange(of: scheduleManager.activeWindowSnapshot) { _, _ in
                viewModel.updateScheduleReadiness()
            }
            .onChange(of: settingsStore.settings.locationMode) { _, _ in
                viewModel.syncSettings()
            }
            .onChange(of: settingsStore.settings.fixedLocation) { _, _ in
                viewModel.syncSettings()
            }
            .onChange(of: locationService.locationName) { _, _ in
                viewModel.syncSettings()
            }
        }
    }

    @ViewBuilder
    private var stepView: some View {
        Group {
            switch viewModel.step {
            case .welcome:
                WelcomeStep(
                    onGetStarted: { viewModel.goTo(.location, animation: Motion.standard(reduceMotion: reduceMotion)) },
                    onHowItWorks: { showHowItWorks = true }
                )
            case .location:
                LocationStep(
                    locationMode: viewModel.locationMode,
                    locationState: viewModel.locationState,
                    locationName: viewModel.locationName,
                    hasFixedLocation: viewModel.hasFixedLocation,
                    isWorking: viewModel.isWorking,
                    onRequestLocation: viewModel.requestLocation,
                    onOpenSettings: viewModel.openSettings,
                    onChooseCity: { showLocationSearch = true },
                    onContinue: { viewModel.advance(animation: Motion.standard(reduceMotion: reduceMotion)) }
                )
            case .alarmKit:
                AlarmKitStep(
                    alarmState: viewModel.alarmKitState,
                    isRequestable: viewModel.alarmKitRequestable,
                    shouldShowFallback: viewModel.shouldShowAlarmKitFallback,
                    onRequestAlarmKit: viewModel.requestAlarmKit,
                    onOpenSettings: viewModel.openSettings,
                    onContinue: { viewModel.advance(animation: Motion.standard(reduceMotion: reduceMotion)) }
                )
        case .notifications:
            NotificationsStep(
                notificationState: viewModel.notificationState,
                showAlarmKitFallback: viewModel.shouldShowAlarmKitFallback,
                onRequestNotifications: viewModel.requestNotifications,
                onOpenSettings: viewModel.openSettings,
                onContinue: {
                    guard !viewModel.isConfigured else { return }
                    viewModel.advance(animation: Motion.standard(reduceMotion: reduceMotion))
                    }
                )
            case .offset:
                OffsetStep(
                    baseMinutes: $settingsStore.settings.baseWakeOffsetMinutes,
                    failureMessage: viewModel.lastEnableFailureMessage,
                    onEnable: { viewModel.enableRoutineAndContinue(animation: Motion.standard(reduceMotion: reduceMotion)) }
                )
            case .confirmation:
                ConfirmationStep(
                    nextAlarmText: nextAlarmText,
                    onDone: viewModel.markOnboardingComplete
                )
            }
        }
        .id(viewModel.step)
        .transition(viewModel.transition(reduceMotion: reduceMotion))
    }

    private var nextAlarmText: String {
        guard let schedule = scheduleManager.schedules.first else {
            return "Next alarm: --"
        }
        let weekday = TimeFormatters.dayFormatter.string(from: schedule.wakeDate)
        let time = TimeFormatters.timeFormatter.string(from: schedule.wakeDate)
        return "Next alarm: \(weekday) \(time)"
    }
}

private struct WelcomeStep: View {
    let onGetStarted: () -> Void
    let onHowItWorks: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.Onboarding.welcomeTitle)
                .font(.largeTitle.weight(.bold))
            Text(Strings.Onboarding.welcomeBody)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(Strings.Onboarding.welcomePrimaryAction, action: onGetStarted)
                .buttonStyle(.borderedProminent)

            Button(Strings.Onboarding.welcomeSecondaryAction, action: onHowItWorks)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct LocationStep: View {
    let locationMode: LocationMode
    let locationState: AppPermissionState
    let locationName: String?
    let hasFixedLocation: Bool
    let isWorking: Bool
    let onRequestLocation: () -> Void
    let onOpenSettings: () -> Void
    let onChooseCity: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.Onboarding.locationTitle)
                .font(.title2.weight(.bold))

            Text(Strings.Onboarding.locationBody)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(Strings.Onboarding.locationPrivacyNote)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let message = statusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if locationState == .needsFollowUp || isWorking {
                ProgressView()
            }

            if let actionTitle = primaryActionTitle {
                Button(actionTitle, action: primaryAction)
                    .buttonStyle(.borderedProminent)
            }

            Button(Strings.Onboarding.locationSecondaryAction, action: onChooseCity)
                .buttonStyle(.bordered)

            Button(Strings.Onboarding.continueAction, action: onContinue)
                .buttonStyle(.borderedProminent)
                .disabled(!isLocationReady)
        }
    }

    private var isLocationReady: Bool {
        switch locationMode {
        case .auto:
            return locationState == .authorized
        case .fixed:
            return hasFixedLocation
        }
    }

    private var primaryActionTitle: String? {
        switch (locationMode, locationState) {
        case (.auto, .notDetermined):
            return Strings.Onboarding.locationPrimaryAction
        case (.auto, .denied), (.auto, .restricted):
            return Strings.LocationAccess.openSettings
        case (.auto, .needsFollowUp):
            return Strings.LocationAccess.tryAgain
        case (.fixed, _):
            return nil
        default:
            return nil
        }
    }

    private func primaryAction() {
        switch (locationMode, locationState) {
        case (.auto, .notDetermined), (.auto, .needsFollowUp):
            onRequestLocation()
        case (.auto, .denied), (.auto, .restricted):
            onOpenSettings()
        default:
            break
        }
    }

    private var statusMessage: String? {
        switch locationMode {
        case .fixed:
            if let locationName {
                return Strings.Onboarding.locationFixedStatus(locationName)
            }
            return hasFixedLocation
                ? Strings.Onboarding.locationFixedReady
                : Strings.Onboarding.locationFixedMissing
        case .auto:
            switch locationState {
            case .authorized:
                if let locationName {
                    return Strings.LocationAccess.currentLocation(locationName)
                }
                return Strings.Onboarding.locationReady
            case .needsFollowUp:
                return Strings.LocationAccess.waitingForLocation
            case .denied, .restricted:
                return Strings.LocationAccess.deniedExplanation
            case .notDetermined:
                return nil
            case .unavailable:
                return Strings.LocationAccess.autoExplanation
            }
        }
    }
}

private struct AlarmKitStep: View {
    let alarmState: AppPermissionState
    let isRequestable: Bool
    let shouldShowFallback: Bool
    let onRequestAlarmKit: () -> Void
    let onOpenSettings: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.Onboarding.alarmKitTitle)
                .font(.title2.weight(.bold))

            Text(Strings.Onboarding.alarmKitBody)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(Strings.Onboarding.alarmKitFootnote)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if shouldShowFallback {
                InfoBanner(systemImage: "alarm", text: Strings.Onboarding.alarmKitFallbackBanner)
            }

            if let actionTitle = primaryActionTitle {
                Button(actionTitle, action: primaryAction)
                    .buttonStyle(.borderedProminent)
            }

            Button(Strings.Onboarding.continueAction, action: onContinue)
                .buttonStyle(.borderedProminent)
        }
    }

    private var primaryActionTitle: String? {
        switch alarmState {
        case .notDetermined where isRequestable:
            return Strings.Onboarding.alarmKitPrimaryAction
        case .denied, .restricted:
            return Strings.LocationAccess.openSettings
        default:
            return nil
        }
    }

    private var statusMessage: String? {
        switch alarmState {
        case .authorized:
            return Strings.Onboarding.alarmKitReady
        case .denied, .restricted:
            return Strings.AlarmAccess.deniedExplanation
        case .unavailable:
            return Strings.AlarmAccess.unavailableExplanation
        default:
            return nil
        }
    }

    private func primaryAction() {
        switch alarmState {
        case .notDetermined where isRequestable:
            onRequestAlarmKit()
        case .denied, .restricted:
            onOpenSettings()
        default:
            break
        }
    }
}

private struct NotificationsStep: View {
    let notificationState: AppPermissionState
    let showAlarmKitFallback: Bool
    let onRequestNotifications: () -> Void
    let onOpenSettings: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.Onboarding.notificationsTitle)
                .font(.title2.weight(.bold))

            Text(Strings.Onboarding.notificationsBody)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if notificationState != .authorized {
                Text(Strings.Onboarding.notificationsRequirement)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if showAlarmKitFallback {
                InfoBanner(systemImage: "alarm", text: Strings.Onboarding.alarmKitFallbackBanner)
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let actionTitle = primaryActionTitle {
                Button(actionTitle, action: primaryAction)
                    .buttonStyle(.borderedProminent)
            }

            Button(Strings.Onboarding.continueAction, action: onContinue)
                .buttonStyle(.borderedProminent)
                .disabled(notificationState != .authorized)
        }
    }

    private var statusMessage: String? {
        switch notificationState {
        case .authorized:
            return Strings.Onboarding.notificationsReady
        case .denied, .restricted:
            return Strings.NotificationAccess.deniedExplanation
        default:
            return nil
        }
    }

    private var primaryActionTitle: String? {
        switch notificationState {
        case .notDetermined:
            return Strings.Onboarding.notificationsPrimaryAction
        case .denied, .restricted:
            return Strings.LocationAccess.openSettings
        default:
            return nil
        }
    }

    private func primaryAction() {
        switch notificationState {
        case .notDetermined:
            onRequestNotifications()
        case .denied, .restricted:
            onOpenSettings()
        default:
            break
        }
    }
}

private struct OffsetStep: View {
    @Binding var baseMinutes: Int
    let failureMessage: String?
    let onEnable: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.Onboarding.offsetTitle)
                .font(.title2.weight(.bold))

            Text(Strings.Onboarding.offsetBody)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            OffsetPickerView(
                baseMinutes: $baseMinutes,
                sentenceText: Strings.Onboarding.offsetSummary
            )
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(Strings.Onboarding.offsetCustomHelper)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let failureMessage {
                InfoBanner(systemImage: "exclamationmark.triangle", text: failureMessage)
            }

            Button(Strings.Onboarding.continueAction, action: onEnable)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct ConfirmationStep: View {
    let nextAlarmText: String
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(Strings.Onboarding.confirmationTitle, systemImage: "checkmark.circle.fill")
                .font(.title2.weight(.bold))

            Text(nextAlarmText)
                .font(.body)

            Text(Strings.Onboarding.confirmationBody)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(Strings.Onboarding.doneAction, action: onDone)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct HowItWorksView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(Strings.Onboarding.HowItWorks.body)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 10) {
                        OnboardingBulletRow(text: Strings.Onboarding.HowItWorks.bulletWakeDefault(settingsStore.settings.baseWakeOffsetMinutes))
                        OnboardingBulletRow(text: Strings.Onboarding.HowItWorks.bulletReminders)
                        OnboardingBulletRow(text: Strings.Onboarding.HowItWorks.bulletCustomize)
                    }
                }
                .padding(24)
            }
            .navigationTitle(Strings.Onboarding.HowItWorks.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct OnboardingBulletRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("•")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OnboardingProgressView: View {
    let stepIndex: Int
    let stepCount: Int

    var body: some View {
        ProgressView(value: Double(stepIndex + 1), total: Double(max(stepCount, 1)))
            .tint(.orange)
            .accessibilityLabel("Onboarding progress")
    }
}
