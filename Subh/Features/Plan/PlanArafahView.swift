import SwiftUI

struct PlanArafahView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        let availability = scheduleManager.islamicQuickAddAvailability(.nextArafah)

        List {
            Section {
                QuickAddCard(
                    title: "Arafah",
                    description: "Adds the corrected 9 Dhul Hijjah.",
                    previewLine: availability.preview?.previewText,
                    statusLine: availability.reasonText
                ) {
                    actionView(for: availability) {
                        Task { _ = await scheduleManager.addIslamicQuickAdd(.nextArafah) }
                    }
                }
            }

            Section {
                InfoBanner(
                    systemImage: "calendar.badge.clock",
                    text: "Uses your Hijri corrections to compute the date."
                ) {
                    NavigationLink("Manage corrections") {
                        HijriCalendarSettingsView()
                    }
                    .font(AppTypography.metricLabel)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Arafah")
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
