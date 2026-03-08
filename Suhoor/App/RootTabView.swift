import SwiftUI

enum RootTab: Hashable {
    case home
    case schedule
    case plans
    case progress
    case settings
}

enum SettingsRoute: Hashable {
    case hijriCorrections
}

struct RootTabView: View {
    @State private var selectedTab: RootTab = .home
    @State private var settingsPath = NavigationPath()
    @State private var planPath = NavigationPath()
    @State private var isShowingQadaWizard = false

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
                Label("Schedule", systemImage: "alarm")
            }
            .tag(RootTab.schedule)

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

            NavigationStack(path: $settingsPath) {
                SettingsRootView()
                    .navigationDestination(for: SettingsRoute.self) { destination in
                        switch destination {
                        case .hijriCorrections:
                            HijriCalendarSettingsView()
                        }
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(RootTab.settings)
        }
        .fullScreenCover(isPresented: $isShowingQadaWizard) {
            NavigationStack {
                QadaPlannerView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToAlarmTab)) { _ in
            selectedTab = .schedule
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
            selectedTab = .settings
            settingsPath.removeLast(settingsPath.count)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToHijriCorrections)) { _ in
            selectedTab = .settings
            settingsPath.removeLast(settingsPath.count)
            settingsPath.append(SettingsRoute.hijriCorrections)
        }
    }
}
