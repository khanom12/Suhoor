import SwiftUI

struct FajrWindowDetailView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var appNavigator: AppNavigator

    let initialPeriod: FajrWindowPeriod

    @StateObject private var store: FajrWindowDetailStore
    @State private var selectedMorningDate: Date?

    init(initialPeriod: FajrWindowPeriod = .sevenDays) {
        self.initialPeriod = initialPeriod
        _store = StateObject(wrappedValue: FajrWindowDetailStore(initialPeriod: initialPeriod))
    }

    var body: some View {
        Group {
            if let snapshot = store.snapshot {
                content(snapshot: snapshot)
            } else {
                ProgressView("Loading mornings")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding()
            }
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
        .task(id: detailRefreshKey) {
            store.load(using: scheduleManager, timeZone: .current)
        }
    }

    private var detailRefreshKey: String {
        "\(scheduleManager.currentRevision)-\(TimeZone.current.identifier)"
    }

    private func content(snapshot: FajrWindowSurfaceSnapshot) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                header(snapshot: snapshot)

                FajrWindowPeriodPicker(selectedPeriod: store.period) { newPeriod in
                    store.setPeriod(newPeriod, using: scheduleManager, timeZone: .current)
                }

                GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.10) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                        FajrWindowChartView(
                            chart: snapshot.chart,
                            layoutStyle: .detail,
                            onSelectDateKey: { store.selectDateKey($0, using: scheduleManager, timeZone: .current) }
                        )

                        FajrWindowOverlayPicker(
                            overlays: snapshot.availableOverlays,
                            selectedOverlay: snapshot.activeOverlay
                        ) { overlay in
                            store.setOverlay(overlay, using: scheduleManager, timeZone: .current)
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
