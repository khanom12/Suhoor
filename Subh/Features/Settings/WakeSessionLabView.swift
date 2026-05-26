#if DEBUG || INTERNAL_TESTING
import SwiftUI
import UIKit

struct WakeSessionLabView: View {
    @ObservedObject var harness: WakeSessionTestingHarness
    @State private var showingQuietConfirmation = false
    @State private var showingRealAlarmConfirmation = false

    var body: some View {
        SettingsScrollPage {
            testModeBanner

            SettingsGroup(title: "Test Mode Status") {
                labRow(
                    title: harness.isActive ? "TEST MODE ACTIVE" : "Test Mode Off",
                    subtitle: harness.statusMessage,
                    systemImage: harness.isActive ? "exclamationmark.triangle.fill" : "checkmark.shield",
                    badgeText: harness.schedulerMode.displayName,
                    badgeTone: harness.isActive ? .warning : .neutral
                )

                AppGroupDivider()

                labRow(
                    title: "Active Scenario",
                    subtitle: harness.activeScenarioTitle,
                    systemImage: "list.bullet.rectangle",
                    badgeText: nil,
                    badgeTone: .neutral
                )

                AppGroupDivider()

                labRow(
                    title: "Simulated Now",
                    subtitle: TimeFormatters.shortDateTime.string(from: harness.simulatedNow),
                    systemImage: "clock.arrow.circlepath",
                    badgeText: nil,
                    badgeTone: .neutral
                )

                AppGroupDivider()

                labRow(
                    title: "Real Device Time",
                    subtitle: TimeFormatters.shortDateTime.string(from: harness.realDeviceNow),
                    systemImage: "iphone",
                    badgeText: nil,
                    badgeTone: .neutral
                )
            }

            SettingsGroup(title: "State Explorer") {
                pickerRow(
                    title: "Scenario",
                    subtitle: "Choose the simulated morning graph.",
                    systemImage: "square.stack.3d.up",
                    selection: $harness.selectedScenario
                ) {
                    ForEach(WakeSessionTestScenario.allCases) { scenario in
                        Text(scenario.title).tag(scenario)
                    }
                }
                AppGroupDivider()
                pickerRow(
                    title: "Date Preset",
                    subtitle: "Select a real or artificial test date.",
                    systemImage: "calendar",
                    selection: $harness.selectedDatePreset
                ) {
                    ForEach(WakeSessionSimulationDatePreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
                AppGroupDivider()
                VStack(alignment: .leading, spacing: 8) {
                    Label("Date / Time", systemImage: "calendar.badge.clock")
                        .font(.subheadline.weight(.semibold))
                    Text("Used by the Today preset for arbitrary simulated date/time checks.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    DatePicker("Simulated date/time", selection: $harness.selectedManualDate)
                        .datePickerStyle(.compact)
                }
                .padding(.vertical, 10)
                AppGroupDivider()
                pickerRow(
                    title: "Location",
                    subtitle: "Does not change the real app location.",
                    systemImage: "location",
                    selection: $harness.selectedLocation
                ) {
                    ForEach(SimulationLocation.allCases) { location in
                        Text(location.displayName).tag(location)
                    }
                }
                AppGroupDivider()
                pickerRow(
                    title: "Prayer Window",
                    subtitle: "Real calculation by default, artificial for edge cases.",
                    systemImage: "sunrise",
                    selection: $harness.selectedPrayerWindowSource
                ) {
                    ForEach(SimulationPrayerWindowSource.allCases) { source in
                        Text(source.displayName).tag(source)
                    }
                }
                AppGroupDivider()
                pickerRow(
                    title: "Clock Mode",
                    subtitle: "Jump instantly without scheduling alarms.",
                    systemImage: "clock.arrow.circlepath",
                    selection: $harness.selectedClockMode
                ) {
                    ForEach(SimulationClockMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                AppGroupDivider()
                pickerRow(
                    title: "Jump Point",
                    subtitle: "Move Home through supported Fajr, Suhoor, and Quiet states.",
                    systemImage: "arrow.triangle.2.circlepath",
                    selection: $harness.selectedJumpPoint
                ) {
                    ForEach(WakeSessionSimulationJumpPoint.allCases) { point in
                        Text(point.title).tag(point)
                    }
                }
                AppGroupDivider()
                actionButton("Activate on Home", subtitle: "Routes the real Home Hero through the simulated morning state.", systemImage: "house.fill", tone: .warning) {
                    Task {
                        await harness.activateOnHome()
                        harness.setJumpPoint(harness.selectedJumpPoint)
                    }
                }
            }

            SettingsGroup(title: "Real AlarmKit Mapped Playback") {
                labRow(
                    title: "Real alarms will ring",
                    subtitle: "Mapped playback pins the simulated primary alarm to a near-future real AlarmKit alarm. Wake Checks remain 5 minutes apart.",
                    systemImage: "alarm.waves.left.and.right",
                    badgeText: "Real",
                    badgeTone: .warning
                )
                AppGroupDivider()
                pickerRow(
                    title: "Sequence Length",
                    subtitle: "Default is Primary + 5 Wake Checks.",
                    systemImage: "list.number",
                    selection: $harness.selectedSequenceLength
                ) {
                    ForEach(WakeSessionMappedSequenceLength.allCases) { length in
                        Text(length.title).tag(length)
                    }
                }
                AppGroupDivider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Delay")
                        .font(.subheadline.weight(.semibold))
                    Slider(value: $harness.mappedStartDelaySeconds, in: 60...120, step: 5)
                    Text("\(Int(harness.mappedStartDelaySeconds)) seconds")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                AppGroupDivider()
                mappedPreviewRows
                AppGroupDivider()
                actionButton("Schedule Real Test Alarms", subtitle: "Shows confirmation before AlarmKit scheduling.", systemImage: "alarm.fill", tone: .warning) {
                    showingRealAlarmConfirmation = true
                }
            }

            SettingsGroup(title: "Scenario Launcher") {
                actionButton("Dry Run Selected Scenario", subtitle: "Builds the simulated plan without scheduling fake or real alarms.", systemImage: "doc.text.magnifyingglass") {
                    Task {
                        await harness.start(harness.selectedScenario, runMode: .dryRun)
                    }
                }
                AppGroupDivider()
                ForEach(Array(WakeSessionTestScenario.allCases.enumerated()), id: \.element.id) { index, scenario in
                    Button {
                        Task {
                            await harness.start(scenario)
                            if scenario == .quietDuringWakeChecks {
                                showingQuietConfirmation = true
                            }
                        }
                    } label: {
                        SettingsRow {
                            SettingsSummaryRow(
                                title: scenario.title,
                                subtitle: scenario == .realAlarmKitMappedPlayback
                                    ? "Explicit physical-device test. Real alarms will ring."
                                    : "Uses test-scoped records and production 5-minute Wake Check spacing.",
                                systemImage: scenario == .realAlarmKitMappedPlayback ? "alarm.waves.left.and.right" : "play.circle",
                                badgeText: scenario == .realAlarmKitMappedPlayback ? "Real" : "Fake",
                                badgeTone: scenario == .realAlarmKitMappedPlayback ? .warning : .neutral
                            )
                        }
                    }
                    .buttonStyle(.plain)

                    if index < WakeSessionTestScenario.allCases.count - 1 {
                        AppGroupDivider()
                    }
                }
            }

            SettingsGroup(title: "Time Controls") {
                actionButton("Jump to primary alarm", subtitle: "Move simulated time to the primary wake.", systemImage: "alarm") {
                    harness.jumpToPrimaryWake()
                }
                AppGroupDivider()
                actionButton("Jump to wake check 1", subtitle: "Move simulated time to the first Wake Check.", systemImage: "bell.badge") {
                    harness.jumpToWakeCheck(index: 1)
                }
                AppGroupDivider()
                actionButton("Jump to Fajr begins", subtitle: "Move simulated time to Fajr begins.", systemImage: "sunrise") {
                    harness.jumpToFajrBegins()
                }
                AppGroupDivider()
                actionButton("Return to real time", subtitle: "Reset simulated now to the device clock.", systemImage: "clock") {
                    harness.returnToRealTime()
                }
            }

            SettingsGroup(title: "Wake Session Actions") {
                actionButton("Record primary alarm fired", subtitle: "Simulate an alarm firing event.", systemImage: "alarm.fill") {
                    harness.recordPrimaryAlarmFired()
                }
                AppGroupDivider()
                actionButton("Record alarm stopped", subtitle: "Stop does not mark awake.", systemImage: "stop.circle") {
                    harness.recordAlarmStopped()
                }
                AppGroupDivider()
                actionButton("Record next Wake Check fired", subtitle: "Move the session to wake-check pending.", systemImage: "bell.and.waves.left.and.right") {
                    harness.recordNextWakeCheckFired()
                }
                AppGroupDivider()
                actionButton("I'm awake for Fajr", subtitle: "Cancels remaining Fajr Wake Checks.", systemImage: "checkmark.circle") {
                    harness.confirmAwakeForFajr()
                }
                AppGroupDivider()
                actionButton("I'm awake for Suhoor", subtitle: "Confirms fasting intent only.", systemImage: "checkmark.circle.fill") {
                    harness.confirmAwakeForSuhoor()
                }
                AppGroupDivider()
                actionButton("I prayed Fajr", subtitle: "Separate from awake confirmation.", systemImage: "hands.sparkles") {
                    harness.confirmFajrPrayer()
                }
                AppGroupDivider()
                actionButton("Apply slider reschedule +1 min", subtitle: "Cancels stale test IDs and schedules new ones.", systemImage: "slider.horizontal.3") {
                    harness.rescheduleActiveWake()
                }
                AppGroupDivider()
                actionButton("Quiet this test morning", subtitle: "Shows active-session confirmation first.", systemImage: "moon.zzz") {
                    showingQuietConfirmation = true
                }
            }

            SettingsGroup(title: "Pending Test Alarms") {
                actionButton("Refresh Pending Test Alarms", subtitle: "Reloads the debug alarm inspector.", systemImage: "arrow.clockwise") {
                    harness.refreshInspectors()
                }
                AppGroupDivider()
                if harness.alarmRecords.isEmpty {
                    labRow(
                        title: "No test alarms",
                        subtitle: "Start a scenario to record fake or real test alarms.",
                        systemImage: "bell.slash",
                        badgeText: nil,
                        badgeTone: .neutral
                    )
                } else {
                    ForEach(Array(harness.alarmRecords.enumerated()), id: \.element.id) { index, record in
                        Button {
                            harness.cancelSelectedTestAlarm(identifier: record.id)
                        } label: {
                            SettingsRow {
                                SettingsSummaryRow(
                                    title: "\(record.role.displayName) - \(record.status.rawValue)",
                                    subtitle: "\(record.scheduledEventID) | simulated \(TimeFormatters.shortDateTime.string(from: record.simulatedFireDate)) | scheduled \(TimeFormatters.shortDateTime.string(from: record.fireDate))",
                                    systemImage: record.channel == .realAlarmKit ? "alarm.waves.left.and.right" : "bell",
                                    badgeText: record.channel.displayName,
                                    badgeTone: record.status == .failed ? .critical : (record.status == .pending ? .warning : .neutral)
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        if index < harness.alarmRecords.count - 1 {
                            AppGroupDivider()
                        }
                    }
                }
            }

            SettingsGroup(title: "MorningLog Inspector") {
                if harness.testMorningLogs.isEmpty {
                    labRow(
                        title: "No test MorningLogs",
                        subtitle: "Test logs are marked isTest and remain separate from real history.",
                        systemImage: "doc.text.magnifyingglass",
                        badgeText: nil,
                        badgeTone: .neutral
                    )
                } else {
                    ForEach(Array(harness.testMorningLogs.enumerated()), id: \.element.dateKey) { index, log in
                        labRow(
                            title: log.dateKey,
                            subtitle: log.records.map(\.type.rawValue).joined(separator: ", "),
                            systemImage: "doc.text",
                            badgeText: log.isTest ? "isTest" : nil,
                            badgeTone: log.isTest ? .warning : .neutral
                        )
                        if index < harness.testMorningLogs.count - 1 {
                            AppGroupDivider()
                        }
                    }
                }
                AppGroupDivider()
                actionButton("Copy Test Report", subtitle: "Copies a local debug summary.", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = harness.debugReport()
                }
                AppGroupDivider()
                actionButton("Export Debug Summary", subtitle: "Copies the same local report for manual sharing.", systemImage: "square.and.arrow.up") {
                    UIPasteboard.general.string = harness.debugReport()
                }
            }

            SettingsGroup(title: "Permission / Failure Simulator") {
                ForEach(Array(WakeSessionTestPermissionState.allCases.enumerated()), id: \.element.id) { index, state in
                    actionButton(state.displayName, subtitle: "Fake/integration mode only. Real iOS permissions are unchanged.", systemImage: state.blocksScheduling ? "exclamationmark.triangle" : "checkmark.shield") {
                        harness.simulatePermissionState(state)
                    }
                    if index < WakeSessionTestPermissionState.allCases.count - 1 {
                        AppGroupDivider()
                    }
                }
            }

            SettingsGroup(title: "Cleanup / Reset Tools") {
                actionButton("Cancel All Test Alarms", subtitle: "Cancels pending fake or recorded real test alarms only.", systemImage: "xmark.octagon.fill", tone: .warning) {
                    harness.cancelAllTestAlarms()
                }
                AppGroupDivider()
                actionButton("Clear Test Wake Sessions", subtitle: "Removes test sessions without touching real sessions.", systemImage: "trash") {
                    harness.clearTestWakeSessions()
                }
                AppGroupDivider()
                actionButton("Clear Test MorningLogs", subtitle: "Removes test logs without deleting real logs.", systemImage: "doc.badge.minus") {
                    harness.clearTestMorningLogs()
                }
                AppGroupDivider()
                actionButton("Reset Test Time", subtitle: "Returns simulated time to the device clock.", systemImage: "clock") {
                    harness.returnToRealTime()
                }
                AppGroupDivider()
                actionButton("Exit Test Mode", subtitle: "Cancels alarms and clears all test-only state.", systemImage: "escape") {
                    harness.exitTestMode()
                }
            }
        }
        .navigationTitle("Wake Session Lab")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Stop wake checks for this morning?",
            isPresented: $showingQuietConfirmation,
            titleVisibility: .visible
        ) {
            Button("Keep wake checks", role: .cancel) {}
            Button("Stop for this morning", role: .destructive) {
                harness.confirmQuietMorning()
            }
        } message: {
            Text("Subh will cancel the remaining alarms and mark this test morning as quiet.")
        }
        .confirmationDialog(
            "Schedule real test alarms?",
            isPresented: $showingRealAlarmConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Schedule Test Alarms") {
                Task {
                    await harness.start(.realAlarmKitMappedPlayback, runMode: .realAlarmKitMappedPlayback)
                }
            }
        } message: {
            Text("Subh will schedule real AlarmKit alarms on this device using your selected alarm sound. These are test alarms mapped from the simulated morning. Wake checks remain 5 minutes apart.")
        }
    }

    private var testModeBanner: some View {
        Text(harness.isActive ? "TEST MODE ACTIVE" : "Developer Test Mode")
            .font(.footnote.weight(.bold))
            .foregroundStyle(harness.isActive ? Color.white : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(harness.isActive ? Color.red : Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityAddTraits(.isHeader)
    }

    private func actionButton(
        _ title: String,
        subtitle: String,
        systemImage: String,
        tone: SettingsBadgeTone = .neutral,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            SettingsRow {
                SettingsSummaryRow(
                    title: title,
                    subtitle: subtitle,
                    systemImage: systemImage,
                    badgeText: nil,
                    badgeTone: tone
                )
            }
        }
        .buttonStyle(.plain)
    }

    private var mappedPreviewRows: some View {
        let plan = harness.makeMappedPlaybackPreview()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Mapped Fire Times")
                .font(.subheadline.weight(.semibold))
            ForEach(plan.mappedEvents) { event in
                let soundRole = event.event.soundRole?.rawValue ?? "default"
                Text("\(event.role.displayName): simulated \(TimeFormatters.timeFormatter.string(from: event.simulatedFireDate)) -> real \(TimeFormatters.timeFormatter.string(from: event.mappedRealFireDate)) · sound \(soundRole)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let explanation = plan.cutoffExplanation {
                Text(explanation)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.orange)
            }
        }
        .padding(.vertical, 10)
    }

    private func pickerRow<Selection: Hashable, Content: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        selection: Binding<Selection>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                content()
            }
            .pickerStyle(.menu)
        }
        .padding(.vertical, 10)
    }

    private func labRow(
        title: String,
        subtitle: String,
        systemImage: String,
        badgeText: String?,
        badgeTone: SettingsBadgeTone
    ) -> some View {
        SettingsRow {
            SettingsSummaryRow(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                badgeText: badgeText,
                badgeTone: badgeTone
            )
        }
    }
}
#endif
