import SwiftUI

struct TodayHomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @StateObject private var layoutStore = TodayCardLayoutStore()
    @State private var isEditingCards = false

    var body: some View {
        let hijriChangeCount = scheduleManager.hijriAdjustmentChanges.count
        let now = Date()
        let components = AdjustedHijriCalendar.shared.adjustedComponents(for: now, timeZone: .current)
        let liveObservanceContext = TodayObservanceEngine.liveContext(now: now)
        ScrollView {
            LazyVStack(spacing: DesignTokens.dashboardStackSpacing) {
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
                    todayCardView(for: card, components: components, observanceContext: liveObservanceContext)
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
        .navigationTitle("Today")
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
    }

    @ViewBuilder
    private func todayCardView(
        for card: TodayCardKind,
        components: AdjustedHijriDateComponents?,
        observanceContext: TodayObservanceContext?
    ) -> some View {
        switch card {
        case .countdown:
            if layoutStore.isVisible(card) {
                TodayCountdownCard()
            }
        case .ramadanProgress:
            if layoutStore.isVisible(card), components?.month == .ramadan {
                TodayRamadanProgressCard()
            }
        case .specialFastSpotlight:
            if layoutStore.isVisible(card) {
                TodaySpecialFastSpotlightCard(mode: specialFastMode(observanceContext))
            }
        case .shawwalSixProgress:
            if layoutStore.isVisible(card) {
                TodayShawwalSixProgressCard(mode: isLiveShawwalDay(components) ? .live : .preview)
            }
        case .shawwalPlan:
            if layoutStore.isVisible(card) {
                TodayShawwalPlanCard(mode: isLiveShawwalDay(components) ? .live : .preview)
            }
        case .dhulHijjahNineProgress:
            if layoutStore.isVisible(card) {
                TodayDhulHijjahProgressCard(mode: isLiveDhulHijjahDay(components) ? .live : .preview)
            }
        case .ashuraProgress:
            if layoutStore.isVisible(card) {
                TodayAshuraProgressCard(mode: isLiveAshuraDay(components) ? .live : .preview)
            }
        case .whiteDaysProgress:
            if layoutStore.isVisible(card) {
                TodayWhiteDaysProgressCard(mode: isLiveWhiteDaysDay(components) ? .live : .preview)
            }
        case .fastCheckIn:
            if layoutStore.isVisible(card) {
                TodayFastCheckInCard()
            }
        case .eidAlFitrNotice:
            if layoutStore.isVisible(card) || warningIsActive(.eidAlFitr, components: components) {
                TodayForbiddenFastDayCard(
                    kind: .eidAlFitr,
                    mode: warningIsActive(.eidAlFitr, components: components) ? .live : .preview
                )
            }
        case .eidAlAdhaNotice:
            if layoutStore.isVisible(card) || warningIsActive(.eidAlAdha, components: components) {
                TodayForbiddenFastDayCard(
                    kind: .eidAlAdha,
                    mode: warningIsActive(.eidAlAdha, components: components) ? .live : .preview
                )
            }
        case .tashreeqNotice:
            if layoutStore.isVisible(card) || warningIsActive(.tashreeq, components: components) {
                TodayForbiddenFastDayCard(
                    kind: .tashreeq,
                    mode: warningIsActive(.tashreeq, components: components) ? .live : .preview
                )
            }
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
        return [13, 14, 15].contains(components.day) && components.month != .ramadan
    }

    private func specialFastMode(_ context: TodayObservanceContext?) -> TodaySeasonalCardMode {
        guard let context,
              context.isRamadan == false,
              context.warnings.isEmpty,
              context.secondaryTags.isEmpty == false else {
            return .preview
        }
        return .live
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
