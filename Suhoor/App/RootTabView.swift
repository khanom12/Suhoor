import SwiftUI

enum RootTab: Hashable {
    case home
    case wake
    case plans
    case progress
}

enum SettingsRoute: Hashable {
    case hijriCorrections
}

struct RootTabView: View {
    @State private var selectedTab: RootTab = .home
    @State private var settingsPath = NavigationPath()
    @State private var planPath = NavigationPath()
    @State private var isShowingQadaWizard = false
    @State private var isShowingSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayHomeView()
            }
            .tabItem {
                Label("Home", systemImage: "sparkles")
            }
            .tag(RootTab.home)

            NavigationStack {
                AlarmsHomeView()
            }
            .tabItem {
                Label("Wake", systemImage: "alarm")
            }
            .tag(RootTab.wake)

            NavigationStack(path: $planPath) {
                PlanRootView()
                    .navigationDestination(for: PlanDestination.self) { destination in
                        switch destination {
                        case .defaultMorningPlan:
                            DefaultAlarmsSettingsView()
                        case .qadaPlanner:
                            QadaPlannerView()
                        case .shawwalPlanner:
                            ShawwalPlannerView()
                        case .sunnahPlanner:
                            PlanSunnahView()
                        case .calendar:
                            PlanCalendarView()
                        case .dhulHijjah:
                            PlanDhulHijjahView()
                        case .arafah:
                            PlanArafahView()
                        case .ashura:
                            PlanAshuraView()
                        case .whiteDays:
                            PlanWhiteDaysView()
                        case .mondayThursday:
                            PlanMondayThursdayView()
                        case .others:
                            PlanOthersView()
                        }
                    }
            }
            .tabItem {
                Label("Plans", systemImage: "calendar")
            }
            .tag(RootTab.plans)

            NavigationStack {
                ProgressRootView()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(RootTab.progress)
        }
        .fullScreenCover(isPresented: $isShowingQadaWizard) {
            NavigationStack {
                QadaPlannerView()
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack(path: $settingsPath) {
                SettingsRootView()
                    .navigationDestination(for: SettingsRoute.self) { destination in
                        switch destination {
                        case .hijriCorrections:
                            HijriCalendarSettingsView()
                        }
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToWakeTab)) { _ in
            selectedTab = .wake
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToAlarmTab)) { _ in
            selectedTab = .wake
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToPlanTab)) { _ in
            selectedTab = .plans
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlanHome)) { _ in
            selectedTab = .plans
            planPath.removeLast(planPath.count)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlanDefaultMorningPlan)) { _ in
            selectedTab = .plans
            planPath.removeLast(planPath.count)
            planPath.append(PlanDestination.defaultMorningPlan)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlanQada)) { _ in
            selectedTab = .plans
            planPath.removeLast(planPath.count)
            isShowingQadaWizard = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlanShawwal)) { _ in
            selectedTab = .plans
            planPath.removeLast(planPath.count)
            planPath.append(PlanDestination.shawwalPlanner)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlanSunnah)) { _ in
            selectedTab = .plans
            planPath.removeLast(planPath.count)
            planPath.append(PlanDestination.sunnahPlanner)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToSettingsTab)) { _ in
            // Compatibility alias: legacy callers still post this notification name,
            // but Settings is now presented as a utility destination, not selected as a tab.
            presentSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToHijriCorrections)) { _ in
            // Compatibility alias for directly opening Hijri corrections inside Settings.
            presentSettings(route: .hijriCorrections)
        }
    }

    private func presentSettings(route: SettingsRoute? = nil) {
        settingsPath.removeLast(settingsPath.count)
        if let route {
            settingsPath.append(route)
        }
        isShowingSettings = true
    }
}
