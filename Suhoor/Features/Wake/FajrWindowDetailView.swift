import SwiftUI
import UIKit

struct FajrWindowDetailView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var appNavigator: AppNavigator
    @Environment(\.scenePhase) private var scenePhase

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
        .task {
            refreshFajrWindowData()
        }
        .onChange(of: scheduleManager.currentRevision) { _, _ in
            refreshFajrWindowData()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refreshFajrWindowData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refreshFajrWindowData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshFajrWindowData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            refreshFajrWindowData()
        }
    }

    private var currentTimeZone: TimeZone {
        .autoupdatingCurrent
    }

    private var refreshContext: FajrWindowRefreshContext {
        FajrWindowRefreshContext.current(
            revision: scheduleManager.currentRevision,
            timeZone: currentTimeZone
        )
    }

    private func refreshFajrWindowData() {
        store.refreshIfNeeded(
            using: scheduleManager,
            refreshContext: refreshContext,
            timeZone: currentTimeZone
        )
    }

    private func content(snapshot: FajrWindowSurfaceSnapshot) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                header(snapshot: snapshot)

                FajrWindowPeriodPicker(selectedPeriod: store.period) { newPeriod in
                    store.setPeriod(newPeriod, using: scheduleManager, timeZone: currentTimeZone)
                }

                GlassCard(style: .header, tintColor: DawnColor.lightGold200, tintOpacity: 0.10) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                        FajrWindowChartView(
                            chart: snapshot.chart,
                            layoutStyle: .detail,
                            onSelectDateKey: { store.selectDateKey($0, using: scheduleManager, timeZone: currentTimeZone) },
                            onMoveSelection: { store.moveSelection(by: $0, using: scheduleManager, timeZone: currentTimeZone) },
                            accessibilityLabel: "Fajr Window chart",
                            accessibilityValue: snapshot.selectedDay?.accessibilitySummary,
                            accessibilityHint: "The shaded band shows the supported Fajr window and the solid line shows your wake. Swipe up or down to move days, or use Previous day and Next day."
                        )

                        if let selectedDay = snapshot.selectedDay {
                            FajrWindowDayStepper(
                                selectedTitle: selectedDay.title,
                                canMoveBackward: canMoveBackward(in: snapshot),
                                canMoveForward: canMoveForward(in: snapshot),
                                onMoveBackward: {
                                    store.moveSelection(by: -1, using: scheduleManager, timeZone: currentTimeZone)
                                },
                                onMoveForward: {
                                    store.moveSelection(by: 1, using: scheduleManager, timeZone: currentTimeZone)
                                }
                            )
                        }

                        FajrWindowOverlayPicker(
                            overlays: overlayOptions(for: snapshot),
                            selectedOverlay: store.requestedOverlay,
                            loadingOverlay: store.loadingOverlay
                        ) { overlay in
                            store.setOverlay(overlay, using: scheduleManager, timeZone: currentTimeZone)
                        }

                        if let loadingOverlay = store.loadingOverlay {
                            Text("Loading \(loadingOverlay.title.lowercased())...")
                                .font(AppTypography.cardBody)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Loading \(loadingOverlay.title.lowercased())")
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
        VStack(alignment: .leading, spacing: DesignTokens.textSpacingCompact) {
            Text("Fajr Window")
                .font(DesignTokens.screenTitleFont)
            Text(snapshot.period.subtitle)
                .font(AppTypography.metricLabel)
                .foregroundStyle(.secondary)
            Text("See how your wake sits inside each morning's supported Fajr window.")
                .font(AppTypography.cardBody)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func overlayOptions(for snapshot: FajrWindowSurfaceSnapshot) -> [FajrWindowOverlay] {
        let shouldOfferFastingWake = snapshot.availableOverlays.contains(.compareFasting)
            || snapshot.points.contains(where: \.isFastingContext)
            || store.loadingOverlay == .compareFasting
            || store.requestedOverlay == .compareFasting

        return FajrWindowOverlay.allCases.filter { overlay in
            switch overlay {
            case .myWake, .compareSafe:
                return snapshot.availableOverlays.contains(overlay)
            case .compareFasting:
                return shouldOfferFastingWake
            case .compareTahajjud:
                return snapshot.availableOverlays.contains(overlay)
            }
        }
    }

    private func canMoveBackward(in snapshot: FajrWindowSurfaceSnapshot) -> Bool {
        guard let selectedDateKey = snapshot.selectedDateKey,
              let currentIndex = snapshot.points.firstIndex(where: { $0.dateKey == selectedDateKey }) else {
            return false
        }
        return currentIndex > 0
    }

    private func canMoveForward(in snapshot: FajrWindowSurfaceSnapshot) -> Bool {
        guard let selectedDateKey = snapshot.selectedDateKey,
              let currentIndex = snapshot.points.firstIndex(where: { $0.dateKey == selectedDateKey }) else {
            return false
        }
        return currentIndex < (snapshot.points.count - 1)
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
