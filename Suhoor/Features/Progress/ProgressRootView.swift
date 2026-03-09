import SwiftUI

struct ProgressRootView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        let snapshot = scheduleManager.progressSurfaceSnapshot()
        List {
            Section {
                NavigationLink {
                    FajrHistoryView()
                } label: {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        LabeledContent("Today", value: snapshot.fajrTodaySummary)
                        LabeledContent("Last 30 mornings", value: snapshot.fajrSummary)
                    }
                }
            } header: {
                Text("Fajr")
            } footer: {
                Text("Prayer completion history.")
            }

            Section {
                NavigationLink {
                    FastHistoryView()
                } label: {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        LabeledContent("Today", value: snapshot.fastTodaySummary)
                        LabeledContent("Last 30 days", value: snapshot.fastSummary)
                    }
                }
            } header: {
                Text("Fasts")
            } footer: {
                Text("Fasting-day completion history.")
            }

            Section {
                LabeledContent("Completed", value: "\(snapshot.qadaProgress.completed)")
                LabeledContent("Remaining", value: "\(snapshot.qadaProgress.remaining)")
                if snapshot.qadaProgress.baselineOwed == 0 {
                    Text("Add Qada obligations from Plans when you need them.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Qada Progress")
            } footer: {
                Text("Completed Qada fasts reduce what remains.")
            }

            Section {
                if let summaryTitle = snapshot.wakeProgress.summaryTitle {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                        Text(summaryTitle)
                            .font(.headline.weight(.semibold))
                        if let summaryDetail = snapshot.wakeProgress.summaryDetail {
                            Text(summaryDetail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(snapshot.wakeProgress.recentActivityLines, id: \.self) { line in
                        Text(line)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if let emptyStateText = snapshot.wakeProgress.emptyStateText {
                    Text(emptyStateText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Wake Activity")
            } footer: {
                Text("Technical wake support only.")
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
    }
}
