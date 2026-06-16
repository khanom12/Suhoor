import Foundation
import UserNotifications

final class NotificationEventDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationEventDelegate()
    var wakeEventRecorder: (@MainActor @Sendable (_ identifier: String, _ isResponse: Bool, _ timestamp: Date) -> Void)?

    private override init() {}

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let id = notification.request.identifier
        EventTimelineLog.shared.record(category: "notifications", message: "willPresent id=\(id)")
        Task { @MainActor [wakeEventRecorder] in
            wakeEventRecorder?(id, false, Date())
        }
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        EventTimelineLog.shared.record(category: "notifications", message: "didReceive id=\(id) action=\(response.actionIdentifier)")
        Task { @MainActor [wakeEventRecorder] in
            wakeEventRecorder?(id, true, Date())
        }
        completionHandler()
    }
}
