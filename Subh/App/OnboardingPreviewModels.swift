import Foundation

enum OnboardingStep: Int, CaseIterable, Hashable, Sendable {
    case valuePreview
    case location
    case permissions
    case success
}

struct OnboardingTomorrowPreview: Equatable {
    let dateText: String
    let targetDate: Date?
    let fajrDate: Date?
    let suhoorDate: Date?
    let fajrTimeText: String?
    let suhoorTimeText: String?
    let statusText: String?

    var wakeDate: Date? { suhoorDate }
    var wakeTimeText: String? { suhoorTimeText }
}
