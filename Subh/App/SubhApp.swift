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
        DeveloperInstallReset.resetIfNeeded {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        #endif

        let appNavigator = AppNavigator()
        let settingsStore = SuhoorSettingsStore()
        let alarmConfigStore = AlarmConfigStore(legacySettings: settingsStore.settings)
        let locationService = LocationService()
        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            usesLegacyContexts: false
        )
        _appNavigator = StateObject(wrappedValue: appNavigator)
        _settingsStore = StateObject(wrappedValue: settingsStore)
        _alarmConfigStore = StateObject(wrappedValue: alarmConfigStore)
        _locationService = StateObject(wrappedValue: locationService)
        _scheduleManager = StateObject(wrappedValue: scheduleManager)
        UNUserNotificationCenter.current().delegate = NotificationEventDelegate.shared
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
        }
    }
}
