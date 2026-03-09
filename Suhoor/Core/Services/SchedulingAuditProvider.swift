import CoreLocation
import Foundation
import UserNotifications

struct SchedulingAuditProvider {
    struct Dependencies {
        let settings: AppSettings
        let coordinate: CLLocationCoordinate2D?
        let canUseAlarmKit: Bool
        let now: Date
        let timeZone: TimeZone
        let dayLabel: (Date) -> String
        let dateParticipatesInWakePlan: (Date, TimeZone) -> Bool
        let effectiveConfig: (Date, TimeZone) -> EffectiveDailyConfig
        let buildSchedule: (Date, CLLocationCoordinate2D, TimeZone, CalculationMethod, Int, Int, EffectiveDailyConfig, String) -> DaySchedule?
        let pendingRequests: () async -> [UNNotificationRequest]
        let alarmKitItems: () async -> [AlarmKitAuditItem]
        let buildAuditMismatches: ([ExpectedScheduledEvent], [NotificationAuditItem], [AlarmKitAuditItem]) -> [AuditMismatch]
    }

    func makeSchedulingAudit(
        dependencies: Dependencies
    ) async -> SchedulingAuditSnapshot {
        guard let coordinate = dependencies.coordinate else {
            let mismatch = AuditMismatch(severity: .error, message: "Location unavailable; unable to compute expected events.")
            return SchedulingAuditSnapshot(
                generatedAt: Date(),
                expectedEvents: [],
                notificationItems: [],
                alarmKitItems: [],
                mismatches: [mismatch]
            )
        }

        let today = DateHelpers.startOfToday(in: dependencies.timeZone)
        let tomorrow = DateHelpers.startOfTomorrow(in: dependencies.timeZone)
        let dates = [today, tomorrow]
        var expectedEvents: [ExpectedScheduledEvent] = []

        for date in dates {
            guard dependencies.dateParticipatesInWakePlan(date, dependencies.timeZone) else { continue }
            let effectiveConfig = dependencies.effectiveConfig(date, dependencies.timeZone)
            guard let schedule = dependencies.buildSchedule(
                date,
                coordinate,
                dependencies.timeZone,
                dependencies.settings.calculationMethod,
                dependencies.settings.fajrAdjustmentMinutes,
                dependencies.settings.maghribAdjustmentMinutes,
                effectiveConfig,
                "Audit"
            ) else {
                continue
            }

            let dayLabelText = dependencies.dayLabel(date)
            if effectiveConfig.suhoorEnabled && !effectiveConfig.skipDay {
                let channel: ExpectedScheduledEvent.Channel = dependencies.canUseAlarmKit ? .alarmKit : .notification
                let identifier = channel == .alarmKit
                    ? SchedulingIdentifiers.alarmID(for: schedule, kind: .wake).uuidString
                    : SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .wake)
                expectedEvents.append(
                    ExpectedScheduledEvent(
                        kind: .wake,
                        date: schedule.wakeDate,
                        dayLabel: dayLabelText,
                        scheduleId: schedule.id,
                        channel: channel,
                        identifier: identifier,
                        isPast: schedule.wakeDate <= dependencies.now
                    )
                )
            }

            if effectiveConfig.reminderEnabled, !effectiveConfig.skipDay, let reminderDate = schedule.reminderDate {
                let channel: ExpectedScheduledEvent.Channel = dependencies.canUseAlarmKit ? .alarmKit : .notification
                let identifier = channel == .alarmKit
                    ? SchedulingIdentifiers.alarmID(for: schedule, kind: .reminder).uuidString
                    : SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .reminder)
                expectedEvents.append(
                    ExpectedScheduledEvent(
                        kind: .reminder,
                        date: reminderDate,
                        dayLabel: dayLabelText,
                        scheduleId: schedule.id,
                        channel: channel,
                        identifier: identifier,
                        isPast: reminderDate <= dependencies.now
                    )
                )
            }

            if effectiveConfig.fajrEnabled, !effectiveConfig.skipDay, let boundaryDate = schedule.boundaryDate {
                let channel: ExpectedScheduledEvent.Channel = dependencies.canUseAlarmKit ? .alarmKit : .notification
                let identifier = channel == .alarmKit
                    ? SchedulingIdentifiers.alarmID(for: schedule, kind: .boundary).uuidString
                    : SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .boundary)
                expectedEvents.append(
                    ExpectedScheduledEvent(
                        kind: .boundary,
                        date: boundaryDate,
                        dayLabel: dayLabelText,
                        scheduleId: schedule.id,
                        channel: channel,
                        identifier: identifier,
                        isPast: boundaryDate <= dependencies.now
                    )
                )
            }

            if effectiveConfig.iftarEnabled, !effectiveConfig.skipDay, let iftarDate = schedule.iftarDate {
                if effectiveConfig.iftarDelivery.includesNotification {
                    expectedEvents.append(
                        ExpectedScheduledEvent(
                            kind: .iftarNotification,
                            date: iftarDate,
                            dayLabel: dayLabelText,
                            scheduleId: schedule.id,
                            channel: .notification,
                            identifier: SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .iftarNotification),
                            isPast: iftarDate <= dependencies.now
                        )
                    )
                }

                switch effectiveConfig.iftarDelivery.audibleMode {
                case .none:
                    break
                case .alarm:
                    let channel: ExpectedScheduledEvent.Channel = dependencies.canUseAlarmKit ? .alarmKit : .notification
                    expectedEvents.append(
                        ExpectedScheduledEvent(
                            kind: .iftarAlarm,
                            date: iftarDate,
                            dayLabel: dayLabelText,
                            scheduleId: schedule.id,
                            channel: channel,
                            identifier: channel == .alarmKit
                                ? SchedulingIdentifiers.alarmID(for: schedule, kind: .iftarAlarm).uuidString
                                : SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .iftarAlarm),
                            isPast: iftarDate <= dependencies.now
                        )
                    )
                case .adhan:
                    let channel: ExpectedScheduledEvent.Channel = dependencies.canUseAlarmKit ? .alarmKit : .notification
                    expectedEvents.append(
                        ExpectedScheduledEvent(
                            kind: .iftarAdhan,
                            date: iftarDate,
                            dayLabel: dayLabelText,
                            scheduleId: schedule.id,
                            channel: channel,
                            identifier: channel == .alarmKit
                                ? SchedulingIdentifiers.alarmID(for: schedule, kind: .iftarAdhan).uuidString
                                : SchedulingIdentifiers.dailyIdentifier(for: schedule, kind: .iftarAdhan),
                            isPast: iftarDate <= dependencies.now
                        )
                    )
                }
            }
        }

        let pendingRequests = await dependencies.pendingRequests()
        let notificationItems = pendingRequests.map { NotificationAuditItem(request: $0) }
        let alarmKitItems = await dependencies.alarmKitItems()
        let mismatches = dependencies.buildAuditMismatches(expectedEvents, notificationItems, alarmKitItems)

        return SchedulingAuditSnapshot(
            generatedAt: Date(),
            expectedEvents: expectedEvents,
            notificationItems: notificationItems,
            alarmKitItems: alarmKitItems,
            mismatches: mismatches
        )
    }
}
