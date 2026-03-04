import SwiftUI

struct TodayFastCheckInCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastLogStore: FastLogStore
    @State private var isPulsing = false

    var body: some View {
        GlassCard(style: .header) {
            TimelineView(.periodic(from: Date(), by: 60)) { context in
                content(now: context.date)
            }
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let timeZone = TimeZone.current
        let calendar = todayCalendar(timeZone: timeZone)
        let todayStart = calendar.startOfDay(for: now)
        let dateKey = DateHelpers.dayIdentifier(for: todayStart, timeZone: timeZone)
        let intent = resolvedIntentSnapshot(for: todayStart, dateKey: dateKey, timeZone: timeZone)
        let scheduleDay = scheduleManager.activeWindowSnapshot.byDateKey[dateKey]
        let phase = phase(now: now, scheduleDay: scheduleDay)
        let status = normalizedStatus(for: dateKey, phase: phase, intent: intent, now: now)
        let viewState = viewState(for: status, phase: phase)

        VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
            switch viewState {
            case .prompt(let promptPhase):
                promptContent(phase: promptPhase, dateKey: dateKey, intent: intent)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .inProgress, .completed, .missed:
                loggedContent(state: viewState, dateKey: dateKey)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewState)
    }

    @ViewBuilder
    private func promptContent(
        phase: FastCheckInPhase,
        dateKey: String,
        intent: FastIntentSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                Text(questionTitle(for: phase))
                    .font(DesignTokens.cardTitleFont)

                Spacer()

                historyButton
            }

            HStack(spacing: DesignTokens.spacingS) {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        fastLogStore.setStatus(primaryAffirmativeStatus(for: phase), for: dateKey, intentSnapshot: intent)
                    }
                } label: {
                    Text(primaryAffirmativeTitle(for: phase))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        fastLogStore.setStatus(.missed, for: dateKey, intentSnapshot: intent)
                    }
                } label: {
                    Text("No")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }

    @ViewBuilder
    private func loggedContent(state: FastCheckInViewState, dateKey: String) -> some View {
        ZStack(alignment: .top) {
            Text(statusTitle(for: state))
                .font(.title3.weight(.semibold))
                .foregroundStyle(statusColor(for: state))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .opacity(state == .inProgress ? (isPulsing ? 1.0 : 0.82) : 1.0)
                .scaleEffect(state == .inProgress ? (isPulsing ? 1.0 : 0.99) : 1.0)
                .onAppear {
                    guard state == .inProgress else {
                        isPulsing = false
                        return
                    }
                    isPulsing = false
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
                .onDisappear {
                    isPulsing = false
                }

            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                undoButton(dateKey: dateKey)

                Spacer()

                historyButton
            }
        }
        .frame(maxWidth: .infinity, minHeight: 88)
    }

    @ViewBuilder
    private var historyButton: some View {
        NavigationLink {
            FastHistoryView()
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(DesignTokens.cardMetaFont.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open fast history")
    }

    @ViewBuilder
    private func undoButton(dateKey: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                fastLogStore.setStatus(.unknown, for: dateKey)
            }
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(DesignTokens.cardMetaFont.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Undo fast status")
    }

    private func resolvedIntentSnapshot(for date: Date, dateKey: String, timeZone: TimeZone) -> FastIntentSnapshot {
        if let day = scheduleManager.activeWindowSnapshot.byDateKey[dateKey] {
            return FastIntentSnapshot(
                primaryIntent: day.tagResult.computedPrimaryIntent,
                secondaryTags: day.tagResult.computedSecondaryTags
            )
        }

        let suggestions = FastIntentEngine.suggestions(for: date, timeZone: timeZone)
        return FastIntentSnapshot(
            primaryIntent: suggestions.suggestedPrimary ?? .other,
            secondaryTags: Set(suggestions.suggestedSecondary)
        )
    }

    private func phase(now: Date, scheduleDay: ActiveAlarmDay?) -> FastCheckInPhase {
        guard let scheduleDay else { return .timeUnknown }
        return now < scheduleDay.schedule.maghribDate ? .preMaghrib : .postMaghrib
    }

    private func normalizedStatus(
        for dateKey: String,
        phase: FastCheckInPhase,
        intent: FastIntentSnapshot,
        now: Date
    ) -> FastLogStatus {
        let current = fastLogStore.status(for: dateKey)
        if phase == .postMaghrib, current == .inProgress {
            withAnimation(.easeInOut(duration: 0.22)) {
                fastLogStore.setStatus(.completed, for: dateKey, intentSnapshot: fastLogStore.entry(for: dateKey)?.intentSnapshot ?? intent, now: now)
            }
            return .completed
        }
        return current
    }

    private func viewState(for status: FastLogStatus, phase: FastCheckInPhase) -> FastCheckInViewState {
        switch status {
        case .unknown:
            return .prompt(phase)
        case .inProgress:
            return .inProgress
        case .completed:
            return .completed
        case .missed:
            return .missed
        }
    }

    private func questionTitle(for phase: FastCheckInPhase) -> String {
        switch phase {
        case .preMaghrib:
            return "Are you fasting today?"
        case .postMaghrib, .timeUnknown:
            return "Did you fast today?"
        }
    }

    private func primaryAffirmativeTitle(for phase: FastCheckInPhase) -> String {
        switch phase {
        case .preMaghrib, .postMaghrib, .timeUnknown:
            return "Yes"
        }
    }

    private func primaryAffirmativeStatus(for phase: FastCheckInPhase) -> FastLogStatus {
        switch phase {
        case .preMaghrib:
            return .inProgress
        case .postMaghrib, .timeUnknown:
            return .completed
        }
    }

    private func statusTitle(for state: FastCheckInViewState) -> String {
        switch state {
        case .prompt:
            return ""
        case .inProgress:
            return "Fasting in progress"
        case .completed:
            return "Fast completed"
        case .missed:
            return "Not fasting today"
        }
    }

    private func statusColor(for state: FastCheckInViewState) -> Color {
        switch state {
        case .prompt:
            return .primary
        case .inProgress:
            return .orange
        case .completed:
            return .green
        case .missed:
            return .secondary
        }
    }

    private func todayCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}

private enum FastCheckInPhase: Equatable {
    case preMaghrib
    case postMaghrib
    case timeUnknown
}

private enum FastCheckInViewState: Equatable {
    case prompt(FastCheckInPhase)
    case inProgress
    case completed
    case missed
}
