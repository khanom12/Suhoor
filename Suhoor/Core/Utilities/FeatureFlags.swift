import Foundation

enum FeatureFlags {
    static let enableCountdown = false
    static let enableSnooze = false
    static let enableAlarmKitTestMode = false

    static var useAlarmCoordinatorForScheduling: Bool {
        enableCountdown || enableAlarmKitTestMode
    }
}
