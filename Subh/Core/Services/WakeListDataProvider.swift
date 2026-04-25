import Foundation
import CoreLocation
import os

@MainActor
final class WakeListDataProvider {
    struct Dependencies {
        let currentCoordinate: () -> CLLocationCoordinate2D?
        let resolvedEntriesForHijriMonth: (HijriYearMonth, TimeZone) -> [ResolvedScheduledDateEntry]
        let buildSnapshot: ([ResolvedScheduledDateEntry], CLLocationCoordinate2D, TimeZone) -> ActiveAlarmWindowSnapshot
    }

    private let alarmConfigStore: AlarmConfigStore
    private let adjustedHijriCalendar: AdjustedHijriCalendar
    private let fastTagStore: FastTagStore
    private let dependencies: Dependencies
    private var expandedMonthSnapshots: [String: ExpandedMonthSnapshot] = [:]
    private var expandedMonthInvalidationToken: Int = 0

    init(
        alarmConfigStore: AlarmConfigStore,
        adjustedHijriCalendar: AdjustedHijriCalendar,
        fastTagStore: FastTagStore,
        dependencies: Dependencies
    ) {
        self.alarmConfigStore = alarmConfigStore
        self.adjustedHijriCalendar = adjustedHijriCalendar
        self.fastTagStore = fastTagStore
        self.dependencies = dependencies
    }

    func wakeDependencies(timeZone: TimeZone) -> WakeSurfaceProvider.Dependencies {
        WakeSurfaceProvider.Dependencies(
            totalScheduledCount: { [weak self] key in
                self?.totalScheduledCount(for: key, timeZone: timeZone) ?? 0
            },
            rollingHijriMonths: { [weak self] in
                self?.rollingHijriMonths(count: 12, timeZone: timeZone) ?? []
            },
            monthPreview: { [weak self] yearMonth in
                self?.hijriMonthStartPreview(
                    for: yearMonth.month,
                    hijriYear: yearMonth.hijriYear,
                    timeZone: timeZone
                )
            },
            cachedMonthEntries: { [weak self] key in
                self?.cachedMonthEntries(for: key)
            }
        )
    }

    func invalidate(reason: String? = nil) {
        expandedMonthInvalidationToken += 1
        expandedMonthSnapshots.removeAll()
        if let reason {
            Logging.diagnostics.debug("[cache] invalidated expanded month snapshots: \(reason, privacy: .public)")
        }
    }

    func currentHijriYearMonth(
        timeZone: TimeZone = .current,
        date: Date = Date()
    ) -> HijriYearMonth? {
        if let components = adjustedHijriCalendar.adjustedComponents(for: date, timeZone: timeZone) {
            return HijriYearMonth(hijriYear: components.hijriYear, month: components.month)
        }
        var fallbackCalendar = Calendar(identifier: .islamicUmmAlQura)
        fallbackCalendar.timeZone = timeZone
        let fallback = fallbackCalendar.dateComponents([.year, .month], from: date)
        guard
            let year = fallback.year,
            let monthValue = fallback.month,
            let month = HijriMonth(rawValue: monthValue)
        else {
            return nil
        }
        return HijriYearMonth(hijriYear: year, month: month)
    }

    func rollingHijriMonths(
        count: Int = 12,
        timeZone: TimeZone = .current,
        date: Date = Date()
    ) -> [HijriYearMonth] {
        guard let start = currentHijriYearMonth(timeZone: timeZone, date: date), count > 0 else { return [] }
        return (0..<count).compactMap { offset in
            start.advanced(byMonths: offset)
        }
    }

    func totalScheduledCount(
        for key: HijriMonthKey,
        timeZone: TimeZone = .current
    ) -> Int {
        guard let month = HijriMonth(rawValue: key.month) else { return 0 }
        return alarmConfigStore.resolvedScheduledEntries(
            forHijriMonth: HijriYearMonth(hijriYear: key.year, month: month),
            timeZone: timeZone
        ).count
    }

    func hijriMonthStartPreview(
        for month: HijriMonth,
        hijriYear: Int,
        timeZone: TimeZone = .current
    ) -> HijriMonthStartPreview? {
        adjustedHijriCalendar.monthStartPreview(
            for: HijriYearMonth(hijriYear: hijriYear, month: month),
            timeZone: timeZone
        )
    }

    func cachedMonthEntries(for key: HijriMonthKey) -> [ActiveAlarmDay]? {
        let identifier = expandedMonthIdentifier(for: key)
        guard let cached = expandedMonthSnapshots[identifier],
              cached.invalidationToken == expandedMonthInvalidationToken,
              cached.tagSelectionRevision == fastTagStore.currentRevision else {
            return nil
        }
        return cached.entries
    }

    func monthEntries(
        for key: HijriMonthKey,
        timeZone: TimeZone = .current
    ) -> [ActiveAlarmDay] {
        let identifier = expandedMonthIdentifier(for: key)
        if let cached = expandedMonthSnapshots[identifier],
           cached.invalidationToken == expandedMonthInvalidationToken,
           cached.tagSelectionRevision == fastTagStore.currentRevision {
            return cached.entries
        }

        guard let coordinate = dependencies.currentCoordinate(),
              let month = HijriMonth(rawValue: key.month) else {
            return []
        }

        let resolvedEntries = dependencies.resolvedEntriesForHijriMonth(
            HijriYearMonth(hijriYear: key.year, month: month),
            timeZone
        )
        let entries = dependencies.buildSnapshot(resolvedEntries, coordinate, timeZone).visibleDays

        expandedMonthSnapshots[identifier] = ExpandedMonthSnapshot(
            key: key,
            generatedAt: Date(),
            invalidationToken: expandedMonthInvalidationToken,
            tagSelectionRevision: fastTagStore.currentRevision,
            entries: entries
        )
        return entries
    }

    private func expandedMonthIdentifier(for key: HijriMonthKey) -> String {
        "\(key.year)-\(key.month)"
    }
}
