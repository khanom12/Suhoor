import SwiftUI

enum RootTab: Hashable {
    case today
    case plan
    case alarms
    case profile
}

enum ProfileDestination: Hashable {
    case settings
}

struct RootTabView: View {
    @State private var selectedTab: RootTab = .today
    @State private var profilePath = NavigationPath()

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

            NavigationStack {
                PlanRootView()
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
        .onReceive(NotificationCenter.default.publisher(for: .switchToSettingsTab)) { _ in
            selectedTab = .profile
            profilePath.removeLast(profilePath.count)
            profilePath.append(ProfileDestination.settings)
        }
    }
}
