import SwiftUI

struct ProgressRootView: View {
    @EnvironmentObject private var qadaBacklogStore: QadaBacklogStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @State private var progress = QadaProgressSnapshot(remaining: 0, completed: 0, baselineOwed: 0)

    var body: some View {
        List {
            Section("Wake & Observance") {
                NavigationLink {
                    FastHistoryView()
                } label: {
                    LabeledContent("History", value: historySummary)
                }
            }

            Section("Qada") {
                LabeledContent("Completed", value: "\(progress.completed)")
                LabeledContent("Remaining", value: "\(progress.remaining)")
                if progress.baselineOwed == 0 {
                    Text("Add Qada obligations from Plans when you need them.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .onAppear(perform: refreshProgress)
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
        return "\(completed) logged"
    }

    private func refreshProgress() {
        progress = QadaProgressEngine.snapshot(
            state: qadaBacklogStore.state,
            logEntries: fastLogStore.entriesByDateKey
        )
    }
}
