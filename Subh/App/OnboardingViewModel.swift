import Combine
import Foundation
import MapKit
import SwiftUI
import UIKit

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var step: OnboardingStep = .valuePreview
    @Published private(set) var previousStep: OnboardingStep?
    @Published private(set) var onboardingPath: OnboardingPath = .fajr
    @Published private(set) var permissionStates: [AppPermissionKind: AppPermissionState] = [:]
    @Published private(set) var isScheduleReady = false
    @Published private(set) var isWorking = false
    @Published private(set) var locationMode: LocationMode = .auto
    @Published private(set) var locationName: String?
    @Published private(set) var hasFixedLocation = false
    @Published private(set) var alarmKitRequestable = false
    @Published private(set) var isReviewingBack = false
    @Published private(set) var activationState: OnboardingActivationState = .idle

    private weak var scheduleManager: ScheduleManager?
    private weak var locationService: LocationService?
    private weak var settingsStore: SuhoorSettingsStore?
    private var refreshTask: Task<Void, Never>?
    private var hasLoaded = false
    private var hasRequestedSchedule = false
    private var useShortFlow = false
    private var lastPermissionStates: [AppPermissionKind: AppPermissionState] = [:]
    private var lastLoggedOffsetMinutes: Int?

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
        resolveOnboardingPath()
        OnboardingAnalytics.log("onboarding_started")
        OnboardingAnalytics.log("onboarding_path_selected", properties: ["path": onboardingPath.rawValue])
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
        activationAttemptIfNeeded()
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
        activationAttemptIfNeeded()
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
        if isLocationReady {
            goTo(.relationship, animation: animation)
        } else {
            goTo(.location, animation: animation)
        }
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

    func handleOffsetChanged(_ minutes: Int) {
        guard step == .relationship else { return }
        if lastLoggedOffsetMinutes != minutes {
            lastLoggedOffsetMinutes = minutes
            OnboardingAnalytics.log("offset_selected", properties: ["minutes": "\(minutes)"])
        }
        activationAttempt()
    }

    func activationAttempt() {
        guard activationState != .attempting else { return }
        guard isLocationReady, isSchedulingReady else { return }
        activationState = .attempting
        Task {
            guard let scheduleManager else {
                activationState = .failed(message: "Wake preview unavailable.")
                return
            }
            let result = await scheduleManager.scheduleTomorrowActivation()
            if result.success, let schedule = result.schedule {
                activationState = .succeeded(schedule: schedule)
                OnboardingAnalytics.log("activation_scheduled_success")
            } else {
                activationState = .failed(message: result.message)
                OnboardingAnalytics.log("activation_scheduled_fail", properties: ["reason": result.message])
            }
        }
    }

    private func activationAttemptIfNeeded() {
        if case .succeeded = activationState { return }
        guard step == .relationship || step == .permissions else { return }
        guard isLocationReady, isSchedulingReady else { return }
        activationAttempt()
    }

    func markOnboardingComplete() {
        settingsStore?.update { draft in
            draft.isConfigured = true
        }
        OnboardingAnalytics.log("onboarding_completed")
        scheduleManager?.requestRefresh(reason: .settingsChanged)
        refreshPermissionsInBackground()
    }

    func markOnboardingCompleteAndOpenPlans() {
        markOnboardingComplete()
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

    var valueTitleText: String { onboardingPath.valueTitle }
    var valueBodyText: String { onboardingPath.valueBody }
    var previewWakeLabelText: String { onboardingPath.previewWakeLabel }
    var locationTitleText: String { onboardingPath.locationTitle }
    var locationBodyText: String { onboardingPath.locationBody }
    var locationTrustBullets: [String] { onboardingPath.locationTrustBullets }
    var showsCalculationMethodSummary: Bool { onboardingPath.showsCalculationMethodSummary }
    var relationshipTitleText: String { onboardingPath.relationshipTitle }
    var relationshipBodyText: String { onboardingPath.relationshipBody }
    var relationshipPresetLabels: [Int: String] { onboardingPath.relationshipPresetLabels }
    var supportBehaviorTitleText: String { onboardingPath.supportBehaviorTitle }
    var supportBehaviorBodyText: String { onboardingPath.supportBehaviorBody }
    var permissionsTitleText: String { onboardingPath.permissionsTitle }
    var permissionsBodyText: String { onboardingPath.permissionsBody }
    var showNotificationsRowInPermissions: Bool { onboardingPath.alwaysShowNotificationsRow || isNotificationsRequired }
    var successTitleText: String { onboardingPath.successTitle }
    var successBodyText: String { onboardingPath.successBody }
    var successPrimaryActionTitle: String { onboardingPath.successPrimaryActionTitle }
    var successSecondaryActionTitle: String? { onboardingPath.successSecondaryActionTitle }
    var calculationMethodName: String {
        settingsStore?.settings.calculationMethod.displayName
            ?? CalculationMethod.defaultForTimeZone(.current).displayName
    }
    var relationshipSentenceText: (Int) -> String {
        { [onboardingPath] minutes in
            onboardingPath.relationshipSentence(minutes)
        }
    }
    var wakeSupportSummaryText: String {
        "\(selectedOffsetMinutes) min before Fajr"
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

    var next5DaysSchedule: [SchedulePreviewRow] {
        guard let scheduleManager else { return [] }
        let calendar = Calendar.current
        let startDate = nextAlarmStartDay
        var rows: [SchedulePreviewRow] = []
        var dayOffset = 0
        while rows.count < 5 && dayOffset < 21 {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: startDate) ?? startDate
            if let schedule = scheduleManager.schedule(for: day) {
                let suhoor = schedule.wakeDate
                rows.append(
                    SchedulePreviewRow(
                        id: DateHelpers.dayIdentifier(for: day, timeZone: .current),
                        date: day,
                        dayLabel: dayLabel(for: day),
                        fajr: schedule.fajrDate,
                        suhoor: suhoor
                    )
                )
            }
            dayOffset += 1
        }
        return rows
    }

    var selectedOffsetMinutes: Int {
        settingsStore?.settings.baseWakeOffsetMinutes ?? 60
    }

    var computedFajrTime: Date? {
        tomorrowPreview.fajrDate
    }

    var computedSuhoorAlarmTime: Date? {
        tomorrowPreview.suhoorDate
    }

    var valuePrimaryActionTitle: String {
        onboardingPath.valuePrimaryActionTitle(for: nextAlarmDisplayLabel(for: nextAlarmStartDay))
    }

    var successSchedule: DaySchedule? {
        switch activationState {
        case .succeeded(let schedule):
            return schedule
        default:
            let tomorrow = DateHelpers.startOfTomorrow(in: .current)
            return scheduleManager?.schedule(for: tomorrow)
        }
    }

    var flowSteps: [OnboardingStep] {
        if useShortFlow {
            let missing = missingShortFlowSteps
            return missing.isEmpty ? [.success] : (missing + [.success])
        }

        return onboardingPath.flowSteps
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
        case .relationship:
            return useShortFlow
        case .supportBehavior:
            return useShortFlow
        case .futureVisualization:
            return useShortFlow
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
        case .relationship:
            return "relationship"
        case .supportBehavior:
            return "support_behavior"
        case .futureVisualization:
            return "future_visualization"
        case .permissions:
            return "permissions"
        case .success:
            return "success"
        }
    }

    private func resolveOnboardingPath() {
        let hijriMonth = scheduleManager?.currentHijriYearMonth(date: Date())?.month
        onboardingPath = OnboardingPath.resolve(currentHijriMonth: hijriMonth)
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
