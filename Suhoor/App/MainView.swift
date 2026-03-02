import SwiftUI

struct MainView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @State private var showAdjustSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Tomorrow")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Toggle("", isOn: alarmEnabledBinding)
                                .labelsHidden()
                                .accessibilityLabel("Enable Suhoor Routine")
                        }

                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(wakeTimeText)
                                    .font(.system(.largeTitle, design: .rounded))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text("Wake")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .leading, spacing: 4) {
                                Text(fajrTimeText)
                                    .font(.title2)
                                    .monospacedDigit()
                                Text("Fajr")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(subtext)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .cardStyle()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)
                }

                Section {
                    Button("Adjust") { showAdjustSheet = true }
                }

            }
            .listStyle(.insetGrouped)
            .navigationTitle("Suhoor")
        }
        .sheet(isPresented: $showAdjustSheet) {
            AlarmDetailView()
        }
    }

    private var tomorrowSchedule: DaySchedule? {
        scheduleManager.schedules.first
    }

    private var wakeTimeText: String {
        guard settingsStore.settings.isEnabled,
              let schedule = tomorrowSchedule else {
            return "--"
        }
        return TimeFormatters.timeFormatter.string(from: schedule.wakeDate)
    }

    private var fajrTimeText: String {
        guard settingsStore.settings.isEnabled,
              let schedule = tomorrowSchedule else {
            return "--"
        }
        return TimeFormatters.timeFormatter.string(from: schedule.fajrDate)
    }

    private var subtext: String {
        guard let schedule = tomorrowSchedule else {
            return "Wake before Fajr"
        }
        var text = "Wake \(schedule.offsetMinutes) min before Fajr"
        let key = DateHelpers.dayIdentifier(for: schedule.date, timeZone: .current)
        if let exception = settingsStore.settings.perDayExceptions[key],
           (exception.wakeOffsetOverrideMinutes != nil
            || exception.reminderEnabledOverride != nil
            || exception.reminderMinutesOverride != nil
            || exception.atFajrEnabledOverride != nil
            || exception.atFajrSoundOverride != nil) {
            text += " · Custom"
        }
        return text
    }

    private var alarmEnabledBinding: Binding<Bool> {
        Binding {
            settingsStore.settings.isEnabled
        } set: { newValue in
            Haptics.medium()
            settingsStore.update { draft in
                draft.isEnabled = newValue
            }
            if newValue {
                Task { _ = await scheduleManager.enableFromUserAction() }
            } else {
                Task { await scheduleManager.disableFromUserAction() }
            }
        }
    }
}
