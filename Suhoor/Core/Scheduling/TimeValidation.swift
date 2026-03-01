import Foundation

struct TimeValidationResult {
    let reminderTime: Date
    let wasClampedToSuhoor: Bool
}

enum TimeValidation {
    static func validateDailyTimes(suhoorTime: Date, reminderTime: Date) -> TimeValidationResult {
        if reminderTime < suhoorTime {
            return TimeValidationResult(reminderTime: suhoorTime, wasClampedToSuhoor: true)
        }
        return TimeValidationResult(reminderTime: reminderTime, wasClampedToSuhoor: false)
    }
}
