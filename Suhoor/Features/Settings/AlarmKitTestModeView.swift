import SwiftUI

struct AlarmKitTestModeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @ObservedObject private var testSettingsStore: AlarmKitTestSettingsStore

    @State private var snapshot: AlarmKitTestSnapshot?
    @State private var isRunning = false
    @State private var cleanupCount: Int?

    init(testSettingsStore: AlarmKitTestSettingsStore) {
        self.testSettingsStore = testSettingsStore
    }

    var body: some View {
        Form {
            Section("AlarmKit Test Mode") {
                Toggle("Enable Test Mode", isOn: $testSettingsStore.settings.isEnabled)

                Stepper(
                    value: $testSettingsStore.settings.suhoorOffsetSeconds,
                    in: 10...600,
                    step: 5
                ) {
                    Text("Suhoor fires in: \(testSettingsStore.settings.suhoorOffsetSeconds)s")
                }

                Stepper(
                    value: $testSettingsStore.settings.reminderOffsetSeconds,
                    in: 10...600,
                    step: 5
                ) {
                    Text("Fajr Reminder fires in: \(testSettingsStore.settings.reminderOffsetSeconds)s")
                }

                Stepper(
                    value: $testSettingsStore.settings.adhanOffsetSeconds,
                    in: 10...600,
                    step: 5
                ) {
                    Text("Fajr Adhan fires in: \(testSettingsStore.settings.adhanOffsetSeconds)s")
                }

                Text("How to run the 60/120/180 sec test on-device: enable Test Mode, keep the app installed, tap Run Test Scenario, then lock the device and wait 1–3 minutes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Actions") {
                Button(isRunning ? "Running..." : "Run Test Scenario") {
                    Task {
                        isRunning = true
                        _ = await scheduleManager.runAlarmKitTestScenario()
                        refreshSnapshot()
                        isRunning = false
                    }
                }
                .disabled(!testSettingsStore.settings.isEnabled || isRunning)

                Button("Cancel Test Alarms") {
                    Task {
                        await scheduleManager.cancelAlarmKitTestAlarms()
                        refreshSnapshot()
                    }
                }

                Button("Stop Countdown UI") {
                    Task {
                        await scheduleManager.stopCountdownUI()
                        refreshSnapshot()
                    }
                }

                Button("Reset Test State") {
                    Task {
                        await scheduleManager.resetAlarmKitTestState()
                        refreshSnapshot()
                    }
                }

                Button("Cleanup Live Activities") {
                    Task {
                        cleanupCount = await scheduleManager.cleanupLiveActivities()
                        refreshSnapshot()
                    }
                }

                if let cleanupCount {
                    Text("Ended \(cleanupCount) Live Activity(ies).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Debug Panel") {
                TimelineView(.periodic(from: Date(), by: 1)) { context in
                    HStack {
                        Text("Current time")
                        Spacer()
                        Text(TimeFormatters.shortDateTime.string(from: context.date))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                if let testRun = snapshot?.testRun {
                    debugRow("Suhoor target", date: testRun.suhoorDate)
                    debugRow("Reminder target", date: testRun.reminderDate)
                    debugRow("Adhan target", date: testRun.adhanDate)
                } else {
                    Text("No test run scheduled.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                alarmStateRow(kind: .wake, title: "Suhoor isScheduled")
                alarmStateRow(kind: .reminder, title: "Reminder isScheduled")
                alarmStateRow(kind: .boundary, title: "Adhan isScheduled")

                countdownSection
            }

            Section("Last 20 Events") {
                if let events = snapshot?.events, !events.isEmpty {
                    ForEach(events) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(TimeFormatters.shortDateTime.string(from: event.timestamp)) • \(event.type.rawValue)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if !event.metadata.isEmpty {
                                Text(event.metadata.map { "\($0.key): \($0.value)" }.sorted().joined(separator: " | "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("No events logged yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("AlarmKit Test Mode")
        .navigationBarTitleDisplayMode(.inline)
        .formStyle(.grouped)
        .task {
            refreshSnapshot()
        }
    }

    private func refreshSnapshot() {
        snapshot = scheduleManager.alarmKitTestSnapshot()
    }

    private func debugRow(_ title: String, date: Date) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(TimeFormatters.shortDateTime.string(from: date))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private func alarmStateRow(kind: ScheduleEventKind, title: String) -> some View {
        let id = SchedulingIdentifiers.testAlarmID(for: kind)
        let isScheduled = snapshot?.alarmStates.first(where: { $0.id == id })?.state.isScheduled ?? false
        return HStack {
            Text(title)
            Spacer()
            Text(isScheduled ? "Yes" : "No")
                .foregroundStyle(isScheduled ? .green : .secondary)
        }
    }

    private var countdownSection: some View {
        Group {
            if let session = snapshot?.countdownSession {
                let remaining = max(0, Int(session.fajrDateTime.timeIntervalSince(Date())))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Countdown session: \(session.status.rawValue)")
                    Text("Fajr at \(TimeFormatters.shortDateTime.string(from: session.fajrDateTime))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Remaining: \(remaining)s")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Countdown session: none")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
