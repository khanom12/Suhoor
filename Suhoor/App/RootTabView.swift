import Combine
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
    @EnvironmentObject private var appNavigator: AppNavigator
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
        .onReceive(appNavigator.$latestRequest.compactMap { $0 }) { request in
            handle(request.intent)
        }
    }

    private func presentSettings(route: SettingsRoute? = nil) {
        settingsPath.removeLast(settingsPath.count)
        if let route {
            settingsPath.append(route)
        }
        isShowingSettings = true
    }

    private func handle(_ intent: AppNavigationIntent) {
        switch intent {
        case .switchToWake:
            selectedTab = .wake
        case .switchToPlans:
            selectedTab = .plans
            planPath.removeLast(planPath.count)
        case .openSettings:
            presentSettings()
        case .openHijriCorrections:
            presentSettings(route: .hijriCorrections)
        case .openDefaultMorningPlan:
            selectedTab = .plans
            planPath.removeLast(planPath.count)
            planPath.append(PlanDestination.defaultMorningPlan)
        case .openQadaPlanner:
            selectedTab = .plans
            planPath.removeLast(planPath.count)
            isShowingQadaWizard = true
        case .openShawwalPlanner:
            selectedTab = .plans
            planPath.removeLast(planPath.count)
            planPath.append(PlanDestination.shawwalPlanner)
        case .openSunnahPlanner:
            selectedTab = .plans
            planPath.removeLast(planPath.count)
            planPath.append(PlanDestination.sunnahPlanner)
        }
    }
}
