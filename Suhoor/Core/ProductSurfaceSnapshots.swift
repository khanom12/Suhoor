import Foundation

struct HomeSurfaceSnapshot: Equatable, Sendable {
    let gregorianText: String
    let hijriText: String
    let heroLabel: String?
    let heroSubline: String?
    let nextWakeEventSummary: NextWakeEventSummary?
    let supportDecision: HomeSupportDecision?

    var supportCard: HomeSupportCardPresentation? {
        supportDecision?.presentation
    }
}

struct WakeSurfaceSnapshot: Equatable, Sendable {
    let visibleDays: [ActiveAlarmDay]
    let nextWakeEventSummary: NextWakeEventSummary?
    let overrideDateKeys: Set<String>
}

struct DefaultMorningPlanSurfaceSummary: Equatable, Sendable {
    let wakeTiming: String
    let anchor: String
    let wakeOffset: String
    let reserveBeforeEnd: String
    let latestWake: String
    let fastingCues: String
    let sounds: String
    let prayerTimes: String
    let tahajjudBehavior: String?
}

struct PlansSurfaceSnapshot: Equatable, Sendable {
    let defaultMorningPlanSummary: DefaultMorningPlanSurfaceSummary
    let configuredPlansSnapshot: ConfiguredPlansSnapshot
    let qadaProgress: QadaProgressSnapshot
}

struct ProgressSurfaceSnapshot: Equatable, Sendable {
    let headlineText: String?
    let fastSectionTitle: String
    let fajrTodaySummary: String
    let fajrSummary: String
    let fastTodaySummary: String
    let fastSummary: String
    let qadaProgress: QadaProgressSnapshot
    let wakeProgress: WakeProgressSnapshot

    static let empty = ProgressSurfaceSnapshot(
        headlineText: nil,
        fastSectionTitle: "Fasts",
        fajrTodaySummary: "Not logged",
        fajrSummary: "No logged mornings yet",
        fastTodaySummary: "Not logged",
        fastSummary: "No logged fasts yet",
        qadaProgress: QadaProgressSnapshot(remaining: 0, completed: 0, baselineOwed: 0),
        wakeProgress: .empty
    )
}

enum ProductSurfaceSnapshots {
    static func defaultMorningPlanSummary(
        defaults: DefaultAlarmConfig,
        settings: AppSettings
    ) -> DefaultMorningPlanSurfaceSummary {
        return DefaultMorningPlanSurfaceSummary(
            wakeTiming: ProductSurfacePresentation.defaultWakeTimingText(for: defaults),
            anchor: ProductSurfacePresentation.defaultWakeAnchorText(for: defaults),
            wakeOffset: ProductSurfacePresentation.defaultWakeOffsetText(for: defaults),
            reserveBeforeEnd: ProductSurfacePresentation.defaultReserveSummaryText(
                defaults: defaults,
                settings: settings
            ),
            latestWake: ProductSurfacePresentation.latestWakeSummaryText(
                minutesFromMidnight: defaults.defaultLatestWakeCapMinutesFromMidnight
            ),
            fastingCues: ProductSurfacePresentation.defaultFastingCueSummaryText(
                defaults: defaults,
                settings: settings
            ),
            sounds: ProductSurfacePresentation.soundSummaryText(settings: settings),
            prayerTimes: defaults.fajrEnabledDefault ? "Fajr cue on" : "Fajr cue off",
            tahajjudBehavior: defaults.defaultWakeState == .preFajr
                ? "Tahajjud stays a date-level refinement."
                : nil
        )
    }

}
