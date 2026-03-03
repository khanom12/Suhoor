import SwiftUI

struct TodayHomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @StateObject private var layoutStore = TodayCardLayoutStore()
    @State private var isEditingCards = false

    var body: some View {
        let isRamadan = AdjustedHijriCalendar.shared.isRamadan(date: Date(), timeZone: .current)
        ScrollView {
            LazyVStack(spacing: DesignTokens.dashboardStackSpacing) {
                ForEach(visibleCards) { card in
                    switch card {
                    case .countdown:
                        TodayCountdownCard()
                    case .ramadanProgress:
                        if isRamadan {
                            TodayRamadanProgressCard()
                        }
                    case .fastCheckIn:
                        TodayFastCheckInCard()
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.top, DesignTokens.spacingM)
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
    }

    private var visibleCards: [TodayCardKind] {
        layoutStore.layout.visibleOrderedCards()
    }

    private func placeholderCard(title: String, detail: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(DesignTokens.cardTitleFont)
                Text(detail)
                    .font(DesignTokens.cardSubtitleFont)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
