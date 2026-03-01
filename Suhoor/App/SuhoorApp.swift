import SwiftUI
import UserNotifications

@main
struct SuhoorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settingsStore: SuhoorSettingsStore
    @StateObject private var alarmConfigStore: AlarmConfigStore
    @StateObject private var locationService: LocationService
    @StateObject private var scheduleManager: ScheduleManager

    @Environment(\.scenePhase) private var scenePhase

    init() {
        let settingsStore = SuhoorSettingsStore()
        let alarmConfigStore = AlarmConfigStore(legacySettings: settingsStore.settings)
        let locationService = LocationService()
        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore
        )
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
                .tint(.orange)
                .environmentObject(settingsStore)
                .environmentObject(alarmConfigStore)
                .environmentObject(locationService)
                .environmentObject(scheduleManager)
                .task {
                    await scheduleManager.ensureScheduleWindow(reason: .appLaunch)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task { await scheduleManager.ensureScheduleWindow(reason: .foreground) }
                    }
                }
                .onChange(of: locationService.lastLocation) { _, _ in
                    Task { await scheduleManager.ensureScheduleWindow(reason: .locationUpdated) }
                }
        }
    }
}
