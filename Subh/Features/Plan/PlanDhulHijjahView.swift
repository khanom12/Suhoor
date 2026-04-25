import SwiftUI

struct PlanDhulHijjahView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        let availability = scheduleManager.islamicQuickAddAvailability(.nextDhulHijjahFirstNine)

        List {
            Section {
                QuickAddCard(
                    title: "First 9 of Dhul Hijjah",
                    description: "Adds the first nine days of Dhul Hijjah with your corrected Hijri calendar.",
                    previewLine: availability.preview?.previewText,
                    statusLine: availability.reasonText
                ) {
                    actionView(for: availability) {
                        Task { _ = await scheduleManager.addIslamicQuickAdd(.nextDhulHijjahFirstNine) }
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
                    .font(AppTypography.metricLabel)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dhul Hijjah")
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
