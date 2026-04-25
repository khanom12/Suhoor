import Combine
import Foundation

enum AppNavigationIntent: Equatable, Sendable {
    case switchToWake
    case openSettings
    case openHijriCorrections
    case openAlarmBehavior
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

    func openSettings() {
        send(.openSettings)
    }

    func openHijriCorrections() {
        send(.openHijriCorrections)
    }

    func openAlarmBehavior() {
        send(.openAlarmBehavior)
    }

    private func bindLegacyNotifications(_ notificationCenter: NotificationCenter) {
        let mappings: [(Notification.Name, AppNavigationIntent)] = [
            (.switchToWakeTab, .switchToWake),
            (.switchToAlarmTab, .switchToWake),
            (.switchToSettingsTab, .openSettings),
            (.switchToHijriCorrections, .openHijriCorrections)
        ]

        for (name, intent) in mappings {
            notificationCenter.publisher(for: name)
                .sink { [weak self] _ in
                    self?.send(intent)
                }
                .store(in: &cancellables)
        }
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
        case .openSettings:
            notificationCenter.post(name: .switchToSettingsTab, object: nil)
        case .openHijriCorrections:
            notificationCenter.post(name: .switchToHijriCorrections, object: nil)
        case .openAlarmBehavior:
            notificationCenter.post(name: .switchToSettingsTab, object: nil)
        }
    }
}
