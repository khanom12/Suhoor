import SwiftUI

struct PlanAshuraView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @State private var showsPatternSheet = false

    var body: some View {
        let recommendedPattern = scheduleManager.recommendedAshuraQuickAddPattern()
        let availability = scheduleManager.ashuraQuickAddAvailability(recommendedPattern)

        List {
            Section {
                QuickAddCard(
                    title: "Ashura",
                    description: "Choose the recommended pairing or add all three days.",
                    previewLine: availability.preview?.previewText,
                    statusLine: availability.reasonText
                ) {
                    actionView(for: availability) {
                        showsPatternSheet = true
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
        .navigationTitle("Ashura")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showsPatternSheet) {
            NavigationStack {
                AshuraQuickAddSheet(
                    onAdd: { pattern in
                        Task {
                            _ = await scheduleManager.addAshuraQuickAdd(pattern)
                            showsPatternSheet = false
                        }
                    }
                )
            }
        }
    }

    private func actionView(
        for availability: AshuraQuickAddAvailability,
        action: @escaping () -> Void
    ) -> some View {
        switch availability.state {
        case .disabled:
            return AnyView(PillBadge(text: "Added", style: .off))
        case .available, .partial:
            return AnyView(
                Button("Select") { action() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            )
        }
    }
}
