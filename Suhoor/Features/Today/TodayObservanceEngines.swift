import Foundation

struct TodayObservanceContext: Equatable, Sendable {
    let now: Date
    let hijriYear: Int
    let month: HijriMonth
    let day: Int
    let isRamadan: Bool
    let warnings: [FastWarning]
    let secondaryTags: [FastSecondaryVirtueTag]
}

enum TodayObservancePriority: Int, CaseIterable, Sendable {
    case arafah = 0
    case ashura = 1
    case dhulHijjahFirstNine = 2
    case whiteDays = 3
    case mondayThursday = 4

    var tag: FastSecondaryVirtueTag {
        switch self {
        case .arafah:
            return .arafah
        case .ashura:
            return .ashura
        case .dhulHijjahFirstNine:
            return .dhulHijjahFirstNine
        case .whiteDays:
            return .whiteDays
        case .mondayThursday:
            return .mondayThursday
        }
    }
}

struct TodayTrackerProgressModel: Equatable, Sendable {
    struct TaggedDay: Equatable, Sendable {
        let date: Date
        let dateKey: String
        let dayNumber: Int
    }

    let mode: TodaySeasonalCardMode
    let hijriYear: Int
    let month: HijriMonth
    let totalCount: Int
    let completedCount: Int
    let hasPendingToday: Bool
    let taggedDays: [TaggedDay]

    var displayFilledCount: Int {
        min(totalCount, completedCount + (hasPendingToday ? 1 : 0))
    }

    var remainingCount: Int {
        max(0, totalCount - completedCount)
    }

    var isComplete: Bool {
        completedCount >= totalCount
    }
}

struct TodayObservancePreview: Equatable, Sendable {
    let date: Date
    let context: TodayObservanceContext
    let primaryTag: FastSecondaryVirtueTag
}

enum TodayObservanceEngine {
    static func liveContext(
        now: Date,
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> TodayObservanceContext? {
        buildContext(for: now, calendar: calendar, timeZone: timeZone)
    }

    static func primaryTag(for context: TodayObservanceContext) -> FastSecondaryVirtueTag? {
        TodayObservancePriority.allCases
            .map(\.tag)
            .first(where: { context.secondaryTags.contains($0) })
    }

    static func previewSample(
        now: Date,
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> TodayObservancePreview? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        let start = DateHelpers.startOfDay(now, in: timeZone)

        for offset in 0..<400 {
            guard let candidate = gregorian.date(byAdding: .day, value: offset, to: start),
                  let context = buildContext(for: candidate, calendar: calendar, timeZone: timeZone),
                  context.isRamadan == false,
                  context.warnings.isEmpty,
                  let primaryTag = primaryTag(for: context) else {
                continue
            }

            return TodayObservancePreview(date: candidate, context: context, primaryTag: primaryTag)
        }

        return nil
    }

    static func dhulHijjahTargetMonthKey(
        now: Date,
        mode: TodaySeasonalCardMode,
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> HijriYearMonth? {
        targetMonthKey(
            now: now,
            mode: mode,
            targetMonth: .dhulHijjah,
            liveDayRange: 1...9,
            calendar: calendar,
            timeZone: timeZone
        )
    }

    static func muharramTargetMonthKey(
        now: Date,
        mode: TodaySeasonalCardMode,
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> HijriYearMonth? {
        targetMonthKey(
            now: now,
            mode: mode,
            targetMonth: .muharram,
            liveDayRange: 9...11,
            calendar: calendar,
            timeZone: timeZone
        )
    }

    static func whiteDaysTargetMonthKey(
        now: Date,
        mode: TodaySeasonalCardMode,
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> HijriYearMonth? {
        guard let components = calendar.adjustedComponents(for: now, timeZone: timeZone) else {
            return nil
        }

        let currentKey = HijriYearMonth(hijriYear: components.hijriYear, month: components.month)
        switch mode {
        case .live:
            return currentKey
        case .preview:
            if components.day < 13 {
                return currentKey
            }
            if components.day > 15 {
                return currentKey.advanced(byMonths: 1)
            }
            return currentKey
        }
    }

    static func trackerModel(
        now: Date,
        mode: TodaySeasonalCardMode,
        targetMonthKey: HijriYearMonth,
        trackedDays: ClosedRange<Int>,
        trackedTag: FastSecondaryVirtueTag,
        scheduledEntries: [ResolvedScheduledDateEntry],
        selections: [String: FastIntentSelection],
        logEntries: [String: FastLogEntry],
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> TodayTrackerProgressModel? {
        let seeds = mergedSeeds(
            scheduledEntries: scheduledEntries,
            logEntries: logEntries,
            targetMonthKey: targetMonthKey,
            trackedDays: trackedDays,
            calendar: calendar,
            timeZone: timeZone
        )
        let computed = TagComputationEngine.results(
            seeds: seeds.sorted(by: { $0.date < $1.date }),
            selections: selections,
            ruleset: .strict,
            timeZone: timeZone
        )
        let trackedDaySet = Set(trackedDays)
        let taggedDays = computed
            .filter { $0.value.computedSecondaryTags.contains(trackedTag) }
            .compactMap { key, _ -> TodayTrackerProgressModel.TaggedDay? in
                guard let date = seeds.first(where: { $0.dateKey == key })?.date,
                      let components = calendar.adjustedComponents(for: date, timeZone: timeZone),
                      trackedDaySet.contains(components.day) else {
                    return nil
                }
                return TodayTrackerProgressModel.TaggedDay(date: date, dateKey: key, dayNumber: components.day)
            }
            .sorted(by: { $0.dayNumber < $1.dayNumber })

        let todayKey = DateHelpers.dayIdentifier(for: DateHelpers.startOfDay(now, in: timeZone), timeZone: timeZone)
        let completedCount = taggedDays.reduce(into: 0) { partialResult, day in
            if logEntries[day.dateKey]?.status == .completed {
                partialResult += 1
            }
        }
        let hasPendingToday = mode == .live
            && taggedDays.contains(where: { $0.dateKey == todayKey })
            && logEntries[todayKey]?.status == .inProgress

        return TodayTrackerProgressModel(
            mode: mode,
            hijriYear: targetMonthKey.hijriYear,
            month: targetMonthKey.month,
            totalCount: trackedDays.count,
            completedCount: completedCount,
            hasPendingToday: hasPendingToday,
            taggedDays: taggedDays
        )
    }

    private static func buildContext(
        for date: Date,
        calendar: AdjustedHijriCalendar,
        timeZone: TimeZone
    ) -> TodayObservanceContext? {
        guard let components = calendar.adjustedComponents(for: date, timeZone: timeZone) else {
            return nil
        }

        let warnings = FastIntentEngine.warnings(for: date, timeZone: timeZone)
        let tags = FastIntentEngine.displaySecondaryTags(
            FastIntentEngine.dateDerivedObservanceTags(
                for: date,
                timeZone: timeZone,
                includeShawwalPotential: false
            )
        )

        return TodayObservanceContext(
            now: date,
            hijriYear: components.hijriYear,
            month: components.month,
            day: components.day,
            isRamadan: components.month == .ramadan,
            warnings: warnings,
            secondaryTags: tags
        )
    }

    private static func targetMonthKey(
        now: Date,
        mode: TodaySeasonalCardMode,
        targetMonth: HijriMonth,
        liveDayRange: ClosedRange<Int>,
        calendar: AdjustedHijriCalendar,
        timeZone: TimeZone
    ) -> HijriYearMonth? {
        guard let components = calendar.adjustedComponents(for: now, timeZone: timeZone) else {
            return nil
        }

        switch mode {
        case .live:
            return HijriYearMonth(hijriYear: components.hijriYear, month: targetMonth)
        case .preview:
            let currentKey = HijriYearMonth(hijriYear: components.hijriYear, month: components.month)
            if components.month == targetMonth, components.day < liveDayRange.lowerBound {
                return HijriYearMonth(hijriYear: components.hijriYear, month: targetMonth)
            }
            if components.month.rawValue < targetMonth.rawValue {
                return HijriYearMonth(hijriYear: components.hijriYear, month: targetMonth)
            }
            if components.month == targetMonth, liveDayRange.contains(components.day) {
                return HijriYearMonth(hijriYear: components.hijriYear, month: targetMonth)
            }
            return currentKey.advanced(byMonths: monthsUntilNext(targetMonth: targetMonth, from: currentKey.month))
        }
    }

    private static func monthsUntilNext(targetMonth: HijriMonth, from currentMonth: HijriMonth) -> Int {
        let delta = targetMonth.rawValue - currentMonth.rawValue
        return delta > 0 ? delta : delta + 12
    }

    private static func mergedSeeds(
        scheduledEntries: [ResolvedScheduledDateEntry],
        logEntries: [String: FastLogEntry],
        targetMonthKey: HijriYearMonth,
        trackedDays: ClosedRange<Int>,
        calendar: AdjustedHijriCalendar,
        timeZone: TimeZone
    ) -> [ActiveTagComputationSeed] {
        var seedsByKey: [String: ActiveTagComputationSeed] = [:]

        for entry in scheduledEntries {
            seedsByKey[entry.dateKey] = ActiveTagComputationSeed(
                date: entry.date,
                dateKey: entry.dateKey,
                defaultPrimaryIntent: entry.provenances.defaultFastPrimaryIntent()
            )
        }

        for entry in logEntries.values {
            guard let date = DateHelpers.date(fromDayIdentifier: entry.dateKey, timeZone: timeZone),
                  let components = calendar.adjustedComponents(for: date, timeZone: timeZone),
                  components.hijriYear == targetMonthKey.hijriYear,
                  components.month == targetMonthKey.month,
                  trackedDays.contains(components.day) else {
                continue
            }

            let existing = seedsByKey[entry.dateKey]
            seedsByKey[entry.dateKey] = ActiveTagComputationSeed(
                date: existing?.date ?? date,
                dateKey: entry.dateKey,
                defaultPrimaryIntent: entry.intentSnapshot?.primaryIntent ?? existing?.defaultPrimaryIntent
            )
        }

        return Array(seedsByKey.values)
    }
}
