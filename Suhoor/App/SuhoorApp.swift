import SwiftUI
import UserNotifications

@main
struct SuhoorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settingsStore: SuhoorSettingsStore
    @StateObject private var alarmConfigStore: AlarmConfigStore
    @StateObject private var locationService: LocationService
    @StateObject private var scheduleManager: ScheduleManager
    @StateObject private var fastTagStore: FastTagStore
    @StateObject private var fastLogStore: FastLogStore
    @StateObject private var qadaBacklogStore: QadaBacklogStore
    @StateObject private var qadaBatchStore: QadaBatchStore

    @Environment(\.scenePhase) private var scenePhase

    init() {
        let settingsStore = SuhoorSettingsStore()
        let alarmConfigStore = AlarmConfigStore(legacySettings: settingsStore.settings)
        let locationService = LocationService()
        let fastTagStore = FastTagStore()
        let fastLogStore = FastLogStore()
        let qadaBacklogStore = QadaBacklogStore()
        let qadaBatchStore = QadaBatchStore()
        let scheduleManager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: locationService,
            alarmConfigStore: alarmConfigStore,
            fastTagStore: fastTagStore
        )
        _settingsStore = StateObject(wrappedValue: settingsStore)
        _alarmConfigStore = StateObject(wrappedValue: alarmConfigStore)
        _locationService = StateObject(wrappedValue: locationService)
        _scheduleManager = StateObject(wrappedValue: scheduleManager)
        _fastTagStore = StateObject(wrappedValue: fastTagStore)
        _fastLogStore = StateObject(wrappedValue: fastLogStore)
        _qadaBacklogStore = StateObject(wrappedValue: qadaBacklogStore)
        _qadaBatchStore = StateObject(wrappedValue: qadaBatchStore)
        fastLogStore.normalizeStaleInProgress(todayKey: DateHelpers.dayIdentifier(for: Date(), timeZone: .current))
        UNUserNotificationCenter.current().delegate = NotificationEventDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Avoid global button/control group styles here; toolbars auto-group and can add unwanted capsules.
                .tint(DawnColor.accent)
                .environmentObject(settingsStore)
                .environmentObject(alarmConfigStore)
                .environmentObject(locationService)
                .environmentObject(scheduleManager)
                .environmentObject(fastTagStore)
                .environmentObject(fastLogStore)
                .environmentObject(qadaBacklogStore)
                .environmentObject(qadaBatchStore)
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
