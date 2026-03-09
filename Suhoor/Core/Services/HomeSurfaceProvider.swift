import Foundation

struct HomeSurfaceProvider {
    func homeSurfaceSnapshot(
        now: Date,
        currentDay: ActiveAlarmDay?,
        todaySchedule: DaySchedule?,
        nextWakeEventSummary: NextWakeEventSummary?,
        permissionSnapshot: PermissionSnapshot,
        hijriComponents: AdjustedHijriDateComponents?,
        supportDecision: HomeSupportDecision?,
        dayLabel: (Date) -> String
    ) -> HomeSurfaceSnapshot {
        let contextDay = nextWakeEventSummary?.day ?? currentDay

        return HomeSurfaceSnapshot(
            gregorianText: GregorianDateFormatter.shared.headerString(for: now),
            hijriText: HijriDateFormatter.shared.string(from: now),
            dayLabel: contextDay.map { dayLabel($0.date) },
            primaryContextTitle: contextDay.map {
                ProductSurfacePresentation.primaryContextTitle($0.resolvedDayContext.primaryContext)
            },
            secondaryContextTitles: contextDay.map {
                ProductSurfacePresentation.meaningfulSecondaryContextTitles(from: $0.resolvedDayContext)
            } ?? [],
            nextWakeEventSummary: nextWakeEventSummary,
            supportDecision: supportDecision ?? fallbackSupportDecision(
                currentDay: currentDay,
                todaySchedule: todaySchedule,
                permissionSnapshot: permissionSnapshot,
                hijriComponents: hijriComponents,
                now: now
            )
        )
    }

    private func fallbackSupportDecision(
        currentDay: ActiveAlarmDay?,
        todaySchedule: DaySchedule?,
        permissionSnapshot: PermissionSnapshot,
        hijriComponents: AdjustedHijriDateComponents?,
        now: Date
    ) -> HomeSupportDecision? {
        CompletionProjectionBuilder.buildHome(
            now: now,
            currentDay: currentDay,
            todaySchedule: todaySchedule,
            permissionSnapshot: permissionSnapshot,
            hijriComponents: hijriComponents,
            dismissedWarnings: []
        ).supportDecision
    }
}
