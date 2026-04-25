import Foundation

struct HomeSurfaceProvider {
    struct Input {
        let now: Date
        let currentDay: ActiveAlarmDay?
        let todaySchedule: DaySchedule?
        let nextWakeEventSummary: NextWakeEventSummary?
        let hijriComponents: AdjustedHijriDateComponents?
        let supportDecision: HomeSupportDecision?
    }

    @MainActor
    func homeSurfaceSnapshot(
        input: Input,
        settings: AppSettings,
        permissionSnapshot: PermissionSnapshot
    ) -> HomeSurfaceSnapshot {
        let contextDay = input.nextWakeEventSummary?.day ?? input.currentDay
        let contextDate = contextDay?.date ?? input.now
        let heroDay = input.nextWakeEventSummary?.day

        return HomeSurfaceSnapshot(
            gregorianText: GregorianDateFormatter.shared.cardString(for: contextDate),
            hijriText: HijriDateFormatter.shared.string(from: contextDate),
            heroPresentation: heroDay.map(ProductSurfacePresentation.homeHeroPresentation(for:)),
            nextWakeEventSummary: input.nextWakeEventSummary,
            supportDecision: input.supportDecision ?? fallbackSupportDecision(
                currentDay: input.currentDay,
                todaySchedule: input.todaySchedule,
                settings: settings,
                permissionSnapshot: permissionSnapshot,
                hijriComponents: input.hijriComponents,
                now: input.now
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
