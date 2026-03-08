import SwiftUI

struct ProgressRootView: View {
    @EnvironmentObject private var qadaBacklogStore: QadaBacklogStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @State private var qadaProgress = QadaProgressSnapshot(remaining: 0, completed: 0, baselineOwed: 0)
    @State private var wakeProgress = WakeProgressSnapshot.empty

    private let wakeProgressSource = DebugEventLogWakeProgressSource()

    var body: some View {
        List {
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
                Text("Recent wake activity uses the current wake-event log until a dedicated wake history model replaces it.")
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
                    LabeledContent("Last 30 days", value: historySummary)
                }
            } header: {
                Text("Observance History")
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
    }

    private var historySummary: String {
        let completed = fastLogStore.entriesByDateKey.values.filter { $0.status == .completed }.count
        if completed == 0 {
            return "No logged days yet"
        }
        return "\(completed) completed"
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
