import Foundation
import os

struct HijriCalendarService {
    let baselineProvider: (Int, TimeZone) -> [HijriMonthBaselineStart]
    let adjustmentStore: HijriMonthAdjustmentStore

    init(
        baselineProvider: @escaping (Int, TimeZone) -> [HijriMonthBaselineStart] = HijriBaselineMonthStarts.starts,
        adjustmentStore: HijriMonthAdjustmentStore
    ) {
        self.baselineProvider = baselineProvider
        self.adjustmentStore = adjustmentStore
    }

    func buildMonthMap(
        hijriYear: Int,
        baselineStarts: [HijriMonthBaselineStart],
        adjustmentStore: HijriMonthAdjustmentStore,
        timeZone: TimeZone = .current
    ) -> HijriMonthMap {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let resolvedStarts = Dictionary(uniqueKeysWithValues: baselineStarts.compactMap { baseline -> (HijriMonth, HijriMonthResolvedStart)? in
            guard baseline.key.hijriYear == hijriYear else { return nil }
            let offsetDays = adjustmentStore.readAdjustment(for: baseline.key)
            let baselineStart = calendar.startOfDay(for: baseline.gregorianStartDate)
            let resolved = calendar.date(byAdding: .day, value: offsetDays, to: baselineStart) ?? baselineStart
            return (
                baseline.key.month,
                HijriMonthResolvedStart(
                    key: baseline.key,
                    baselineStart: baselineStart,
                    offsetDays: offsetDays,
                    resolvedStart: calendar.startOfDay(for: resolved)
                )
            )
        })

        return HijriMonthMap(hijriYear: hijriYear, resolvedStarts: resolvedStarts)
    }

    func buildMonthMap(hijriYear: Int, timeZone: TimeZone = .current) -> HijriMonthMap {
        buildMonthMap(
            hijriYear: hijriYear,
            baselineStarts: baselineProvider(hijriYear, timeZone),
            adjustmentStore: adjustmentStore,
            timeZone: timeZone
        )
    }

    func gregorianDate(
        for hijriYearMonth: HijriYearMonth,
        dayOfMonth: Int,
        monthMap: HijriMonthMap,
        timeZone: TimeZone = .current
    ) -> Date? {
        guard (1...30).contains(dayOfMonth) else { return nil }
        guard let start = monthMap.resolvedStart(for: hijriYearMonth.month) else {
            Logging.scheduler.debug("Missing Hijri baseline for \(hijriYearMonth.persistenceKey, privacy: .public)")
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalized = calendar.startOfDay(for: start.resolvedStart)
        let offset = dayOfMonth - 1
        let date = calendar.date(byAdding: .day, value: offset, to: normalized) ?? normalized
        return calendar.startOfDay(for: date)
    }

    func dateForAshura(hijriYear: Int, timeZone: TimeZone = .current) -> Date? {
        let map = buildMonthMap(hijriYear: hijriYear, timeZone: timeZone)
        return gregorianDate(for: HijriYearMonth(hijriYear: hijriYear, month: .muharram), dayOfMonth: 10, monthMap: map, timeZone: timeZone)
    }

    func datesForWhiteDays(hijriYear: Int, month: HijriMonth, timeZone: TimeZone = .current) -> [Date] {
        let map = buildMonthMap(hijriYear: hijriYear, timeZone: timeZone)
        let key = HijriYearMonth(hijriYear: hijriYear, month: month)
        return [13, 14, 15].compactMap { gregorianDate(for: key, dayOfMonth: $0, monthMap: map, timeZone: timeZone) }
    }

    func dateForRamadanStart(hijriYear: Int, timeZone: TimeZone = .current) -> Date? {
        let map = buildMonthMap(hijriYear: hijriYear, timeZone: timeZone)
        return gregorianDate(for: HijriYearMonth(hijriYear: hijriYear, month: .ramadan), dayOfMonth: 1, monthMap: map, timeZone: timeZone)
    }

    func dateForEidAlFitr(hijriYear: Int, timeZone: TimeZone = .current) -> Date? {
        let map = buildMonthMap(hijriYear: hijriYear, timeZone: timeZone)
        return gregorianDate(for: HijriYearMonth(hijriYear: hijriYear, month: .shawwal), dayOfMonth: 1, monthMap: map, timeZone: timeZone)
    }

    func dateForArafah(hijriYear: Int, timeZone: TimeZone = .current) -> Date? {
        let map = buildMonthMap(hijriYear: hijriYear, timeZone: timeZone)
        return gregorianDate(for: HijriYearMonth(hijriYear: hijriYear, month: .dhulHijjah), dayOfMonth: 9, monthMap: map, timeZone: timeZone)
    }

    func dateForEidAlAdha(hijriYear: Int, timeZone: TimeZone = .current) -> Date? {
        let map = buildMonthMap(hijriYear: hijriYear, timeZone: timeZone)
        return gregorianDate(for: HijriYearMonth(hijriYear: hijriYear, month: .dhulHijjah), dayOfMonth: 10, monthMap: map, timeZone: timeZone)
    }
}
