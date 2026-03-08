import SwiftUI

struct TodayHomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var layoutStore = TodayCardLayoutStore()
    @StateObject private var dismissalStore = TodayCardDismissalStore()
    @State private var isEditingCards = false
    private let autoEnableStore = TodaySeasonalAutoEnableStore()

    var body: some View {
        let hijriChangeCount = scheduleManager.hijriAdjustmentChanges.count
        let now = Date()
        let components = AdjustedHijriCalendar.shared.adjustedComponents(for: now, timeZone: .current)
        let hijriDateKey = seasonalAutoEnableDateKey(for: components)
        ScrollView {
            LazyVStack(spacing: DesignTokens.dashboardStackSpacing) {
                TodayNextWakeHeroCard()

                VStack(alignment: .leading, spacing: 2) {
                    Text(GregorianDateFormatter.shared.headerString(for: now))
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)

                    Text(HijriDateFormatter.shared.string(from: now))
                        .font(DesignTokens.cardMetaFont)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(layoutStore.layout.ordered) { card in
                    todayCardView(
                        for: card,
                        now: now,
                        components: components
                    )
                }
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.top, DesignTokens.spacingXS)
            .padding(.bottom, DesignTokens.spacingXL)
        }
        .background(
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        )
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Edit") { isEditingCards = true }
            }
        }
        .sheet(isPresented: $isEditingCards) {
            TodayEditCardsSheet(layoutStore: layoutStore)
        }
        .onAppear { _ = scheduleManager.lastUpdated }
        .onAppear { _ = hijriChangeCount }
        .task(id: hijriDateKey) {
            autoEnableSeasonalCards(for: components)
        }
    }

    @ViewBuilder
    private func todayCardView(
        for card: TodayCardKind,
        now: Date,
        components: AdjustedHijriDateComponents?
    ) -> some View {
        switch card {
        case .countdown:
            if layoutStore.isVisible(card) {
                TodayCountdownCard()
            }
        case .ramadanProgress:
            if let mode = seasonalMode(for: card, isLive: isLiveRamadanDay(components)) {
                TodayRamadanProgressCard(mode: mode)
            }
        case .eidMubarak:
            if let mode = seasonalMode(for: card, isLive: isLiveEidMubarakDay(components)) {
                TodayEidMubarakCard(mode: mode)
            }
        case .shawwalSixProgress:
            if let mode = seasonalMode(for: card, isLive: isLiveShawwalDay(components)) {
                TodayShawwalSixProgressCard(mode: mode)
            }
        case .dhulHijjahNineProgress:
            if let mode = seasonalMode(for: card, isLive: isLiveDhulHijjahDay(components)) {
                TodayDhulHijjahProgressCard(mode: mode)
            }
        case .ashuraProgress:
            if let mode = seasonalMode(for: card, isLive: isLiveAshuraDay(components)) {
                TodayAshuraProgressCard(mode: mode)
            }
        case .whiteDaysProgress:
            if let mode = whiteDaysMode(for: card, components: components) {
                TodayWhiteDaysProgressCard(mode: mode)
            }
        case .fastCheckIn:
            if layoutStore.isVisible(card) {
                TodayFastCheckInCard()
            }
        case .eidAlFitrNotice:
            if shouldRenderForbiddenCard(.eidAlFitr, card: card, components: components, now: now) {
                TodayForbiddenFastDayCard(
                    kind: .eidAlFitr,
                    mode: forbiddenCardMode(.eidAlFitr, components: components),
                    onDismiss: {
                        dismissForbiddenCard(.eidAlFitr, card: card, now: now)
                    }
                )
                .transition(.opacity)
            }
        case .eidAlAdhaNotice:
            if shouldRenderForbiddenCard(.eidAlAdha, card: card, components: components, now: now) {
                TodayForbiddenFastDayCard(
                    kind: .eidAlAdha,
                    mode: forbiddenCardMode(.eidAlAdha, components: components),
                    onDismiss: {
                        dismissForbiddenCard(.eidAlAdha, card: card, now: now)
                    }
                )
                .transition(.opacity)
            }
        case .tashreeqNotice:
            if shouldRenderForbiddenCard(.tashreeq, card: card, components: components, now: now) {
                TodayForbiddenFastDayCard(
                    kind: .tashreeq,
                    mode: forbiddenCardMode(.tashreeq, components: components),
                    onDismiss: {
                        dismissForbiddenCard(.tashreeq, card: card, now: now)
                    }
                )
                .transition(.opacity)
            }
        }
    }

    private func seasonalMode(for card: TodayCardKind, isLive: Bool) -> TodaySeasonalCardMode? {
        guard layoutStore.isVisible(card) else {
            return nil
        }
        if isLive {
            return .live
        }
        return .reference
    }

    private func dismissForbiddenCard(_ warning: FastWarning, card: TodayCardKind, now: Date) {
        withAnimation(Motion.fade(reduceMotion: reduceMotion)) {
            dismissalStore.dismiss(warning, on: now)
            layoutStore.setVisible(false, for: card)
        }
    }

    private func isLiveShawwalDay(_ components: AdjustedHijriDateComponents?) -> Bool {
        guard let components else { return false }
        return components.month == .shawwal && components.day >= 2
    }

    private func isLiveDhulHijjahDay(_ components: AdjustedHijriDateComponents?) -> Bool {
        guard let components else { return false }
        return components.month == .dhulHijjah && (1...9).contains(components.day)
    }

    private func isLiveAshuraDay(_ components: AdjustedHijriDateComponents?) -> Bool {
        guard let components else { return false }
        return components.month == .muharram && (9...11).contains(components.day)
    }

    private func isLiveWhiteDaysDay(_ components: AdjustedHijriDateComponents?) -> Bool {
        guard let components else { return false }
        return components.month != .ramadan
    }

    private func isLiveRamadanDay(_ components: AdjustedHijriDateComponents?) -> Bool {
        components?.month == .ramadan
    }

    private func whiteDaysMode(
        for card: TodayCardKind,
        components: AdjustedHijriDateComponents?
    ) -> TodaySeasonalCardMode? {
        guard components?.month != .ramadan else { return nil }
        return seasonalMode(for: card, isLive: isLiveWhiteDaysDay(components))
    }

    private func isLiveEidMubarakDay(_ components: AdjustedHijriDateComponents?) -> Bool {
        guard let components else { return false }
        if components.month == .shawwal, components.day == 1 {
            return true
        }
        return components.month == .dhulHijjah && components.day == 10
    }

    private func forbiddenCardMode(
        _ warning: FastWarning,
        components: AdjustedHijriDateComponents?
    ) -> TodaySeasonalCardMode {
        warningIsActive(warning, components: components) ? .live : .reference
    }

    private func shouldRenderForbiddenCard(
        _ warning: FastWarning,
        card: TodayCardKind,
        components: AdjustedHijriDateComponents?,
        now: Date
    ) -> Bool {
        if layoutStore.isVisible(card) {
            return true
        }
        if dismissalStore.isDismissed(warning, on: now) {
            return false
        }
        let live = warningIsActive(warning, components: components)
        return live || layoutStore.isVisible(card)
    }

    private func seasonalAutoEnableDateKey(for components: AdjustedHijriDateComponents?) -> String {
        guard let components else { return "unknown" }
        return "\(components.hijriYear)-\(components.month.persistenceValue)-\(components.day)"
    }

    private func autoEnableSeasonalCards(for components: AdjustedHijriDateComponents?) {
        guard let components else { return }

        switch (components.month, components.day) {
        case (.shawwal, 2):
            autoEnable(.shawwalSixProgress, components: components)
        case (.dhulHijjah, 1):
            autoEnable(.dhulHijjahNineProgress, components: components)
        case (.muharram, 9):
            autoEnable(.ashuraProgress, components: components)
        default:
            break
        }
    }

    private func autoEnable(_ card: TodayCardKind, components: AdjustedHijriDateComponents) {
        let key = seasonalAutoEnableDateKey(for: components)
        guard layoutStore.isVisible(card) == false,
              autoEnableStore.hasAutoEnabled(card, for: key) == false else {
            return
        }

        layoutStore.setVisible(true, for: card)
        autoEnableStore.markAutoEnabled(card, for: key)
    }

    private func warningIsActive(_ warning: FastWarning, components: AdjustedHijriDateComponents?) -> Bool {
        guard let components else { return false }
        switch warning {
        case .eidAlFitr:
            return components.month == .shawwal && components.day == 1
        case .eidAlAdha:
            return components.month == .dhulHijjah && components.day == 10
        case .tashreeq:
            return components.month == .dhulHijjah && (11...13).contains(components.day)
        }
    }
}

private struct TodayNextWakeHeroCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.18) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                Text("Next Wake Event")
                    .font(DesignTokens.cardMetaFont)
                    .foregroundStyle(.secondary)

                if let summary = scheduleManager.nextWakeEventSummary {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        Text(TimeFormatters.timeFormatter.string(from: summary.event.fireDate))
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                            .monospacedDigit()

                        Text(summaryLabel(for: summary))
                            .font(DesignTokens.cardTitleFont)

                        Text(summary.relationText)
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)

                        contextChips(for: summary.day)

                        Text(summary.day.resolvedDayContext.explanation.summary)
                            .font(DesignTokens.cardMetaFont)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        Text("No wake event is scheduled yet.")
                            .font(DesignTokens.cardTitleFont)
                        Text("Set your location and morning plan to compute the next wake around Fajr.")
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func summaryLabel(for summary: NextWakeEventSummary) -> String {
        let eventTitle: String
        switch summary.event.type {
        case .wakeReminder:
            eventTitle = "Wake reminder"
        case .wakeAlarm:
            eventTitle = "Main wake"
        case .wakeFollowUp:
            eventTitle = "Wake follow-up"
        case .fajrBoundaryNotice:
            eventTitle = "Fajr notice"
        case .iftarReminder:
            eventTitle = "Iftar reminder"
        }

        let dayLabel = scheduleManager.dayLabel(for: summary.day.date)
        return "\(eventTitle) for \(dayLabel)"
    }

    @ViewBuilder
    private func contextChips(for day: ActiveAlarmDay) -> some View {
        let labels = [day.resolvedDayContext.primaryContext.title] + day.resolvedDayContext.secondaryContexts.map(\.title)
        if labels.isEmpty == false {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.spacingS) {
                    ForEach(labels, id: \.self) { label in
                        Text(label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                    }
                }
            }
        }
    }
}
