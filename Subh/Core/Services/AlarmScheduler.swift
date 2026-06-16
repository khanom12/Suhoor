import Foundation
import os

@MainActor
final class AlarmScheduler {
    private let routineScheduler: any RoutineScheduling
    private var lastPlannedEvents: [String: PlannedScheduledEvent] = [:]

    init(routineScheduler: any RoutineScheduling) {
        self.routineScheduler = routineScheduler
    }

    func resetReconciliationState() {
        lastPlannedEvents.removeAll()
    }

    func scheduleAll(
        days: [ActiveAlarmDay],
        settings: AppSettings,
        canUseAlarmKit: Bool,
        cancelWindowDays: Int
    ) async -> Bool {
        await scheduleAll(
            days: days,
            settings: settings,
            mode: canUseAlarmKit ? .alarmKit : .notifications,
            cancelWindowDays: cancelWindowDays
        )
    }

    func scheduleAll(
        days: [ActiveAlarmDay],
        settings: AppSettings,
        mode: SchedulingMode,
        cancelWindowDays: Int
    ) async -> Bool {
        let nextPlans = buildPlannedEvents(
            days: days,
            settings: settings,
            mode: mode
        )

        if lastPlannedEvents.isEmpty {
            await routineScheduler.cancelAllUpcoming(days: cancelWindowDays)
        }

        return await reconcile(
            to: nextPlans,
            settings: settings,
            affectedDayIDs: nil
        )
    }

    func scheduleDay(
        day: ActiveAlarmDay,
        settings: AppSettings,
        canUseAlarmKit: Bool
    ) async -> Bool {
        await scheduleDay(
            day: day,
            settings: settings,
            mode: canUseAlarmKit ? .alarmKit : .notifications
        )
    }

    func scheduleDay(
        day: ActiveAlarmDay,
        settings: AppSettings,
        mode: SchedulingMode
    ) async -> Bool {
        if lastPlannedEvents.values.contains(where: { $0.dayID == day.id }) == false {
            await routineScheduler.cancelIdentifiers(
                SchedulingIdentifierSet.forSchedule(day.schedule, events: day.scheduledEvents)
            )
        }
        let nextPlans = buildPlannedEvents(
            days: [day],
            settings: settings,
            mode: mode
        )
        return await reconcile(
            to: nextPlans,
            settings: settings,
            affectedDayIDs: [day.id]
        )
    }

    func cancelDay(day: ActiveAlarmDay) async {
        if lastPlannedEvents.values.contains(where: { $0.dayID == day.id }) == false {
            await routineScheduler.cancelIdentifiers(
                SchedulingIdentifierSet.forSchedule(day.schedule, events: day.scheduledEvents)
            )
            return
        }
        _ = await reconcile(
            to: [:],
            settings: nil,
            affectedDayIDs: [day.id]
        )
    }

    @discardableResult
    func cancelWakeSessionEvents(
        day: ActiveAlarmDay,
        wakeSessionID: String?,
        now: Date = Date()
    ) async -> [ScheduledEvent] {
        let events = WakeSessionPlanner.cancellableWakeSessionEvents(
            for: day,
            wakeSessionID: wakeSessionID,
            now: now
        )
        guard !events.isEmpty else { return [] }

        let identifiers = events.reduce(SchedulingIdentifierSet()) { partial, event in
            event.deliveryKinds.reduce(partial) { result, deliveryKind in
                result.union(SchedulingIdentifierSet.forEvent(event, deliveryKind: deliveryKind))
            }
        }
        await routineScheduler.cancelIdentifiers(identifiers)

        let cancelledEventIDs = Set(events.map(\.id))
        lastPlannedEvents = lastPlannedEvents.filter { _, plan in
            !cancelledEventIDs.contains(plan.event.id)
        }
        return events
    }

    @discardableResult
    func cancelWakeSessionDate(
        day: ActiveAlarmDay,
        persistedExpectedDeliveries: [ExpectedDeliveryRecord],
        now: Date = Date()
    ) async -> [ScheduledEvent] {
        let events = day.scheduledEvents.filter { event in
            guard event.fireDate > now else { return false }
            return event.deliveryKinds.contains(.wake)
                || event.wakeSessionRole == .primaryWake
                || event.wakeSessionRole == .wakeCheck
        }
        let identifiers = SchedulingIdentifierSet
            .forWakeSessionDate(dateKey: day.dateKey, schedule: day.schedule, events: day.scheduledEvents)
            .union(.forExpectedDeliveries(persistedExpectedDeliveries))
        await routineScheduler.cancelIdentifiers(identifiers)

        let cancelledEventIDs = Set(events.map(\.id))
        let persistedEventIDs = Set(persistedExpectedDeliveries.map(\.eventID))
        lastPlannedEvents = lastPlannedEvents.filter { _, plan in
            !cancelledEventIDs.contains(plan.event.id) && !persistedEventIDs.contains(plan.event.id)
        }
        return events
    }

    @discardableResult
    func repairDeliveries(
        days: [ActiveAlarmDay],
        settings: AppSettings,
        mode: SchedulingMode,
        report: DeliveryReconciliationReport,
        staleAlarmScope: Set<UUID>
    ) async -> DeliveryRepairResult {
        let nextPlans = buildPlannedEvents(
            days: days,
            settings: settings,
            mode: mode
        )
        let missingNotifications = Set(report.missingNotificationIdentifiers)
        let mismatchedNotifications = Set(report.mismatchedNotificationIdentifiers)
        let duplicateNotifications = Set(report.duplicateNotificationIdentifiers)
        let missingAlarms = Set(report.missingAlarmIdentifiers)
        let mismatchedAlarms = Set(report.mismatchedAlarmIdentifiers)
        let duplicateAlarms = Set(report.duplicateAlarmIdentifiers)

        let unexpectedNotifications = report.unexpectedNotificationIdentifiers
            .filter(SchedulingIdentifiers.isSubhOwnedNotificationIdentifier)
        let unexpectedAlarms = report.unexpectedAlarmIdentifiers
            .filter { staleAlarmScope.contains($0) }

        let cancelIdentifiers = SchedulingIdentifierSet(
            notificationIdentifiers: Array(mismatchedNotifications.union(duplicateNotifications)) + unexpectedNotifications,
            alarmIdentifiers: Array(mismatchedAlarms.union(duplicateAlarms)) + unexpectedAlarms
        )
        await routineScheduler.cancelIdentifiers(cancelIdentifiers)

        var rescheduledMissing = 0
        var rescheduledMismatched = 0
        var failed = 0
        var repairedPlanIDs: [String] = []

        for plan in nextPlans.values.sorted(by: { $0.fireDate < $1.fireDate }) {
            let shouldRescheduleMissing: Bool
            let shouldRescheduleMismatched: Bool
            switch plan.channel {
            case .notification:
                shouldRescheduleMissing = missingNotifications.contains(plan.planID)
                shouldRescheduleMismatched = mismatchedNotifications.contains(plan.planID)
                    || duplicateNotifications.contains(plan.planID)
            case .alarmKit:
                let alarmID = SchedulingIdentifiers.alarmID(
                    for: plan.event,
                    deliveryKind: plan.kind,
                    channel: .alarmKit
                )
                shouldRescheduleMissing = missingAlarms.contains(alarmID)
                shouldRescheduleMismatched = mismatchedAlarms.contains(alarmID)
                    || duplicateAlarms.contains(alarmID)
            }

            guard shouldRescheduleMissing || shouldRescheduleMismatched else { continue }
            if await schedule(plan, settings: settings) {
                repairedPlanIDs.append(plan.planID)
                if shouldRescheduleMissing {
                    rescheduledMissing += 1
                } else {
                    rescheduledMismatched += 1
                }
            } else {
                failed += 1
            }
        }

        for id in repairedPlanIDs {
            if let plan = nextPlans[id] {
                lastPlannedEvents[id] = plan
            }
        }

        return DeliveryRepairResult(
            cancelledUnexpected: unexpectedNotifications.count + unexpectedAlarms.count,
            rescheduledMissing: rescheduledMissing,
            rescheduledMismatched: rescheduledMismatched,
            leftUnchanged: max(0, report.expectedDeliveryCount - rescheduledMissing - rescheduledMismatched),
            verificationUnavailable: DeliveryRepairCoordinator.verificationUnavailableCount(in: report),
            failed: failed
        )
    }

    private func reconcile(
        to nextPlans: [String: PlannedScheduledEvent],
        settings: AppSettings?,
        affectedDayIDs: Set<String>?
    ) async -> Bool {
        let previousPlans: [String: PlannedScheduledEvent]
        let scopedNextPlans: [String: PlannedScheduledEvent]

        if let affectedDayIDs {
            previousPlans = lastPlannedEvents.filter { affectedDayIDs.contains($0.value.dayID) }
            scopedNextPlans = nextPlans.filter { affectedDayIDs.contains($0.value.dayID) }
        } else {
            previousPlans = lastPlannedEvents
            scopedNextPlans = nextPlans
        }

        var success = true

        for previous in previousPlans.values.sorted(by: { $0.fireDate < $1.fireDate }) {
            if let next = scopedNextPlans[previous.planID], next == previous {
                continue
            }
            await cancel(previous)
        }

        if let settings {
            for next in scopedNextPlans.values.sorted(by: { $0.fireDate < $1.fireDate }) {
                if previousPlans[next.planID] == next {
                    continue
                }
                success = await schedule(next, settings: settings) && success
            }
        }

        if let affectedDayIDs {
            lastPlannedEvents = lastPlannedEvents.filter { !affectedDayIDs.contains($0.value.dayID) }
            for (id, plan) in scopedNextPlans {
                lastPlannedEvents[id] = plan
            }
        } else {
            lastPlannedEvents = scopedNextPlans
        }

        return success
    }

    private func buildPlannedEvents(
        days: [ActiveAlarmDay],
        settings: AppSettings,
        mode: SchedulingMode
    ) -> [String: PlannedScheduledEvent] {
        let now = Date()
        var plans: [String: PlannedScheduledEvent] = [:]

        for day in days {
            guard !day.effectiveConfig.skipDay else { continue }

            for event in day.scheduledEvents where event.fireDate > now {
                for deliveryKind in event.deliveryKinds {
                    guard !shouldSuppressDelivery(
                        day: day,
                        event: event,
                        deliveryKind: deliveryKind,
                        settings: settings
                    ) else {
                        continue
                    }

                    guard let channel = plannedChannel(for: event, deliveryKind: deliveryKind, mode: mode) else {
                        continue
                    }

                    let plan = PlannedScheduledEvent(
                        planID: SchedulingIdentifiers.identifier(
                            for: event,
                            deliveryKind: deliveryKind,
                            channel: .notification
                        ),
                        dayID: day.id,
                        kind: deliveryKind,
                        channel: channel,
                        fireDate: event.fireDate,
                        schedule: day.schedule,
                        event: event
                    )
                    plans[plan.planID] = plan
                }
            }
        }

        return plans
    }

    private func shouldSuppressDelivery(
        day: ActiveAlarmDay,
        event: ScheduledEvent,
        deliveryKind: ScheduleEventKind,
        settings: AppSettings
    ) -> Bool {
        guard deliveryKind == .wake || event.wakeSessionRole == .primaryWake || event.wakeSessionRole == .wakeCheck else {
            return false
        }
        if day.effectiveConfig.dateAlarmOverride == .quiet {
            return true
        }
        if settings.wakeAlarmsPausedIndefinitely,
           day.effectiveConfig.dateAlarmOverride != .ringDespitePause {
            return true
        }
        return false
    }

    private func schedule(_ plan: PlannedScheduledEvent, settings: AppSettings) async -> Bool {
        await routineScheduler.scheduleEvent(
            identifier: plan.planID,
            event: plan.event,
            deliveryKind: plan.kind,
            schedule: plan.schedule,
            settings: settings,
            canUseAlarmKit: plan.channel == .alarmKit,
            now: Date()
        )
    }

    private func cancel(_ plan: PlannedScheduledEvent) async {
        await routineScheduler.cancelEvent(
            identifier: plan.planID,
            event: plan.event,
            deliveryKind: plan.kind,
            schedule: plan.schedule
        )
    }

    private func plannedChannel(
        for event: ScheduledEvent,
        deliveryKind: ScheduleEventKind,
        mode: SchedulingMode
    ) -> PlannedScheduledEvent.Channel? {
        switch mode {
        case .none:
            return nil
        case .notifications:
            return .notification
        case .alarmKit:
            if deliveryKind == .iftarNotification {
                return .notification
            }
            if event.fajrStartBehavior == .takeoverIfUnresolvedOtherwiseCue,
               deliveryKind == .boundary {
                return nil
            }
            return .alarmKit
        case .mixed:
            if event.fajrStartBehavior == .takeoverIfUnresolvedOtherwiseCue,
               deliveryKind == .boundary {
                return nil
            }
            if deliveryKind == .wake || deliveryKind == .iftarAlarm || deliveryKind == .iftarAdhan {
                return .alarmKit
            }
            return .notification
        }
    }
}

private struct PlannedScheduledEvent: Equatable {
    enum Channel: Equatable {
        case alarmKit
        case notification
    }

    let planID: String
    let dayID: String
    let kind: ScheduleEventKind
    let channel: Channel
    let fireDate: Date
    let schedule: DaySchedule
    let event: ScheduledEvent
}
