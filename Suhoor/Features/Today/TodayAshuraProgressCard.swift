import SwiftUI

struct TodayAshuraProgressCard: View {
    let mode: TodaySeasonalCardMode

    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulsePendingBar = false

    private let accent = FastSecondaryVirtueTag.ashura.style.color

    var body: some View {
        if let model = progressModel {
            GlassCard(style: .header) {
                VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                    HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ashura \(model.hijriYear)")
                                .font(DesignTokens.cardTitleFont)
                            Text(mode == .preview ? "Previewing Muharram 9-11" : "Muharram 9, 10, and 11")
                                .font(DesignTokens.cardSubtitleFont)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        TodaySeasonalBadge(
                            text: mode == .live ? "\(model.completedCount)/3" : "Preview",
                            accent: nil
                        )
                    }

                    TodayDiscreteProgressBars(
                        totalCount: model.totalCount,
                        completedCount: model.completedCount,
                        hasPending: model.hasPendingToday,
                        color: accent,
                        pulsePending: pulsePendingBar,
                        celebrate: model.isComplete
                    )
                    .animation(Motion.spring(reduceMotion: reduceMotion), value: model.displayFilledCount)

                    Text(mode == .preview
                         ? "Previewing the next Ashura sequence."
                         : "Track the Muharram 9, 10, and 11 sequence.")
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)
                }
            }
            .onAppear { updatePulse(for: model) }
            .onChange(of: model.hasPendingToday) { _, _ in updatePulse(for: model) }
        }
    }

    private var progressModel: TodayTrackerProgressModel? {
        guard let targetMonthKey = TodayObservanceEngine.muharramTargetMonthKey(now: Date(), mode: mode) else {
            return nil
        }
        return TodayObservanceEngine.trackerModel(
            now: Date(),
            mode: mode,
            targetMonthKey: targetMonthKey,
            trackedDays: 9...11,
            trackedTag: .ashura,
            scheduledEntries: alarmConfigStore.resolvedScheduledEntries(forHijriMonth: targetMonthKey, timeZone: .current),
            selections: fastTagStore.selections,
            logEntries: fastLogStore.entriesByDateKey
        )
    }

    private func updatePulse(for model: TodayTrackerProgressModel) {
        if model.hasPendingToday, reduceMotion == false {
            pulsePendingBar = false
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulsePendingBar = true
            }
        } else {
            pulsePendingBar = model.hasPendingToday
        }
    }
}
