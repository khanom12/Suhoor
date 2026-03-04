import SwiftUI

struct TodayShawwalPlanCard: View {
    let mode: TodaySeasonalCardMode

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
            mode: mode,
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
              let targetMonth = targetMonthKey(currentComponents: components) else {
            return []
        }

        return alarmConfigStore.resolvedScheduledEntries(
            forHijriMonth: targetMonth,
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
                if mode == .preview {
                    Text("Previewing the next Shawwal window")
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            TodaySeasonalBadge(
                text: mode == .live ? (model.isComplete ? "Done" : "\(model.remainingCount) left") : "Preview",
                accent: mode == .live && model.isComplete ? shawwalColor : nil
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
        if mode == .preview {
            return "Previewing the next Shawwal window. Monday, Thursday, and White Days stay at the top of the list."
        }
        if model.isComplete {
            return "All six are done. Keep building on Shawwal with Monday, Thursday, and White Day fasts when they line up."
        }
        if model.recommendations.isEmpty {
            return "No highlighted Shawwal windows remain. Any eligible voluntary day in Shawwal can still count toward the six."
        }
        return "Use the strongest remaining Shawwal windows first. Monday, Thursday, and White Days stay at the top of the list."
    }

    private func targetMonthKey(currentComponents: AdjustedHijriDateComponents) -> HijriYearMonth? {
        switch mode {
        case .live:
            return HijriYearMonth(hijriYear: currentComponents.hijriYear, month: .shawwal)
        case .preview:
            let previewYear = currentComponents.month.rawValue <= HijriMonth.shawwal.rawValue
                ? currentComponents.hijriYear
                : currentComponents.hijriYear + 1
            return HijriYearMonth(hijriYear: previewYear, month: .shawwal)
        }
    }
}
