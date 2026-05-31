#if DEBUG || INTERNAL_TESTING
import SwiftUI
import UIKit

struct WakeSessionLabView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var harness: WakeSessionTestingHarness

    @State private var selectedArea: WakeSessionLabTopLevelArea = .previewHomeUI
    @State private var showingCustomPreview = false
    @State private var showingAdvancedOptions = false
    @State private var showingRealAlarmSetup = false
    @State private var showingRealAlarmConfirmation = false
    @State private var heroSlotInspectorExpanded = true
    @State private var timeInspectorExpanded = false
    @State private var surfaceConsistencyExpanded = false
    @State private var scheduledAlarmsExpanded = false
    @State private var testEventLogExpanded = false
    @State private var permissionSimulationExpanded = false
    @State private var resetToolsExpanded = false

    var body: some View {
        SettingsScrollPage {
            statusHeader

            Picker("Wake Session Lab area", selection: $selectedArea) {
                ForEach(WakeSessionLabTopLevelArea.allCases) { area in
                    Text(area.title).tag(area)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 2)

            switch selectedArea {
            case .previewHomeUI:
                previewHomeArea
            case .realAlarmTest:
                realAlarmArea
            case .diagnostics:
                diagnosticsArea
            }
        }
        .navigationTitle("Wake Session Lab")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Schedule real test alarms?",
            isPresented: $showingRealAlarmConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Schedule Test Alarms") {
                Task {
                    await harness.scheduleSelectedRealAlarmTest()
                }
            }
        } message: {
            Text(realAlarmConfirmationMessage)
        }
        .onChange(of: harness.selectedCustomPreviewMode) { _, mode in
            harness.selectCustomPreviewMode(mode)
        }
        .onChange(of: harness.selectedCustomAlarmState) { _, alarmState in
            harness.selectCustomAlarmState(alarmState)
        }
    }

    private var statusHeader: some View {
        SettingsGroup(title: nil) {
            SettingsRow {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(harness.isActive ? "TEST MODE ACTIVE" : "Wake Session Lab")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(harness.isActive ? Color.red : Color.primary)
                        Spacer(minLength: 12)
                        Text(harness.schedulerMode.displayName)
                            .font(AppTypography.badge)
                            .foregroundStyle(.secondary)
                    }
                    Text(harness.isActive ? activeStatusSummary : "Test Subh mornings without waiting for real Fajr.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if harness.isActive {
                        HStack(spacing: 10) {
                            Button("Return to Home") {
                                dismiss()
                            }
                            Button("Exit Test Mode", role: .destructive) {
                                harness.exitTestMode()
                            }
                            if !harness.pendingTestAlarms.isEmpty {
                                Button("Cancel Test Alarms", role: .destructive) {
                                    harness.cancelAllTestAlarms()
                                }
                            }
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var activeStatusSummary: String {
        [
            harness.activeScenarioTitle,
            harness.activeSimulationContext?.simulatedLocation.displayName,
            harness.activeSimulationContext.map { TimeFormatters.shortDateTime.string(from: $0.simulatedNow) }
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
    }

    private var previewHomeArea: some View {
        VStack(spacing: DesignTokens.spacingM) {
            SettingsGroup(
                title: "Preview Home UI",
                footer: "Choose a scenario. No real alarms will ring."
            ) {
                ForEach(Array(harness.previewScenarioCards.enumerated()), id: \.element.id) { index, card in
                    previewCard(card)
                    if index < harness.previewScenarioCards.count - 1 {
                        AppGroupDivider()
                    }
                }
            }

            if showingCustomPreview {
                customPreviewForm
            }
        }
    }

    private func previewCard(_ card: WakeSessionPreviewScenarioCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            scenarioCopy(
                card: card,
                calculatedTimes: harness.previewTimeSummary(for: card),
                systemImage: card.id == "custom-test-builder" ? "calendar.badge.clock" : "house"
            )

            HStack(spacing: 10) {
                Button(card.primaryActionTitle) {
                    if card.id == "custom-test-builder" {
                        showingCustomPreview = true
                    } else {
                        Task {
                            await harness.startPreview(card: card)
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                Button(card.secondaryActionTitle) {
                    if card.id == "custom-test-builder" {
                        showingCustomPreview = true
                    } else {
                        selectedArea = .diagnostics
                    }
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.regular)
        }
        .padding(.vertical, 10)
    }

    private var customPreviewForm: some View {
        SettingsGroup(
            title: "Custom Home Preview",
            footer: "Choose a simulated morning and see it on Home. Advanced options stay collapsed unless you need edge cases."
        ) {
            pickerRow(title: "Date", subtitle: "Choose the simulated date context.", systemImage: "calendar", selection: $harness.selectedDatePreset) {
                ForEach(WakeSessionSimulationDatePreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            AppGroupDivider()
            VStack(alignment: .leading, spacing: 8) {
                Label("Pick date and time", systemImage: "calendar.badge.clock")
                    .font(.subheadline.weight(.semibold))
                DatePicker("Simulated date/time", selection: $harness.selectedManualDate)
                    .datePickerStyle(.compact)
            }
            .padding(.vertical, 10)
            AppGroupDivider()
            pickerRow(title: "Scrub horizon", subtitle: "Scrub minute-by-minute from the selected start time.", systemImage: "timeline.selection", selection: $harness.selectedScrubHorizon) {
                ForEach(WakeSessionSimulationScrubHorizon.allCases) { horizon in
                    Text(horizon.title).tag(horizon)
                }
            }
            AppGroupDivider()
            VStack(alignment: .leading, spacing: 8) {
                Label("Minute scrubber", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                Slider(
                    value: Binding(
                        get: { harness.selectedScrubOffsetMinutes },
                        set: { harness.setScrubOffsetMinutes($0) }
                    ),
                    in: harness.simulationScrubRange,
                    step: 1
                )
                Text("Scrubbed time: \(harness.scrubbedSimulationTimeText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
            AppGroupDivider()
            pickerRow(title: "Location", subtitle: "Does not change the real app location.", systemImage: "location", selection: $harness.selectedLocation) {
                ForEach(SimulationLocation.allCases) { location in
                    Text(location.displayName).tag(location)
                }
            }
            AppGroupDivider()
            pickerRow(title: "Wake purpose", subtitle: "Choose why this morning wakes the user.", systemImage: "moon.stars", selection: $harness.selectedCustomPreviewMode) {
                ForEach(WakeSessionCustomPreviewMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            AppGroupDivider()
            pickerRow(title: "Alarm state", subtitle: "Quiet and Pause live here, not in wake purpose.", systemImage: "bell.badge", selection: $harness.selectedCustomAlarmState) {
                ForEach(WakeSessionCustomAlarmState.allCases) { state in
                    Text(state.title).tag(state)
                }
            }
            AppGroupDivider()
            pickerRow(title: "State", subtitle: "Home will jump directly to this state.", systemImage: "arrow.triangle.2.circlepath", selection: $harness.selectedJumpPoint) {
                ForEach(harness.selectedCustomStateOptions) { point in
                    Text(point.title).tag(point)
                }
            }
            AppGroupDivider()
            DisclosureGroup("Advanced Options", isExpanded: $showingAdvancedOptions) {
                VStack(spacing: 0) {
                    pickerRow(title: "Prayer window source", subtitle: "Real calculation by default; custom windows are for edge cases.", systemImage: "sunrise", selection: $harness.selectedPrayerWindowSource) {
                        ForEach(SimulationPrayerWindowSource.allCases) { source in
                            Text(source.displayName).tag(source)
                        }
                    }
                    AppGroupDivider()
                    pickerRow(title: "Clock mode", subtitle: "State jumps are instant and do not compress follow-up alarms.", systemImage: "clock.arrow.circlepath", selection: $harness.selectedClockMode) {
                        ForEach(SimulationClockMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                }
            }
            .padding(.vertical, 10)
            AppGroupDivider()
            let report = harness.timeValidationReport()
            labRow(
                title: report.passed ? "Time validation passed" : "Test setup issue",
                subtitle: timeValidationSummary(report),
                systemImage: report.passed ? "checkmark.seal" : "exclamationmark.triangle",
                badgeText: report.prayerTimeSource,
                badgeTone: report.passed ? .neutral : .critical
            )
            AppGroupDivider()
            actionButton("Preview on Home", subtitle: "Routes the real Home Hero through the simulated morning state.", systemImage: "house.fill", tone: .warning) {
                Task {
                    await harness.previewCustomOnHome()
                    dismiss()
                }
            }
        }
    }

    private var realAlarmArea: some View {
        VStack(spacing: DesignTokens.spacingM) {
            SettingsGroup(
                title: "Real Alarm Test",
                footer: "These alarms will actually ring. Follow-up alarms stay 5 minutes apart."
            ) {
                ForEach(Array(harness.realAlarmScenarioCards.enumerated()), id: \.element.id) { index, card in
                    realAlarmCard(card)
                    if index < harness.realAlarmScenarioCards.count - 1 {
                        AppGroupDivider()
                    }
                }
            }

            if showingRealAlarmSetup {
                realAlarmSetup
            }
        }
    }

    private func realAlarmCard(_ card: WakeSessionRealAlarmScenarioCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            scenarioCopy(
                title: card.title,
                description: card.description,
                whatThisTests: card.whatThisTests,
                realAlarms: card.realAlarms,
                approximateDuration: card.approximateDuration,
                whatToExpect: card.whatToExpect,
                systemImage: "alarm.waves.left.and.right"
            )

            Button(card.primaryActionTitle) {
                harness.configureRealAlarmTest(card.scenario)
                showingRealAlarmSetup = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.red)
        }
        .padding(.vertical, 10)
    }

    private var realAlarmSetup: some View {
        SettingsGroup(
            title: "Real Alarm Setup",
            footer: "Subh maps simulated events onto near-future real AlarmKit alarms. Follow-up alarms remain five minutes apart."
        ) {
            pickerRow(title: "Scenario", subtitle: "Choose which simulated Wake Session to map.", systemImage: "square.stack.3d.up", selection: $harness.selectedRealAlarmScenario) {
                Text("Fajr alarm test").tag(WakeSessionTestScenario.fajrStateExplorer)
                Text("Suhoor alarm test").tag(WakeSessionTestScenario.suhoorStateExplorer)
                Text("System dismissal test").tag(WakeSessionTestScenario.alarmStopVsAwake)
                Text("Cancel remaining alarms test").tag(WakeSessionTestScenario.sliderReschedule)
            }
            AppGroupDivider()
            pickerRow(title: "Start delay", subtitle: "When the primary alarm should ring.", systemImage: "timer", selection: $harness.mappedStartDelaySeconds) {
                Text("60 seconds").tag(TimeInterval(60))
                Text("90 seconds").tag(TimeInterval(90))
                Text("120 seconds").tag(TimeInterval(120))
            }
            AppGroupDivider()
            pickerRow(title: "Sequence length", subtitle: "Default is Primary + 5 follow-up alarms.", systemImage: "list.number", selection: $harness.selectedSequenceLength) {
                ForEach(WakeSessionMappedSequenceLength.allCases) { length in
                    Text(length.title).tag(length)
                }
            }
            AppGroupDivider()
            labRow(
                title: "Sound",
                subtitle: currentSoundSummary,
                systemImage: "speaker.wave.2",
                badgeText: nil,
                badgeTone: .neutral
            )
            AppGroupDivider()
            mappingPreview
            AppGroupDivider()
            actionButton("Schedule Real Test Alarms", subtitle: "Shows a warning before AlarmKit scheduling.", systemImage: "alarm.fill", tone: .warning) {
                showingRealAlarmConfirmation = true
            }
        }
    }

    private var diagnosticsArea: some View {
        SettingsGroup(
            title: "Diagnostics",
            footer: "Use these only when a test does not behave as expected."
        ) {
            diagnosticDisclosure("Hero Slot Inspector", isExpanded: $heroSlotInspectorExpanded) {
                heroSlotInspector
            }
            AppGroupDivider()
            diagnosticDisclosure("Time Inspector", isExpanded: $timeInspectorExpanded) {
                timeInspector
            }
            AppGroupDivider()
            diagnosticDisclosure("Surface Consistency", isExpanded: $surfaceConsistencyExpanded) {
                surfaceConsistency
            }
            AppGroupDivider()
            diagnosticDisclosure("Scheduled Test Alarms", isExpanded: $scheduledAlarmsExpanded) {
                scheduledTestAlarms
            }
            AppGroupDivider()
            diagnosticDisclosure("Test Event Log", isExpanded: $testEventLogExpanded) {
                testEventLog
            }
            AppGroupDivider()
            diagnosticDisclosure("Permission Simulation", isExpanded: $permissionSimulationExpanded) {
                permissionSimulation
            }
            AppGroupDivider()
            diagnosticDisclosure("Reset Test Mode", isExpanded: $resetToolsExpanded) {
                resetTools
            }
        }
    }

    private func diagnosticDisclosure<Content: View>(
        _ title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        DisclosureGroup(title, isExpanded: isExpanded) {
            VStack(spacing: 0) {
                content()
            }
            .padding(.top, 8)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.vertical, 10)
    }

    private var heroSlotInspector: some View {
        VStack(spacing: 0) {
            ForEach(Array(harness.heroSlotInspectionRows().enumerated()), id: \.element.id) { index, row in
                labRow(
                    title: row.slot,
                    subtitle: "Expected: \(row.expected)\nActual: \(row.actual)",
                    systemImage: row.passed ? "checkmark.circle" : "xmark.octagon",
                    badgeText: row.passed ? "Pass" : "Check",
                    badgeTone: row.passed ? .neutral : .critical
                )
                if index < harness.heroSlotInspectionRows().count - 1 {
                    AppGroupDivider()
                }
            }
        }
    }

    private var timeInspector: some View {
        let report = harness.timeValidationReport()
        return VStack(spacing: 0) {
            labRow(
                title: report.passed ? "Time validation passed" : "Time validation failed",
                subtitle: report.reason ?? "Standard scenario has calculated times.",
                systemImage: report.passed ? "checkmark.seal" : "exclamationmark.triangle",
                badgeText: report.prayerTimeSource,
                badgeTone: report.passed ? .neutral : .critical
            )
            AppGroupDivider()
            labRow(
                title: "Simulated clock",
                subtitle: "\(TimeFormatters.shortDateTime.string(from: report.simulatedNow)) · \(report.timeZone.identifier)",
                systemImage: "clock",
                badgeText: nil,
                badgeTone: .neutral
            )
            AppGroupDivider()
            labRow(
                title: "Location",
                subtitle: report.location,
                systemImage: "location",
                badgeText: nil,
                badgeTone: .neutral
            )
            AppGroupDivider()
            labRow(
                title: "Fajr window",
                subtitle: "\(timeText(report.fajrBegins)) - \(timeText(report.fajrEnds))",
                systemImage: "sunrise",
                badgeText: report.selectedWakePurpose.displayTitle,
                badgeTone: .neutral
            )
            AppGroupDivider()
            labRow(
                title: "Alarm schedule",
                subtitle: alarmScheduleSummary(report),
                systemImage: "alarm",
                badgeText: nil,
                badgeTone: .neutral
            )
        }
    }

    private var surfaceConsistency: some View {
        VStack(spacing: 0) {
            ForEach(Array(harness.surfaceConsistencyRows().enumerated()), id: \.element.id) { index, row in
                labRow(
                    title: row.surface,
                    subtitle: "Expected: \(row.expectedState)\nActual: \(row.actualState)",
                    systemImage: row.passed ? "checkmark.circle" : "xmark.octagon",
                    badgeText: row.passed ? "Pass" : "Check",
                    badgeTone: row.passed ? .neutral : .critical
                )
                if index < harness.surfaceConsistencyRows().count - 1 {
                    AppGroupDivider()
                }
            }
        }
    }

    private var scheduledTestAlarms: some View {
        VStack(spacing: 0) {
            actionButton("Refresh", subtitle: "Reload scheduled test alarm records.", systemImage: "arrow.clockwise") {
                harness.refreshInspectors()
            }
            AppGroupDivider()
            if harness.alarmRecords.isEmpty {
                labRow(
                    title: "No scheduled test alarms",
                    subtitle: "Preview Home UI will not schedule real alarms.",
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
                                title: "\(record.role.displayName) · \(record.status.rawValue)",
                                subtitle: alarmRecordSummary(record),
                                systemImage: record.channel == .realAlarmKit ? "alarm.waves.left.and.right" : "bell",
                                badgeText: record.isTest ? record.channel.displayName : "Production",
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
            AppGroupDivider()
            actionButton("Cancel all test alarms", subtitle: "Cancels test alarms without touching production alarms.", systemImage: "xmark.octagon.fill", tone: .warning) {
                harness.cancelAllTestAlarms()
            }
        }
    }

    private var testEventLog: some View {
        VStack(spacing: 0) {
            if harness.testMorningLogs.isEmpty {
                labRow(
                    title: "No test events yet",
                    subtitle: "Test records are marked isTest and stay out of real history.",
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
            actionButton("Copy report", subtitle: "Copies a local debug summary.", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = harness.debugReport()
            }
            AppGroupDivider()
            actionButton("Clear test log", subtitle: "Clears test logs without deleting real logs.", systemImage: "doc.badge.minus") {
                harness.clearTestMorningLogs()
            }
        }
    }

    private var permissionSimulation: some View {
        VStack(spacing: 0) {
            let visibleStates: [WakeSessionTestPermissionState] = [
                .alarmKitUnavailable,
                .alarmKitDenied,
                .notificationsDenied,
                .soundAssetMissing,
                .scheduleFailure
            ]
            ForEach(Array(visibleStates.enumerated()), id: \.element.id) { index, state in
                actionButton(state.displayName, subtitle: "Does not change real iOS settings and does not become Quiet.", systemImage: state.blocksScheduling ? "exclamationmark.triangle" : "checkmark.shield") {
                    harness.simulatePermissionState(state)
                }
                if index < visibleStates.count - 1 {
                    AppGroupDivider()
                }
            }
        }
    }

    private var resetTools: some View {
        VStack(spacing: 0) {
            actionButton("Cancel all test alarms", subtitle: "Cancels pending fake or recorded real test alarms only.", systemImage: "xmark.octagon.fill", tone: .warning) {
                harness.cancelAllTestAlarms()
            }
            AppGroupDivider()
            actionButton("Clear test sessions", subtitle: "Removes test sessions without touching real sessions.", systemImage: "trash") {
                harness.clearTestWakeSessions()
            }
            AppGroupDivider()
            actionButton("Clear test logs", subtitle: "Removes test logs without deleting real logs.", systemImage: "doc.badge.minus") {
                harness.clearTestMorningLogs()
            }
            AppGroupDivider()
            actionButton("Exit test mode", subtitle: "Cancels alarms, clears test state, and restores real Home.", systemImage: "escape", tone: .warning) {
                harness.exitTestMode()
            }
        }
    }

    private func scenarioCopy(
        card: WakeSessionPreviewScenarioCard,
        calculatedTimes: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(card.title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
            Text(card.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                metadataChip(card.wakePurpose.displayTitle)
                metadataChip(card.alarmState.shortTitle)
                metadataChip(card.dateContext)
            }
            .fixedSize(horizontal: false, vertical: true)
            labeledCopy("Calculated times", calculatedTimes)
            labeledCopy("What this tests", card.whatThisTests)
            labeledCopy("Real alarms", card.realAlarms)
            labeledCopy("Estimated test time", card.approximateDuration)
            labeledCopy("What to expect", card.whatToExpect)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func scenarioCopy(
        title: String,
        description: String,
        whatThisTests: String,
        realAlarms: String,
        approximateDuration: String,
        whatToExpect: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            labeledCopy("What this tests", whatThisTests)
            labeledCopy("Real alarms", realAlarms)
            labeledCopy("Approximate time", approximateDuration)
            labeledCopy("What to expect", whatToExpect)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func metadataChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
            }
    }

    private func labeledCopy(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var mappingPreview: some View {
        let plan = harness.makeMappedPlaybackPreview()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Simulated schedule")
                .font(.subheadline.weight(.semibold))
            ForEach(plan.mappedEvents) { event in
                scheduleLine(
                    role: event.role.displayName,
                    time: TimeFormatters.timeFormatter.string(from: event.simulatedFireDate)
                )
            }
            Text("Real alarm schedule")
                .font(.subheadline.weight(.semibold))
                .padding(.top, 4)
            ForEach(plan.mappedEvents) { event in
                scheduleLine(
                    role: event.role.displayName,
                    time: TimeFormatters.timeFormatter.string(from: event.mappedRealFireDate)
                )
            }
            if let explanation = plan.cutoffExplanation {
                Text(explanation)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.orange)
            }
        }
        .padding(.vertical, 10)
    }

    private func scheduleLine(role: String, time: String) -> some View {
        HStack {
            Text(role)
                .font(.caption.weight(.semibold))
            Spacer()
            Text(time)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var currentSoundSummary: String {
        let plan = harness.makeMappedPlaybackPreview()
        let role = plan.mappedEvents.first?.event.soundRole?.rawValue
        return role.map { "Sound role: \($0)" } ?? "Sound: Default test sound"
    }

    private var realAlarmConfirmationMessage: String {
        let plan = harness.makeMappedPlaybackPreview()
        let mapped = plan.mappedEvents.map {
            "\($0.role.displayName): simulated \(TimeFormatters.timeFormatter.string(from: $0.simulatedFireDate)) -> real \(TimeFormatters.timeFormatter.string(from: $0.mappedRealFireDate))"
        }
        .joined(separator: "\n")
        return [
            "These alarms will ring on this iPhone using your selected alarm sound. Follow-up alarms remain 5 minutes apart.",
            "Scenario: \(harness.selectedRealAlarmScenario.mode.confirmationTitle)",
            "Sequence: \(harness.selectedSequenceLength.title)",
            "Cancel All Test Alarms is available in Diagnostics and while test mode is active.",
            mapped
        ]
        .joined(separator: "\n\n")
    }

    private func alarmRecordSummary(_ record: WakeSessionTestAlarmRecord) -> String {
        [
            "simulated \(TimeFormatters.shortDateTime.string(from: record.simulatedFireDate))",
            "real \(record.mappedRealFireDate.map { TimeFormatters.shortDateTime.string(from: $0) } ?? TimeFormatters.shortDateTime.string(from: record.fireDate))",
            record.id
        ]
        .joined(separator: " · ")
    }

    private func timeValidationSummary(_ report: WakeSessionTimeValidationReport) -> String {
        if let reason = report.reason {
            return reason
        }
        return [
            "Fajr \(timeText(report.fajrBegins))-\(timeText(report.fajrEnds))",
            "Alarm \(timeText(report.primaryAlarmTime))",
            "\(report.followUpAlarmTimes.count) follow-up alarms"
        ]
        .joined(separator: " · ")
    }

    private func alarmScheduleSummary(_ report: WakeSessionTimeValidationReport) -> String {
        let followUps = report.followUpAlarmTimes.enumerated().map { index, date in
            "Follow-up \(index + 1) \(TimeFormatters.timeFormatter.string(from: date))"
        }
        let parts = [
            "Primary \(timeText(report.primaryAlarmTime))",
            "Cutoff \(timeText(report.cutoffBoundary))"
        ] + followUps + [report.omittedFollowUpReason].compactMap { $0 }
        return parts.joined(separator: "\n")
    }

    private func timeText(_ date: Date?) -> String {
        date.map { TimeFormatters.timeFormatter.string(from: $0) } ?? "Unavailable"
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
