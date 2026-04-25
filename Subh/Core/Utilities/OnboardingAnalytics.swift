import Foundation

enum OnboardingAnalytics {
    static func log(_ event: String, properties: [String: String]? = nil) {
        let payload: String
        if let properties, !properties.isEmpty {
            let serialized = properties
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")
            payload = "\(event) [\(serialized)]"
        } else {
            payload = event
        }
        EventTimelineLog.shared.record(category: "onboarding", message: payload)
    }
}
