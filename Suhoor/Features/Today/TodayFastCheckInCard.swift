import SwiftUI

struct TodayFastCheckInCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var fastLogStore: FastLogStore

    var body: some View {
        GlassCard {
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

                tagSummary(intent)
            }

            statusRow(status: status, phase: phase, dateKey: dateKey, intent: intent)
        }
    }

    @ViewBuilder
    private func tagSummary(_ snapshot: FastIntentSnapshot) -> some View {
        let tags = visibleTagItems(for: snapshot)
        if !tags.isEmpty {
            HStack(spacing: 6) {
                ForEach(tags) { tag in
                    switch tag.kind {
                    case .primary(let intent):
                        TodayPrimaryIntentCapsule(intent: intent, iconOnly: true)
                    case .secondary(let secondary):
                        TodaySecondaryTagCapsule(tag: secondary, iconOnly: true)
                    case .overflow(let count):
                        TodayOverflowCapsule(count: count)
                    }
                }
            }
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

                footerRow()
            }

        case .inProgress, .completed, .missed:
            VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                statusSelectorRow(status: status, phase: phase, dateKey: dateKey, intent: intent)
                footerRow()
            }
        }
    }

    @ViewBuilder
    private func footerRow() -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
            NavigationLink {
                FastHistoryView()
            } label: {
                Text("History")
                    .font(DesignTokens.cardMetaFont)
            }

            Spacer()
        }
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

    private func visibleTagItems(for snapshot: FastIntentSnapshot) -> [TodayIntentTagItem] {
        let allItems = tagItems(for: snapshot)
        guard allItems.count > 4 else { return allItems }
        let head = Array(allItems.prefix(4))
        return head + [TodayIntentTagItem(kind: .overflow(allItems.count - head.count))]
    }

    private func tagItems(for snapshot: FastIntentSnapshot) -> [TodayIntentTagItem] {
        var items: [TodayIntentTagItem] = []
        if snapshot.primaryIntent != .other {
            items.append(TodayIntentTagItem(kind: .primary(snapshot.primaryIntent)))
        }
        items.append(contentsOf: FastIntentEngine.displaySecondaryTags(snapshot.secondaryTags).map {
            TodayIntentTagItem(kind: .secondary($0))
        })
        return items
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

private struct TodayIntentTagItem: Identifiable {
    enum Kind {
        case primary(FastPrimaryIntent)
        case secondary(FastSecondaryVirtueTag)
        case overflow(Int)
    }

    let kind: Kind

    var id: String {
        switch kind {
        case .primary(let intent):
            return "primary-\(intent.rawValue)"
        case .secondary(let tag):
            return "secondary-\(tag.rawValue)"
        case .overflow(let count):
            return "overflow-\(count)"
        }
    }
}

private struct TodayPrimaryIntentCapsule: View {
    let intent: FastPrimaryIntent
    let iconOnly: Bool

    var body: some View {
        let style = intent.style
        TodayCapsuleLabel(
            title: style.title,
            shortTitle: style.shortTitle,
            systemImage: style.systemImage,
            color: style.color,
            prominence: .strong,
            useIconOnly: iconOnly
        )
    }
}

private struct TodaySecondaryTagCapsule: View {
    let tag: FastSecondaryVirtueTag
    let iconOnly: Bool

    var body: some View {
        let style = tag.style
        TodayCapsuleLabel(
            title: style.title,
            shortTitle: style.shortTitle,
            systemImage: style.systemImage,
            color: style.color,
            prominence: .subtle,
            useIconOnly: iconOnly
        )
    }
}

private struct TodayOverflowCapsule: View {
    let count: Int

    var body: some View {
        Text("+\(count)")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 0.6)
            )
            .accessibilityLabel("\(count) more tags")
    }
}

private struct TodayCapsuleLabel: View {
    enum Prominence {
        case strong
        case subtle
    }

    let title: String
    let shortTitle: String
    let systemImage: String?
    let color: Color
    let prominence: Prominence
    let useIconOnly: Bool

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
            }
            if !useIconOnly {
                Text(displayText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .font(font)
        .foregroundStyle(color)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(color.opacity(backgroundOpacity))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(borderOpacity), lineWidth: 0.6)
        )
        .accessibilityLabel(title)
    }

    private var displayText: String {
        shortTitle.isEmpty ? title : shortTitle
    }

    private var font: Font {
        switch prominence {
        case .strong:
            return .caption.weight(.semibold)
        case .subtle:
            return .caption2.weight(.semibold)
        }
    }

    private var backgroundOpacity: Double {
        switch prominence {
        case .strong:
            return 0.22
        case .subtle:
            return 0.14
        }
    }

    private var borderOpacity: Double {
        switch prominence {
        case .strong:
            return 0.4
        case .subtle:
            return 0.25
        }
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
