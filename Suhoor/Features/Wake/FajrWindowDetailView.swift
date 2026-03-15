import SwiftUI

struct FajrWindowDetailView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var appNavigator: AppNavigator

    let initialPeriod: FajrWindowPeriod

    @State private var period: FajrWindowPeriod
    @State private var requestedOverlay: FajrWindowOverlay = .myWake
    @State private var selectedDateKey: String?
    @State private var selectedMorningDate: Date?

    init(initialPeriod: FajrWindowPeriod = .sevenDays) {
        self.initialPeriod = initialPeriod
        _period = State(initialValue: initialPeriod)
    }

    var body: some View {
        let snapshot = scheduleManager.fajrWindowSurfaceSnapshot(
            period: period,
            overlay: requestedOverlay,
            selectedDateKey: selectedDateKey
        )

        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                header(snapshot: snapshot)

                FajrWindowPeriodPicker(selectedPeriod: period) { newPeriod in
                    period = newPeriod
                }

                GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.10) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                        FajrWindowChartView(
                            snapshot: snapshot,
                            layoutStyle: .detail,
                            onSelectDateKey: { selectedDateKey = $0 }
                        )

                        FajrWindowOverlayPicker(
                            overlays: snapshot.availableOverlays,
                            selectedOverlay: snapshot.activeOverlay
                        ) { overlay in
                            requestedOverlay = overlay
                        }
                    }
                }

                if let selectedDay = snapshot.selectedDay {
                    FajrWindowSelectedDayCard(snapshot: selectedDay)
                }

                if let primarySummary = snapshot.primarySummary {
                    FajrWindowSummaryBlock(summary: primarySummary, tintColor: DawnColor.lightGold200, tintOpacity: 0.10)
                }

                ForEach(snapshot.supportSummaries) { summary in
                    FajrWindowSummaryBlock(summary: summary, tintColor: DawnColor.accent, tintOpacity: 0.08)
                }

                if !snapshot.insightItems.isEmpty {
                    FajrWindowInsightList(items: snapshot.insightItems)
                }

                if !snapshot.actionItems.isEmpty {
                    FajrWindowActionRows(items: snapshot.actionItems, onSelect: { intent in
                        handle(intent: intent, snapshot: snapshot)
                    })
                }
            }
            .padding(.horizontal, DesignTokens.spacingL)
            .padding(.vertical, DesignTokens.spacingL)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Fajr Window")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedMorningDate) { date in
            if let schedule = scheduleManager.activeDay(for: date)?.schedule {
                AlarmDayDetailView(schedule: schedule)
            } else {
                ContentUnavailableView(
                    "Morning unavailable",
                    systemImage: "sun.haze",
                    description: Text("This morning could not be reopened right now.")
                )
            }
        }
        .onChange(of: snapshot.selectedDateKey) { _, newValue in
            if selectedDateKey == nil {
                selectedDateKey = newValue
            }
        }
    }

    private func header(snapshot: FajrWindowSurfaceSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Fajr Window")
                .font(.title2.weight(.semibold))
            Text(snapshot.period.subtitle)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("A calm view of where your wake sits inside the morning window Suhoor can truthfully support today.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func handle(
        intent: FajrWindowActionIntent,
        snapshot: FajrWindowSurfaceSnapshot
    ) {
        switch intent {
        case .openDefaultMorningPlan:
            appNavigator.openDefaultMorningPlan()
        case .openSelectedMorning(let dateKey):
            guard let point = snapshot.points.first(where: { $0.dateKey == dateKey }) else { return }
            selectedMorningDate = point.date
        }
    }
}
