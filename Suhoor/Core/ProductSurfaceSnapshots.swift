import Foundation

struct HomeSurfaceSnapshot: Equatable, Sendable {
    let gregorianText: String
    let hijriText: String
    let dayLabel: String?
    let primaryContextTitle: String?
    let secondaryContextTitles: [String]
    let nextWakeEventSummary: NextWakeEventSummary?
    let supportCard: HomeSupportCardPresentation?
}

struct WakeSurfaceSnapshot: Equatable, Sendable {
    let visibleDays: [ActiveAlarmDay]
    let nextWakeEventSummary: NextWakeEventSummary?
    let overrideDateKeys: Set<String>
}

struct DefaultMorningPlanSurfaceSummary: Equatable, Sendable {
    let wakeRelation: String
    let reminder: String
    let followUp: String
    let fajrNotice: String
    let fastingDaySupport: String
    let compatibilityNote: String?
}

struct PlansSurfaceSnapshot: Equatable, Sendable {
    let defaultMorningPlanSummary: DefaultMorningPlanSurfaceSummary
    let configuredPlansSnapshot: ConfiguredPlansSnapshot
    let qadaProgress: QadaProgressSnapshot
}

struct ProgressSurfaceSnapshot: Equatable, Sendable {
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
        let wakeRelation: String
        switch defaults.defaultSuhoorTimeMode {
        case .relativeToFajrMinusMinutes:
            wakeRelation = "\(defaults.defaultSuhoorOffsetMinutes) min before Fajr"
        case .fixedTime:
            let timeText = SettingsSummaryFormatter.timeText(minutesFromMidnight: defaults.defaultSuhoorOffsetMinutes)
            wakeRelation = "\(timeText) fixed wake (compatibility)"
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
                ? "Reminder \(timeText) fixed"
                : "Reminder off"
        }

        let followUpSummary = settings.snoozeEnabled
            ? "\(settings.snoozeMinutes) min after wake"
            : "Off"

        return DefaultMorningPlanSurfaceSummary(
            wakeRelation: wakeRelation,
            reminder: reminderSummary,
            followUp: followUpSummary,
            fajrNotice: defaults.fajrEnabledDefault ? "On" : "Off",
            fastingDaySupport: defaults.iftarEnabledDefault ? "Iftar support on" : "Wake-only support",
            compatibilityNote: defaults.defaultSuhoorTimeMode == .fixedTime ? "Using fixed-time compatibility." : nil
        )
    }

    static func fastTodaySummary(entry: FastLogEntry?) -> String {
        guard let entry else { return FastLogStatus.unknown.title }
        let isQada = entry.intentSnapshot?.primaryIntent == .qadaMakeup
        switch entry.status {
        case .unknown:
            return "Not logged"
        case .inProgress:
            return isQada ? "Qada in progress" : "In progress"
        case .completed:
            return isQada ? "Qada completed" : "Completed"
        case .missed:
            return isQada ? "Qada not completed" : "Missed"
        }
    }

    static func summaryForLast30Fajr(entries: [FajrLogEntry]) -> String {
        let completed = entries.filter { $0.status == .completed }.count
        let missed = entries.filter { $0.status == .missed }.count
        if completed == 0 && missed == 0 {
            return "No logged mornings yet"
        }
        return "\(completed) made it · \(missed) missed"
    }

    static func summaryForLast30Fasts(entries: [FastLogEntry]) -> String {
        let completed = entries.filter { $0.status == .completed }.count
        let missed = entries.filter { $0.status == .missed }.count
        if completed == 0 && missed == 0 {
            return "No logged fasts yet"
        }
        return "\(completed) completed · \(missed) missed"
    }
}
