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
    let wakeDate: Date?
    let fajrTimeText: String?
    let wakeTimeText: String?
    let statusText: String?
}
