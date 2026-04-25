import SwiftUI

struct PlanMondayThursdayView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        let availability = scheduleManager.islamicQuickAddAvailability(.nextMondayThursdayPair)
        let recurringStatus = scheduleManager.recurringRuleStatus(.mondayThursday)

        List {
            Section("Next Pair") {
                QuickAddCard(
                    title: "Next Monday + Thursday",
                    description: "Adds the next upcoming Monday and Thursday.",
                    previewLine: availability.preview?.previewText,
                    statusLine: availability.reasonText
                ) {
                    actionView(for: availability) {
                        Task { _ = await scheduleManager.addIslamicQuickAdd(.nextMondayThursdayPair) }
                    }
                }
            }

            Section("Recurring") {
                QuickAddCard(
                    title: "Recurring Mondays & Thursdays",
                    description: "Adds Mondays and Thursdays for the next Hijri year.",
                    statusLine: recurringStatus.isAdded ? "Already added" : nil
                ) {
                    if recurringStatus.isAdded {
                        PillBadge(text: "Added", style: .off)
                    } else {
                        Button("Add") {
                            Task { _ = await scheduleManager.addRecurringIslamicRule(.mondayThursday) }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Monday/Thursday")
        .navigationBarTitleDisplayMode(.large)
    }

    private func actionView(
        for availability: IslamicQuickAddAvailability,
        action: @escaping () -> Void
    ) -> some View {
        switch availability.state {
        case .disabled:
            return AnyView(PillBadge(text: "Added", style: .off))
        case .available, .partial:
            let title = availability.state == .partial ? "Add Remaining" : "Add"
            return AnyView(
                Button(title) { action() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            )
        }
    }
}
