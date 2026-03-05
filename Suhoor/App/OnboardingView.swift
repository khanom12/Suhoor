import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var locationService: LocationService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showLocationSearch = false
    @State private var didAutoShowCityPicker = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                OnboardingHeaderView(
                    stepIndex: viewModel.progressIndex,
                    stepCount: viewModel.progressCount,
                    shouldShowProgress: viewModel.shouldShowProgress,
                    canGoBack: viewModel.canGoBack,
                    onBack: { viewModel.goBack(animation: Motion.onboarding(reduceMotion: reduceMotion)) }
                )
                ScrollView(showsIndicators: false) {
                    stepView
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showLocationSearch) {
                NavigationStack {
                    LocationSearchView(
                        selectedName: viewModel.locationName,
                        onSelectCity: { city in
                            viewModel.chooseCity(city)
                            showLocationSearch = false
                            viewModel.advance(animation: Motion.onboarding(reduceMotion: reduceMotion))
                        },
                        onSelectMapItem: { item in
                            viewModel.chooseMapItem(item)
                            showLocationSearch = false
                            viewModel.advance(animation: Motion.onboarding(reduceMotion: reduceMotion))
                        }
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
            .onChange(of: locationService.authorizationStatus) { _, _ in
                viewModel.refreshPermissionsInBackground()
            }
            .onChange(of: locationService.lastLocation) { _, _ in
                viewModel.refreshPermissionsInBackground()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.refreshPermissionsInBackground()
                }
            }
            .onChange(of: settingsStore.settings.baseWakeOffsetMinutes) { _, newValue in
                viewModel.handleOffsetChanged(newValue)
                // Keep schedule previews + activation in sync with what the user chose in onboarding.
                alarmConfigStore.defaults.defaultSuhoorTimeMode = .relativeToFajrMinusMinutes
                alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = newValue
            }
            .onChange(of: viewModel.step) { _, newStep in
                if newStep == .offset {
                    viewModel.activationAttempt()
                }
                if newStep != .location {
                    didAutoShowCityPicker = false
                }
            }
            .onChange(of: viewModel.locationState) { _, newState in
                // If the system prompt fails (denied/restricted/unavailable), offer the city picker immediately.
                guard viewModel.step == .location else { return }
                guard !didAutoShowCityPicker else { return }
                switch newState {
                case .denied, .restricted, .unavailable:
                    didAutoShowCityPicker = true
                    showLocationSearch = true
                default:
                    break
                }
            }
        }
    }

    @ViewBuilder
    private var stepView: some View {
        Group {
            switch viewModel.step {
            case .valuePreview:
                ValuePreviewStep(
                    preview: viewModel.valueScreenPreview,
                    offsetMinutes: viewModel.selectedOffsetMinutes,
                    activationState: .idle,
                    primaryTitle: viewModel.valuePrimaryActionTitle,
                    onPrimary: { viewModel.startFlow(animation: Motion.onboarding(reduceMotion: reduceMotion)) }
                )
            case .location:
                LocationStep(
                    locationMode: viewModel.locationMode,
                    locationState: viewModel.locationState,
                    locationName: viewModel.locationName,
                    hasFixedLocation: viewModel.hasFixedLocation,
                    isWorking: viewModel.isWorking,
                    showNextAction: viewModel.shouldShowManualAdvanceForCurrentStep,
                    onRequestLocation: viewModel.requestLocation,
                    onOpenSettings: viewModel.openSettings,
                    onChooseCity: { showLocationSearch = true },
                    onNext: { viewModel.advance(animation: Motion.onboarding(reduceMotion: reduceMotion)) }
                )
            case .offset:
                OffsetStep(
                    baseMinutes: $settingsStore.settings.baseWakeOffsetMinutes,
                    preview: viewModel.tomorrowPreview,
                    offsetHelperText: viewModel.offsetHelperText,
                    offsetMinutes: viewModel.selectedOffsetMinutes,
                    activationState: viewModel.activationState,
                    onContinue: { viewModel.advance(animation: Motion.onboarding(reduceMotion: reduceMotion)) }
                )
            case .futureVisualization:
                FutureVisualizationStep(
                    rows: viewModel.next5DaysSchedule,
                    offsetMinutes: viewModel.selectedOffsetMinutes,
                    onContinue: { viewModel.advance(animation: Motion.onboarding(reduceMotion: reduceMotion)) }
                )
            case .permissions:
                PermissionsStep(
                    alarmState: viewModel.alarmKitState,
                    notificationState: viewModel.notificationState,
                    isAlarmRequestable: viewModel.alarmKitRequestable,
                    isNotificationsRequired: viewModel.isNotificationsRequired,
                    showAlarmKitFallback: viewModel.shouldShowAlarmKitFallback,
                    showNextAction: viewModel.shouldShowManualAdvanceForCurrentStep,
                    onRequestAlarm: viewModel.requestAlarmKit,
                    onRequestNotifications: viewModel.requestNotifications,
                    onOpenSettings: viewModel.openSettings,
                    onContinue: { viewModel.advance(animation: Motion.onboarding(reduceMotion: reduceMotion)) }
                )
            case .success:
                SuccessStep(
                    preview: viewModel.tomorrowPreview,
                    offsetMinutes: viewModel.selectedOffsetMinutes,
                    title: viewModel.successTitleText,
                    onDone: viewModel.markOnboardingComplete
                )
            }
        }
        .id(viewModel.step)
        .transition(viewModel.transition(reduceMotion: reduceMotion))
    }
}

private struct ValuePreviewStep: View {
    let preview: OnboardingTomorrowPreview
    let offsetMinutes: Int
    let activationState: OnboardingActivationState
    let primaryTitle: String
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Onboarding.valueTitle)
                .font(.largeTitle.weight(.bold))
            Text(Strings.Onboarding.valueBody)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            OnboardingTimeCard(
                preview: preview,
                offsetMinutes: offsetMinutes,
                activationState: activationState,
                animateRelationshipOnAppear: true
            )

            Button(primaryTitle, action: onPrimary)
                .buttonStyle(BorderedProminentButtonStyle())
        }
    }
}

private struct LocationStep: View {
    let locationMode: LocationMode
    let locationState: AppPermissionState
    let locationName: String?
    let hasFixedLocation: Bool
    let isWorking: Bool
    let showNextAction: Bool
    let onRequestLocation: () -> Void
    let onOpenSettings: () -> Void
    let onChooseCity: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Onboarding.locationTitle)
                .font(.title2.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            Text(Strings.Onboarding.locationBody)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                trustLine(Strings.Onboarding.locationTrustLine1)
                trustLine(Strings.Onboarding.locationTrustLine2)
            }

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
                    .buttonStyle(BorderedProminentButtonStyle())
            }

            if locationState == .denied || locationState == .restricted {
                Button(Strings.LocationAccess.tryAgain, action: onRequestLocation)
                    .buttonStyle(BorderedButtonStyle())
            }

            Button(Strings.Onboarding.locationSecondaryAction, action: onChooseCity)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(minHeight: 44, alignment: .leading)
                .buttonStyle(.plain)

            if showNextAction {
                Button(Strings.Onboarding.continueAction, action: onNext)
                    .buttonStyle(BorderedProminentButtonStyle())
            }
        }
    }

    private func trustLine(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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

private struct FutureVisualizationStep: View {
    let rows: [SchedulePreviewRow]
    let offsetMinutes: Int
    let onContinue: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Onboarding.futureVisualizationTitle)
                .font(.title2.weight(.bold))

            Text(Strings.Onboarding.futureVisualizationOffsetLine(offsetMinutes))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            weekCard

            Text(Strings.Onboarding.futureVisualizationFooter)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(Strings.Onboarding.continueAction, action: onContinue)
                .buttonStyle(BorderedProminentButtonStyle())
        }
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Onboarding.futureVisualizationCardTitle)
                .font(DesignTokens.cardTitleFont)

            Text(Strings.Onboarding.futureVisualizationTableOffset(offsetMinutes))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.06), in: Capsule())

            if dynamicTypeSize.isAccessibilitySize {
                accessibilityRows
            } else {
                standardRows
            }
        }
        .cardStyle()
    }

    private var standardRows: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("Day")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(Strings.Onboarding.previewFajrLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 86, alignment: .trailing)
                Text(Strings.Onboarding.previewSuhoorLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 98, alignment: .trailing)
            }

            ForEach(rows) { row in
                HStack(spacing: 8) {
                    Text(row.dayLabel)
                        .font(DesignTokens.cardMetaFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(TimeFormatters.timeFormatter.string(from: row.fajr))
                        .font(DesignTokens.cardSubtitleFont.monospacedDigit())
                        .frame(width: 86, alignment: .trailing)
                    Text(TimeFormatters.timeFormatter.string(from: row.suhoor))
                        .font(DesignTokens.cardSubtitleFont.monospacedDigit())
                        .frame(width: 98, alignment: .trailing)
                }
            }
        }
    }

    private var accessibilityRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.dayLabel)
                        .font(DesignTokens.cardMetaFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    HStack {
                        Text(Strings.Onboarding.previewFajrLabel)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(TimeFormatters.timeFormatter.string(from: row.fajr))
                            .font(DesignTokens.cardSubtitleFont.monospacedDigit())
                    }
                    HStack {
                        Text(Strings.Onboarding.previewSuhoorLabel)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(TimeFormatters.timeFormatter.string(from: row.suhoor))
                            .font(DesignTokens.cardSubtitleFont.monospacedDigit())
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct PermissionsStep: View {
    let alarmState: AppPermissionState
    let notificationState: AppPermissionState
    let isAlarmRequestable: Bool
    let isNotificationsRequired: Bool
    let showAlarmKitFallback: Bool
    let showNextAction: Bool
    let onRequestAlarm: () -> Void
    let onRequestNotifications: () -> Void
    let onOpenSettings: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Onboarding.permissionsTitle)
                .font(.title2.weight(.bold))

            Text(Strings.Onboarding.permissionsBody)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            let shouldShowNotificationsRow = isNotificationsRequired

            VStack(alignment: .leading, spacing: 12) {
                permissionRow(
                    title: Strings.Onboarding.permissionsAlarmTitle,
                    status: alarmStatus,
                    actionTitle: alarmActionTitle,
                    secondaryActionTitle: nil,
                    isPrimary: true,
                    showsCheckmark: alarmState == .authorized,
                    action: alarmAction,
                    secondaryAction: onContinue
                )

                if shouldShowNotificationsRow {
                    Divider()

                    permissionRow(
                        title: Strings.Onboarding.permissionsNotificationsTitle,
                        status: notificationStatus,
                        actionTitle: notificationActionTitle,
                        secondaryActionTitle: shouldShowNotificationSkip
                            ? Strings.Onboarding.permissionsNotificationsSkipAction
                            : nil,
                        isPrimary: false,
                        showsCheckmark: notificationState == .authorized,
                        action: notificationAction,
                        secondaryAction: onContinue
                    )
                }
            }

            if showAlarmKitFallback {
                InfoBanner(systemImage: "alarm", text: Strings.Onboarding.permissionsFallbackBanner)
            }

            if showNextAction {
                Button(Strings.Onboarding.continueAction, action: onContinue)
                    .buttonStyle(BorderedProminentButtonStyle())
            }
        }
    }

    private var alarmActionTitle: String? {
        switch alarmState {
        case .notDetermined where isAlarmRequestable:
            return Strings.Onboarding.permissionsAlarmAction
        case .denied, .restricted:
            return Strings.LocationAccess.openSettings
        default:
            return nil
        }
    }

    private var alarmStatus: String? {
        switch alarmState {
        case .authorized:
            return Strings.Onboarding.permissionsAlarmReady
        case .denied, .restricted:
            return Strings.AlarmAccess.deniedExplanation
        case .unavailable:
            return Strings.AlarmAccess.unavailableExplanation
        default:
            return Strings.Onboarding.permissionsAlarmHelper
        }
    }

    private func alarmAction() {
        switch alarmState {
        case .notDetermined where isAlarmRequestable:
            onRequestAlarm()
        case .denied, .restricted:
            onOpenSettings()
        default:
            break
        }
    }

    private var notificationActionTitle: String? {
        switch notificationState {
        case .notDetermined:
            return Strings.Onboarding.permissionsNotificationsAction
        case .denied, .restricted:
            return Strings.LocationAccess.openSettings
        default:
            return nil
        }
    }

    private var notificationStatus: String? {
        switch notificationState {
        case .authorized:
            return Strings.Onboarding.permissionsNotificationsReady
        case .denied, .restricted:
            return Strings.NotificationAccess.deniedExplanation
        default:
            return isNotificationsRequired
                ? Strings.Onboarding.permissionsNotificationsRequired
                : Strings.Onboarding.permissionsNotificationsRecommended
        }
    }

    private func notificationAction() {
        switch notificationState {
        case .notDetermined:
            onRequestNotifications()
        case .denied, .restricted:
            onOpenSettings()
        default:
            break
        }
    }

    private var shouldShowNotificationSkip: Bool {
        alarmState == .authorized
            && !isNotificationsRequired
            && notificationState != .authorized
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        status: String?,
        actionTitle: String?,
        secondaryActionTitle: String?,
        isPrimary: Bool,
        showsCheckmark: Bool,
        action: @escaping () -> Void,
        secondaryAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline.weight(.semibold))
                Spacer()
                if showsCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            if let status {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if actionTitle != nil || secondaryActionTitle != nil {
                HStack(spacing: 10) {
                    if let actionTitle {
                        if isPrimary {
                            Button(actionTitle, action: action)
                                .buttonStyle(BorderedProminentButtonStyle())
                        } else {
                            Button(actionTitle, action: action)
                                .buttonStyle(BorderedButtonStyle())
                        }
                    }
                    if let secondaryActionTitle {
                        Button(secondaryActionTitle, action: secondaryAction)
                            .buttonStyle(BorderedButtonStyle())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OffsetStep: View {
    @Binding var baseMinutes: Int
    let preview: OnboardingTomorrowPreview
    let offsetHelperText: String
    let offsetMinutes: Int
    let activationState: OnboardingActivationState
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Onboarding.offsetTitle)
                .font(.title2.weight(.bold))

            Text(Strings.Onboarding.offsetBody)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            OffsetPickerView(
                baseMinutes: $baseMinutes,
                presetMinutes: [30, 45, 60, 75],
                presetLabels: [
                    30: "Quick Suhoor",
                    45: "Comfortable",
                    60: "Recommended",
                    75: "Unhurried"
                ],
                sentenceText: nil
            )

            Text(Strings.Onboarding.offsetCustomHelper)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(offsetHelperText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: offsetHelperText)

            OnboardingTimeCard(
                preview: preview,
                offsetMinutes: offsetMinutes,
                activationState: activationState
            )

            Button(Strings.Onboarding.continueAction, action: onContinue)
                .buttonStyle(BorderedProminentButtonStyle())
        }
    }
}

private struct SuccessStep: View {
    let preview: OnboardingTomorrowPreview
    let offsetMinutes: Int
    let title: String
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "checkmark.circle.fill")
                .font(.title2.weight(.bold))

            OnboardingTimeCard(preview: preview, offsetMinutes: offsetMinutes, activationState: .idle)

            Text(Strings.Onboarding.successBody)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(Strings.Onboarding.successAction, action: onDone)
                .buttonStyle(BorderedProminentButtonStyle())
        }
    }
}

private struct OnboardingTimeCard: View {
    let preview: OnboardingTomorrowPreview
    let offsetMinutes: Int
    let activationState: OnboardingActivationState
    var animateRelationshipOnAppear: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showRelationship: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(preview.dateText)
                    .font(DesignTokens.cardTitleFont)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                cardRow(
                    label: Strings.Onboarding.previewFajrLabel,
                    value: preview.fajrTimeText ?? Strings.Onboarding.previewFajrPlaceholder
                )

                HStack {
                    offsetBadge
                    Spacer(minLength: 0)
                }

                if dynamicTypeSize.isAccessibilitySize {
                    suhoorRow
                    .opacity(showRelationship ? 1 : 0)
                    .offset(y: showRelationship ? 0 : 4)
                } else {
                    suhoorRow
                        .opacity(showRelationship ? 1 : 0)
                        .offset(y: showRelationship ? 0 : 4)
                }
            }
            .animation(.easeInOut(duration: 0.28), value: showRelationship)

            if let statusText = preview.statusText {
                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            switch activationState {
            case .attempting:
                ProgressView()
            case .failed(let message):
                InfoBanner(systemImage: "exclamationmark.triangle", text: message)
            default:
                EmptyView()
            }
        }
        .cardStyle()
        .onAppear {
            guard animateRelationshipOnAppear else {
                showRelationship = true
                return
            }
            showRelationship = false
            if reduceMotion {
                showRelationship = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showRelationship = true
                    }
                }
            }
        }
    }

    private var offsetBadge: some View {
        Text("\(offsetMinutes)m before Fajr")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.06), in: Capsule())
            .accessibilityLabel("\(offsetMinutes) minutes before Fajr")
    }

    private var suhoorRow: some View {
        cardRow(
            label: Strings.Onboarding.previewSuhoorLabel,
            value: preview.suhoorTimeText ?? Strings.Onboarding.previewSuhoorPlaceholder
        )
    }

    @ViewBuilder
    private func cardRow(label: String, value: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(DesignTokens.cardSubtitleFont.monospacedDigit())
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.25), value: value)
            }
        } else {
            HStack {
                Text(label)
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(value)
                    .font(DesignTokens.cardSubtitleFont.monospacedDigit())
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.25), value: value)
            }
        }
    }
}

private struct OnboardingProgressView: View {
    let stepIndex: Int
    let stepCount: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<stepCount, id: \.self) { index in
                Capsule()
                    .fill(index <= stepIndex ? DawnColor.accent : Color.primary.opacity(0.08))
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
            }
        }
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Step \(stepIndex + 1) of \(stepCount)")
    }
}

private struct OnboardingHeaderView: View {
    let stepIndex: Int
    let stepCount: Int
    let shouldShowProgress: Bool
    let canGoBack: Bool
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if canGoBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.semibold))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 36, height: 36)
                }

                if shouldShowProgress {
                    Text("Step \(stepIndex + 1) of \(max(stepCount, 1))")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if shouldShowProgress {
                OnboardingProgressView(stepIndex: stepIndex, stepCount: stepCount)
            }
        }
    }
}
