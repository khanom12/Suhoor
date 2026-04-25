import Foundation

@MainActor
protocol FastCompletionPromptHandling: Sendable {
    func handleIftarNotificationResponse(identifier: String, actionIdentifier: String)
}

struct NoopFastCompletionPromptHandler: FastCompletionPromptHandling {
    func handleIftarNotificationResponse(identifier: String, actionIdentifier: String) {}
}

enum FastCompletionNotificationAction {
    static let completed = "suhoor.iftar.completed"
    static let notCompleted = "suhoor.iftar.not-completed"
}

@MainActor
final class ScheduleManagerFastCompletionPromptHandler: FastCompletionPromptHandling {
    private weak var scheduleManager: ScheduleManager?

    init(scheduleManager: ScheduleManager) {
        self.scheduleManager = scheduleManager
    }

    func handleIftarNotificationResponse(identifier: String, actionIdentifier: String) {
        guard let scheduleManager,
              let dateKey = dateKey(from: identifier),
              let status = fastStatus(from: actionIdentifier) else {
            return
        }

        let intentSnapshot = scheduleManager.activeWindowSnapshot.byDateKey[dateKey]?.dailyCompletion.fast.intentSnapshot
        scheduleManager.performCompletionEdit(
            .setFastStatus(dateKey: dateKey, status: status, intentSnapshot: intentSnapshot),
            source: .notificationAction
        )
    }

    private func dateKey(from identifier: String) -> String? {
        let prefixes = [
            "iftar-notification-",
            "iftar-alarm-",
            "iftar-adhan-",
        ]

        for prefix in prefixes where identifier.hasPrefix(prefix) {
            return String(identifier.dropFirst(prefix.count))
        }

        return nil
    }

    private func fastStatus(from actionIdentifier: String) -> FastCompletionStatus? {
        switch actionIdentifier {
        case FastCompletionNotificationAction.completed:
            return .completed
        case FastCompletionNotificationAction.notCompleted:
            return .notCompleted
        default:
            return nil
        }
    }
}
