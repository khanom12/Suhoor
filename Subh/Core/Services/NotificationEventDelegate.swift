import Foundation
import UserNotifications

final class NotificationEventDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationEventDelegate()

    private override init() {}

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
        completionHandler()
    }
}
