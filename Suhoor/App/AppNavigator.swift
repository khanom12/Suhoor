import Combine
import Foundation

enum AppNavigationIntent: Equatable, Sendable {
    case switchToWake
    case switchToPlans
    case openSettings
    case openHijriCorrections
    case openDefaultMorningPlan
    case openQadaPlanner
    case openShawwalPlanner
    case openSunnahPlanner
}

struct AppNavigationRequest: Identifiable, Equatable, Sendable {
    let id = UUID()
    let intent: AppNavigationIntent
}

@MainActor
final class AppNavigator: ObservableObject {
    @Published private(set) var latestRequest: AppNavigationRequest?

    private var cancellables: Set<AnyCancellable> = []

    init(notificationCenter: NotificationCenter = .default) {
        bindLegacyNotifications(notificationCenter)
    }

    func send(_ intent: AppNavigationIntent) {
        latestRequest = AppNavigationRequest(intent: intent)
    }

    func switchToWake() {
        send(.switchToWake)
    }

    func switchToPlans() {
        send(.switchToPlans)
    }

    func openSettings() {
        send(.openSettings)
    }

    func openHijriCorrections() {
        send(.openHijriCorrections)
    }

    func openDefaultMorningPlan() {
        send(.openDefaultMorningPlan)
    }

    func openQadaPlanner() {
        send(.openQadaPlanner)
    }

    func openShawwalPlanner() {
        send(.openShawwalPlanner)
    }

    func openSunnahPlanner() {
        send(.openSunnahPlanner)
    }

    private func bindLegacyNotifications(_ notificationCenter: NotificationCenter) {
        let mappings: [(Notification.Name, AppNavigationIntent)] = [
            (.switchToWakeTab, .switchToWake),
            (.switchToAlarmTab, .switchToWake),
            (.switchToPlanTab, .switchToPlans),
            (.switchToSettingsTab, .openSettings),
            (.switchToHijriCorrections, .openHijriCorrections),
            (.openPlanDefaultMorningPlan, .openDefaultMorningPlan),
            (.openPlanQada, .openQadaPlanner),
            (.openPlanShawwal, .openShawwalPlanner),
            (.openPlanSunnah, .openSunnahPlanner)
        ]

        for (name, intent) in mappings {
            notificationCenter.publisher(for: name)
                .sink { [weak self] _ in
                    self?.send(intent)
                }
                .store(in: &cancellables)
        }

        notificationCenter.publisher(for: .openPlanHome)
            .sink { [weak self] _ in
                self?.switchToPlans()
            }
            .store(in: &cancellables)
    }
}

enum AppNavigationBridge {
    static func send(
        _ intent: AppNavigationIntent,
        notificationCenter: NotificationCenter = .default
    ) {
        switch intent {
        case .switchToWake:
            notificationCenter.post(name: .switchToWakeTab, object: nil)
        case .switchToPlans:
            notificationCenter.post(name: .switchToPlanTab, object: nil)
        case .openSettings:
            notificationCenter.post(name: .switchToSettingsTab, object: nil)
        case .openHijriCorrections:
            notificationCenter.post(name: .switchToHijriCorrections, object: nil)
        case .openDefaultMorningPlan:
            notificationCenter.post(name: .openPlanDefaultMorningPlan, object: nil)
        case .openQadaPlanner:
            notificationCenter.post(name: .openPlanQada, object: nil)
        case .openShawwalPlanner:
            notificationCenter.post(name: .openPlanShawwal, object: nil)
        case .openSunnahPlanner:
            notificationCenter.post(name: .openPlanSunnah, object: nil)
        }
    }
}
