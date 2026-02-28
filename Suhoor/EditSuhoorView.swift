import SwiftUI

struct EditSuhoorView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                summarySection
                wakeSection
                alertDefaultsSection
                snoozeSection
                labelSection
                scheduleSection
            }
            .navigationTitle(Strings.AlarmDetail.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var nextSchedule: DaySchedule? {
        scheduleManager.nextUpcomingSchedule
    }

    private var summarySection: some View {
        Section(Strings.AlarmDetail.nextSection) {
            HStack {
                Text(Strings.AlarmDetail.wakeRow)
                Spacer()
                Text(nextAlarmText)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            if let schedule = nextSchedule {
                HStack {
                    Text(Strings.AlarmDetail.fajrRow)
                    Spacer()
                    Text(TimeFormatters.timeFormatter.string(from: schedule.fajrDate))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(Strings.AlarmList.notSetUp)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(Strings.AlarmDetail.updatesFooter)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var wakeSection: some View {
        Section(Strings.AlarmDetail.wakeSection) {
            NavigationLink {
                OffsetPickerScreen(title: Strings.AlarmDetail.wakeMe, baseMinutes: $settingsStore.settings.baseWakeOffsetMinutes, range: 1...240, step: 1)
                    .onDisappear { Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) } }
            } label: {
                HStack {
                    Text(Strings.AlarmDetail.wakeMe)
                    Spacer()
                    Text("\(settingsStore.settings.baseWakeOffsetMinutes)m before Fajr")
                        .foregroundStyle(.secondary)
                }
            }

            Text(Strings.AlarmDetail.wakeHelper)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var alertDefaultsSection: some View {
        Section(Strings.AlarmDetail.alertDefaultsSection) {
            Button(Strings.AlarmDetail.editAlertDefaults) {
                NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
                dismiss()
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Text(Strings.AlarmDetail.alertDefaultsHelper)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var snoozeSection: some View {
        Section(Strings.AlarmDetail.snoozeSection) {
            Toggle(Strings.AlarmDetail.snoozeToggle, isOn: $settingsStore.settings.snoozeEnabled)

            if settingsStore.settings.snoozeEnabled {
                Picker(Strings.AlarmDetail.snoozeDuration, selection: $settingsStore.settings.snoozeMinutes) {
                    ForEach([5, 9, 10, 15], id: \.self) { value in
                        Text("\(value) minutes").tag(value)
                    }
                }

                Text(Strings.AlarmDetail.snoozeHelper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var labelSection: some View {
        Section(Strings.AlarmDetail.labelSection) {
            TextField(Strings.AlarmDetail.labelSection, text: $settingsStore.settings.label)
        }
    }

    private var scheduleSection: some View {
        Section {
            Button(Strings.AlarmDetail.viewSchedule) {
                NotificationCenter.default.post(name: .switchToScheduleTab, object: nil)
                dismiss()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var nextAlarmText: String {
        guard let schedule = nextSchedule else { return "--" }
        let weekday = TimeFormatters.dayFormatter.string(from: schedule.wakeDate)
        let time = TimeFormatters.timeFormatter.string(from: schedule.wakeDate)
        return "\(weekday) \(time)"
    }
}

private struct ReminderOffsetPickerView: View {
    @Binding var minutes: Int
    @Environment(\.dismiss) private var dismiss

    private let options = [5, 10, 15, 20, 30]

    var body: some View {
        Form {
            Picker(Strings.AlarmDetail.reminderTime, selection: $minutes) {
                ForEach(options, id: \.self) { option in
                    Text("\(option)m before Fajr").tag(option)
                }
            }
        }
        .navigationTitle("Reminder time")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
