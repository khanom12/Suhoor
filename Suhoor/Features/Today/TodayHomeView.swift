import SwiftUI

struct TodayHomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @StateObject private var layoutStore = TodayCardLayoutStore()
    @State private var isEditingCards = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.spacingL) {
                ForEach(visibleCards) { card in
                    switch card {
                    case .countdown:
                        TodayCountdownCard()
                    case .ramadanProgress:
                        placeholderCard(title: "Ramadan Progress", detail: "Coming next: day/progress until Eid.")
                    case .fastCheckIn:
                        placeholderCard(title: "Fast Check-in", detail: "Coming next: Completed/Missed logging and history.")
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, DesignTokens.spacingL)
        }
        .background(
            LinearGradient(
                colors: [DawnColor.bgWarmTop, DawnColor.bgWarmBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { isEditingCards = true }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
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
                    .font(.headline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
