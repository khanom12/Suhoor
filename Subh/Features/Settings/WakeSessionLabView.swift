#if DEBUG || INTERNAL_TESTING
import SwiftUI

struct WakeSessionLabView: View {
    @ObservedObject var harness: WakeSessionTestingHarness
    @State private var showingQuietConfirmation = false

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

            SettingsGroup(title: "Scenario Launcher") {
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
                                subtitle: scenario == .realAlarmKitCompressed
                                    ? "Explicit physical-device test. Real alarms will ring."
                                    : "Uses compressed test time and test-scoped records.",
                                systemImage: scenario == .realAlarmKitCompressed ? "alarm.waves.left.and.right" : "play.circle",
                                badgeText: scenario == .realAlarmKitCompressed ? "Real" : "Fake",
                                badgeTone: scenario == .realAlarmKitCompressed ? .warning : .neutral
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
                        labRow(
                            title: "\(record.role.displayName) - \(record.status.rawValue)",
                            subtitle: "\(record.scheduledEventID) | \(TimeFormatters.shortDateTime.string(from: record.fireDate))",
                            systemImage: record.channel == .realAlarmKit ? "alarm.waves.left.and.right" : "bell",
                            badgeText: record.channel.displayName,
                            badgeTone: record.status == .failed ? .critical : (record.status == .pending ? .warning : .neutral)
                        )
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
