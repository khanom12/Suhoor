import Foundation

enum LegacyResolvedDayAdapter {
    static func makeSchedule(
        snapshot: ResolvedDaySnapshot,
        effectiveConfig: EffectiveDailyConfig,
        settings: AppSettings,
        locationDescription: String,
        timeZone: TimeZone
    ) -> DaySchedule {
        DaySchedule(
            date: snapshot.date,
            fajrDate: snapshot.prayerWindow.fajrStart,
            fajrEndDate: snapshot.prayerWindow.fajrEnd,
            maghribDate: snapshot.prayerWindow.maghrib,
            wakeDate: snapshot.decisionLog.resolvedWakeTime,
            reminderDate: eventDate(for: .wakeReminder, in: snapshot.materializedEvents),
            boundaryDate: eventDate(for: .fajrBoundaryNotice, in: snapshot.materializedEvents),
            iftarDate: eventDate(for: .iftarReminder, in: snapshot.materializedEvents),
            fajrSoundChoice: effectiveConfig.fajrSoundChoice,
            iftarSoundChoice: effectiveConfig.iftarSoundChoice,
            locationDescription: locationDescription,
            offsetMinutes: max(0, Int(round(snapshot.prayerWindow.fajrStart.timeIntervalSince(snapshot.decisionLog.resolvedWakeTime) / 60))),
            calculationMethodName: snapshot.prayerWindow.methodDisplayName ?? settings.calculationMethod.displayName,
            timeZone: timeZone
        )
    }

    static func makeActiveAlarmDay(
        snapshot: ResolvedDaySnapshot,
        effectiveConfig: EffectiveDailyConfig,
        provenances: [ResolvedScheduledDateProvenance],
        isImplicitRamadan: Bool,
        isExplicitOneOff: Bool,
        tagResult: TagComputationResult,
        sourceSummaryText: String,
        settings: AppSettings,
        locationDescription: String,
        timeZone: TimeZone
    ) -> ActiveAlarmDay {
        let schedule = makeSchedule(
            snapshot: snapshot,
            effectiveConfig: effectiveConfig,
            settings: settings,
            locationDescription: locationDescription,
            timeZone: timeZone
        )

        return ActiveAlarmDay(
            date: snapshot.date,
            dateKey: snapshot.dateKey,
            schedule: schedule,
            effectiveConfig: effectiveConfig,
            provenances: provenances,
            isImplicitRamadan: isImplicitRamadan,
            isExplicitOneOff: isExplicitOneOff,
            tagResult: tagResult,
            primaryDisplay: effectiveConfig.primaryDisplay(schedule: schedule),
            sourceSummaryText: sourceSummaryText,
            resolvedDayContext: snapshot.resolvedDayContext,
            scheduledEvents: snapshot.materializedEvents,
            decisionLog: snapshot.decisionLog,
            dailyCompletion: snapshot.dailyCompletion
        )
    }

    private static func eventDate(
        for type: ScheduledEventType,
        in events: [ScheduledEvent]
    ) -> Date? {
        events.first(where: { $0.type == type })?.fireDate
    }
}
