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
        _ = dayLabel
        let contextDay = nextWakeEventSummary?.day ?? currentDay
        let contextDate = contextDay?.date ?? now
        let heroDay = nextWakeEventSummary?.day

        return HomeSurfaceSnapshot(
            gregorianText: GregorianDateFormatter.shared.headerString(for: contextDate),
            hijriText: HijriDateFormatter.shared.string(from: contextDate),
            heroLabel: heroDay.map(ProductSurfacePresentation.homeHeroLabel(for:)),
            heroSubline: heroDay.map(ProductSurfacePresentation.homeHeroSubline(for:)),
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
