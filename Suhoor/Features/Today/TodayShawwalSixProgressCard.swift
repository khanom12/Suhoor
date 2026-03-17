import SwiftUI

struct TodayShawwalSixProgressCard: View {
    let mode: TodaySeasonalCardMode

    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulsePendingBar = false
    @State private var hasCelebratedCompletion = false
    @State private var model: ShawwalSixProgressEngine.Model?

    private let shawwalColor = FastSecondaryVirtueTag.shawwalSix.style.color

    var body: some View {
        Group {
            if let model {
                GlassCard(style: .header) {
                    VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                        header(model: model)
                        bars(model: model)

                        if model.isComplete {
                            completionRow
                        } else if mode == .live, model.hasPendingToday {
                            Text("Today's Shawwal fast is in progress.")
                                .font(DesignTokens.cardSubtitleFont)
                                .foregroundStyle(.secondary)
                        } else if model.hasTrackedDays == false {
                            helperRow
                        }
                    }
                }
                .onAppear {
                    updateCompletionState(for: model)
                    startPendingPulseIfNeeded(model)
                }
                .onChange(of: model.completedCount) { _, _ in
                    updateCompletionState(for: model)
                }
                .onChange(of: model.hasPendingToday) { _, _ in
                    startPendingPulseIfNeeded(model)
                }
            }
        }
        .onAppear(perform: refreshModel)
        .onChange(of: mode) { _, _ in refreshModel() }
        .onChange(of: alarmConfigStore.currentRevision) { _, _ in refreshModel() }
        .onChange(of: fastTagStore.currentRevision) { _, _ in refreshModel() }
        .onChange(of: fastLogStore.currentRevision) { _, _ in refreshModel() }
        .onChange(of: scheduleManager.hijriAdjustmentChanges.count) { _, _ in refreshModel() }
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

    private func refreshModel() {
        model = ShawwalSixProgressEngine.model(
            now: Date(),
            mode: mode,
            scheduledEntries: currentMonthEntries,
            selections: fastTagStore.selections,
            logEntries: fastLogStore.entriesByDateKey
        )
    }

    @ViewBuilder
    private func header(model: ShawwalSixProgressEngine.Model) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                Text("Shawwal \(String(model.hijriYear))")
                    .font(AppTypography.cardTitle)
            }

            Spacer()

            historyButton
            TodayOpenScheduleButton(accent: shawwalColor)

            TodaySeasonalBadge(
                text: "\(model.completedCount)/6",
                accent: nil
            )
        }
    }

    @ViewBuilder
    private func bars(model: ShawwalSixProgressEngine.Model) -> some View {
        TodayDiscreteProgressBars(
            totalCount: 6,
            completedCount: model.completedCount,
            hasPending: model.hasPendingToday,
            color: shawwalColor,
            pulsePending: pulsePendingBar,
            celebrate: model.isComplete && hasCelebratedCompletion
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Shawwal six progress")
        .accessibilityValue(accessibilityValue(for: model))
        .animation(Motion.spring(reduceMotion: reduceMotion), value: model.displayFilledCount)
    }

    private var completionRow: some View {
        HStack(spacing: DesignTokens.spacingS) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(shawwalColor)
                .scaleEffect(hasCelebratedCompletion ? 1.0 : 0.85)
                .opacity(hasCelebratedCompletion ? 1.0 : 0.0)

            Text("All six Shawwal fasts are completed.")
                .font(AppTypography.metricLabel)
                .foregroundStyle(shawwalColor)
        }
        .animation(Motion.spring(reduceMotion: reduceMotion), value: hasCelebratedCompletion)
    }

    private var helperRow: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            Text("Mark Shawwal days as Voluntary to start tracking.")
                .font(AppTypography.cardBody)
                .foregroundStyle(.secondary)
        }
    }

    private var historyButton: some View {
        NavigationLink {
            FastHistoryView()
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(AppTypography.controlIcon)
                .foregroundStyle(shawwalColor)
                .frame(width: DesignTokens.regularControlFrame, height: DesignTokens.regularControlFrame)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open fast history")
    }

    private func accessibilityValue(for model: ShawwalSixProgressEngine.Model) -> String {
        if model.isComplete {
            return "6 of 6 completed"
        }
        if mode == .live, model.hasPendingToday {
            return "\(model.completedCount) of 6 completed, 1 in progress"
        }
        return "\(model.completedCount) of 6 completed"
    }

    private func updateCompletionState(for model: ShawwalSixProgressEngine.Model) {
        guard model.isComplete else {
            hasCelebratedCompletion = false
            return
        }
        guard hasCelebratedCompletion == false else { return }
        withAnimation(Motion.spring(reduceMotion: reduceMotion)) {
            hasCelebratedCompletion = true
        }
    }

    private func startPendingPulseIfNeeded(_ model: ShawwalSixProgressEngine.Model) {
        guard model.hasPendingToday else {
            pulsePendingBar = false
            return
        }
        guard reduceMotion == false else {
            pulsePendingBar = true
            return
        }
        pulsePendingBar = false
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            pulsePendingBar = true
        }
    }

    private func targetMonthKey(currentComponents: AdjustedHijriDateComponents) -> HijriYearMonth? {
        switch mode {
        case .live:
            return HijriYearMonth(hijriYear: currentComponents.hijriYear, month: .shawwal)
        case .reference:
            let referenceYear = currentComponents.month.rawValue <= HijriMonth.shawwal.rawValue
                ? currentComponents.hijriYear
                : currentComponents.hijriYear + 1
            return HijriYearMonth(hijriYear: referenceYear, month: .shawwal)
        }
    }
}
