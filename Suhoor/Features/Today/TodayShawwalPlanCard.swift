import SwiftUI

struct TodayShawwalPlanCard: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private let shawwalColor = FastSecondaryVirtueTag.shawwalSix.style.color

    var body: some View {
        let _ = fastTagStore.currentRevision
        let _ = fastLogStore.currentRevision
        let _ = scheduleManager.hijriAdjustmentChanges.count

        if let model = ShawwalPlanEngine.model(
            now: Date(),
            scheduledEntries: currentMonthEntries,
            selections: fastTagStore.selections,
            logEntries: fastLogStore.entriesByDateKey
        ) {
            GlassCard(style: .header) {
                VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                    header(model: model)

                    Text(summaryText(for: model))
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)

                    if model.recommendations.isEmpty == false {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                            ForEach(model.recommendations, id: \.dateKey) { recommendation in
                                recommendationRow(recommendation)
                            }
                        }
                    }

                    actionRow(model: model)
                }
            }
        }
    }

    private var currentMonthEntries: [ResolvedScheduledDateEntry] {
        guard let components = AdjustedHijriCalendar.shared.adjustedComponents(for: Date(), timeZone: .current),
              components.month == .shawwal else {
            return []
        }

        return alarmConfigStore.resolvedScheduledEntries(
            forHijriMonth: HijriYearMonth(hijriYear: components.hijriYear, month: .shawwal),
            timeZone: .current
        )
    }

    private func header(model: ShawwalPlanEngine.Model) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.isComplete ? "Keep the momentum" : "Plan the rest of Shawwal")
                    .font(DesignTokens.cardTitleFont)
                Text("Shawwal \(model.hijriYear)")
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(model.isComplete ? "Done" : "\(model.remainingCount) left")
                .font(DesignTokens.cardMetaFont)
                .foregroundStyle(model.isComplete ? shawwalColor : .secondary)
                .padding(.horizontal, DesignTokens.spacingS)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
    }

    private func recommendationRow(_ recommendation: ShawwalPlanEngine.Recommendation) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            VStack(alignment: .leading, spacing: 2) {
                Text(GregorianDateFormatter.shared.cardString(for: recommendation.date))
                    .font(DesignTokens.cardMetaFont)
                Text(HijriDateFormatter.shared.shortString(from: recommendation.date))
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if recommendation.tagLabels.isEmpty == false {
                Text(recommendation.tagLabels.joined(separator: " + "))
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(shawwalColor)
            }
        }
    }

    private func actionRow(model: ShawwalPlanEngine.Model) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            Button(model.isComplete ? "Open Schedule" : "Schedule More Days") {
                NotificationCenter.default.post(name: .switchToAlarmTab, object: nil)
            }
            .font(DesignTokens.cardMetaFont)

            Spacer(minLength: 0)

            NavigationLink {
                FastHistoryView()
            } label: {
                Text("History")
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(shawwalColor)
            }
        }
    }

    private func summaryText(for model: ShawwalPlanEngine.Model) -> String {
        if model.isComplete {
            return "All six are done. Keep building on Shawwal with Monday, Thursday, and White Day fasts when they line up."
        }
        if model.recommendations.isEmpty {
            return "No highlighted Shawwal windows remain. Any eligible voluntary day in Shawwal can still count toward the six."
        }
        return "Use the strongest remaining Shawwal windows first. Monday, Thursday, and White Days stay at the top of the list."
    }
}
