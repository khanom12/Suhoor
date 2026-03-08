import SwiftUI

private enum OnboardingSpacing {
    static let xSmall: CGFloat = 8
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let sidePadding: CGFloat = 24
    static let titleToSubtitle: CGFloat = 12
    static let cardToCTA: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardRowSpacing: CGFloat = 12
    static let cardCornerRadius: CGFloat = 24
    static let tileCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 20
    static let buttonHeight: CGFloat = 54
    static let tapTargetMin: CGFloat = 44
}

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
            VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
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
            .padding(.horizontal, OnboardingSpacing.sidePadding)
            .padding(.top, OnboardingSpacing.large)
            .padding(.bottom, OnboardingSpacing.large)
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showLocationSearch) {
                NavigationStack {
                    LocationSearchView(
                        selectedName: viewModel.locationName,
                        onSelectCity: { city in
                            viewModel.chooseCity(city)
                            showLocationSearch = false
                        },
                        onSelectMapItem: { item in
                            viewModel.chooseMapItem(item)
                            showLocationSearch = false
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
            .onChange(of: scheduleManager.currentRevision) { _, _ in
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
        VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
            VStack(alignment: .leading, spacing: OnboardingSpacing.titleToSubtitle) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Never miss")
                    Text("Suhoor again")
                }
                .font(.largeTitle.weight(.bold))
                Text(Strings.Onboarding.valueBody)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            OnboardingTimeCard(
                preview: preview,
                offsetMinutes: offsetMinutes,
                activationState: activationState,
                previewTag: Strings.Onboarding.previewTag,
                animateRelationshipOnAppear: true
            )

            Button(primaryTitle, action: onPrimary)
                .onboardingPrimaryButton()
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
        VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
            VStack(alignment: .leading, spacing: OnboardingSpacing.titleToSubtitle) {
                Text(Strings.Onboarding.locationTitle)
                    .font(.title2.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(Strings.Onboarding.locationBody)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
                    .onboardingPrimaryButton()
            }

            if locationState == .denied || locationState == .restricted {
                Button(Strings.LocationAccess.tryAgain, action: onRequestLocation)
                    .onboardingSecondaryButton()
            }

            Button(action: onChooseCity) {
                HStack(spacing: OnboardingSpacing.xSmall) {
                    Text(Strings.Onboarding.locationSecondaryAction)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: OnboardingSpacing.xSmall)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showNextAction {
                Button(Strings.Onboarding.continueAction, action: onNext)
                    .onboardingPrimaryButton()
            }
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
            return Strings.Onboarding.locationPrimaryAction
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
        case (.fixed, _):
            onRequestLocation()
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
        VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
            VStack(alignment: .leading, spacing: OnboardingSpacing.titleToSubtitle) {
                Text(Strings.Onboarding.futureVisualizationTitle)
                    .font(.title2.weight(.bold))

                Text(Strings.Onboarding.futureVisualizationOffsetLine(offsetMinutes))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            weekCard

            Button(Strings.Onboarding.continueAction, action: onContinue)
                .onboardingPrimaryButton()
        }
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: OnboardingSpacing.small) {
            Text(Strings.Onboarding.futureVisualizationCardTitle)
                .font(DesignTokens.cardTitleFont)

            Text(Strings.Onboarding.futureVisualizationTableOffset(offsetMinutes))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if dynamicTypeSize >= .accessibility1 {
                accessibilityRows
            } else {
                standardRows
            }
        }
        .onboardingCardStyle()
    }

    private var standardRows: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Color.clear
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
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(1)
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
        VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
            VStack(alignment: .leading, spacing: OnboardingSpacing.titleToSubtitle) {
                Text(Strings.Onboarding.permissionsTitle)
                    .font(.title2.weight(.bold))

                Text(Strings.Onboarding.permissionsBody)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

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
                    .onboardingPrimaryButton()
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
                        Button(actionTitle, action: action)
                            .onboardingPrimaryButton()
                    }
                    if let secondaryActionTitle {
                        Button(secondaryActionTitle, action: secondaryAction)
                            .onboardingPrimaryButton()
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
    let offsetMinutes: Int
    let activationState: OnboardingActivationState
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
            VStack(alignment: .leading, spacing: OnboardingSpacing.titleToSubtitle) {
                Text(Strings.Onboarding.offsetTitle)
                    .font(.title2.weight(.bold))
                Text(Strings.Onboarding.offsetBody)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            OnboardingTimeCard(
                preview: preview,
                offsetMinutes: offsetMinutes,
                activationState: activationState,
                pulseOnOffsetChange: true
            )

            OffsetPickerView(
                baseMinutes: $baseMinutes,
                presetMinutes: [30, 45, 60, 75, 90],
                presetLabels: [
                    30: "Quick Suhoor",
                    45: "Comfortable",
                    60: "Recommended",
                    75: "Unhurried",
                    90: "Relaxed"
                ],
                sentenceText: nil
            )

            Button(Strings.Onboarding.continueAction, action: onContinue)
                .onboardingPrimaryButton()
        }
    }
}

private struct SuccessStep: View {
    let preview: OnboardingTomorrowPreview
    let offsetMinutes: Int
    let title: String
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
            Label(title, systemImage: "checkmark.circle.fill")
                .font(.title2.weight(.bold))

            OnboardingTimeCard(preview: preview, offsetMinutes: offsetMinutes, activationState: .idle)

            Text(Strings.Onboarding.successBody)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(Strings.Onboarding.successAction, action: onDone)
                .onboardingPrimaryButton()
        }
    }
}

private struct OnboardingTimeCard: View {
    let preview: OnboardingTomorrowPreview
    let offsetMinutes: Int
    let activationState: OnboardingActivationState
    var previewTag: String? = nil
    var animateRelationshipOnAppear: Bool = false
    var pulseOnOffsetChange: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showRelationship: Bool = false
    @State private var pulseConnector: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingSpacing.small) {
            HStack {
                Text(preview.dateText)
                    .font(DesignTokens.cardTitleFont)
                Spacer()
                if let previewTag {
                    Text(previewTag)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.06), in: Capsule())
                }
            }

            cardRows
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
        .onboardingCardStyle()
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
        .onChange(of: offsetMinutes) { _, _ in
            guard pulseOnOffsetChange, !reduceMotion else { return }
            pulseConnector = false
            withAnimation(.easeInOut(duration: 0.18)) {
                pulseConnector = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                withAnimation(.easeOut(duration: 0.4)) {
                    pulseConnector = false
                }
            }
        }
    }

    private var connectorLine: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            (
                Text("\(offsetMinutes) min")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(pulseConnector ? DawnColor.accent : .primary)
                +
                Text(" earlier")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            )
        }
        .scaleEffect(pulseConnector ? 1.08 : 1)
        .accessibilityLabel("\(offsetMinutes) minutes earlier")
    }

    @ViewBuilder
    private var cardRows: some View {
        if dynamicTypeSize >= .accessibility1 {
            VStack(alignment: .leading, spacing: OnboardingSpacing.cardRowSpacing) {
                stackedRow(
                    label: Strings.Onboarding.previewFajrLabel,
                    value: preview.fajrTimeText ?? Strings.Onboarding.previewFajrPlaceholder
                )
                connectorLine
                    .opacity(showRelationship ? 1 : 0)
                    .offset(y: showRelationship ? 0 : 4)
                stackedRow(
                    label: Strings.Onboarding.previewSuhoorLabel,
                    value: preview.suhoorTimeText ?? Strings.Onboarding.previewSuhoorPlaceholder
                )
                .opacity(showRelationship ? 1 : 0)
                .offset(y: showRelationship ? 0 : 4)
            }
        } else {
            Grid(horizontalSpacing: OnboardingSpacing.small, verticalSpacing: OnboardingSpacing.cardRowSpacing) {
                GridRow {
                    connectedRow(
                        label: Strings.Onboarding.previewFajrLabel,
                        value: preview.fajrTimeText ?? Strings.Onboarding.previewFajrPlaceholder
                    )
                    .gridCellColumns(2)
                }
                GridRow {
                    Color.clear
                    connectorLine
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .gridColumnAlignment(.trailing)
                        .opacity(showRelationship ? 1 : 0)
                        .offset(y: showRelationship ? 0 : 4)
                }
                GridRow {
                    connectedRow(
                        label: Strings.Onboarding.previewSuhoorLabel,
                        value: preview.suhoorTimeText ?? Strings.Onboarding.previewSuhoorPlaceholder
                    )
                    .gridCellColumns(2)
                }
                .opacity(showRelationship ? 1 : 0)
                .offset(y: showRelationship ? 0 : 4)
            }
        }
    }

    private func stackedRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.semibold).monospacedDigit())
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: value)
        }
    }

    private func connectedRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.semibold).monospacedDigit())
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: value)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        )
    }
}

private struct OnboardingCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(OnboardingSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: OnboardingSpacing.cardCornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingSpacing.cardCornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

private extension View {
    func onboardingCardStyle() -> some View {
        modifier(OnboardingCardStyle())
    }

    func onboardingPrimaryButton() -> some View {
        self
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: OnboardingSpacing.buttonHeight)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: OnboardingSpacing.buttonCornerRadius))
            .controlSize(.large)
            .frame(minHeight: OnboardingSpacing.tapTargetMin)
    }

    func onboardingSecondaryButton() -> some View {
        self
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: OnboardingSpacing.buttonCornerRadius))
            .controlSize(.regular)
            .frame(minHeight: OnboardingSpacing.tapTargetMin)
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
        VStack(alignment: .leading, spacing: OnboardingSpacing.small) {
            HStack(spacing: OnboardingSpacing.small) {
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

#if DEBUG
@available(iOS 17.0, *)
#Preview("Step 1 - Default") {
    ValuePreviewStep(
        preview: OnboardingTomorrowPreview(
            dateText: "Today",
            targetDate: Date(),
            fajrDate: Date(),
            suhoorDate: Date().addingTimeInterval(-45 * 60),
            fajrTimeText: "5:27 AM",
            suhoorTimeText: "4:42 AM",
            statusText: nil
        ),
        offsetMinutes: 45,
        activationState: .idle,
        primaryTitle: Strings.Onboarding.valuePrimaryActionToday,
        onPrimary: {}
    )
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}

@available(iOS 17.0, *)
#Preview("Step 1 - XXL") {
    ValuePreviewStep(
        preview: OnboardingTomorrowPreview(
            dateText: "Today",
            targetDate: Date(),
            fajrDate: Date(),
            suhoorDate: Date().addingTimeInterval(-60 * 60),
            fajrTimeText: "6:02 AM",
            suhoorTimeText: "5:02 AM",
            statusText: nil
        ),
        offsetMinutes: 60,
        activationState: .idle,
        primaryTitle: Strings.Onboarding.valuePrimaryActionToday,
        onPrimary: {}
    )
    .environment(\.dynamicTypeSize, .xxLarge)
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}

@available(iOS 17.0, *)
#Preview("Step 1 - Accessibility1") {
    ValuePreviewStep(
        preview: OnboardingTomorrowPreview(
            dateText: "Today",
            targetDate: Date(),
            fajrDate: Date(),
            suhoorDate: Date().addingTimeInterval(-45 * 60),
            fajrTimeText: "5:27 AM",
            suhoorTimeText: "4:42 AM",
            statusText: nil
        ),
        offsetMinutes: 45,
        activationState: .idle,
        primaryTitle: Strings.Onboarding.valuePrimaryActionToday,
        onPrimary: {}
    )
    .environment(\.dynamicTypeSize, .accessibility1)
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}

@available(iOS 17.0, *)
#Preview("Step 2 - Default") {
    LocationStep(
        locationMode: .auto,
        locationState: .notDetermined,
        locationName: nil,
        hasFixedLocation: false,
        isWorking: false,
        showNextAction: false,
        onRequestLocation: {},
        onOpenSettings: {},
        onChooseCity: {},
        onNext: {}
    )
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}

@available(iOS 17.0, *)
#Preview("Step 2 - XXL") {
    LocationStep(
        locationMode: .fixed,
        locationState: .authorized,
        locationName: "San Francisco",
        hasFixedLocation: true,
        isWorking: false,
        showNextAction: false,
        onRequestLocation: {},
        onOpenSettings: {},
        onChooseCity: {},
        onNext: {}
    )
    .environment(\.dynamicTypeSize, .xxLarge)
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}

@available(iOS 17.0, *)
#Preview("Step 2 - Accessibility1") {
    LocationStep(
        locationMode: .auto,
        locationState: .denied,
        locationName: nil,
        hasFixedLocation: false,
        isWorking: false,
        showNextAction: false,
        onRequestLocation: {},
        onOpenSettings: {},
        onChooseCity: {},
        onNext: {}
    )
    .environment(\.dynamicTypeSize, .accessibility1)
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}

@available(iOS 17.0, *)
#Preview("Step 3 - Default") {
    @Previewable @State var baseMinutes: Int = 45
    return OffsetStep(
        baseMinutes: $baseMinutes,
        preview: OnboardingTomorrowPreview(
            dateText: "Tomorrow",
            targetDate: Date().addingTimeInterval(86400),
            fajrDate: Date().addingTimeInterval(86400),
            suhoorDate: Date().addingTimeInterval(86400 - 45 * 60),
            fajrTimeText: "5:27 AM",
            suhoorTimeText: "4:42 AM",
            statusText: nil
        ),
        offsetMinutes: 45,
        activationState: .idle,
        onContinue: {}
    )
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}

@available(iOS 17.0, *)
#Preview("Step 3 - XXL") {
    @Previewable @State var baseMinutes: Int = 60
    return OffsetStep(
        baseMinutes: $baseMinutes,
        preview: OnboardingTomorrowPreview(
            dateText: "Tomorrow",
            targetDate: Date().addingTimeInterval(86400),
            fajrDate: Date().addingTimeInterval(86400),
            suhoorDate: Date().addingTimeInterval(86400 - 60 * 60),
            fajrTimeText: "5:27 AM",
            suhoorTimeText: "4:27 AM",
            statusText: nil
        ),
        offsetMinutes: 60,
        activationState: .idle,
        onContinue: {}
    )
    .environment(\.dynamicTypeSize, .xxLarge)
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}

@available(iOS 17.0, *)
#Preview("Step 3 - Accessibility1") {
    @Previewable @State var baseMinutes: Int = 75
    return OffsetStep(
        baseMinutes: $baseMinutes,
        preview: OnboardingTomorrowPreview(
            dateText: "Today",
            targetDate: Date(),
            fajrDate: Date(),
            suhoorDate: Date().addingTimeInterval(-75 * 60),
            fajrTimeText: "5:27 AM",
            suhoorTimeText: "4:12 AM",
            statusText: nil
        ),
        offsetMinutes: 75,
        activationState: .idle,
        onContinue: {}
    )
    .environment(\.dynamicTypeSize, .accessibility1)
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}

@available(iOS 17.0, *)
#Preview("Step 6 - Default") {
    SuccessStep(
        preview: OnboardingTomorrowPreview(
            dateText: "Tomorrow",
            targetDate: Date().addingTimeInterval(86400),
            fajrDate: Date().addingTimeInterval(86400),
            suhoorDate: Date().addingTimeInterval(86400 - 60 * 60),
            fajrTimeText: "5:27 AM",
            suhoorTimeText: "4:27 AM",
            statusText: nil
        ),
        offsetMinutes: 60,
        title: "You’re ready for tomorrow.",
        onDone: {}
    )
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}

@available(iOS 17.0, *)
#Preview("Step 6 - XXL") {
    SuccessStep(
        preview: OnboardingTomorrowPreview(
            dateText: "Today",
            targetDate: Date(),
            fajrDate: Date(),
            suhoorDate: Date().addingTimeInterval(-45 * 60),
            fajrTimeText: "6:12 AM",
            suhoorTimeText: "5:27 AM",
            statusText: nil
        ),
        offsetMinutes: 45,
        title: "You’re ready for today.",
        onDone: {}
    )
    .environment(\.dynamicTypeSize, .xxLarge)
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}

@available(iOS 17.0, *)
#Preview("Step 6 - Accessibility1") {
    SuccessStep(
        preview: OnboardingTomorrowPreview(
            dateText: "Tomorrow",
            targetDate: Date().addingTimeInterval(86400),
            fajrDate: Date().addingTimeInterval(86400),
            suhoorDate: Date().addingTimeInterval(86400 - 30 * 60),
            fajrTimeText: "5:55 AM",
            suhoorTimeText: "5:25 AM",
            statusText: nil
        ),
        offsetMinutes: 30,
        title: "You’re ready for tomorrow.",
        onDone: {}
    )
    .environment(\.dynamicTypeSize, .accessibility1)
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}
#endif
