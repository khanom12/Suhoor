import SwiftUI

struct ProgressRootView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        let snapshot = scheduleManager.progressSurfaceSnapshot()
        List {
            if let headlineText = snapshot.headlineText {
                Section {
                    Text(headlineText)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.vertical, DesignTokens.spacingXS)
                }
            }

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
                Text(Strings.ProgressSurface.fajrFooter)
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
                Text(snapshot.fastSectionTitle)
            } footer: {
                Text(Strings.ProgressSurface.fastFooter)
            }

            Section {
                LabeledContent("Completed", value: "\(snapshot.qadaProgress.completed)")
                LabeledContent("Remaining", value: "\(snapshot.qadaProgress.remaining)")
                if snapshot.qadaProgress.baselineOwed == 0 {
                    Text(Strings.ProgressSurface.qadaEnablePrompt)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Qada Progress")
            } footer: {
                Text(Strings.ProgressSurface.qadaFooter)
            }

            Section {
                if let summaryTitle = snapshot.wakeProgress.summaryTitle {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                        Text(summaryTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
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
                Text(Strings.ProgressSurface.wakeFooter)
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
    }
}
