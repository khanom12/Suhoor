import Foundation
import AlarmKit

enum DebugInstallAlarmKitCleanup {
    static func cancelSubhOwnedDeliveries(days: Int, now: Date = Date(), timeZone: TimeZone = .current) -> Bool {
        guard #available(iOS 26.0, *) else { return false }
        guard ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] == nil else { return false }
        cancelAlarmKitIdentifiers(days: days, now: now, timeZone: timeZone)
        return true
    }

    @available(iOS 26.0, *)
    private static func cancelAlarmKitIdentifiers(days: Int, now: Date, timeZone: TimeZone) {
        let identifiers = SchedulingIdentifierSet.forUpcoming(
            days: days,
            now: now,
            timeZone: timeZone
        ).alarmIdentifiers
        for identifier in identifiers {
            try? AlarmManager.shared.cancel(id: identifier)
        }
    }
}
