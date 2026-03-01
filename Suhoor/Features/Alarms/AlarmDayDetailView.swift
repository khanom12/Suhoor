import SwiftUI

struct AlarmDayDetailView: View {
    let schedule: DaySchedule

    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private let timeZone: TimeZone = .current
    @State private var reminderTimeClamped = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(HijriDateFormatter.shared.string(from: schedule.date))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(TimeFormatters.timeFormatter.string(from: suhoorTime))
                        .font(.system(size: 56, weight: .light, design: .default))
                        .monospacedDigit()

                    Text("Fajr \(TimeFormatters.timeFormatter.string(from: schedule.fajrDate))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }

            Section {
                Toggle("Enable this day", isOn: dayActiveBinding)

                if !dayActiveBinding.wrappedValue {
                    Text("No alarms will run on this date.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(Strings.AlarmsTab.suhoorLabel) {
                Toggle(Strings.AlarmsTab.enabledLabel, isOn: suhoorEnabledBinding)
                    .disabled(isSkippingDay)

                Toggle(Strings.AlarmsTab.useFixedTime, isOn: suhoorFixedTimeBinding)
                    .disabled(isSkippingDay)

                if usesFixedSuhoorTime {
                    DatePicker(
                        Strings.AlarmsTab.suhoorTime,
                        selection: suhoorTimeBinding,
                        displayedComponents: [.hourAndMinute]
                    )
                    .disabled(isSkippingDay)
                } else {
                    Stepper(value: suhoorOffsetBinding, in: 5...240, step: 5) {
                        Text("Minutes before Fajr: \(suhoorOffsetBinding.wrappedValue)m")
                    }
                    .disabled(isSkippingDay)
                }

                Text(Strings.AlarmsTab.suhoorComputed(TimeFormatters.timeFormatter.string(from: suhoorTime)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(Strings.AlarmsTab.reminderLabel) {
                Toggle(Strings.AlarmsTab.enabledLabel, isOn: reminderEnabledBinding)
                    .disabled(isSkippingDay)

                if usesFixedReminderTime {
                    DatePicker(
                        Strings.Settings.reminderTime,
                        selection: reminderFixedTimeBinding,
                        displayedComponents: [.hourAndMinute]
                    )
                    .disabled(isSkippingDay || !effectiveConfig.reminderEnabled)
                } else {
                    Stepper(value: reminderOffsetBinding, in: 1...maxReminderOffsetMinutes, step: 1) {
                        Text(Strings.AlarmsTab.reminderOffsetLabel(reminderOffsetBinding.wrappedValue))
                    }
                    .disabled(isSkippingDay || !effectiveConfig.reminderEnabled)
                }

                Text(reminderFooterText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if reminderTimeClamped || reminderValidationResult?.wasClampedToSuhoor == true {
                    Text(Strings.Settings.reminderBeforeSuhoorWarning)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }

            Section(Strings.AlarmsTab.fajrLabel) {
                Toggle(Strings.AlarmsTab.enabledLabel, isOn: fajrEnabledBinding)
                    .disabled(isSkippingDay)

                Text(Strings.AlarmsTab.fajrComputed(TimeFormatters.timeFormatter.string(from: schedule.fajrDate)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(Strings.AlarmsTab.resetDay, role: .destructive) {
                    alarmConfigStore.removeOverride(for: schedule.date, timeZone: timeZone)
                    Task { await scheduleManager.rescheduleDay(schedule.date) }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(GregorianDateFormatter.shared.cardString(for: schedule.date))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var ruleEngine: RuleEngine {
        RuleEngine(settings: settingsStore.settings, configStore: alarmConfigStore, timeZone: timeZone)
    }

    private var effectiveConfig: EffectiveDailyConfig {
        alarmConfigStore.effectiveConfig(
            for: schedule.date,
            ruleSummary: ruleEngine.ruleSummary(for: schedule.date),
            settings: settingsStore.settings,
            timeZone: timeZone
        )
    }

    private var isSkippingDay: Bool {
        effectiveConfig.skipDay
    }

    private var skipBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.skipDay ?? false
        }, set: { newValue in
            updateOverride { $0.skipDay = newValue }
        })
    }

    private var dayActiveBinding: Binding<Bool> {
        Binding(get: {
            !skipBinding.wrappedValue
        }, set: { newValue in
            updateOverride { $0.skipDay = !newValue }
        })
    }

    private var suhoorEnabledBinding: Binding<Bool> {
        Binding(get: {
            effectiveConfig.suhoorEnabled
        }, set: { newValue in
            updateOverride { $0.suhoorEnabled = newValue }
        })
    }

    private var reminderEnabledBinding: Binding<Bool> {
        Binding(get: {
            effectiveConfig.reminderEnabled
        }, set: { newValue in
            updateOverride { $0.reminderEnabled = newValue }
        })
    }

    private var fajrEnabledBinding: Binding<Bool> {
        Binding(get: {
            effectiveConfig.fajrEnabled
        }, set: { newValue in
            updateOverride { $0.fajrEnabled = newValue }
        })
    }

    private var suhoorOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.suhoorOffsetOverrideMinutes
                ?? ruleEngine.ruleSummary(for: schedule.date).finalOffsetMinutes
        }, set: { newValue in
            updateOverride { $0.suhoorOffsetOverrideMinutes = newValue }
            clampReminderOffsetIfNeeded()
        })
    }

    private var suhoorFixedTimeBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.suhoorTimeOverrideMinutesFromMidnight != nil
        }, set: { newValue in
            updateOverride { override in
                if newValue {
                    override.suhoorTimeOverrideMinutesFromMidnight = minutesFromMidnight(for: schedule.wakeDate)
                } else {
                    override.suhoorTimeOverrideMinutesFromMidnight = nil
                }
            }
            clampReminderOffsetIfNeeded()
        })
    }

    private var usesFixedSuhoorTime: Bool {
        alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.suhoorTimeOverrideMinutesFromMidnight != nil
    }

    private var suhoorTimeBinding: Binding<Date> {
        Binding(get: {
            if let overrideMinutes = alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.suhoorTimeOverrideMinutesFromMidnight {
                return dateFromMidnight(for: schedule.date, minutes: overrideMinutes)
            }
            return suhoorTime
        }, set: { newValue in
            updateOverride { override in
                override.suhoorTimeOverrideMinutesFromMidnight = minutesFromMidnight(for: newValue)
            }
            clampReminderOffsetIfNeeded()
        })
    }

    private var reminderOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.reminderOffsetOverrideMinutes
                ?? effectiveConfig.reminderMinutesBeforeFajr
        }, set: { newValue in
            let clamped = min(newValue, maxReminderOffsetMinutes)
            updateOverride { override in
                override.reminderOffsetOverrideMinutes = clamped
                override.reminderTimeOverrideMinutesFromMidnight = nil
            }
            reminderTimeClamped = clamped != newValue
        })
    }

    private var reminderFixedTimeBinding: Binding<Date> {
        Binding(get: {
            if let overrideMinutes = alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.reminderTimeOverrideMinutesFromMidnight {
                return dateFromMidnight(for: schedule.date, minutes: overrideMinutes)
            }
            return dateFromMidnight(for: schedule.date, minutes: effectiveConfig.reminderFixedTimeMinutes)
        }, set: { newValue in
            let validation = TimeValidation.validateDailyTimes(suhoorTime: suhoorTime, reminderTime: newValue)
            updateOverride { override in
                override.reminderTimeOverrideMinutesFromMidnight = minutesFromMidnight(for: validation.reminderTime)
                override.reminderOffsetOverrideMinutes = nil
            }
            reminderTimeClamped = validation.wasClampedToSuhoor
        })
    }

    private var reminderFooterText: String {
        if !effectiveConfig.reminderEnabled {
            return Strings.AlarmsTab.reminderOff
        }
        if let reminderDate = reminderTime {
            return Strings.AlarmsTab.reminderComputed(TimeFormatters.timeFormatter.string(from: reminderDate))
        }
        return Strings.AlarmsTab.reminderOff
    }

    private var maxReminderOffsetMinutes: Int {
        let minutesBetween = Int(round(schedule.fajrDate.timeIntervalSince(suhoorTime) / 60))
        return max(1, minutesBetween)
    }

    private var suhoorTime: Date {
        if let overrideMinutes = effectiveConfig.suhoorTimeOverrideMinutesFromMidnight {
            return dateFromMidnight(for: schedule.date, minutes: overrideMinutes)
        }
        if effectiveConfig.suhoorTimeMode == .fixedTime {
            return dateFromMidnight(for: schedule.date, minutes: effectiveConfig.suhoorOffsetMinutes)
        }
        return ScheduleEventCalculator.wakeDate(
            for: schedule.fajrDate,
            offsetMinutes: effectiveConfig.suhoorOffsetMinutes,
            calendar: calendar
        )
    }

    private var reminderTime: Date? {
        reminderValidationResult?.reminderTime
    }

    private var usesFixedReminderTime: Bool {
        if alarmConfigStore.override(for: schedule.date, timeZone: timeZone)?.reminderTimeOverrideMinutesFromMidnight != nil {
            return true
        }
        return effectiveConfig.reminderTimeMode == .fixedTime
    }

    private var reminderValidationResult: TimeValidationResult? {
        guard effectiveConfig.reminderEnabled else { return nil }
        let reminderDate: Date
        if let overrideMinutes = effectiveConfig.reminderTimeOverrideMinutesFromMidnight {
            reminderDate = dateFromMidnight(for: schedule.date, minutes: overrideMinutes)
        } else if effectiveConfig.reminderTimeMode == .fixedTime {
            reminderDate = dateFromMidnight(for: schedule.date, minutes: effectiveConfig.reminderFixedTimeMinutes)
        } else {
            reminderDate = ScheduleEventCalculator.reminderDate(
                for: schedule.fajrDate,
                reminderMinutes: effectiveConfig.reminderMinutesBeforeFajr,
                calendar: calendar
            )
        }
        return TimeValidation.validateDailyTimes(suhoorTime: suhoorTime, reminderTime: reminderDate)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private func updateOverride(_ update: (inout DailyAlarmOverride) -> Void) {
        alarmConfigStore.updateOverride(for: schedule.date, timeZone: timeZone, update: update)
        Task { await scheduleManager.rescheduleDay(schedule.date) }
    }

    private func clampReminderOffsetIfNeeded() {
        guard let override = alarmConfigStore.override(for: schedule.date, timeZone: timeZone),
              let reminderOverride = override.reminderOffsetOverrideMinutes else { return }
        let clamped = min(reminderOverride, maxReminderOffsetMinutes)
        guard clamped != reminderOverride else { return }
        alarmConfigStore.updateOverride(for: schedule.date, timeZone: timeZone) { draft in
            draft.reminderOffsetOverrideMinutes = clamped
        }
        Task { await scheduleManager.rescheduleDay(schedule.date) }
    }

    private func minutesFromMidnight(for date: Date) -> Int {
        let start = calendar.startOfDay(for: date)
        return max(0, Int(round(date.timeIntervalSince(start) / 60)))
    }

    private func dateFromMidnight(for day: Date, minutes: Int) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: start) ?? start
    }
}
