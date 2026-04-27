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
            contentStack
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
            .sheet(isPresented: $showCalculationMethodSheet) {
                NavigationStack {
                    CalculationMethodSelectionView()
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
                isNotificationsRequired: viewModel.isNotificationsRequired,
                showNotificationsRow: viewModel.showNotificationsRowInPermissions,
                showAlarmKitFallback: viewModel.shouldShowAlarmKitFallback,
                showNextAction: viewModel.shouldShowManualAdvanceForCurrentStep,
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
                primaryActionTitle: viewModel.successPrimaryActionTitle,
                onPrimary: viewModel.markOnboardingComplete
            ))
        }
    }
}

private struct ValuePreviewStep: View {
    let title: String
    let descriptionText: String
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
            }

            OnboardingTimeCard(
                preview: preview,
                relationshipText: relationshipText,
                wakeLabel: wakeLabel,
                previewTag: Strings.Onboarding.previewTag,
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

private struct PermissionsStep: View {
    let title: String
    let descriptionText: String
    let alarmState: AppPermissionState
    let notificationState: AppPermissionState
    let isAlarmRequestable: Bool
    let isNotificationsRequired: Bool
    let showNotificationsRow: Bool
    let showAlarmKitFallback: Bool
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

private struct SuccessStep: View {
    let title: String
    let descriptionText: String
    let preview: OnboardingTomorrowPreview
    let relationshipText: String
    let wakeLabel: String
    let primaryActionTitle: String
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingSpacing.medium) {
            Label(title, systemImage: "checkmark.circle.fill")
                .font(.title2.weight(.bold))

            OnboardingTimeCard(
                preview: preview,
                relationshipText: relationshipText,
                wakeLabel: wakeLabel
            )

            Text(descriptionText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(primaryActionTitle, action: onPrimary)
                .onboardingPrimaryButton()
        }
    }
}

private struct OnboardingTimeCard: View {
    let preview: OnboardingTomorrowPreview
    let relationshipText: String
    let wakeLabel: String
    var previewTag: String? = nil
    var animateRelationshipOnAppear: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showRelationship: Bool = false

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
    }

    private var connectorLine: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(relationshipText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .accessibilityLabel(relationshipText)
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
                    label: wakeLabel,
                    value: preview.wakeTimeText ?? Strings.Onboarding.previewWakePlaceholder
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
                        label: wakeLabel,
                        value: preview.wakeTimeText ?? Strings.Onboarding.previewWakePlaceholder
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
#Preview("Fajr Value") {
    ValuePreviewStep(
        title: "Wake for and around Fajr",
        descriptionText: "Subh resolves your next morning from local Fajr times and keeps the main wake anchored to the supported Fajr end.",
        preview: OnboardingTomorrowPreview(
            dateText: "Today",
            targetDate: Date(),
            fajrDate: Date(),
            wakeDate: Date().addingTimeInterval(-30 * 60),
            fajrTimeText: "5:27 AM",
            wakeTimeText: "4:57 AM",
            statusText: nil
        ),
        relationshipText: "30 min before supported Fajr end",
        primaryTitle: "Set my morning plan",
        wakeLabel: "Next wake",
        onPrimary: {}
    )
    .padding(.horizontal, OnboardingSpacing.sidePadding)
}
#endif
