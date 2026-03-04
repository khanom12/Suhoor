import SwiftUI

struct PlanWhiteDaysView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        let availability = scheduleManager.islamicQuickAddAvailability(.nextWhiteDays)
        let recurringStatus = scheduleManager.recurringRuleStatus(.whiteDays)

        List {
            Section("Next White Days") {
                QuickAddCard(
                    title: "Next White Days",
                    description: "Adds the upcoming 13th, 14th, and 15th of the Hijri month.",
                    previewLine: availability.preview?.previewText,
                    statusLine: availability.reasonText
                ) {
                    actionView(for: availability) {
                        Task { _ = await scheduleManager.addIslamicQuickAdd(.nextWhiteDays) }
                    }
                }
            }

            Section("Recurring") {
                QuickAddCard(
                    title: "Recurring White Days",
                    description: "Adds white days for each month for the next Hijri year.",
                    statusLine: recurringStatus.isAdded ? "Already added" : nil
                ) {
                    if recurringStatus.isAdded {
                        PillBadge(text: "Added", style: .off)
                    } else {
                        Button("Add") {
                            Task { _ = await scheduleManager.addRecurringIslamicRule(.whiteDays) }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }

            Section {
                InfoBanner(
                    systemImage: "calendar.badge.clock",
                    text: "Uses your Hijri corrections to compute the dates."
                ) {
                    NavigationLink("Manage corrections") {
                        HijriCalendarSettingsView()
                    }
                    .font(.footnote.weight(.semibold))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("White Days")
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
