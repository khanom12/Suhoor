import SwiftUI

struct TodayFastCheckInCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastLogStore: FastLogStore

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

        VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                Text(questionTitle(for: phase))
                    .font(DesignTokens.cardTitleFont)

                Spacer()

                historyButton
            }

            statusRow(status: status, phase: phase, dateKey: dateKey, intent: intent)
        }
    }

    @ViewBuilder
    private func statusRow(
        status: FastLogStatus,
        phase: FastCheckInPhase,
        dateKey: String,
        intent: FastIntentSnapshot
    ) -> some View {
        switch status {
        case .unknown:
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                HStack(spacing: DesignTokens.spacingS) {
                    Button {
                        fastLogStore.setStatus(primaryAffirmativeStatus(for: phase), for: dateKey, intentSnapshot: intent)
                    } label: {
                        Text(primaryAffirmativeTitle(for: phase))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button {
                        fastLogStore.setStatus(.missed, for: dateKey, intentSnapshot: intent)
                    } label: {
                        Text("No")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }

        case .inProgress, .completed, .missed:
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                statusSelectorRow(status: status, phase: phase, dateKey: dateKey, intent: intent)
            }
        }
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
    private func statusSelectorRow(status: FastLogStatus, phase: FastCheckInPhase, dateKey: String, intent: FastIntentSnapshot) -> some View {
        let model = selectorModel(for: status, phase: phase)
        HStack(spacing: 6) {
            Text("Fast")
                .font(DesignTokens.cardSubtitleFont)
                .foregroundStyle(.secondary)

            Menu {
                ForEach(model.options, id: \.self) { option in
                    Button(option.title) {
                        fastLogStore.setStatus(option.status, for: dateKey, intentSnapshot: intent)
                    }
                }
                Button("Clear") {
                    fastLogStore.setStatus(.unknown, for: dateKey)
                }
            } label: {
                HStack(spacing: 6) {
                    Text(model.current.word)
                        .font(DesignTokens.cardSubtitleFont.weight(.semibold))
                        .foregroundStyle(model.current.color)
                    if let icon = model.current.icon {
                        Image(systemName: icon)
                            .foregroundStyle(model.current.color)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .accessibilityLabel("Fast status: \(model.current.accessibilityTitle)")
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
            fastLogStore.setStatus(.completed, for: dateKey, intentSnapshot: fastLogStore.entry(for: dateKey)?.intentSnapshot ?? intent, now: now)
            return .completed
        }
        return current
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
        case .preMaghrib:
            return "Yes"
        case .postMaghrib, .timeUnknown:
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

    private func todayCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}

private enum FastCheckInPhase {
    case preMaghrib
    case postMaghrib
    case timeUnknown
}

private struct FastCheckInSelectorModel {
    struct Current {
        let word: String
        let icon: String?
        let color: Color
        let accessibilityTitle: String
    }

    struct Option: Hashable {
        let status: FastLogStatus
        let title: String
    }

    let current: Current
    let options: [Option]
}

private extension TodayFastCheckInCard {
    func selectorModel(for status: FastLogStatus, phase: FastCheckInPhase) -> FastCheckInSelectorModel {
        switch phase {
        case .preMaghrib:
            return selectorModelPreMaghrib(status: status)
        case .postMaghrib:
            return selectorModelPostMaghrib(status: status)
        case .timeUnknown:
            return selectorModelTimeUnknown(status: status)
        }
    }

    private func selectorModelPreMaghrib(status: FastLogStatus) -> FastCheckInSelectorModel {
        let current = selectorCurrent(for: status, inProgressWord: "In progress")
        return .init(
            current: current,
            options: [
                .init(status: .inProgress, title: "In progress"),
                .init(status: .missed, title: "Missed"),
            ]
        )
    }

    private func selectorModelPostMaghrib(status: FastLogStatus) -> FastCheckInSelectorModel {
        let current = selectorCurrent(for: status, inProgressWord: "In progress")
        return .init(
            current: current,
            options: [
                .init(status: .completed, title: "Completed"),
                .init(status: .missed, title: "Missed"),
            ]
        )
    }

    private func selectorModelTimeUnknown(status: FastLogStatus) -> FastCheckInSelectorModel {
        let current = selectorCurrent(for: status, inProgressWord: "In progress")
        return .init(
            current: current,
            options: [
                .init(status: .completed, title: "Completed"),
                .init(status: .missed, title: "Missed"),
            ]
        )
    }

    private func selectorCurrent(for status: FastLogStatus, inProgressWord: String) -> FastCheckInSelectorModel.Current {
        switch status {
        case .inProgress:
            return .init(word: inProgressWord, icon: nil, color: .orange, accessibilityTitle: inProgressWord)
        case .completed:
            return .init(word: "Completed", icon: "checkmark.seal.fill", color: .green, accessibilityTitle: "Completed")
        case .missed:
            return .init(word: "Missed", icon: "xmark.seal.fill", color: .red, accessibilityTitle: "Missed")
        case .unknown:
            return .init(word: "Not logged", icon: nil, color: .secondary, accessibilityTitle: "Not logged")
        }
    }
}
