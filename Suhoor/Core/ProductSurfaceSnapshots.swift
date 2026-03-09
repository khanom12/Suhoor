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
    let wakeLead: String
    let extraWakeBuffer: String
    let reminders: String
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
}

enum ProductSurfaceSnapshots {
    static func defaultMorningPlanSummary(
        defaults: DefaultAlarmConfig,
        settings: AppSettings
    ) -> DefaultMorningPlanSurfaceSummary {
        let wakeLead: String
        switch defaults.defaultSuhoorTimeMode {
        case .relativeToFajrMinusMinutes:
            wakeLead = "\(defaults.defaultSuhoorOffsetMinutes) min before Fajr"
        case .fixedTime:
            let timeText = SettingsSummaryFormatter.timeText(minutesFromMidnight: defaults.defaultSuhoorOffsetMinutes)
            wakeLead = "Fixed at \(timeText)"
        }

        let reminderSummary: String
        switch defaults.defaultReminderTimeMode {
        case .beforeFajr:
            reminderSummary = defaults.reminderEnabledDefault
                ? "Reminder \(defaults.defaultReminderMinutesBeforeFajr) min before Fajr"
                : "Reminder off"
        case .fixedTime:
            let timeText = SettingsSummaryFormatter.timeText(minutesFromMidnight: defaults.defaultReminderFixedTimeMinutes)
            reminderSummary = defaults.reminderEnabledDefault
                ? "Reminder at \(timeText)"
                : "Reminder off"
        }

        let prayerTimes = defaults.fajrEnabledDefault
            ? "Fajr adhan on"
            : "Fajr adhan off"

        return DefaultMorningPlanSurfaceSummary(
            wakeLead: wakeLead,
            extraWakeBuffer: settings.snoozeEnabled ? "\(settings.snoozeMinutes) min follow-up" : "Off",
            reminders: reminderSummary,
            prayerTimes: prayerTimes,
            tahajjudBehavior: nil
        )
    }

}
