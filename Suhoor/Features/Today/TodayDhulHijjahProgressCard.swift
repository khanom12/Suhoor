import SwiftUI

struct TodayDhulHijjahProgressCard: View {
    let mode: TodaySeasonalCardMode

    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulsePendingBar = false
    @State private var celebrateCompletion = false

    private let accent = FastSecondaryVirtueTag.dhulHijjahFirstNine.style.color

    var body: some View {
        if let model = progressModel {
            GlassCard(style: .header) {
                VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                    HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dhul Hijjah \(model.hijriYear)")
                                .font(DesignTokens.cardTitleFont)
                            if mode == .preview {
                                Text("Previewing the next 1-9 Dhul Hijjah window")
                                    .font(DesignTokens.cardSubtitleFont)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        TodaySeasonalBadge(
                            text: mode == .live ? "\(model.completedCount)/9" : "Preview",
                            accent: mode == .live && model.isComplete ? accent : nil
                        )
                    }

                    TodayDiscreteProgressBars(
                        totalCount: model.totalCount,
                        completedCount: model.completedCount,
                        hasPending: model.hasPendingToday,
                        color: accent,
                        pulsePending: pulsePendingBar,
                        celebrate: celebrateCompletion
                    )
                    .animation(Motion.spring(reduceMotion: reduceMotion), value: model.displayFilledCount)

                    Text(summaryText(for: model))
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)
                }
            }
            .onAppear { updateAnimationState(for: model) }
            .onChange(of: model.hasPendingToday) { _, _ in updateAnimationState(for: model) }
            .onChange(of: model.completedCount) { _, _ in updateAnimationState(for: model) }
        }
    }

    private var progressModel: TodayTrackerProgressModel? {
        guard let targetMonthKey = TodayObservanceEngine.dhulHijjahTargetMonthKey(now: Date(), mode: mode) else {
            return nil
        }
        return TodayObservanceEngine.trackerModel(
            now: Date(),
            mode: mode,
            targetMonthKey: targetMonthKey,
            trackedDays: 1...9,
            trackedTag: .dhulHijjahFirstNine,
            scheduledEntries: alarmConfigStore.resolvedScheduledEntries(forHijriMonth: targetMonthKey, timeZone: .current),
            selections: fastTagStore.selections,
            logEntries: fastLogStore.entriesByDateKey
        )
    }

    private func summaryText(for model: TodayTrackerProgressModel) -> String {
        if mode == .preview {
            return "Previewing the next Dhul Hijjah run. Arafah is highlighted on day 9."
        }
        if let todayComponents = AdjustedHijriCalendar.shared.adjustedComponents(for: Date(), timeZone: .current),
           todayComponents.month == .dhulHijjah,
           todayComponents.day == 9 {
            return "Arafah is today."
        }
        if model.hasPendingToday {
            return "Today's Dhul Hijjah fast is in progress."
        }
        return "Track voluntary fasting across the first nine days of Dhul Hijjah."
    }

    private func updateAnimationState(for model: TodayTrackerProgressModel) {
        if model.hasPendingToday, reduceMotion == false {
            pulsePendingBar = false
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulsePendingBar = true
            }
        } else {
            pulsePendingBar = model.hasPendingToday
        }
        celebrateCompletion = model.isComplete
    }
}
