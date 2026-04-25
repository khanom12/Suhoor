import Combine
import SwiftUI

enum RootTab: Hashable {
    case home
    case wake
    case plans
    case progress

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .wake:
            return Strings.AlarmsTab.title
        case .plans:
            return "Plans"
        case .progress:
            return "Progress"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "sparkles"
        case .wake:
            return "alarm"
        case .plans:
            return "calendar"
        case .progress:
            return "chart.line.uptrend.xyaxis"
        }
    }

    var index: Int {
        switch self {
        case .home:
            return 0
        case .wake:
            return 1
        case .plans:
            return 2
        case .progress:
            return 3
        }
    }
}

enum SettingsRoute: Hashable {
    case hijriCorrections
    case alarmBehavior
}

struct RootTabView: View {
    @EnvironmentObject private var appNavigator: AppNavigator

    @State private var selectedTab: RootTab = .home
    @State private var settingsPath = NavigationPath()
    @State private var planPath = NavigationPath()
    @State private var isShowingQadaWizard = false
    @State private var isShowingSettings = false

    var body: some View {
        GeometryReader { proxy in
            let bottomSafeInset = proxy.safeAreaInsets.bottom
            let tabBarBottomPadding = RootTabBarLayout.bottomPadding
            let tabBarReserveHeight = RootTabBarLayout.height + bottomSafeInset + tabBarBottomPadding

            ZStack(alignment: .bottom) {
                tabHostStack(
                    reserveHeight: tabBarReserveHeight,
                    containerWidth: proxy.size.width
                )

                AppBottomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, RootTabBarLayout.horizontalInset)
                .padding(.bottom, tabBarBottomPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppPageBackground().ignoresSafeArea())
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $isShowingQadaWizard) {
            NavigationStack {
                QadaPlannerView()
            }
            .appPresentedChrome()
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack(path: $settingsPath) {
                SettingsRootView()
                    .navigationDestination(for: SettingsRoute.self) { destination in
                        switch destination {
                        case .hijriCorrections:
                            HijriCalendarSettingsView()
                        case .alarmBehavior:
                            AlarmBehaviorSettingsView()
                        }
                    }
            }
            .appPresentedChrome()
        }
        .onReceive(appNavigator.$latestRequest.compactMap { $0 }) { request in
            handle(request.intent)
        }
    }

    @ViewBuilder
    private func tabHostStack(reserveHeight: CGFloat, containerWidth: CGFloat) -> some View {
        ZStack {
            RootTabSceneHost(
                tab: .home,
                selectedTab: selectedTab,
                reserveHeight: reserveHeight,
                containerWidth: containerWidth
            ) {
                NavigationStack {
                    TodayHomeView()
                }
            }

            RootTabSceneHost(
                tab: .wake,
                selectedTab: selectedTab,
                reserveHeight: reserveHeight,
                containerWidth: containerWidth
            ) {
                NavigationStack {
                    AlarmsHomeView()
                }
            }

            RootTabSceneHost(
                tab: .plans,
                selectedTab: selectedTab,
                reserveHeight: reserveHeight,
                containerWidth: containerWidth
            ) {
                NavigationStack(path: $planPath) {
                    PlanRootView()
                        .navigationDestination(for: PlanDestination.self) { destination in
                            switch destination {
                            case .defaultMorningPlan:
                                DefaultAlarmsSettingsView()
                            case .qadaPlanner:
                                QadaPlannerView()
                            case .upcomingSpecialPlans:
                                UpcomingSpecialPlansView()
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
            }

            RootTabSceneHost(
                tab: .progress,
                selectedTab: selectedTab,
                reserveHeight: reserveHeight,
                containerWidth: containerWidth
            ) {
                NavigationStack {
                    ProgressRootView()
                }
            }
        }
        .clipped()
        .animation(RootTabTransition.animation, value: selectedTab)
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
        case .openAlarmBehavior:
            presentSettings(route: .alarmBehavior)
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

    private func presentSettings(route: SettingsRoute? = nil) {
        settingsPath.removeLast(settingsPath.count)
        if let route {
            settingsPath.append(route)
        }
        isShowingSettings = true
    }
}

private struct RootTabSceneHost<Content: View>: View {
    let tab: RootTab
    let selectedTab: RootTab
    let reserveHeight: CGFloat
    let containerWidth: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: reserveHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isActive ? 1 : 0)
            .offset(x: horizontalOffset)
            .allowsHitTesting(isActive)
            .accessibilityHidden(!isActive)
            .zIndex(isActive ? 1 : 0)
    }

    private var isActive: Bool {
        selectedTab == tab
    }

    private var horizontalOffset: CGFloat {
        CGFloat(tab.index - selectedTab.index) * containerWidth * RootTabTransition.distanceMultiplier
    }
}

private struct AppBottomTabBar: View {
    @Binding var selectedTab: RootTab

    private let tabs: [RootTab] = [.home, .wake, .plans, .progress]
    private let horizontalPadding = DesignTokens.spacingS
    private let verticalPadding: CGFloat = 6
    private let itemSpacing = DesignTokens.spacingXS

    var body: some View {
        let itemHeight = RootTabBarLayout.height - (verticalPadding * 2)

        ZStack {
            glassBackground

            HStack(spacing: itemSpacing) {
                ForEach(tabs, id: \.self) { tab in
                    tabButton(for: tab, itemHeight: itemHeight)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .frame(height: RootTabBarLayout.height)
        .overlay {
            tabBarShape
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.22), radius: 20, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tab bar")
    }

    private func tabButton(for tab: RootTab, itemHeight: CGFloat) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 17, weight: .semibold))

                Text(tab.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.60))
            .frame(maxWidth: .infinity)
            .frame(height: itemHeight)
        }
        .buttonStyle(TabBarPulseButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                tabBarPlate
            }
        } else {
            tabBarPlate
        }
    }

    private var tabBarPlate: some View {
        Group {
            if #available(iOS 26.0, *) {
                tabBarShape
                    .fill(.clear)
                    .glassEffect(
                        .clear
                            .tint(Color.black.opacity(0.24))
                            .interactive(false),
                        in: tabBarShape
                    )
                    .overlay {
                        tabBarShape.fill(Color.white.opacity(0.02))
                    }
                    .overlay {
                        tabBarShape.fill(Color.black.opacity(0.12))
                    }
            } else {
                tabBarShape
                    .fill(.thinMaterial)
                    .overlay {
                        tabBarShape.fill(Color.black.opacity(0.22))
                    }
            }
        }
    }

    private var tabBarShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: RootTabBarLayout.cornerRadius, style: .continuous)
    }
}

private struct TabBarPulseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Capsule(style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private enum RootTabBarLayout {
    static let height: CGFloat = 60
    static let bottomPadding: CGFloat = 0
    static let horizontalInset: CGFloat = DesignTokens.spacingL
    static let cornerRadius: CGFloat = height / 2
}

private enum RootTabTransition {
    static let distanceMultiplier: CGFloat = 1.0
    static let animation: Animation = .snappy(duration: 0.34, extraBounce: 0.02)
}
