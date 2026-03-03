import Combine
import Foundation
import MapKit
import SwiftUI
import UIKit

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case welcome
        case location
        case alarmKit
        case notifications
        case offset
        case confirmation
    }

    @Published private(set) var step: Step = .welcome
    @Published private(set) var previousStep: Step?
    @Published private(set) var permissionStates: [AppPermissionKind: AppPermissionState] = [:]
    @Published private(set) var isScheduleReady = false
    @Published private(set) var isWorking = false
    @Published private(set) var locationMode: LocationMode = .auto
    @Published private(set) var locationName: String?
    @Published private(set) var hasFixedLocation = false
    @Published private(set) var alarmKitRequestable = false
    @Published private(set) var lastEnableFailureMessage: String?

    private weak var scheduleManager: ScheduleManager?
    private weak var locationService: LocationService?
    private weak var settingsStore: SuhoorSettingsStore?
    private var refreshTask: Task<Void, Never>?
    private var hasLoaded = false
    private var hasRequestedSchedule = false
    private var useShortFlow = false

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
        alarmKitRequestable = scheduleManager.canRequestAlarmKitAuthorization
        syncSettings()
        updateScheduleReadiness()
        skipIfNeeded()
        isWorking = false
    }

    func updateFromSnapshot() {
        guard let scheduleManager else { return }
        permissionStates = scheduleManager.permissionSnapshot.presentations.mapValues(\.state)
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
        guard isLocationReady, isNotificationsReady else { return }
        guard !hasRequestedSchedule else { return }
        hasRequestedSchedule = true
        scheduleManager.requestRefresh(reason: .settingsChanged)
    }

    func goTo(_ newStep: Step) {
        guard newStep != step else { return }
        withAnimation(.easeInOut) {
            previousStep = step
            step = newStep
        }
    }

    func advance() {
        guard let next = nextStep(after: step) else { return }
        guard let resolved = resolvedStep(startingAt: next) else { return }
        goTo(resolved)
    }

    func requestLocation() {
        guard let locationService else { return }
        if locationState == .needsFollowUp {
            locationService.requestLocation()
        } else {
            locationService.requestAuthorization()
        }
        refreshPermissionsInBackground()
    }

    func requestAlarmKit() {
        Task {
            guard let scheduleManager else { return }
            _ = await scheduleManager.requestAlarmAuthorization()
            await refreshPermissions()
        }
    }

    func requestNotifications() {
        Task {
            guard let scheduleManager else { return }
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

    func enableRoutineAndContinue() {
        Task {
            guard let scheduleManager else { return }
            lastEnableFailureMessage = nil
            let enabled = await scheduleManager.enableFromUserAction(markConfigured: false)
            lastEnableFailureMessage = scheduleManager.lastEnableFailureMessage
            guard enabled else { return }
            goTo(.confirmation)
        }
    }

    func markOnboardingComplete() {
        settingsStore?.update { draft in
            draft.isConfigured = true
        }
    }

    var stepIndex: Int { step.rawValue }
    var stepCount: Int { Step.allCases.count }

    var progressIndex: Int {
        if useShortFlow {
            switch step {
            case .location: return 0
            case .alarmKit: return 1
            case .notifications: return 2
            default: return 0
            }
        }
        return stepIndex
    }

    var progressCount: Int {
        useShortFlow ? 3 : stepCount
    }

    var transition: AnyTransition {
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

    var isConfigured: Bool {
        settingsStore?.settings.isConfigured ?? false
    }

    var shouldShowAlarmKitFallback: Bool {
        alarmKitState == .unavailable
    }

    private func skipIfNeeded() {
        guard let resolved = resolvedStep(startingAt: step) else { return }
        guard resolved != step else { return }
        goTo(resolved)
    }

    private func resolvedStep(startingAt start: Step) -> Step? {
        var candidate: Step? = start
        while let current = candidate, shouldSkip(current) {
            candidate = nextStep(after: current)
        }
        return candidate
    }

    private func nextStep(after step: Step) -> Step? {
        if useShortFlow, step == .notifications {
            return nil
        }
        return step.next
    }

    private func shouldSkip(_ step: Step) -> Bool {
        switch step {
        case .welcome:
            return false
        case .location:
            return isLocationReady
        case .alarmKit:
            return alarmKitState == .authorized || alarmKitState == .unavailable
        case .notifications:
            return isNotificationsReady
        case .offset:
            return useShortFlow
        case .confirmation:
            return useShortFlow
        }
    }

    private func updateInitialStep() {
        guard useShortFlow else {
            step = .welcome
            previousStep = nil
            return
        }
        if (locationMode == .auto && locationState != .authorized)
            || (locationMode == .fixed && !hasFixedLocation) {
            step = .location
        } else if !isNotificationsReady {
            step = .notifications
        } else {
            step = .notifications
        }
        previousStep = nil
    }
}

private extension OnboardingViewModel.Step {
    var next: OnboardingViewModel.Step? {
        switch self {
        case .welcome: return .location
        case .location: return .alarmKit
        case .alarmKit: return .notifications
        case .notifications: return .offset
        case .offset: return .confirmation
        case .confirmation: return nil
        }
    }
}
