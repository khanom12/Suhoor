import Combine
import Foundation
import MapKit
import SwiftUI
import UIKit

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var step: OnboardingStep = .valuePreview
    @Published private(set) var previousStep: OnboardingStep?
    @Published private(set) var permissionStates: [AppPermissionKind: AppPermissionState] = [:]
    @Published private(set) var isScheduleReady = false
    @Published private(set) var isWorking = false
    @Published private(set) var locationMode: LocationMode = .auto
    @Published private(set) var locationName: String?
    @Published private(set) var hasFixedLocation = false
    @Published private(set) var alarmKitRequestable = false
    @Published private(set) var isReviewingBack = false

    private weak var scheduleManager: ScheduleManager?
    private weak var locationService: LocationService?
    private weak var settingsStore: SuhoorSettingsStore?
    private var refreshTask: Task<Void, Never>?
    private var hasLoaded = false
    private var hasRequestedSchedule = false
    private var useShortFlow = false
    private var lastPermissionStates: [AppPermissionKind: AppPermissionState] = [:]

    func bind(
        scheduleManager: ScheduleManager,
        locationService: LocationService,
        settingsStore: SuhoorSettingsStore
    ) {
        guard self.scheduleManager !== scheduleManager else { return }
        self.scheduleManager = scheduleManager
        self.locationService = locationService
        self.settingsStore = settingsStore
        syncSettings()
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        useShortFlow = settingsStore?.settings.isConfigured ?? false
        OnboardingAnalytics.log("onboarding_started")
        await refreshPermissions()
        updateInitialStep()
    }

    func refreshPermissionsInBackground() {
        refreshTask?.cancel()
        refreshTask = Task { await refreshPermissions() }
    }

    func refreshPermissions() async {
        guard let scheduleManager else { return }
        isWorking = true
        await scheduleManager.refreshPermissionSummary()
        guard !Task.isCancelled else {
            isWorking = false
            return
        }
        permissionStates = scheduleManager.permissionSnapshot.presentations.mapValues(\.state)
        logPermissionTransitions(from: lastPermissionStates, to: permissionStates)
        lastPermissionStates = permissionStates
        alarmKitRequestable = scheduleManager.canRequestAlarmKitAuthorization
        syncSettings()
        updateScheduleReadiness()
        skipIfNeeded()
        isWorking = false
    }

    func updateFromSnapshot() {
        guard let scheduleManager else { return }
        permissionStates = scheduleManager.permissionSnapshot.presentations.mapValues(\.state)
        logPermissionTransitions(from: lastPermissionStates, to: permissionStates)
        lastPermissionStates = permissionStates
        alarmKitRequestable = scheduleManager.canRequestAlarmKitAuthorization
        syncSettings()
        updateScheduleReadiness()
        skipIfNeeded()
    }

    func syncSettings() {
        guard let settingsStore, let locationService else { return }
        locationMode = settingsStore.settings.locationMode
        hasFixedLocation = settingsStore.settings.fixedLocation != nil
        locationName = SettingsSummaryFormatter.effectiveLocationName(
            settings: settingsStore.settings,
            locationService: locationService
        )
        skipIfNeeded()
    }

    func updateScheduleReadiness() {
        guard let scheduleManager else { return }
        let ready = !scheduleManager.activeWindowSnapshot.visibleDays.isEmpty
        isScheduleReady = ready
        guard !ready else {
            hasRequestedSchedule = false
            return
        }
        guard isLocationReady, isSchedulingReady else { return }
        guard !hasRequestedSchedule else { return }
        hasRequestedSchedule = true
        scheduleManager.requestRefresh(reason: .settingsChanged)
    }

    func goTo(_ newStep: OnboardingStep, animation: Animation?) {
        guard newStep != step else { return }
        isReviewingBack = false
        if let animation {
            withAnimation(animation) {
                previousStep = step
                step = newStep
            }
        } else {
            previousStep = step
            step = newStep
        }
        logStepViewed(step: newStep)
    }

    func advance(animation: Animation?) {
        guard let next = nextStep(after: step) else { return }
        guard let resolved = resolvedStep(startingAt: next) else { return }
        goTo(resolved, animation: animation)
    }

    func goBack(animation: Animation?) {
        guard let currentIndex = flowSteps.firstIndex(of: step), currentIndex > 0 else { return }
        let previous = flowSteps[currentIndex - 1]
        isReviewingBack = true
        if let animation {
            withAnimation(animation) {
                previousStep = step
                step = previous
            }
        } else {
            previousStep = step
            step = previous
        }
    }

    func startFlow(animation: Animation?) {
        let next: OnboardingStep = isLocationReady ? .permissions : .location
        goTo(resolvedStep(startingAt: next) ?? .success, animation: animation)
    }

    func handleExplore(animation: Animation?) {
        if isConfigured && isLocationReady && isSchedulingReady {
            markOnboardingComplete()
        } else {
            startFlow(animation: animation)
        }
    }

    func requestLocation() {
        guard let locationService else { return }

        if locationMode != .auto {
            settingsStore?.update { draft in
                draft.locationMode = .auto
            }
            scheduleManager?.requestRefresh(reason: .settingsChanged)
            syncSettings()
        }

        OnboardingAnalytics.log("location_selected")
        OnboardingAnalytics.log("permission_location_prompted")
        if locationState == .notDetermined {
            locationService.requestAuthorization()
        } else {
            locationService.requestLocation()
        }
        refreshPermissionsInBackground()
    }

    func requestAlarmKit() {
        Task {
            guard let scheduleManager else { return }
            OnboardingAnalytics.log("permission_alarm_prompted")
            _ = await scheduleManager.requestAlarmAuthorization()
            await refreshPermissions()
        }
    }

    func requestNotifications() {
        Task {
            guard let scheduleManager else { return }
            OnboardingAnalytics.log("permission_notifications_prompted")
            _ = await scheduleManager.requestNotificationAuthorization()
            await refreshPermissions()
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func chooseCity(_ city: City) {
        guard let settingsStore, let locationService, let scheduleManager else { return }
        OnboardingAnalytics.log("city_selected", properties: ["name": city.name])
        locationService.locationName = city.name
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: city.latitude, longitude: city.longitude)
        }
        scheduleManager.requestRefresh(reason: .settingsChanged)
        syncSettings()
        refreshPermissionsInBackground()
    }

    func chooseMapItem(_ mapItem: MKMapItem) {
        guard let settingsStore, let locationService, let scheduleManager else { return }
        let coordinate = mapItem.location.coordinate
        if let city = mapItem.addressRepresentations?.cityName ?? mapItem.name {
            OnboardingAnalytics.log("city_selected", properties: ["name": city])
            locationService.locationName = city
        }
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        scheduleManager.requestRefresh(reason: .settingsChanged)
        syncSettings()
        refreshPermissionsInBackground()
    }

    func markOnboardingComplete() {
        settingsStore?.update { draft in
            draft.isConfigured = true
        }
        OnboardingAnalytics.log("onboarding_completed")
        scheduleManager?.requestRefresh(reason: .settingsChanged)
        refreshPermissionsInBackground()
    }

    var progressIndex: Int {
        flowSteps.firstIndex(of: step) ?? 0
    }

    var progressCount: Int {
        flowSteps.count
    }

    var canGoBack: Bool {
        (flowSteps.firstIndex(of: step) ?? 0) > 0
    }

    var shouldShowProgress: Bool {
        !useShortFlow && step != .success
    }

    var shouldShowManualAdvanceForCurrentStep: Bool {
        isReviewingBack && shouldSkip(step)
    }

    var valueTitleText: String { "Wake for and around Fajr" }
    var valueBodyText: String {
        "Subh resolves your next morning from local Fajr times and keeps the main wake anchored to the supported Fajr end."
    }
    var previewWakeLabelText: String { "Next wake" }
    var wakeRelationshipText: String { "30 min before supported Fajr end" }
    var locationTitleText: String { "Trust your local prayer times" }
    var locationBodyText: String {
        "Your morning plan follows local Fajr times. Use your location or choose a city, and change the calculation method if needed."
    }
    var locationTrustBullets: [String] {
        [
            "Used to calculate accurate local prayer times",
            "Change your city or method anytime"
        ]
    }
    var showsCalculationMethodSummary: Bool { true }
    var permissionsTitleText: String { "Keep your wake reliable" }
    var permissionsBodyText: String {
        "Alarm access helps your main wake ring reliably around Fajr. Notifications support reminders and fallback delivery where needed."
    }
    var showNotificationsRowInPermissions: Bool { true }
    var successTitleText: String { "Your morning plan is ready" }
    var successBodyText: String {
        "Your next wake is set from the shared Subh resolver, 30 minutes before the supported Fajr end."
    }
    var successPrimaryActionTitle: String { "Go to Home" }
    var calculationMethodName: String {
        settingsStore?.settings.calculationMethod.displayName
            ?? CalculationMethod.defaultForTimeZone(.current).displayName
    }
    var reminderMinutesOptions: [Int] { [5, 10, 15, 20, 30] }

    var tomorrowPreview: OnboardingTomorrowPreview {
        let targetDay = nextAlarmStartDay
        let dateText = nextAlarmDisplayLabel(for: targetDay)
        guard let schedule = scheduleManager?.schedule(for: targetDay) else {
            let statusText = isLocationReady
                ? Strings.Onboarding.previewUnavailable
                : Strings.Onboarding.previewNeedsLocation
            return OnboardingTomorrowPreview(
                dateText: dateText,
                targetDate: nil,
                fajrDate: nil,
                suhoorDate: nil,
                fajrTimeText: nil,
                suhoorTimeText: nil,
                statusText: statusText
            )
        }

        let wakeDate = schedule.wakeDate
        let fajrTime = TimeFormatters.timeFormatter.string(from: schedule.fajrDate)
        let suhoorTime = TimeFormatters.timeFormatter.string(from: wakeDate)
        return OnboardingTomorrowPreview(
            dateText: dateText,
            targetDate: targetDay,
            fajrDate: schedule.fajrDate,
            suhoorDate: wakeDate,
            fajrTimeText: fajrTime,
            suhoorTimeText: suhoorTime,
            statusText: nil
        )
    }

    var valueScreenPreview: OnboardingTomorrowPreview {
        let targetDay = nextAlarmStartDay
        let label = nextAlarmDisplayLabel(for: targetDay)
        if isLocationReady, let schedule = scheduleManager?.schedule(for: targetDay) {
            let wakeDate = schedule.wakeDate
            let fajrTime = TimeFormatters.timeFormatter.string(from: schedule.fajrDate)
            let suhoorTime = TimeFormatters.timeFormatter.string(from: wakeDate)
            return OnboardingTomorrowPreview(
                dateText: label,
                targetDate: targetDay,
                fajrDate: schedule.fajrDate,
                suhoorDate: wakeDate,
                fajrTimeText: fajrTime,
                suhoorTimeText: suhoorTime,
                statusText: nil
            )
        }

        return OnboardingTomorrowPreview(
            dateText: label,
            targetDate: targetDay,
            fajrDate: nil,
            suhoorDate: nil,
            fajrTimeText: "5:27 AM",
            suhoorTimeText: "4:57 AM",
            statusText: nil
        )
    }

    var computedFajrTime: Date? {
        tomorrowPreview.fajrDate
    }

    var computedSuhoorAlarmTime: Date? {
        tomorrowPreview.suhoorDate
    }

    var valuePrimaryActionTitle: String {
        "Set my morning plan"
    }

    var flowSteps: [OnboardingStep] {
        if useShortFlow {
            let missing = missingShortFlowSteps
            return missing.isEmpty ? [.success] : (missing + [.success])
        }

        return [.valuePreview, .location, .permissions, .success]
    }

    private var missingShortFlowSteps: [OnboardingStep] {
        var steps: [OnboardingStep] = []
        if !isLocationReady {
            steps.append(.location)
        }
        if !isSchedulingReady {
            steps.append(.permissions)
        }
        return steps
    }

    func transition(reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        guard let previousStep else { return .opacity }
        if step.rawValue >= previousStep.rawValue {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
        return .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    var locationState: AppPermissionState { permissionStates[.location] ?? .notDetermined }
    var alarmKitState: AppPermissionState { permissionStates[.alarmKit] ?? .notDetermined }
    var notificationState: AppPermissionState { permissionStates[.notifications] ?? .notDetermined }

    var isLocationReady: Bool {
        switch locationMode {
        case .auto:
            return locationState == .authorized
        case .fixed:
            return hasFixedLocation
        }
    }

    var isNotificationsReady: Bool {
        notificationState == .authorized
    }

    var isAlarmAccessReady: Bool {
        alarmKitState == .authorized || alarmKitState == .unavailable
    }

    var isSchedulingReady: Bool {
        switch alarmKitState {
        case .authorized:
            return true
        case .unavailable:
            return isNotificationsReady
        default:
            return false
        }
    }

    var isNotificationsRequired: Bool {
        alarmKitState == .unavailable
    }

    var isConfigured: Bool {
        settingsStore?.settings.isConfigured ?? false
    }

    var shouldShowAlarmKitFallback: Bool {
        alarmKitState == .unavailable
    }

    private func skipIfNeeded() {
        guard !isReviewingBack else { return }
        guard let resolved = resolvedStep(startingAt: step) else { return }
        guard resolved != step else { return }
        goTo(resolved, animation: currentAnimation)
    }

    private func resolvedStep(startingAt start: OnboardingStep) -> OnboardingStep? {
        var candidate: OnboardingStep? = start
        while let current = candidate, shouldSkip(current) {
            candidate = nextStep(after: current)
        }
        return candidate
    }

    private func nextStep(after step: OnboardingStep) -> OnboardingStep? {
        guard let index = flowSteps.firstIndex(of: step), index + 1 < flowSteps.count else {
            return nil
        }
        return flowSteps[index + 1]
    }

    private func shouldSkip(_ step: OnboardingStep) -> Bool {
        switch step {
        case .valuePreview:
            return false
        case .location:
            return isLocationReady
        case .permissions:
            return isSchedulingReady
        case .success:
            return false
        }
    }

    private func updateInitialStep() {
        if useShortFlow {
            if missingShortFlowSteps.isEmpty {
                step = .success
            } else {
                step = flowSteps.first ?? .success
            }
        } else {
            step = .valuePreview
        }
        previousStep = nil
        logStepViewed(step: step)
    }

    private var currentAnimation: Animation? {
        UIAccessibility.isReduceMotionEnabled ? nil : .easeInOut(duration: 0.28)
    }

    private func logPermissionTransitions(
        from oldStates: [AppPermissionKind: AppPermissionState],
        to newStates: [AppPermissionKind: AppPermissionState]
    ) {
        for kind in AppPermissionKind.allCases {
            let old = oldStates[kind] ?? .notDetermined
            let new = newStates[kind] ?? .notDetermined
            guard old != new else { continue }
            let result = permissionStateLabel(new)
            switch kind {
            case .location:
                OnboardingAnalytics.log("permission_location_result", properties: ["result": result])
                if new == .authorized {
                    OnboardingAnalytics.log("permission_granted", properties: ["kind": "location"])
                }
            case .alarmKit:
                OnboardingAnalytics.log("permission_alarm_result", properties: ["result": result])
                if new == .authorized {
                    OnboardingAnalytics.log("permission_granted", properties: ["kind": "alarm"])
                }
            case .notifications:
                OnboardingAnalytics.log("permission_notifications_result", properties: ["result": result])
                if new == .authorized {
                    OnboardingAnalytics.log("permission_granted", properties: ["kind": "notifications"])
                }
            }
        }
    }

    private func permissionStateLabel(_ state: AppPermissionState) -> String {
        switch state {
        case .notDetermined:
            return "not_determined"
        case .authorized:
            return "authorized"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .unavailable:
            return "unavailable"
        case .needsFollowUp:
            return "needs_follow_up"
        }
    }

    private func logStepViewed(step: OnboardingStep) {
        OnboardingAnalytics.log("onboarding_step_viewed", properties: ["step": stepKey(step)])
    }

    private func stepKey(_ step: OnboardingStep) -> String {
        switch step {
        case .valuePreview:
            return "value"
        case .location:
            return "location"
        case .permissions:
            return "permissions"
        case .success:
            return "success"
        }
    }

    private var nextAlarmStartDay: Date {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = DateHelpers.startOfToday(in: .current)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        guard let scheduleManager else { return tomorrow }
        guard let todaySchedule = scheduleManager.schedule(for: startOfToday) else { return tomorrow }
        let todaySuhoor = todaySchedule.wakeDate
        return now < todaySuhoor ? startOfToday : tomorrow
    }

    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let today = DateHelpers.startOfToday(in: .current)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        if calendar.isDate(date, inSameDayAs: today) {
            return Strings.Onboarding.todayLabel
        }
        if calendar.isDate(date, inSameDayAs: tomorrow) {
            return Strings.Onboarding.tomorrowLabel
        }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func nextAlarmDisplayLabel(for date: Date) -> String {
        dayLabel(for: date)
    }
}
