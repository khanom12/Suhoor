import Foundation

struct ShawwalSixProgressEngine {
    struct Model: Equatable, Sendable {
        struct TaggedDay: Equatable, Sendable {
            let date: Date
            let dateKey: String
        }

        let hijriYear: Int
        let completedCount: Int
        let hasPendingToday: Bool
        let taggedDays: [TaggedDay]

        var pendingCount: Int { hasPendingToday ? 1 : 0 }
        var displayFilledCount: Int { min(6, completedCount + pendingCount) }
        var remainingCount: Int { max(0, 6 - completedCount) }
        var isComplete: Bool { completedCount >= 6 }
        var hasTrackedDays: Bool { taggedDays.isEmpty == false }
    }

    static func model(
        now: Date,
        mode: TodaySeasonalCardMode,
        scheduledEntries: [ResolvedScheduledDateEntry],
        selections: [String: FastIntentSelection],
        logEntries: [String: FastLogEntry],
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> Model? {
        guard let context = ShawwalMonthContext.resolve(now: now, mode: mode, calendar: calendar, timeZone: timeZone) else {
            return nil
        }

        let seeds = mergedSeeds(
            scheduledEntries: scheduledEntries,
            logEntries: logEntries,
            hijriYear: context.hijriYear,
            calendar: calendar,
            timeZone: timeZone
        )
        let computed = TagComputationEngine.results(
            seeds: seeds.sorted(by: { $0.date < $1.date }),
            selections: selections,
            ruleset: .strict,
            timeZone: timeZone
        )

        let datesByKey = Dictionary(uniqueKeysWithValues: seeds.map { ($0.dateKey, $0.date) })
        let taggedDays = computed
            .filter { $0.value.computedSecondaryTags.contains(.shawwalSix) }
            .compactMap { key, _ in
                datesByKey[key].map { Model.TaggedDay(date: $0, dateKey: key) }
            }
            .sorted(by: { $0.date < $1.date })

        let todayKey = DateHelpers.dayIdentifier(for: context.todayStart, timeZone: timeZone)
        let completedCount = taggedDays.reduce(into: 0) { count, day in
            if logEntries[day.dateKey]?.status == .completed {
                count += 1
            }
        }
        let hasPendingToday = mode == .live
            && taggedDays.contains(where: { $0.dateKey == todayKey })
            && logEntries[todayKey]?.status == .inProgress

        return Model(
            hijriYear: context.hijriYear,
            completedCount: completedCount,
            hasPendingToday: hasPendingToday,
            taggedDays: taggedDays
        )
    }

    static func monthDates(
        now: Date,
        mode: TodaySeasonalCardMode,
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> [Date] {
        guard let context = ShawwalMonthContext.resolve(now: now, mode: mode, calendar: calendar, timeZone: timeZone) else {
            return []
        }

        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone

        var dates: [Date] = []
        let startDay = gregorian.date(byAdding: .day, value: 1, to: context.monthStart) ?? context.monthStart
        var cursor = mode == .live ? max(startDay, context.todayStart) : startDay

        while cursor < context.nextMonthStart {
            dates.append(cursor)
            guard let next = gregorian.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return dates
    }

    private static func mergedSeeds(
        scheduledEntries: [ResolvedScheduledDateEntry],
        logEntries: [String: FastLogEntry],
        hijriYear: Int,
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
                  components.month == .shawwal,
                  components.hijriYear == hijriYear,
                  components.day >= 2 else {
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

struct ForbiddenFastDayEngine {
    struct Model: Equatable, Sendable {
        let title: String
        let badgeText: String
        let message: String
        let isLive: Bool
    }

    static func model(
        kind: FastWarning,
        mode: TodaySeasonalCardMode,
        now: Date,
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> Model? {
        let components = calendar.adjustedComponents(for: now, timeZone: timeZone)
        let isLive: Bool

        switch kind {
        case .eidAlFitr:
            isLive = components?.month == .shawwal && components?.day == 1
        case .eidAlAdha:
            isLive = components?.month == .dhulHijjah && components?.day == 10
        case .tashreeq:
            isLive = components?.month == .dhulHijjah && (11...13).contains(components?.day ?? 0)
        }

        guard isLive || mode == .reference else { return nil }

        switch kind {
        case .eidAlFitr:
            return Model(
                title: "Eid al-Fitr",
                badgeText: "Do Not Fast",
                message: isLive ? "It is not allowed to fast today." : "It is not allowed to fast on this day.",
                isLive: isLive
            )
        case .eidAlAdha:
            return Model(
                title: "Eid al-Adha",
                badgeText: "Do Not Fast",
                message: isLive ? "It is not allowed to fast today." : "It is not allowed to fast on this day.",
                isLive: isLive
            )
        case .tashreeq:
            return Model(
                title: "Days of Tashreeq",
                badgeText: "Do Not Fast",
                message: isLive ? "It is not allowed to fast today." : "It is not allowed to fast on this day.",
                isLive: isLive
            )
        }
    }
}

private struct ShawwalMonthContext {
    let hijriYear: Int
    let todayStart: Date
    let monthStart: Date
    let nextMonthStart: Date

    static func resolve(
        now: Date,
        mode: TodaySeasonalCardMode,
        calendar: AdjustedHijriCalendar,
        timeZone: TimeZone
    ) -> ShawwalMonthContext? {
        guard let components = calendar.adjustedComponents(for: now, timeZone: timeZone) else {
            return nil
        }

        let monthKey: HijriYearMonth
        switch mode {
        case .live:
            guard components.month == .shawwal, components.day >= 2 else {
                return nil
            }
            monthKey = HijriYearMonth(hijriYear: components.hijriYear, month: .shawwal)
        case .reference:
            let referenceYear = components.month.rawValue <= HijriMonth.shawwal.rawValue
                ? components.hijriYear
                : components.hijriYear + 1
            monthKey = HijriYearMonth(hijriYear: referenceYear, month: .shawwal)
        }

        let monthStart = calendar.gregorianDate(for: monthKey, dayOfMonth: 1, timeZone: timeZone) ?? now
        let nextMonthKey = monthKey.advanced(byMonths: 1)
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        let nextMonthStart = nextMonthKey.flatMap {
            calendar.gregorianDate(for: $0, dayOfMonth: 1, timeZone: timeZone)
        } ?? gregorian.date(byAdding: .day, value: 30, to: monthStart) ?? monthStart

        return ShawwalMonthContext(
            hijriYear: monthKey.hijriYear,
            todayStart: DateHelpers.startOfDay(now, in: timeZone),
            monthStart: DateHelpers.startOfDay(monthStart, in: timeZone),
            nextMonthStart: DateHelpers.startOfDay(nextMonthStart, in: timeZone)
        )
    }
}
