import Foundation

struct HomeSurfaceProvider {
    func homeSurfaceSnapshot(
        now: Date,
        currentDay: ActiveAlarmDay?,
        todaySchedule: DaySchedule?,
        nextWakeEventSummary: NextWakeEventSummary?,
        settings: AppSettings,
        permissionSnapshot: PermissionSnapshot,
        hijriComponents: AdjustedHijriDateComponents?,
        supportDecision: HomeSupportDecision?,
        dayLabel: (Date) -> String
    ) -> HomeSurfaceSnapshot {
        let contextDay = nextWakeEventSummary?.day ?? currentDay
        let contextDate = contextDay?.date ?? now
        let contextDayLabel = contextDay.map { dayLabel($0.date) }

        return HomeSurfaceSnapshot(
            gregorianText: GregorianDateFormatter.shared.headerString(for: contextDate),
            hijriText: HijriDateFormatter.shared.string(from: contextDate),
            contextSummaryText: contextDay.map {
                ProductSurfacePresentation.homeContextSummaryText(for: $0, dayLabel: contextDayLabel)
            },
            secondaryContextTitles: contextDay.map {
                ProductSurfacePresentation.scheduleChipTitles(for: $0, hasDayOverride: false)
            } ?? [],
            nextWakeEventSummary: nextWakeEventSummary,
            supportDecision: supportDecision ?? fallbackSupportDecision(
                currentDay: currentDay,
                todaySchedule: todaySchedule,
                settings: settings,
                permissionSnapshot: permissionSnapshot,
                hijriComponents: hijriComponents,
                now: now
            )
        )
    }

    private func fallbackSupportDecision(
        currentDay: ActiveAlarmDay?,
        todaySchedule: DaySchedule?,
        settings: AppSettings,
        permissionSnapshot: PermissionSnapshot,
        hijriComponents: AdjustedHijriDateComponents?,
        now: Date
    ) -> HomeSupportDecision? {
        CompletionProjectionBuilder.buildHome(
            now: now,
            currentDay: currentDay,
            todaySchedule: todaySchedule,
            settings: settings,
            permissionSnapshot: permissionSnapshot,
            hijriComponents: hijriComponents,
            dismissedWarnings: []
        ).supportDecision
    }
}
