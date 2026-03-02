import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @State private var snapshot: SchedulingAuditSnapshot?
    @State private var isRefreshing = false
    @State private var timelineEntries: [EventTimelineEntry] = []
    @State private var testStatusMessage: String?
    @State private var testDetails: [String] = []

    var body: some View {
        Form {
            Section("Quick Test") {
                Text("Schedules a wake, reminder, and adhan test in 1–3 minutes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Run Test (1–3 min)") {
                    Task {
                        let result = await scheduleManager.runThreeEventTestWithPermissions()
                        testStatusMessage = result.message
                        testDetails = result.details
                        await refreshAudit()
                    }
                }
                if let testStatusMessage {
                    Text(testStatusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ForEach(testDetails, id: \.self) { detail in
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Permissions") {
                Text(scheduleManager.permissionSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Effective mode: \(effectiveModeText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Scheduling Audit") {
                Text("Lists what should be scheduled vs. what’s actually scheduled.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button(isRefreshing ? "Refreshing..." : "Refresh Audit") {
                    Task { await refreshAudit() }
                }
                .disabled(isRefreshing)

                if let snapshot {
                    Text("Generated: \(TimeFormatters.shortDateTime.string(from: snapshot.generatedAt))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(snapshot.expectedEvents) { expected in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(expected.dayLabel) - \(expected.kind.title)")
                                Text("\(TimeFormatters.timeFormatter.string(from: expected.date)) - \(expected.channel.rawValue)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text(expected.identifier)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if expected.isPast {
                                Text("Past")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("Tap Refresh Audit to load expected events.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let snapshot, !snapshot.mismatches.isEmpty {
                Section("Mismatches") {
                    ForEach(snapshot.mismatches) { mismatch in
                        Text(mismatch.message)
                            .font(.footnote)
                            .foregroundStyle(mismatch.severity == .error ? .red : .secondary)
                    }
                }
            }

            if let snapshot, !snapshot.alarmKitItems.isEmpty {
                Section("AlarmKit Alarms") {
                    ForEach(snapshot.alarmKitItems) { alarm in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(alarm.id.uuidString)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(alarm.scheduleDescription) \(alarm.nextTriggerDate.map { TimeFormatters.shortDateTime.string(from: $0) } ?? "--")")
                                .font(.footnote)
                            Text(alarm.stateDescription)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let snapshot, !snapshot.notificationItems.isEmpty {
                Section("Pending Notifications") {
                    ForEach(snapshot.notificationItems) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.id)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(item.title)
                            Text(item.triggerDate.map { TimeFormatters.shortDateTime.string(from: $0) } ?? "--")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Event Timeline") {
                Text("Recent scheduling actions and decisions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Clear Timeline") {
                    EventTimelineLog.shared.clear()
                    timelineEntries = EventTimelineLog.shared.entries()
                }
                ForEach(timelineEntries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(TimeFormatters.shortDateTime.string(from: entry.timestamp)) - \(entry.category)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(entry.message)
                            .font(.footnote)
                    }
                }
            }

        }
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .formStyle(.grouped)
        .task {
            await scheduleManager.refreshPermissionSummary()
            await refreshAudit()
            timelineEntries = EventTimelineLog.shared.entries()
        }
    }

    private var effectiveModeText: String {
        switch scheduleManager.schedulingMode {
        case .alarmKit:
            return "AlarmKit"
        case .notifications:
            return "Notifications"
        case .none:
            return "Blocked"
        }
    }

    private func refreshAudit() async {
        isRefreshing = true
        snapshot = await scheduleManager.makeSchedulingAudit()
        timelineEntries = EventTimelineLog.shared.entries()
        isRefreshing = false
    }
}
