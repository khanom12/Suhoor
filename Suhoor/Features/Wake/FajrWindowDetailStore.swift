import Combine
import Foundation

@MainActor
final class FajrWindowDetailStore: ObservableObject {
    @Published private(set) var snapshot: FajrWindowSurfaceSnapshot?
    @Published private(set) var period: FajrWindowPeriod
    @Published private(set) var requestedOverlay: FajrWindowOverlay = .myWake
    @Published private(set) var selectedDateKey: String?

    private var overlayPrefetchTask: Task<Void, Never>?

    init(initialPeriod: FajrWindowPeriod = .sevenDays) {
        self.period = initialPeriod
    }

    deinit {
        overlayPrefetchTask?.cancel()
    }

    func load(
        using scheduleManager: ScheduleManager,
        timeZone: TimeZone = .current
    ) {
        refreshSnapshot(using: scheduleManager, timeZone: timeZone)
        prefetchComparisonOverlayIfNeeded(using: scheduleManager, timeZone: timeZone)
    }

    func setPeriod(
        _ newPeriod: FajrWindowPeriod,
        using scheduleManager: ScheduleManager,
        timeZone: TimeZone = .current
    ) {
        guard period != newPeriod else { return }
        period = newPeriod
        selectedDateKey = nil
        refreshSnapshot(using: scheduleManager, timeZone: timeZone)
        prefetchComparisonOverlayIfNeeded(using: scheduleManager, timeZone: timeZone)
    }

    func setOverlay(
        _ overlay: FajrWindowOverlay,
        using scheduleManager: ScheduleManager,
        timeZone: TimeZone = .current
    ) {
        guard requestedOverlay != overlay else { return }
        requestedOverlay = overlay

        if overlay == .compareFasting || overlay == .compareTahajjud {
            _ = scheduleManager.fajrWindowOverlaySeries(
                period: period,
                overlay: overlay,
                timeZone: timeZone
            )
        }

        refreshSnapshot(using: scheduleManager, timeZone: timeZone)
    }

    func selectDateKey(
        _ dateKey: String?,
        using scheduleManager: ScheduleManager,
        timeZone: TimeZone = .current
    ) {
        guard selectedDateKey != dateKey else { return }
        selectedDateKey = dateKey
        refreshSnapshot(using: scheduleManager, timeZone: timeZone)
    }

    private func refreshSnapshot(
        using scheduleManager: ScheduleManager,
        timeZone: TimeZone
    ) {
        let dataset = scheduleManager.fajrWindowDataset(period: period, timeZone: timeZone)
        let projected = scheduleManager.projectedFajrWindowSurfaceSnapshot(
            dataset: dataset,
            overlay: requestedOverlay,
            selectedDateKey: selectedDateKey,
            timeZone: timeZone
        )

        snapshot = projected
        if selectedDateKey == nil {
            selectedDateKey = projected.selectedDateKey
        }
        if requestedOverlay != projected.activeOverlay {
            requestedOverlay = projected.activeOverlay
        }
    }

    private func prefetchComparisonOverlayIfNeeded(
        using scheduleManager: ScheduleManager,
        timeZone: TimeZone
    ) {
        overlayPrefetchTask?.cancel()
        guard snapshot?.availableOverlays.contains(.compareFasting) != true else { return }

        overlayPrefetchTask = Task { @MainActor [weak self] in
            await Task.yield()
            guard let self, Task.isCancelled == false else { return }

            _ = scheduleManager.fajrWindowOverlaySeries(
                period: self.period,
                overlay: .compareFasting,
                timeZone: timeZone
            )

            guard Task.isCancelled == false else { return }
            self.refreshSnapshot(using: scheduleManager, timeZone: timeZone)
        }
    }
}
