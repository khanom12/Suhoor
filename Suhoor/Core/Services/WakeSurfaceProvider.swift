import Foundation

struct WakeSurfaceProvider {
    struct Dependencies {
        let totalScheduledCount: (HijriMonthKey) -> Int
        let rollingHijriMonths: () -> [HijriYearMonth]
        let monthPreview: (HijriYearMonth) -> HijriMonthStartPreview?
        let cachedMonthEntries: (HijriMonthKey) -> [ActiveAlarmDay]?
    }

    func wakeSurfaceSnapshot(
        activeWindowSnapshot: ActiveAlarmWindowSnapshot,
        nextWakeEventSummary: NextWakeEventSummary?,
        overrideDateKeys: Set<String>
    ) -> WakeSurfaceSnapshot {
        WakeSurfaceSnapshot(
            visibleDays: activeWindowSnapshot.visibleDays,
            nextWakeEventSummary: nextWakeEventSummary,
            overrideDateKeys: overrideDateKeys
        )
    }

    func wakeListSnapshot(
        wakeSnapshot: WakeSurfaceSnapshot,
        tagFilter: WakeTagFilter,
        pinnedEntryIDs: [String],
        timeZone: TimeZone = .current,
        dependencies: Dependencies
    ) -> WakeListSnapshotBuildResult {
        WakeListSnapshotBuilder.build(
            wakeSnapshot: wakeSnapshot,
            tagFilter: tagFilter,
            pinnedEntryIDs: pinnedEntryIDs,
            timeZone: timeZone,
            totalScheduledCount: dependencies.totalScheduledCount,
            rollingHijriMonths: dependencies.rollingHijriMonths,
            monthPreview: dependencies.monthPreview,
            cachedMonthEntries: dependencies.cachedMonthEntries
        )
    }
}
