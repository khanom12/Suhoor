import Foundation

struct RuleSummary: Sendable {
    let baseOffsetMinutes: Int
    let finalOffsetMinutes: Int
    let overrideOffsetMinutes: Int?
    let disabledForDay: Bool
}

struct RuleEngine: Sendable {
    let settings: AppSettings
    let defaultConfig: DefaultAlarmConfig
    let overridesByDay: [String: DailyAlarmOverride]
    let timeZone: TimeZone

    init(
        settings: AppSettings,
        defaultConfig: DefaultAlarmConfig = .default,
        overridesByDay: [String: DailyAlarmOverride] = [:],
        timeZone: TimeZone = .current
    ) {
        self.settings = settings
        self.defaultConfig = defaultConfig
        self.overridesByDay = overridesByDay
        self.timeZone = timeZone
    }

    func effectiveWakeOffsetMinutes(for date: Date) -> Int {
        ruleSummary(for: date).finalOffsetMinutes
    }

    func effectiveReminderEnabled(for date: Date) -> Bool {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let override = overridesByDay[key]?.reminderEnabled {
            return override
        }
        return defaultsActive(on: date) ? defaultConfig.reminderEnabledDefault : false
    }

    func effectiveAtFajrEnabled(for date: Date) -> Bool {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let override = overridesByDay[key]?.fajrEnabled {
            return override
        }
        return defaultsActive(on: date) ? defaultConfig.fajrEnabledDefault : false
    }

    func effectiveAtFajrSoundChoice(for date: Date) -> SoundChoice {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let override = overridesByDay[key]?.fajrSoundOverride {
            return override
        }
        return settings.atFajrSoundSelectionGlobal
    }

    func effectiveReminderMinutes(for date: Date) -> Int {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let override = overridesByDay[key]?.reminderOffsetOverrideMinutes {
            return override
        }
        return defaultConfig.defaultReminderMinutesBeforeFajr
    }

    func ruleSummary(for date: Date) -> RuleSummary {
        let baseOffset = defaultConfig.defaultSuhoorOffsetMinutes
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if let override = overridesByDay[key] {
            if override.skipDay {
                return RuleSummary(
                    baseOffsetMinutes: baseOffset,
                    finalOffsetMinutes: baseOffset,
                    overrideOffsetMinutes: override.suhoorOffsetOverrideMinutes,
                    disabledForDay: true
                )
            }
            if let overrideMinutes = override.suhoorOffsetOverrideMinutes {
                return RuleSummary(
                    baseOffsetMinutes: baseOffset,
                    finalOffsetMinutes: overrideMinutes,
                    overrideOffsetMinutes: overrideMinutes,
                    disabledForDay: false
                )
            }
        }

        return RuleSummary(
            baseOffsetMinutes: baseOffset,
            finalOffsetMinutes: baseOffset,
            overrideOffsetMinutes: nil,
            disabledForDay: false
        )
    }

    private func defaultsActive(on date: Date) -> Bool {
        switch defaultConfig.activationMode {
        case .alwaysOn:
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            if defaultConfig.deletedDates.contains(key) {
                return false
            }
            return true
        case .dateRange:
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            if defaultConfig.deletedDates.contains(key) {
                return false
            }
            if defaultConfig.extraOneOffDates.contains(key) {
                return true
            }
            guard let start = defaultConfig.activeStartDate, let end = defaultConfig.activeEndDate else {
                return false
            }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let target = calendar.startOfDay(for: date)
            let startDay = calendar.startOfDay(for: start)
            let endDay = calendar.startOfDay(for: end)
            return target >= startDay && target <= endDay
        }
    }
}
