import SwiftUI

struct TodayEditCardsSheet: View {
    @ObservedObject var layoutStore: TodayCardLayoutStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let components = AdjustedHijriCalendar.shared.adjustedComponents(for: Date(), timeZone: .current)

        NavigationStack {
            List {
                Section {
                    ForEach(layoutStore.layout.ordered) { card in
                        HStack(spacing: DesignTokens.space12) {
                            VStack(alignment: .leading, spacing: DesignTokens.textSpacingMicro) {
                                Text(displayTitle(for: card, components: components))
                                    .font(AppTypography.rowTitle)
                                Text(subtitle(for: card))
                                    .font(AppTypography.rowBody)
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
            return "Shows during Ramadan"
        case .eidMubarak:
            return "Celebration card shown on Eid days (tap for fireworks)"
        case .shawwalSixProgress:
            return "Six-bar Shawwal tracker"
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

    private func displayTitle(
        for card: TodayCardKind,
        components: AdjustedHijriDateComponents?
    ) -> String {
        guard layoutStore.isVisible(card), isInReferenceState(card, components: components) else {
            return card.title
        }
        return "\(card.title) (Preview)"
    }

    private func isInReferenceState(
        _ card: TodayCardKind,
        components: AdjustedHijriDateComponents?
    ) -> Bool {
        switch card {
        case .countdown, .fastCheckIn:
            return false
        case .ramadanProgress:
            return components?.month != .ramadan
        case .eidMubarak:
            return isLiveEidMubarakDay(components) == false
        case .shawwalSixProgress:
            return isLiveShawwalDay(components) == false
        case .dhulHijjahNineProgress:
            return isLiveDhulHijjahDay(components) == false
        case .ashuraProgress:
            return isLiveAshuraDay(components) == false
        case .whiteDaysProgress:
            return components?.month == .ramadan
        case .eidAlFitrNotice:
            return isWarningActive(.eidAlFitr, components: components) == false
        case .eidAlAdhaNotice:
            return isWarningActive(.eidAlAdha, components: components) == false
        case .tashreeqNotice:
            return isWarningActive(.tashreeq, components: components) == false
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

    private func isLiveEidMubarakDay(_ components: AdjustedHijriDateComponents?) -> Bool {
        guard let components else { return false }
        if components.month == .shawwal, components.day == 1 {
            return true
        }
        return components.month == .dhulHijjah && components.day == 10
    }

    private func isWarningActive(_ warning: FastWarning, components: AdjustedHijriDateComponents?) -> Bool {
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
