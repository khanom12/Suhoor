import SwiftUI

struct DefaultAlarmsSettingsView: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @State private var reminderTimeClamped = false
    @State private var expandedAlarm: DefaultAlarmSection? = .suhoor

    var body: some View {
        Form {
            Section {
                Toggle(Strings.Settings.wakeAlarmLabel, isOn: suhoorDefaultBinding)
                Toggle(Strings.Settings.reminderLabel, isOn: reminderDefaultBinding)
                Toggle(Strings.Settings.fajrAdhanLabel, isOn: fajrDefaultBinding)
            } header: {
                SettingsSectionHeader(
                    title: Strings.Settings.alertsSection,
                    supportingText: Strings.Settings.defaultAlarmsHelper
                )
            }

            Section {
                VStack(spacing: DesignTokens.spacingM) {
                    AlarmTimingEditor(
                        title: Strings.Settings.wakeAlarmLabel,
                        summary: wakeSummaryText,
                        isEnabled: suhoorDefaultBinding,
                        mode: suhoorEditorModeBinding,
                        relativeValue: defaultSuhoorOffsetBinding,
                        fixedTime: defaultSuhoorTimeBinding,
                        relativeLabel: Strings.Settings.minutesBeforeFajr,
                        relativeDetail: Strings.AlarmsTab.willRingAt(defaultSuhoorComputedTimeText),
                        fixedLabel: Strings.Settings.wakeTimeLabel,
                        fixedDetail: Strings.AlarmsTab.willRingAt(defaultSuhoorComputedTimeText),
                        relativeRange: 5...240,
                        relativeStep: 5,
                        warningText: nil,
                        isExpanded: expandedAlarm == .suhoor,
                        onToggleExpanded: { toggleExpanded(.suhoor) }
                    )

                    AlarmTimingEditor(
                        title: Strings.Settings.reminderLabel,
                        summary: reminderSummaryText,
                        isEnabled: reminderDefaultBinding,
                        mode: reminderEditorModeBinding,
                        relativeValue: reminderDefaultOffsetBinding,
                        fixedTime: defaultReminderTimeBinding,
                        relativeLabel: Strings.Settings.minutesBeforeFajr,
                        relativeDetail: defaultReminderFooterText,
                        fixedLabel: Strings.Settings.reminderTime,
                        fixedDetail: defaultReminderFooterText,
                        relativeRange: reminderOffsetRange,
                        relativeStep: 1,
                        warningText: showsReminderBeforeSuhoorWarning ? Strings.Settings.reminderBeforeSuhoorWarning : nil,
                        isExpanded: expandedAlarm == .reminder,
                        onToggleExpanded: { toggleExpanded(.reminder) }
                    )

                    SettingsEditorCard(
                        title: Strings.Settings.fajrAdhanLabel,
                        subtitle: fajrSummaryText,
                        trailing: AnyView(
                            Toggle("", isOn: fajrDefaultBinding)
                                .labelsHidden()
                        )
                    ) {
                        EmptyView()
                    }
                }
                .padding(.vertical, 4)
            } header: {
                SettingsSectionHeader(title: Strings.Settings.routineDefaultsSection)
            }

            Section {
                if let preview = scheduleManager.schedules.first {
                    previewRow(
                        title: Strings.Settings.wakeAlarmLabel,
                        value: alarmConfigStore.defaults.suhoorEnabledDefault
                            ? TimeFormatters.timeFormatter.string(from: preview.wakeDate)
                            : Strings.AlarmList.offLabel
                    )

                    previewRow(
                        title: Strings.Settings.reminderLabel,
                        value: alarmConfigStore.defaults.reminderEnabledDefault
                            ? preview.reminderDate.map { TimeFormatters.timeFormatter.string(from: $0) } ?? "--"
                            : Strings.AlarmList.offLabel
                    )

                    previewRow(
                        title: Strings.Settings.fajrAdhanLabel,
                        value: alarmConfigStore.defaults.fajrEnabledDefault
                            ? TimeFormatters.timeFormatter.string(from: preview.fajrDate)
                            : Strings.AlarmList.offLabel
                    )
                } else {
                    Text(Strings.Settings.previewUnavailable)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                SettingsSectionHeader(
                    title: Strings.Settings.previewSection,
                    supportingText: Strings.Settings.previewHelper
                )
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.Settings.defaultAlarmsScreenTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var wakeSummaryText: String {
        guard alarmConfigStore.defaults.suhoorEnabledDefault else {
            return Strings.AlarmsTab.alarmOffLabel
        }
        if alarmConfigStore.defaults.defaultSuhoorTimeMode == .fixedTime {
            return Strings.SettingsSummary.wakeFixed(defaultSuhoorComputedTimeText)
        }
        return Strings.SettingsSummary.wakeBeforeFajr(defaultSuhoorOffsetBinding.wrappedValue)
    }

    private var reminderSummaryText: String {
        guard alarmConfigStore.defaults.reminderEnabledDefault else {
            return Strings.AlarmsTab.alarmOffLabel
        }
        if alarmConfigStore.defaults.defaultReminderTimeMode == .fixedTime {
            return Strings.SettingsSummary.reminderFixed(defaultReminderComputedTimeText)
        }
        return Strings.SettingsSummary.reminderBeforeFajr(reminderDefaultOffsetBinding.wrappedValue)
    }

    private var fajrSummaryText: String {
        alarmConfigStore.defaults.fajrEnabledDefault
            ? Strings.AlarmsTab.fajrHelper
            : Strings.AlarmsTab.alarmOffLabel
    }

    private func previewRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private func toggleExpanded(_ section: DefaultAlarmSection) {
        expandedAlarm = expandedAlarm == section ? nil : section
    }

    private var suhoorDefaultBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.suhoorEnabledDefault
        }, set: { newValue in
            alarmConfigStore.defaults.suhoorEnabledDefault = newValue
            if newValue {
                Task { _ = await scheduleManager.enableFromUserAction() }
            } else {
                rescheduleFromDefaults()
            }
        })
    }

    private var reminderDefaultBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.reminderEnabledDefault
        }, set: { newValue in
            alarmConfigStore.defaults.reminderEnabledDefault = newValue
            rescheduleFromDefaults()
        })
    }

    private var fajrDefaultBinding: Binding<Bool> {
        Binding(get: {
            alarmConfigStore.defaults.fajrEnabledDefault
        }, set: { newValue in
            alarmConfigStore.defaults.fajrEnabledDefault = newValue
            rescheduleFromDefaults()
        })
    }

    private var suhoorEditorModeBinding: Binding<AlarmTimingEditorMode> {
        Binding(get: {
            alarmConfigStore.defaults.defaultSuhoorTimeMode == .fixedTime ? .fixedTime : .beforeFajr
        }, set: { newValue in
            suhoorTimeModeBinding.wrappedValue = newValue == .fixedTime ? .fixedTime : .relativeToFajrMinusMinutes
        })
    }

    private var reminderEditorModeBinding: Binding<AlarmTimingEditorMode> {
        Binding(get: {
            alarmConfigStore.defaults.defaultReminderTimeMode == .fixedTime ? .fixedTime : .beforeFajr
        }, set: { newValue in
            reminderTimeModeBinding.wrappedValue = newValue == .fixedTime ? .fixedTime : .beforeFajr
        })
    }

    private var suhoorTimeModeBinding: Binding<SuhoorTimeMode> {
        Binding(get: {
            alarmConfigStore.defaults.defaultSuhoorTimeMode
        }, set: { newValue in
            alarmConfigStore.defaults.defaultSuhoorTimeMode = newValue
            if newValue == .fixedTime, let wakeDate = scheduleManager.schedules.first?.wakeDate {
                alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = minutesFromMidnight(for: wakeDate)
            } else if newValue == .relativeToFajrMinusMinutes,
                      alarmConfigStore.defaults.defaultSuhoorOffsetMinutes > 240 {
                alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = 30
            }
            clampReminderFixedTimeIfNeeded()
            rescheduleFromDefaults()
        })
    }

    private var defaultSuhoorOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.defaults.defaultSuhoorOffsetMinutes
        }, set: { newValue in
            alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = newValue
            clampReminderFixedTimeIfNeeded()
            rescheduleFromDefaults()
        })
    }

    private var defaultSuhoorTimeBinding: Binding<Date> {
        Binding(get: {
            dateFromMidnight(for: Date(), minutes: alarmConfigStore.defaults.defaultSuhoorOffsetMinutes)
        }, set: { newValue in
            alarmConfigStore.defaults.defaultSuhoorOffsetMinutes = minutesFromMidnight(for: newValue)
            clampReminderFixedTimeIfNeeded()
            rescheduleFromDefaults()
        })
    }

    private var reminderDefaultOffsetBinding: Binding<Int> {
        Binding(get: {
            alarmConfigStore.defaults.defaultReminderMinutesBeforeFajr
        }, set: { newValue in
            let clamped = min(newValue, maxReminderDefaultOffset)
            alarmConfigStore.defaults.defaultReminderMinutesBeforeFajr = clamped
            reminderTimeClamped = clamped != newValue
            rescheduleFromDefaults()
        })
    }

    private var reminderTimeModeBinding: Binding<ReminderTimeMode> {
        Binding(get: {
            alarmConfigStore.defaults.defaultReminderTimeMode
        }, set: { newValue in
            alarmConfigStore.defaults.defaultReminderTimeMode = newValue
            if newValue == .fixedTime {
                let reminderSeed = scheduleManager.schedules.first?.reminderDate
                    ?? scheduleManager.schedules.first?.fajrDate
                    ?? Date()
                alarmConfigStore.defaults.defaultReminderFixedTimeMinutes = minutesFromMidnight(for: reminderSeed)
                clampReminderFixedTimeIfNeeded()
            } else {
                reminderTimeClamped = false
            }
            rescheduleFromDefaults()
        })
    }

    private var defaultReminderTimeBinding: Binding<Date> {
        Binding(get: {
            dateFromMidnight(for: Date(), minutes: alarmConfigStore.defaults.defaultReminderFixedTimeMinutes)
        }, set: { newValue in
            alarmConfigStore.defaults.defaultReminderFixedTimeMinutes = minutesFromMidnight(for: newValue)
            clampReminderFixedTimeIfNeeded()
            rescheduleFromDefaults()
        })
    }

    private var showsReminderBeforeSuhoorWarning: Bool {
        reminderTimeClamped
    }

    private var maxReminderDefaultOffset: Int {
        guard let schedule = scheduleManager.schedules.first else { return 180 }
        let minutesBetween = Int(round(schedule.fajrDate.timeIntervalSince(schedule.wakeDate) / 60))
        return max(5, min(180, minutesBetween))
    }

    private var reminderOffsetRange: ClosedRange<Int> {
        let lowerBound = min(5, maxReminderDefaultOffset)
        return lowerBound...maxReminderDefaultOffset
    }

    private var defaultSuhoorComputedTimeText: String {
        if alarmConfigStore.defaults.defaultSuhoorTimeMode == .fixedTime {
            return TimeFormatters.timeFormatter.string(from: defaultSuhoorTimeBinding.wrappedValue)
        }
        return scheduleManager.schedules.first.map { TimeFormatters.timeFormatter.string(from: $0.wakeDate) } ?? "--"
    }

    private var defaultReminderComputedTimeText: String {
        if alarmConfigStore.defaults.defaultReminderTimeMode == .fixedTime {
            return TimeFormatters.timeFormatter.string(from: defaultReminderTimeBinding.wrappedValue)
        }
        return scheduleManager.schedules.first?.reminderDate.map { TimeFormatters.timeFormatter.string(from: $0) } ?? "--"
    }

    private var defaultReminderFooterText: String {
        if !alarmConfigStore.defaults.reminderEnabledDefault {
            return Strings.AlarmsTab.reminderOff
        }
        return Strings.AlarmsTab.willRingAt(defaultReminderComputedTimeText)
    }

    private func rescheduleFromDefaults() {
        scheduleManager.requestRefresh(reason: .settingsChanged)
    }

    private func clampReminderFixedTimeIfNeeded() {
        guard alarmConfigStore.defaults.defaultReminderTimeMode == .fixedTime else {
            reminderTimeClamped = false
            return
        }
        guard let suhoorTime = defaultSuhoorSampleTime else { return }
        let reminderTime = dateFromMidnight(for: Date(), minutes: alarmConfigStore.defaults.defaultReminderFixedTimeMinutes)
        let validation = TimeValidation.validateDailyTimes(suhoorTime: suhoorTime, reminderTime: reminderTime)
        reminderTimeClamped = validation.wasClampedToSuhoor
        if validation.wasClampedToSuhoor {
            alarmConfigStore.defaults.defaultReminderFixedTimeMinutes = minutesFromMidnight(for: validation.reminderTime)
        }
    }

    private var defaultSuhoorSampleTime: Date? {
        if alarmConfigStore.defaults.defaultSuhoorTimeMode == .fixedTime {
            return dateFromMidnight(for: Date(), minutes: alarmConfigStore.defaults.defaultSuhoorOffsetMinutes)
        }
        return scheduleManager.schedules.first?.wakeDate
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
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

private enum DefaultAlarmSection {
    case suhoor
    case reminder
}
