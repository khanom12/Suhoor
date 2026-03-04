import SwiftUI

enum RootTab: Hashable {
    case today
    case plan
    case alarms
    case profile
}

enum ProfileDestination: Hashable {
    case settings
    case hijriCorrections
}

struct RootTabView: View {
    @State private var selectedTab: RootTab = .today
    @State private var profilePath = NavigationPath()
    @State private var planPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayHomeView()
            }
            .tabItem {
                Label("Today", systemImage: "sparkles")
            }
            .tag(RootTab.today)

            NavigationStack {
                AlarmsHomeView()
            }
            .tabItem {
                Label("Alarms", systemImage: "alarm")
            }
            .tag(RootTab.alarms)

            NavigationStack(path: $planPath) {
                PlanRootView()
                    .navigationDestination(for: PlanDestination.self) { destination in
                        switch destination {
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
                Label("Plan", systemImage: "calendar")
            }
            .tag(RootTab.plan)

            NavigationStack(path: $profilePath) {
                ProfileRootView()
                    .navigationDestination(for: ProfileDestination.self) { destination in
                        switch destination {
                        case .settings:
                            SettingsRootView()
                        case .hijriCorrections:
                            HijriCalendarSettingsView()
                        }
                    }
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(RootTab.profile)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToAlarmTab)) { _ in
            selectedTab = .alarms
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToPlanTab)) { _ in
            selectedTab = .plan
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlanHome)) { _ in
            selectedTab = .plan
            planPath.removeLast(planPath.count)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlanQada)) { _ in
            selectedTab = .plan
            planPath.removeLast(planPath.count)
            planPath.append(PlanDestination.qadaPlanner)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlanShawwal)) { _ in
            selectedTab = .plan
            planPath.removeLast(planPath.count)
            planPath.append(PlanDestination.shawwalPlanner)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlanSunnah)) { _ in
            selectedTab = .plan
            planPath.removeLast(planPath.count)
            planPath.append(PlanDestination.sunnahPlanner)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToSettingsTab)) { _ in
            selectedTab = .profile
            profilePath.removeLast(profilePath.count)
            profilePath.append(ProfileDestination.settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToHijriCorrections)) { _ in
            selectedTab = .profile
            profilePath.removeLast(profilePath.count)
            profilePath.append(ProfileDestination.settings)
            profilePath.append(ProfileDestination.hijriCorrections)
        }
    }
}
