import Combine
import Foundation

struct FajrWindowRefreshContext: Equatable, Sendable {
    let revision: Int
    let timeZoneIdentifier: String
    let startOfDay: Date

    static func current(
        revision: Int,
        now: Date = Date(),
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> FajrWindowRefreshContext {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = timeZone

        return FajrWindowRefreshContext(
            revision: revision,
            timeZoneIdentifier: timeZone.identifier,
            startOfDay: calendar.startOfDay(for: now)
        )
    }
}

@MainActor
final class FajrWindowDetailStore: ObservableObject {
    @Published private(set) var snapshot: FajrWindowSurfaceSnapshot?
    @Published private(set) var period: FajrWindowPeriod
    @Published private(set) var requestedOverlay: FajrWindowOverlay = .myWake
    @Published private(set) var selectedDateKey: String?
    @Published private(set) var loadingOverlay: FajrWindowOverlay?

    private var overlayLoadTask: Task<Void, Never>?
    private var lastRefreshContext: FajrWindowRefreshContext?

    init(
        initialPeriod: FajrWindowPeriod = .sevenDays,
        initialSelectedDateKey: String? = nil
    ) {
        self.period = initialPeriod
        self.selectedDateKey = initialSelectedDateKey
    }

    deinit {
        overlayLoadTask?.cancel()
    }

    func load(
        using scheduleManager: ScheduleManager,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        lastRefreshContext = nil
        refreshSnapshot(using: scheduleManager, timeZone: timeZone)
    }

    func refreshIfNeeded(
        using scheduleManager: ScheduleManager,
        refreshContext: FajrWindowRefreshContext,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        guard lastRefreshContext != refreshContext else { return }
        cancelOverlayLoad(resetRequestedOverlay: false)
        lastRefreshContext = refreshContext
        refreshSnapshot(using: scheduleManager, timeZone: timeZone)
    }

    func setPeriod(
        _ newPeriod: FajrWindowPeriod,
        using scheduleManager: ScheduleManager,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        guard period != newPeriod else { return }
        period = newPeriod
        selectedDateKey = nil
        cancelOverlayLoad()

        if requestedOverlay == .compareFasting || requestedOverlay == .compareTahajjud {
            requestedOverlay = .myWake
        }

        refreshSnapshot(using: scheduleManager, timeZone: timeZone)
    }

    func setOverlay(
        _ overlay: FajrWindowOverlay,
        using scheduleManager: ScheduleManager,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        guard requestedOverlay != overlay || loadingOverlay != overlay else { return }

        cancelOverlayLoad(resetRequestedOverlay: false)
        requestedOverlay = overlay

        guard overlay == .compareFasting || overlay == .compareTahajjud else {
            refreshSnapshot(using: scheduleManager, timeZone: timeZone)
            return
        }

        if snapshot?.availableOverlays.contains(overlay) == true {
            refreshSnapshot(using: scheduleManager, timeZone: timeZone)
            return
        }

        loadingOverlay = overlay
        overlayLoadTask = Task { @MainActor [weak self] in
            await Task.yield()
            guard let self, Task.isCancelled == false else { return }

            _ = scheduleManager.fajrWindowOverlaySeries(
                period: self.period,
                overlay: overlay,
                timeZone: timeZone
            )

            guard Task.isCancelled == false else { return }
            self.loadingOverlay = nil
            self.refreshSnapshot(using: scheduleManager, timeZone: timeZone)
        }
    }

    func selectDateKey(
        _ dateKey: String?,
        using scheduleManager: ScheduleManager,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        guard selectedDateKey != dateKey else { return }
        selectedDateKey = dateKey
        refreshSnapshot(using: scheduleManager, timeZone: timeZone)
    }

    func moveSelection(
        by offset: Int,
        using scheduleManager: ScheduleManager,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        guard let snapshot, snapshot.points.isEmpty == false else { return }

        let currentKey = selectedDateKey ?? snapshot.selectedDateKey ?? snapshot.points.first?.dateKey
        let currentIndex = snapshot.points.firstIndex { $0.dateKey == currentKey } ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), snapshot.points.count - 1)
        guard nextIndex != currentIndex else { return }

        selectDateKey(snapshot.points[nextIndex].dateKey, using: scheduleManager, timeZone: timeZone)
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
        if loadingOverlay == nil, requestedOverlay != projected.activeOverlay {
            requestedOverlay = projected.activeOverlay
        }
    }

    private func cancelOverlayLoad(resetRequestedOverlay: Bool = false) {
        overlayLoadTask?.cancel()
        overlayLoadTask = nil
        loadingOverlay = nil

        if resetRequestedOverlay {
            requestedOverlay = .myWake
        }
    }
}
