import SwiftUI
import UserNotifications

@main
struct SubhApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appNavigator: AppNavigator
    @StateObject private var settingsStore: SuhoorSettingsStore
    @StateObject private var alarmConfigStore: AlarmConfigStore
    @StateObject private var locationService: LocationService
    @StateObject private var scheduleManager: ScheduleManager

    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        UITestFixtureConfigurator.resetPersistentStateIfNeeded()
        let resetMode = DeveloperInstallReset.configuredMode()
        let didReset = DeveloperInstallReset.resetIfNeeded(mode: resetMode) {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            let didCleanAlarmKit = DebugInstallAlarmKitCleanup.cancelSubhOwnedDeliveries(days: 30)
            if !didCleanAlarmKit {
                EventTimelineLog.shared.record(
                    category: "startup",
                    message: "Debug install reset AlarmKit cleanup verification limited."
                )
            }
        }
        EventTimelineLog.shared.record(
            category: "startup",
            message: didReset
                ? "Debug install reset applied (mode=\(resetMode.rawValue))."
                : "Debug install reset skipped (mode=\(resetMode.rawValue))."
        )
        #endif

        let appNavigator = AppNavigator()
        #if DEBUG
        let timeProvider = UITestLaunchConfiguration.timeProvider
        #else
        let timeProvider = SystemTimeProvider()
        #endif
        let settingsStore = SuhoorSettingsStore()
        let alarmConfigStore = AlarmConfigStore(legacySettings: settingsStore.settings)
        #if DEBUG
        UITestFixtureConfigurator.applyIfNeeded(
            settingsStore: settingsStore,
            alarmConfigStore: alarmConfigStore,
            timeProvider: timeProvider
        )
        #endif
        let locationService = LocationService()
        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            usesLegacyContexts: false,
            timeProvider: timeProvider
        )
        _appNavigator = StateObject(wrappedValue: appNavigator)
        _settingsStore = StateObject(wrappedValue: settingsStore)
        _alarmConfigStore = StateObject(wrappedValue: alarmConfigStore)
        _locationService = StateObject(wrappedValue: locationService)
        _scheduleManager = StateObject(wrappedValue: scheduleManager)
        UNUserNotificationCenter.current().delegate = NotificationEventDelegate.shared
        NotificationEventDelegate.shared.wakeEventRecorder = { [weak scheduleManager] identifier, isResponse, timestamp in
            scheduleManager?.recordPlatformNotificationWakeEvent(
                identifier: identifier,
                isResponse: isResponse,
                timestamp: timestamp
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Avoid global button/control group styles here; toolbars auto-group and can add unwanted capsules.
                .tint(DawnColor.accent)
                .environmentObject(settingsStore)
                .environmentObject(appNavigator)
                .environmentObject(alarmConfigStore)
                .environmentObject(locationService)
                .environmentObject(scheduleManager)
                .task {
                    scheduleManager.requestRefresh(reason: .appLaunch)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        scheduleManager.requestRefresh(reason: .foreground)
                    }
                }
                .onChange(of: settingsStore.settings) { oldValue, newValue in
                    guard newValue.requiresReschedule(comparedTo: oldValue) else { return }
                    scheduleManager.requestRefresh(reason: .settingsChanged)
                }
                .onChange(of: alarmConfigStore.defaults) { _, _ in
                    scheduleManager.requestRefresh(reason: .settingsChanged)
                }
                .onChange(of: locationService.lastLocation) { _, _ in
                    scheduleManager.requestRefresh(reason: .locationUpdated)
                }
                .onChange(of: locationService.authorizationStatus) { _, _ in
                    scheduleManager.requestRefresh(reason: .locationUpdated)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    scheduleManager.requestRefresh(reason: .timeChanged)
                }
                .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
                    scheduleManager.requestRefresh(reason: .timeZoneChanged)
                }
        }
    }
}
