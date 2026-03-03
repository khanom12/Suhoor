import Foundation

protocol FastCompletionPromptHandling: Sendable {
    func handleIftarNotificationResponse(identifier: String, actionIdentifier: String)
}

struct NoopFastCompletionPromptHandler: FastCompletionPromptHandling {
    func handleIftarNotificationResponse(identifier: String, actionIdentifier: String) {}
}
