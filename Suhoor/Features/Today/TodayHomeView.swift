import SwiftUI

struct TodayHomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @StateObject private var layoutStore = TodayCardLayoutStore()
    @State private var isEditingCards = false

    var body: some View {
        let hijriChangeCount = scheduleManager.hijriAdjustmentChanges.count
        let now = Date()
        let components = AdjustedHijriCalendar.shared.adjustedComponents(for: now, timeZone: .current)
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
                    todayCardView(for: card, components: components)
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
        components: AdjustedHijriDateComponents?
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
        case .shawwalSixProgress:
            if layoutStore.isVisible(card), isLiveShawwalDay(components) {
                TodayShawwalSixProgressCard()
            }
        case .shawwalPlan:
            if layoutStore.isVisible(card), isLiveShawwalDay(components) {
                TodayShawwalPlanCard()
            }
        case .fastCheckIn:
            if layoutStore.isVisible(card) {
                TodayFastCheckInCard()
            }
        case .eidAlFitrNotice:
            if layoutStore.isVisible(card) || warningIsActive(.eidAlFitr, components: components) {
                TodayForbiddenFastDayCard(kind: .eidAlFitr, isPreview: !warningIsActive(.eidAlFitr, components: components))
            }
        case .eidAlAdhaNotice:
            if layoutStore.isVisible(card) || warningIsActive(.eidAlAdha, components: components) {
                TodayForbiddenFastDayCard(kind: .eidAlAdha, isPreview: !warningIsActive(.eidAlAdha, components: components))
            }
        case .tashreeqNotice:
            if layoutStore.isVisible(card) || warningIsActive(.tashreeq, components: components) {
                TodayForbiddenFastDayCard(kind: .tashreeq, isPreview: !warningIsActive(.tashreeq, components: components))
            }
        }
    }

    private func isLiveShawwalDay(_ components: AdjustedHijriDateComponents?) -> Bool {
        guard let components else { return false }
        return components.month == .shawwal && components.day >= 2
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
