import SwiftUI

struct ProgressRootView: View {
    @EnvironmentObject private var qadaBacklogStore: QadaBacklogStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @EnvironmentObject private var fajrLogStore: FajrLogStore
    @State private var qadaProgress = QadaProgressSnapshot(remaining: 0, completed: 0, baselineOwed: 0)
    @State private var wakeProgress = WakeProgressSnapshot.empty

    private let wakeProgressSource = DebugEventLogWakeProgressSource()

    var body: some View {
        List {
            Section {
                NavigationLink {
                    FajrHistoryView()
                } label: {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        LabeledContent("Today", value: fajrTodaySummary)
                        LabeledContent("Last 30 mornings", value: fajrSummary)
                    }
                }
            } header: {
                Text("Fajr Completion")
            } footer: {
                Text("Log whether you made Fajr. This stays separate from fasting.")
            }

            Section {
                VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                    LabeledContent("Today", value: fastTodaySummary)
                    LabeledContent("Last 30 days", value: fastSummary)
                }
            } header: {
                Text("Fast Completion")
            } footer: {
                Text("Use fasting logs only for fasting days.")
            }

            Section {
                LabeledContent("Completed", value: "\(qadaProgress.completed)")
                LabeledContent("Remaining", value: "\(qadaProgress.remaining)")
                if qadaProgress.baselineOwed == 0 {
                    Text("Add Qada obligations from Plans when you need them.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Qada Progress")
            }

            Section {
                NavigationLink {
                    FastHistoryView()
                } label: {
                    LabeledContent("Past 30 days", value: historySummary)
                }
            } header: {
                Text("Observance History")
            }

            Section {
                if let summaryTitle = wakeProgress.summaryTitle {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                        Text(summaryTitle)
                            .font(.headline.weight(.semibold))
                        if let summaryDetail = wakeProgress.summaryDetail {
                            Text(summaryDetail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(wakeProgress.recentActivityLines, id: \.self) { line in
                        Text(line)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if let emptyStateText = wakeProgress.emptyStateText {
                    Text(emptyStateText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Wake Activity")
            } footer: {
                Text("Wake activity still uses the current wake-event log until a dedicated wake history model replaces it.")
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            refreshProgress()
            refreshWakeProgress()
        }
        .onChange(of: qadaBacklogStore.state) { _, _ in
            refreshProgress()
        }
        .onChange(of: fastLogStore.currentRevision) { _, _ in
            refreshProgress()
        }
        .onChange(of: fajrLogStore.currentRevision) { _, _ in
            refreshProgress()
        }
    }

    private var historySummary: String {
        let logged = fastLogStore.entriesByDateKey.values.count
        if logged == 0 {
            return "No logged days yet"
        }
        return "\(logged) logged"
    }

    private var fajrTodaySummary: String {
        let todayKey = DateHelpers.dayIdentifier(for: Date(), timeZone: .current)
        return fajrLogStore.status(for: todayKey).title
    }

    private var fastTodaySummary: String {
        let todayKey = DateHelpers.dayIdentifier(for: Date(), timeZone: .current)
        switch fastLogStore.status(for: todayKey) {
        case .unknown:
            return "No fast logged"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Completed"
        case .missed:
            return "Missed"
        }
    }

    private var fajrSummary: String {
        let entries = recentFajrEntries
        let completed = entries.filter { $0.status == .completed }.count
        let missed = entries.filter { $0.status == .missed }.count
        if completed == 0 && missed == 0 {
            return "No logged mornings yet"
        }
        return "\(completed) made it · \(missed) missed"
    }

    private var fastSummary: String {
        let entries = recentFastEntries
        let completed = entries.filter { $0.status == .completed }.count
        let missed = entries.filter { $0.status == .missed }.count
        if completed == 0 && missed == 0 {
            return "No logged fasts yet"
        }
        return "\(completed) completed · \(missed) missed"
    }

    private var recentFajrEntries: [FajrLogEntry] {
        let keys = recentDateKeys(days: 30)
        return keys.compactMap { fajrLogStore.entry(for: $0) }
    }

    private var recentFastEntries: [FastLogEntry] {
        let keys = recentDateKeys(days: 30)
        return keys.compactMap { fastLogStore.entry(for: $0) }
    }

    private func recentDateKeys(days: Int) -> [String] {
        let timeZone = TimeZone.current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: Date())
        return (0..<days).compactMap { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        }
    }

    private func refreshProgress() {
        qadaProgress = QadaProgressEngine.snapshot(
            state: qadaBacklogStore.state,
            logEntries: fastLogStore.entriesByDateKey
        )
    }

    private func refreshWakeProgress() {
        wakeProgress = wakeProgressSource.snapshot(limit: 20)
    }
}
