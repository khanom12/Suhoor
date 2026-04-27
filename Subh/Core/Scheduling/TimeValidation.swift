import Foundation

struct TimeValidationResult {
    let reminderTime: Date
    let wasClampedToWake: Bool
}

enum TimeValidation {
    static func validateDailyTimes(wakeTime: Date, reminderTime: Date) -> TimeValidationResult {
        if reminderTime < wakeTime {
            return TimeValidationResult(reminderTime: wakeTime, wasClampedToWake: true)
        }
        return TimeValidationResult(reminderTime: reminderTime, wasClampedToWake: false)
    }
}
