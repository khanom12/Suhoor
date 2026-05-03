import SwiftUI

private enum OnboardingSpacing {
    static let xSmall: CGFloat = 8
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let sidePadding: CGFloat = 24
    static let titleToSubtitle: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let cardRowSpacing: CGFloat = 12
    static let cardCornerRadius: CGFloat = 24
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
    @State private var showCalculationMethodSheet = false
    @State private var didAutoShowCityPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppPageBackground()
                    .ignoresSafeArea()

                AppHomeContrastOverlay()
                    .ignoresSafeArea()

                contentStack
                    .padding(.horizontal, OnboardingSpacing.sidePadding)
                    .padding(.top, OnboardingSpacing.large)
                    .padding(.bottom, OnboardingSpacing.large)
            }
            .preferredColorScheme(.dark)
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
                .appSettingsPresentedChrome()
            }
            .sheet(isPresented: $showCalculationMethodSheet) {
                NavigationStack {
                    CalculationMethodSelectionView()
                }
                .appSettingsPresentedChrome()
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
            .onChange(of: viewModel.step) { _, newStep in
                if newStep != .location {
                    didAutoShowCityPicker = false
                }
            }
            .onChange(of: viewModel.locationState) { _, newState in
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

    private var contentStack: some View {
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
    }

    private var stepView: some View {
        stepContent
            .id(viewModel.step)
            .transition(viewModel.transition(reduceMotion: reduceMotion))
    }

    private var stepContent: AnyView {
        switch viewModel.step {
        case .valuePreview:
            AnyView(ValuePreviewStep(
                title: viewModel.valueTitleText,
                descriptionText: viewModel.valueBodyText,
                supportText: viewModel.valueSupportText,
                preview: viewModel.valueScreenPreview,
                relationshipText: viewModel.wakeRelationshipText,
                primaryTitle: viewModel.valuePrimaryActionTitle,
                wakeLabel: viewModel.previewWakeLabelText,
                onPrimary: { viewModel.startFlow(animation: Motion.onboarding(reduceMotion: reduceMotion)) }
            ))
        case .location:
            AnyView(LocationStep(
                title: viewModel.locationTitleText,
                descriptionText: viewModel.locationBodyText,
                trustBullets: viewModel.locationTrustBullets,
                calculationMethodName: viewModel.showsCalculationMethodSummary ? viewModel.calculationMethodName : nil,
                locationMode: viewModel.locationMode,
                locationState: viewModel.locationState,
                locationName: viewModel.locationName,
                hasFixedLocation: viewModel.hasFixedLocation,
                isWorking: viewModel.isWorking,
                showNextAction: viewModel.shouldShowManualAdvanceForCurrentStep,
                onRequestLocation: viewModel.requestLocation,
                onOpenSettings: viewModel.openSettings,
                onChooseCity: { showLocationSearch = true },
                onChangeCalculationMethod: { showCalculationMethodSheet = true },
                onNext: { viewModel.advance(animation: Motion.onboarding(reduceMotion: reduceMotion)) }
            ))
        case .permissions:
            AnyView(PermissionsStep(
                title: viewModel.permissionsTitleText,
                descriptionText: viewModel.permissionsBodyText,
                alarmState: viewModel.alarmKitState,
                notificationState: viewModel.notificationState,
                isAlarmRequestable: viewModel.alarmKitRequestable,
                showNotificationsRow: viewModel.showNotificationsRowInPermissions,
                requiredNoteText: viewModel.permissionsRequiredNoteText,
                blockedContinueNoteText: viewModel.permissionsContinueBlockedNoteText,
                showNextAction: viewModel.shouldShowPermissionsContinueAction,
                onRequestAlarm: viewModel.requestAlarmKit,
                onRequestNotifications: viewModel.requestNotifications,
                onOpenSettings: viewModel.openSettings,
                onContinue: { viewModel.advance(animation: Motion.onboarding(reduceMotion: reduceMotion)) }
            ))
        case .success:
            AnyView(SuccessStep(
                title: viewModel.successTitleText,
                descriptionText: viewModel.successBodyText,
                preview: viewModel.tomorrowPreview,
                relationshipText: viewModel.wakeRelationshipText,
                wakeLabel: viewModel.previewWakeLabelText,
                readyState: viewModel.readyState,
                isWorking: viewModel.isWorking,
                primaryActionTitle: viewModel.successPrimaryActionTitle,
                onPrimary: {
                    if viewModel.readyState == .blocked {
                        viewModel.startFlow(animation: Motion.onboarding(reduceMotion: reduceMotion))
                    } else {
                        viewModel.markOnboardingComplete()
                    }
                }
            ))
        }
    }
}

private struct ValuePreviewStep: View {
    let title: String
    let descriptionText: String
    let supportText: String
    let preview: OnboardingTomorrowPreview
    let relationshipText: String
    let primaryTitle: String
    let wakeLabel: String
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
            VStack(alignment: .leading, spacing: OnboardingSpacing.titleToSubtitle) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                Text(descriptionText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(supportText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            OnboardingMorningHeroPreview(
                preview: preview,
                relationshipText: relationshipText,
                wakeLabel: wakeLabel,
                animateRelationshipOnAppear: true
            )

            Button(primaryTitle, action: onPrimary)
                .onboardingPrimaryButton()
        }
    }
}

private struct LocationStep: View {
    let title: String
    let descriptionText: String
    let trustBullets: [String]
    let calculationMethodName: String?
    let locationMode: LocationMode
    let locationState: AppPermissionState
    let locationName: String?
    let hasFixedLocation: Bool
    let isWorking: Bool
    let showNextAction: Bool
    let onRequestLocation: () -> Void
    let onOpenSettings: () -> Void
    let onChooseCity: () -> Void
    let onChangeCalculationMethod: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
            VStack(alignment: .leading, spacing: OnboardingSpacing.titleToSubtitle) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(descriptionText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let message = statusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let calculationMethodName {
                VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                    Text("Prayer-time method")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline) {
                        Text(calculationMethodName)
                            .font(.body.weight(.semibold))
                        Spacer()
                        Button("Change", action: onChangeCalculationMethod)
                            .font(.footnote.weight(.semibold))
                    }
                }
                .onboardingCardStyle()
            }

            if !trustBullets.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                    ForEach(trustBullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: DesignTokens.spacingXS) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.footnote)
                                .foregroundStyle(DawnColor.accent)
                            Text(bullet)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if locationState == .needsFollowUp || isWorking {
                ProgressView()
            }

            if let actionTitle = primaryActionTitle {
                Button(actionTitle, action: primaryAction)
                    .onboardingPrimaryButton()
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
                return Strings.Onboarding.locationWaiting
            case .denied:
                return Strings.Onboarding.locationDenied
            case .restricted:
                return Strings.Onboarding.locationRestricted
            case .notDetermined:
                return nil
            case .unavailable:
                return Strings.Onboarding.locationUnavailable
            }
        }
    }
}

private struct PermissionsStep: View {
    let title: String
    let descriptionText: String
    let alarmState: AppPermissionState
    let notificationState: AppPermissionState
    let isAlarmRequestable: Bool
    let showNotificationsRow: Bool
    let requiredNoteText: String
    let blockedContinueNoteText: String
    let showNextAction: Bool
    let onRequestAlarm: () -> Void
    let onRequestNotifications: () -> Void
    let onOpenSettings: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
            VStack(alignment: .leading, spacing: OnboardingSpacing.titleToSubtitle) {
                Text(title)
                    .font(.title2.weight(.bold))

                Text(descriptionText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                permissionRow(
                    title: Strings.Onboarding.permissionsAlarmTitle,
                    roleText: "Required",
                    status: alarmStatus,
                    actionTitle: alarmActionTitle,
                    secondaryActionTitle: nil,
                    showsCheckmark: alarmState == .authorized,
                    action: alarmAction,
                    secondaryAction: onContinue
                )

                if showNotificationsRow {
                    Divider()

                    permissionRow(
                        title: Strings.Onboarding.permissionsNotificationsTitle,
                        roleText: "Recommended",
                        status: notificationStatus,
                        actionTitle: notificationActionTitle,
                        secondaryActionTitle: shouldShowNotificationSkip
                            ? Strings.Onboarding.permissionsNotificationsSkipAction
                            : nil,
                        showsCheckmark: notificationState == .authorized,
                        action: notificationAction,
                        secondaryAction: onContinue
                    )
                }
            }
            .onboardingCardStyle()

            InfoBanner(systemImage: "alarm", text: requiredNoteText)

            if showNextAction {
                Button(Strings.Onboarding.continueAction, action: onContinue)
                    .onboardingPrimaryButton()
            } else {
                Text(blockedContinueNoteText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var alarmActionTitle: String? {
        switch alarmState {
        case .notDetermined where isAlarmRequestable:
            return Strings.Onboarding.permissionsAlarmAction
        case .denied, .restricted:
            return Strings.LocationAccess.openSettings
        case .needsFollowUp:
            return Strings.LocationAccess.tryAgain
        default:
            return nil
        }
    }

    private var alarmStatus: String? {
        switch alarmState {
        case .authorized:
            return Strings.Onboarding.permissionsAlarmReady
        case .denied:
            return Strings.Onboarding.permissionsAlarmDenied
        case .restricted:
            return Strings.Onboarding.permissionsAlarmRestricted
        case .unavailable:
            return Strings.Onboarding.permissionsAlarmUnavailable
        case .needsFollowUp:
            return Strings.Onboarding.permissionsAlarmChecking
        case .notDetermined:
            return Strings.Onboarding.permissionsAlarmHelper
        }
    }

    private func alarmAction() {
        switch alarmState {
        case .notDetermined where isAlarmRequestable:
            onRequestAlarm()
        case .denied, .restricted:
            onOpenSettings()
        case .needsFollowUp:
            onRequestAlarm()
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
        case .needsFollowUp:
            return Strings.LocationAccess.tryAgain
        default:
            return nil
        }
    }

    private var notificationStatus: String? {
        switch notificationState {
        case .authorized:
            return Strings.Onboarding.permissionsNotificationsReady
        case .denied:
            return Strings.Onboarding.permissionsNotificationsDenied
        case .restricted:
            return Strings.Onboarding.permissionsNotificationsRestricted
        case .unavailable:
            return Strings.Onboarding.permissionsNotificationsUnavailable
        case .needsFollowUp:
            return Strings.Onboarding.permissionsNotificationsChecking
        case .notDetermined:
            return Strings.Onboarding.permissionsNotificationsRecommended
        }
    }

    private func notificationAction() {
        switch notificationState {
        case .notDetermined:
            onRequestNotifications()
        case .denied, .restricted:
            onOpenSettings()
        case .needsFollowUp:
            onRequestNotifications()
        default:
            break
        }
    }

    private var shouldShowNotificationSkip: Bool {
        alarmState == .authorized
            && notificationState == .notDetermined
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        roleText: String,
        status: String?,
        actionTitle: String?,
        secondaryActionTitle: String?,
        showsCheckmark: Bool,
        action: @escaping () -> Void,
        secondaryAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                    Text(roleText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
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
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        permissionButtons(
                            actionTitle: actionTitle,
                            secondaryActionTitle: secondaryActionTitle,
                            action: action,
                            secondaryAction: secondaryAction
                        )
                    }
                    VStack(spacing: 10) {
                        permissionButtons(
                            actionTitle: actionTitle,
                            secondaryActionTitle: secondaryActionTitle,
                            action: action,
                            secondaryAction: secondaryAction
                        )
                    }
                }
            }
        }
        .padding(OnboardingSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityHint(roleText == "Required" ? "Required before Subh can prepare your first wake." : "Recommended. You can skip this for now.")
    }

    @ViewBuilder
    private func permissionButtons(
        actionTitle: String?,
        secondaryActionTitle: String?,
        action: @escaping () -> Void,
        secondaryAction: @escaping () -> Void
    ) -> some View {
        if let actionTitle {
            Button(actionTitle, action: action)
                .onboardingPrimaryButton()
        }
        if let secondaryActionTitle {
            Button(secondaryActionTitle, action: secondaryAction)
                .onboardingSecondaryButton()
        }
    }
}

private struct SuccessStep: View {
    let title: String
    let descriptionText: String
    let preview: OnboardingTomorrowPreview
    let relationshipText: String
    let wakeLabel: String
    let readyState: OnboardingReadyState
    let isWorking: Bool
    let primaryActionTitle: String
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
            Label(title, systemImage: readyState == .blocked ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.title2.weight(.bold))
                .accessibilityAddTraits(.isHeader)

            if readyState == .blocked {
                InfoBanner(systemImage: "alarm", text: descriptionText)
            } else {
                OnboardingMorningHeroPreview(
                    preview: preview,
                    relationshipText: relationshipText,
                    wakeLabel: wakeLabel
                )
            }

            if readyState != .blocked {
                Text(descriptionText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(isWorking ? Strings.Onboarding.successLoadingText : primaryActionTitle, action: onPrimary)
                .onboardingPrimaryButton()
                .disabled(isWorking)
                .accessibilityHint(readyState == .blocked ? "Returns to the setup step that needs attention." : "")
        }
    }
}

private struct OnboardingMorningHeroPreview: View {
    let preview: OnboardingTomorrowPreview
    let relationshipText: String
    let wakeLabel: String
    var animateRelationshipOnAppear: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showRelationship: Bool = false

    var body: some View {
        let metrics = MorningHeroMetrics(dynamicTypeSize: dynamicTypeSize)
        let display = heroDisplay

        AppGlassSurface(variant: .hero, prominence: .high, contentPadding: OnboardingSpacing.cardPadding) {
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center, spacing: OnboardingSpacing.small) {
                    Text(preview.previewLabelText)
                        .appTextRole(.eyebrow)
                        .foregroundStyle(WakeGlassTheme.tertiaryText)
                    Spacer(minLength: OnboardingSpacing.small)
                    badgeStack
                }
                .padding(.bottom, DesignTokens.spacingS)

                Text(display.locationText)
                    .font(.system(size: metrics.dateLineSize, weight: .regular))
                    .foregroundStyle(WakeGlassTheme.secondaryText.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(display.title)
                    .font(.system(size: metrics.relativeLabelSize, weight: .regular))
                    .foregroundStyle(WakeGlassTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, metrics.dateToRelativeGap)

                MorningHeroPrimaryWakeRow(
                    display: display,
                    metrics: metrics,
                    rollsActiveWakeTime: false,
                    reduceMotion: reduceMotion
                )
                .padding(.top, metrics.relativeToPrimaryGap)

                if display.fajrWindowVisualMode.rendersRange {
                    FajrWindowRangeVisual(
                        display: display,
                        metrics: metrics,
                        reduceMotion: reduceMotion
                    )
                    .allowsHitTesting(false)
                    .padding(.top, metrics.primaryToWindowGap)
                }

                MorningHeroFadingRelationText(
                    text: display.detailText,
                    tone: display.relationTone,
                    metrics: metrics,
                    reduceMotion: reduceMotion
                )
                .opacity(showRelationship ? 1 : 0)
                .padding(.top, display.fajrWindowVisualMode.rendersRange ? metrics.windowToRelationGap : metrics.primaryToRelationGap)

                if let statusText = preview.statusText {
                    Text(statusText)
                        .font(AppTypography.cardBody)
                        .foregroundStyle(WakeGlassTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, DesignTokens.spacingS)
                }
            }
            .frame(maxWidth: metrics.maxContentWidth)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .onAppear {
            guard animateRelationshipOnAppear else {
                showRelationship = true
                return
            }
            showRelationship = false
            if reduceMotion {
                showRelationship = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        showRelationship = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var badgeStack: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: OnboardingSpacing.xSmall) {
                badges
            }
            VStack(alignment: .trailing, spacing: OnboardingSpacing.xSmall) {
                badges
            }
        }
    }

    @ViewBuilder
    private var badges: some View {
        if preview.isExample {
            heroBadge(Strings.Onboarding.previewLabelExample)
        }
        if let alarmStatusText = preview.alarmStatusText {
            heroBadge(alarmStatusText)
        }
        if let notificationStatusText = preview.notificationStatusText {
            heroBadge(notificationStatusText)
        }
    }

    private func heroBadge(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.badge)
            .foregroundStyle(WakeGlassTheme.secondaryText)
            .lineLimit(1)
            .padding(.horizontal, DesignTokens.compactChipHorizontalPadding)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(WakeGlassTheme.chipFill)
                    .overlay {
                        Capsule().stroke(WakeGlassTheme.chipStroke, lineWidth: 1)
                    }
            )
    }

    private var heroDisplay: MorningHomeHeroDisplay {
        let hasRange = preview.fajrDate != nil && preview.fajrEndDate != nil
        let ratio = wakeWindowPositionRatio
        let location = preview.locationText ?? (preview.isExample ? Strings.Onboarding.previewExampleLocation : Strings.Onboarding.previewLocalLocation)
        let primaryText = preview.wakeTimeText ?? Strings.Onboarding.previewWakePlaceholder
        let fajrWindowAccessibilityText: String? = {
            guard let fajrTime = preview.fajrTimeText, let fajrEndTime = preview.fajrEndTimeText else { return nil }
            return "Fajr begins \(fajrTime). Fajr ends \(fajrEndTime)."
        }()

        return MorningHomeHeroDisplay(
            locationText: location,
            locationIconName: nil,
            title: preview.dateText,
            dateLine: nil,
            wakeState: preview.wakeDate == nil ? .unavailable : .active,
            primaryTime: preview.wakeDate,
            primaryText: primaryText,
            wakeIconName: "alarm",
            statusText: primaryText,
            detailText: relationshipText,
            relationTone: .normal,
            fajrWindowLine: fajrWindowAccessibilityText ?? Strings.Onboarding.previewUnavailable,
            fajrBeginDisplayText: preview.fajrTimeText,
            fajrEndDisplayText: preview.fajrEndTimeText,
            wakeWindowPositionRatio: ratio,
            wakeWindowIndicatorState: ratio == nil ? .none : .active,
            wakeWindowIndicatorIconName: "alarm.fill",
            leftBoundaryMarkerStyle: hasRange ? .verticalLine : .none,
            rightBoundaryMarkerStyle: hasRange ? .endpointCircle : .none,
            fajrWindowVisualMode: hasRange ? .staticWithinFajrWindow : .hiddenUnavailable,
            fajrWindowAccessibilityText: fajrWindowAccessibilityText,
            wakeAdjustmentEnabled: false,
            wakeAdjustmentMinTime: nil,
            wakeAdjustmentMaxTime: nil,
            wakeAdjustmentFajrEndTime: preview.fajrEndDate,
            wakeAdjustmentStepMinutes: 5,
            wakeAdjustmentRelationAnchor: .fajrEnd,
            wakeAdjustmentAccessibilityValue: nil,
            selectedQuickWakeMode: nil,
            quickWakeModeOptions: [],
            chipTitles: [],
            accessibilityLabel: accessibilityLabel
        )
    }

    private var wakeWindowPositionRatio: Double? {
        guard
            let begin = preview.fajrDate,
            let end = preview.fajrEndDate,
            let wake = preview.wakeDate,
            end > begin
        else {
            return nil
        }

        return min(1, max(0, wake.timeIntervalSince(begin) / end.timeIntervalSince(begin)))
    }

    private var accessibilityLabel: String {
        [
            preview.isExample ? Strings.Onboarding.previewLabelExample : nil,
            "\(preview.dateText) morning",
            preview.wakeTimeText.map { "\(wakeLabel) at \($0)" },
            relationshipText,
            preview.locationText,
            preview.alarmStatusText,
            preview.notificationStatusText,
            preview.statusText
        ]
            .compactMap { $0 }
            .joined(separator: ". ")
    }
}

private struct OnboardingCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(OnboardingSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: OnboardingSpacing.cardCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: OnboardingSpacing.cardCornerRadius, style: .continuous)
                            .fill(Color.black.opacity(0.18))
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingSpacing.cardCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
            .appControlStyle(.primary, tint: DawnColor.accent)
            .buttonBorderShape(.roundedRectangle(radius: OnboardingSpacing.buttonCornerRadius))
            .controlSize(.large)
            .frame(minHeight: OnboardingSpacing.tapTargetMin)
    }

    func onboardingSecondaryButton() -> some View {
        self
            .appControlStyle(.secondary)
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
#Preview("Fajr Value") {
    ValuePreviewStep(
        title: Strings.Onboarding.valueTitle,
        descriptionText: Strings.Onboarding.valueBody,
        supportText: Strings.Onboarding.valueSupport,
        preview: OnboardingTomorrowPreview(
            previewLabelText: Strings.Onboarding.previewLabelExample,
            dateText: "Today",
            locationText: Strings.Onboarding.previewExampleLocation,
            isExample: true,
            targetDate: Date(),
            fajrDate: Date(),
            fajrEndDate: Date().addingTimeInterval(57 * 60),
            wakeDate: Date().addingTimeInterval(-30 * 60),
            fajrTimeText: "4:30 AM",
            fajrEndTimeText: "5:27 AM",
            wakeTimeText: "4:57 AM",
            statusText: nil
        ),
        relationshipText: Strings.Onboarding.previewRelationshipText,
        primaryTitle: Strings.Onboarding.valuePrimaryAction,
        wakeLabel: Strings.Onboarding.previewWakeLabel,
        onPrimary: {}
    )
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}
#endif
