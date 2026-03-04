import SwiftUI

struct TodayEditCardsSheet: View {
    @ObservedObject var layoutStore: TodayCardLayoutStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(layoutStore.layout.ordered) { card in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(card.title)
                                    .font(DesignTokens.cardTitleFont)
                                Text(subtitle(for: card))
                                    .font(DesignTokens.cardSubtitleFont)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Toggle(
                                "Show",
                                isOn: Binding(
                                    get: { layoutStore.isVisible(card) },
                                    set: { layoutStore.setVisible($0, for: card) }
                                )
                            )
                            .labelsHidden()
                        }
                    }
                    .onMove { from, to in
                        layoutStore.move(fromOffsets: from, toOffset: to)
                    }
                } header: {
                    Text("Cards")
                } footer: {
                    Text("Reorder and choose which cards appear on your Today dashboard.")
                }

                Section {
                    Button("Reset to Default") {
                        layoutStore.resetToDefault()
                    }
                    .foregroundStyle(DawnColor.danger)
                }
            }
            .navigationTitle("Edit Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func subtitle(for card: TodayCardKind) -> String {
        switch card {
        case .countdown:
            return "Countdown to Fajr or Iftar"
        case .ramadanProgress:
            return "Shows only during Ramadan"
        case .specialFastSpotlight:
            return "Dynamic spotlight for today's Sunnah observances"
        case .shawwalSixProgress:
            return "Six-bar Shawwal tracker"
        case .shawwalPlan:
            return "Plans remaining Shawwal fasts"
        case .dhulHijjahNineProgress:
            return "Tracks 1-9 Dhul Hijjah outside Ramadan"
        case .ashuraProgress:
            return "Tracks 9-11 Muharram outside Ramadan"
        case .whiteDaysProgress:
            return "Tracks 13-15 of the Hijri month outside Ramadan"
        case .fastCheckIn:
            return "Log your fast for today"
        case .eidAlFitrNotice:
            return "Hidden by default, auto-shows on 1 Shawwal"
        case .eidAlAdhaNotice:
            return "Hidden by default, auto-shows on 10 Dhul Hijjah"
        case .tashreeqNotice:
            return "Hidden by default, auto-shows on 11-13 Dhul Hijjah"
        }
    }
}
