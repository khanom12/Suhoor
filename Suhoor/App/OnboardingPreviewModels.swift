import Foundation

struct OnboardingTomorrowPreview: Equatable {
    let dateText: String
    let fajrTimeText: String?
    let suhoorTimeText: String?
    let statusText: String?
}

struct SchedulePreviewRow: Identifiable, Equatable {
    let id: String
    let date: Date
    let dayLabel: String
    let fajr: Date
    let suhoor: Date
}

enum OnboardingActivationState: Equatable {
    case idle
    case attempting
    case succeeded(schedule: DaySchedule)
    case failed(message: String)
}
