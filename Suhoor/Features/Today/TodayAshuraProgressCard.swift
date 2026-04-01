import SwiftUI

struct TodayAshuraProgressCard: View {
    let mode: TodaySeasonalCardMode

    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulsePendingBar = false
    @State private var model: TodayTrackerProgressModel?

    private let accent = FastSecondaryVirtueTag.ashura.style.color

    var body: some View {
        Group {
            if let model {
                GlassCard(style: .header) {
                    VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                            VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                                Text("Ashura \(String(model.hijriYear))")
                                    .font(AppTypography.cardTitle)
                                Text("Muharram 9, 10, and 11")
                                    .font(AppTypography.cardBody)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            TodayOpenScheduleButton(accent: accent)

                            TodaySeasonalBadge(
                                text: "\(model.completedCount)/3",
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

                        Text("Track the Muharram 9, 10, and 11 sequence.")
                            .font(AppTypography.cardBody)
                            .foregroundStyle(.secondary)
                    }
                }
                .onAppear { updatePulse(for: model) }
                .onChange(of: model.hasPendingToday) { _, _ in updatePulse(for: model) }
            }
        }
        .onAppear(perform: refreshModel)
        .onChange(of: mode) { _, _ in refreshModel() }
        .onChange(of: alarmConfigStore.currentRevision) { _, _ in refreshModel() }
        .onChange(of: fastTagStore.currentRevision) { _, _ in refreshModel() }
        .onChange(of: fastLogStore.currentRevision) { _, _ in refreshModel() }
        .onChange(of: scheduleManager.hijriAdjustmentChanges.count) { _, _ in refreshModel() }
    }

    private func refreshModel() {
        guard let targetMonthKey = TodayObservanceEngine.muharramTargetMonthKey(now: Date(), mode: mode) else {
            model = nil
            return
        }
        model = TodayObservanceEngine.trackerModel(
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
