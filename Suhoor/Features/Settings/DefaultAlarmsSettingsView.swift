import SwiftUI

struct DefaultAlarmsSettingsView: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @State private var reminderTimeClamped = false

    var body: some View {
        Form {
            Section {
                Toggle(Strings.Settings.wakeAlarmLabel, isOn: suhoorDefaultBinding)
                Toggle(Strings.Settings.reminderLabel, isOn: reminderDefaultBinding)
                Toggle(Strings.Settings.fajrAdhanLabel, isOn: fajrDefaultBinding)
            } header: {
                Text(Strings.Settings.alertsSection)
            } footer: {
                Text(Strings.Settings.defaultAlarmsHelper)
            }

            Section {
                Picker(Strings.Settings.timeStyleLabel, selection: suhoorTimeModeBinding) {
                    ForEach(SuhoorTimeMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if alarmConfigStore.defaults.defaultSuhoorTimeMode == .fixedTime {
                    DatePicker(
                        Strings.Settings.wakeTimeLabel,
                        selection: defaultSuhoorTimeBinding,
                        displayedComponents: [.hourAndMinute]
                    )
                } else {
                    NavigationLink {
                        OffsetSelectionView(
                            title: Strings.Settings.wakeOffsetTitle,
                            stepperLabel: Strings.Settings.minutesBeforeFajr,
                            minutes: defaultSuhoorOffsetBinding,
                            presets: [15, 30, 45, 60, 90],
                            range: 5...240,
                            step: 5
                        )
                    } label: {
                        valueRow(
                            title: Strings.Settings.minutesBeforeFajr,
                            value: Strings.Settings.offsetValue(defaultSuhoorOffsetBinding.wrappedValue)
                        )
                    }
                }
            } header: {
                Text(Strings.Settings.wakeAlarmSection)
            } footer: {
                Text(Strings.Settings.wakeAlarmHelper)
            }

            Section {
                Picker(Strings.Settings.timeStyleLabel, selection: reminderTimeModeBinding) {
                    ForEach(ReminderTimeMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if alarmConfigStore.defaults.defaultReminderTimeMode == .fixedTime {
                    DatePicker(
                        Strings.Settings.reminderTime,
                        selection: defaultReminderTimeBinding,
                        displayedComponents: [.hourAndMinute]
                    )
                } else {
                    NavigationLink {
                        OffsetSelectionView(
                            title: Strings.Settings.reminderOffsetTitle,
                            stepperLabel: Strings.Settings.minutesBeforeFajr,
                            minutes: reminderDefaultOffsetBinding,
                            presets: [5, 10, 15, 20, 30],
                            range: 5...maxReminderDefaultOffset,
                            step: 1
                        )
                    } label: {
                        valueRow(
                            title: Strings.Settings.minutesBeforeFajr,
                            value: Strings.Settings.offsetValue(reminderDefaultOffsetBinding.wrappedValue)
                        )
                    }
                }

                if showsReminderBeforeSuhoorWarning {
                    Text(Strings.Settings.reminderBeforeSuhoorWarning)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text(Strings.Settings.reminderSection)
            } footer: {
                Text(Strings.Settings.reminderScreenHelper)
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
                Text(Strings.Settings.previewSection)
            } footer: {
                Text(Strings.Settings.previewHelper)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.Settings.defaultAlarmsScreenTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func valueRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
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
