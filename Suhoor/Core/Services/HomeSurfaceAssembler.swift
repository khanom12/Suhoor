import Foundation

struct HomeSurfaceAssembler {
    func makeInput(
        now: Date,
        dismissedWarnings: Set<FastWarning>,
        activeWindowSnapshot: ActiveAlarmWindowSnapshot,
        nextWakeEventSummary: NextWakeEventSummary?,
        settings: AppSettings,
        permissionSnapshot: PermissionSnapshot,
        adjustedHijriCalendar: AdjustedHijriCalendar,
        scheduleLookup: (Date) -> DaySchedule?,
        timeZone: TimeZone = .current
    ) -> HomeSurfaceProvider.Input {
        let hijriComponents = adjustedHijriCalendar.adjustedComponents(for: now, timeZone: timeZone)
        let todayKey = DateHelpers.dayIdentifier(for: now, timeZone: timeZone)
        let todayStart = DateHelpers.startOfDay(now, in: timeZone)
        let currentDay = activeWindowSnapshot.byDateKey[todayKey]
        let todaySchedule = currentDay?.schedule ?? scheduleLookup(todayStart)
        let completionProjection = CompletionProjectionBuilder.buildHome(
            now: now,
            currentDay: currentDay,
            todaySchedule: todaySchedule,
            settings: settings,
            permissionSnapshot: permissionSnapshot,
            hijriComponents: hijriComponents,
            dismissedWarnings: dismissedWarnings
        )

        return HomeSurfaceProvider.Input(
            now: now,
            currentDay: currentDay,
            todaySchedule: todaySchedule,
            nextWakeEventSummary: nextWakeEventSummary,
            hijriComponents: hijriComponents,
            supportDecision: completionProjection.supportDecision
        )
    }
}
