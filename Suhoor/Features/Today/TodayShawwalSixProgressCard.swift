import SwiftUI

struct TodayShawwalSixProgressCard: View {
    @EnvironmentObject private var alarmConfigStore: AlarmConfigStore
    @EnvironmentObject private var fastTagStore: FastTagStore
    @EnvironmentObject private var fastLogStore: FastLogStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulsePendingBar = false
    @State private var hasCelebratedCompletion = false

    private let shawwalColor = FastSecondaryVirtueTag.shawwalSix.style.color

    var body: some View {
        let _ = fastTagStore.currentRevision
        let _ = fastLogStore.currentRevision
        let _ = scheduleManager.hijriAdjustmentChanges.count

        if let model = ShawwalSixProgressEngine.model(
            now: Date(),
            scheduledEntries: currentMonthEntries,
            selections: fastTagStore.selections,
            logEntries: fastLogStore.entriesByDateKey
        ) {
            GlassCard(style: .header) {
                VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                    header(model: model)
                    bars(model: model)

                    if model.isComplete {
                        completionRow
                    } else if model.hasPendingToday {
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

    @ViewBuilder
    private func header(model: ShawwalSixProgressEngine.Model) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            Text("Shawwal \(model.hijriYear)")
                .font(DesignTokens.cardTitleFont)

            Spacer()

            historyButton

            Text("\(model.completedCount)/6")
                .font(DesignTokens.cardMetaFont)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DesignTokens.spacingS)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
    }

    @ViewBuilder
    private func bars(model: ShawwalSixProgressEngine.Model) -> some View {
        HStack(spacing: DesignTokens.spacingXS) {
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fillColor(for: index, model: model))
                    .frame(maxWidth: .infinity)
                    .frame(height: 18)
                    .scaleEffect(x: 1.0, y: model.isComplete && hasCelebratedCompletion ? 1.05 : 1.0)
                    .opacity(barOpacity(for: index, model: model))
                    .animation(Motion.spring(reduceMotion: reduceMotion), value: model.displayFilledCount)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Shawwal six progress")
        .accessibilityValue(accessibilityValue(for: model))
    }

    private var completionRow: some View {
        HStack(spacing: DesignTokens.spacingS) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(shawwalColor)
                .scaleEffect(hasCelebratedCompletion ? 1.0 : 0.85)
                .opacity(hasCelebratedCompletion ? 1.0 : 0.0)

            Text("All six Shawwal fasts are completed.")
                .font(DesignTokens.cardSubtitleFont.weight(.semibold))
                .foregroundStyle(shawwalColor)
        }
        .animation(Motion.spring(reduceMotion: reduceMotion), value: hasCelebratedCompletion)
    }

    private var helperRow: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            Text("Mark Shawwal days as Voluntary to start tracking.")
                .font(DesignTokens.cardSubtitleFont)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Button("Open Schedule") {
                NotificationCenter.default.post(name: .switchToAlarmTab, object: nil)
            }
            .font(DesignTokens.cardMetaFont)
        }
    }

    private var historyButton: some View {
        NavigationLink {
            FastHistoryView()
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(DesignTokens.cardMetaFont.weight(.semibold))
                .foregroundStyle(shawwalColor)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open fast history")
    }

    private func fillColor(for index: Int, model: ShawwalSixProgressEngine.Model) -> Color {
        if index < model.completedCount {
            return shawwalColor
        }
        if model.hasPendingToday && index == model.completedCount {
            return shawwalColor.opacity(0.5)
        }
        return Color(.secondarySystemGroupedBackground)
    }

    private func barOpacity(for index: Int, model: ShawwalSixProgressEngine.Model) -> Double {
        if model.hasPendingToday && index == model.completedCount {
            return pulsePendingBar ? 1.0 : 0.65
        }
        return 1.0
    }

    private func accessibilityValue(for model: ShawwalSixProgressEngine.Model) -> String {
        if model.isComplete {
            return "6 of 6 completed"
        }
        if model.hasPendingToday {
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
}
