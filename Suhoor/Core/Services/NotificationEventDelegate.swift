import Foundation
import UserNotifications

final class NotificationEventDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationEventDelegate()
    private var fastCompletionPromptHandler: any FastCompletionPromptHandling

    private override init() {
        self.fastCompletionPromptHandler = NoopFastCompletionPromptHandler()
    }

    @MainActor
    func configure(fastCompletionPromptHandler: any FastCompletionPromptHandling) {
        self.fastCompletionPromptHandler = fastCompletionPromptHandler
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let id = notification.request.identifier
        EventTimelineLog.shared.record(category: "notifications", message: "willPresent id=\(id)")
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        EventTimelineLog.shared.record(category: "notifications", message: "didReceive id=\(id) action=\(response.actionIdentifier)")
        if response.notification.request.content.categoryIdentifier == NotificationScheduler.iftarCategoryIdentifier {
            Task { @MainActor [fastCompletionPromptHandler] in
                fastCompletionPromptHandler.handleIftarNotificationResponse(
                    identifier: id,
                    actionIdentifier: response.actionIdentifier
                )
            }
        }
        completionHandler()
    }
}
