import Foundation

@MainActor
struct AlarmKitTestScenarioRunner {
    let alarmCoordinator: AlarmCoordinator
    let testRunStore: AlarmKitTestRunStore
    let timeProvider: TimeProviding

    func run(
        settings: AlarmKitTestSettings,
        label: String,
        soundName: String?,
        snoozeDuration: TimeInterval?
    ) async -> Bool {
        let baseNow = timeProvider.now()
        let suhoorDate = baseNow.addingTimeInterval(TimeInterval(settings.suhoorOffsetSeconds))
        let reminderDate = baseNow.addingTimeInterval(TimeInterval(settings.reminderOffsetSeconds))
        let adhanDate = baseNow.addingTimeInterval(TimeInterval(settings.adhanOffsetSeconds))
        let testRunId = UUID()

        let ids = ScheduleEventKind.allCases.map { SchedulingIdentifiers.testAlarmID(for: $0) }
        alarmCoordinator.cancel(ids: ids)

        let wakeScheduled = await alarmCoordinator.scheduleAlarm(
            id: SchedulingIdentifiers.testAlarmID(for: .wake),
            kind: .wake,
            date: suhoorDate,
            label: label,
            fajrDateTime: adhanDate,
            soundName: nil,
            snoozeDuration: snoozeDuration,
            isTest: true,
            testRunId: testRunId
        )

        let reminderScheduled = await alarmCoordinator.scheduleAlarm(
            id: SchedulingIdentifiers.testAlarmID(for: .reminder),
            kind: .reminder,
            date: reminderDate,
            label: label,
            fajrDateTime: adhanDate,
            soundName: nil,
            snoozeDuration: nil,
            isTest: true,
            testRunId: testRunId
        )

        let adhanScheduled = await alarmCoordinator.scheduleAlarm(
            id: SchedulingIdentifiers.testAlarmID(for: .boundary),
            kind: .boundary,
            date: adhanDate,
            label: label,
            fajrDateTime: adhanDate,
            soundName: soundName,
            snoozeDuration: nil,
            isTest: true,
            testRunId: testRunId
        )

        testRunStore.save(
            AlarmKitTestRunState(
                testRunId: testRunId,
                baseNow: baseNow,
                suhoorDate: suhoorDate,
                reminderDate: reminderDate,
                adhanDate: adhanDate
            )
        )

        return wakeScheduled && reminderScheduled && adhanScheduled
    }
}
