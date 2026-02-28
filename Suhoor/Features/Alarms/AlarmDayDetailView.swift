import SwiftUI

struct AlarmDayDetailView: View {
    let schedule: DaySchedule

    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private let timeZone: TimeZone = .current

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DawnColor.bgWarmTop, DawnColor.bgWarmBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.spacingL) {
                    headerCard
                    skipCard
                    suhoorCard
                    reminderCard
                    fajrCard
                    resetCard
                }
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.top, DesignTokens.spacingL)
                .padding(.bottom, DesignTokens.spacingM)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
    }

    private var headerCard: some View {
        GlassCard(style: .header, padding: DesignTokens.spacingM) {
            VStack(alignment: .leading, spacing: 6) {
                Text(TimeFormatters.dayFormatter.string(from: schedule.date))
                    .font(DesignTokens.screenTitleFont)
                Text(TimeFormatters.fullDateTitle.string(from: schedule.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var skipCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView(Strings.DayDetail.exceptionSection)
                Toggle(Strings.DayDetail.skipDay, isOn: skipBinding)
            }
        }
    }

    private var suhoorCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView(Strings.AlarmsTab.suhoorLabel)

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
                    OffsetPickerView(
                        baseMinutes: suhoorOffsetBinding,
                        presetMinutes: [15, 30, 45, 60, 90],
                        range: 5...240,
                        step: 5,
                        sentenceText: { "Wake me \($0) min before Fajr." }
                    )
                    .disabled(isSkippingDay)
                }

                Text(Strings.AlarmsTab.suhoorComputed(TimeFormatters.timeFormatter.string(from: suhoorTime)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var reminderCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView(Strings.AlarmsTab.reminderLabel)

                Toggle(Strings.AlarmsTab.enabledLabel, isOn: reminderEnabledBinding)
                    .disabled(isSkippingDay)

                Stepper(value: reminderOffsetBinding, in: 1...maxReminderOffsetMinutes, step: 1) {
                    Text(Strings.AlarmsTab.reminderOffsetLabel(reminderOffsetBinding.wrappedValue))
                }
                .disabled(isSkippingDay || !effectiveConfig.reminderEnabled)

                Text(reminderFooterText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var fajrCard: some View {
        GlassCard(style: .normal) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                SectionHeaderView(Strings.AlarmsTab.fajrLabel)

                Toggle(Strings.AlarmsTab.enabledLabel, isOn: fajrEnabledBinding)
                    .disabled(isSkippingDay)

                Text(Strings.AlarmsTab.fajrComputed(TimeFormatters.timeFormatter.string(from: schedule.fajrDate)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var resetCard: some View {
        GlassCard(style: .normal) {
            Button(Strings.AlarmsTab.resetDay) {
                alarmConfigStore.removeOverride(for: schedule.date, timeZone: timeZone)
                Task { await scheduleManager.rescheduleDay(schedule.date) }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
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
                ?? effectiveConfig.reminderOffsetMinutes
        }, set: { newValue in
            let clamped = min(newValue, maxReminderOffsetMinutes)
            updateOverride { $0.reminderOffsetOverrideMinutes = clamped }
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
        return max(1, minutesBetween - 1)
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
        guard effectiveConfig.reminderEnabled else { return nil }
        let reminderDate: Date
        if let overrideMinutes = effectiveConfig.reminderTimeOverrideMinutesFromMidnight {
            reminderDate = dateFromMidnight(for: schedule.date, minutes: overrideMinutes)
        } else {
            reminderDate = ScheduleEventCalculator.reminderDate(
                for: schedule.fajrDate,
                reminderMinutes: effectiveConfig.reminderOffsetMinutes,
                calendar: calendar
            )
        }
        if reminderDate < suhoorTime {
            return suhoorTime
        }
        return reminderDate
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
