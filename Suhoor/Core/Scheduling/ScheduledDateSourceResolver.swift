import Foundation

struct ScheduledDateSourceResolver {
    private let sourceStore: ScheduledDateSourceStore
    private let suppressedDateStore: SuppressedScheduledDateStore
    private let adjustedHijriCalendar: AdjustedHijriCalendar
    private let islamicQuickAddGenerator: IslamicQuickAddGenerator

    init(
        sourceStore: ScheduledDateSourceStore,
        suppressedDateStore: SuppressedScheduledDateStore,
        adjustedHijriCalendar: AdjustedHijriCalendar = .shared
    ) {
        self.sourceStore = sourceStore
        self.suppressedDateStore = suppressedDateStore
        self.adjustedHijriCalendar = adjustedHijriCalendar
        self.islamicQuickAddGenerator = IslamicQuickAddGenerator(adjustedHijriCalendar: adjustedHijriCalendar)
    }

    func resolvedEntries(
        from startDate: Date,
        limit: Int,
        timeZone: TimeZone = .current
    ) -> [ResolvedScheduledDateEntry] {
        guard limit > 0 else { return [] }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedStart = calendar.startOfDay(for: startDate)

        let byKey = resolvedEntriesByKey(
            matchingDates: { source in
                materializedDates(for: source, startDate: normalizedStart, limit: limit, timeZone: timeZone)
            },
            implicitDates: implicitRamadanDates(from: normalizedStart, timeZone: timeZone),
            timeZone: timeZone
        )

        return byKey.values
            .sorted { $0.date < $1.date }
            .prefix(limit)
            .map { value in
                ResolvedScheduledDateEntry(
                    date: value.date,
                    dateKey: DateHelpers.dayIdentifier(for: value.date, timeZone: timeZone),
                    provenances: value.provenances.sorted { $0.label < $1.label }
                )
            }
    }

    func resolvedEntries(
        in interval: DateInterval,
        timeZone: TimeZone = .current
    ) -> [ResolvedScheduledDateEntry] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedStart = calendar.startOfDay(for: interval.start)
        guard interval.duration > 0 else { return [] }

        let byKey = resolvedEntriesByKey(
            matchingDates: { source in
                materializedDates(for: source, in: interval, timeZone: timeZone)
            },
            implicitDates: implicitRamadanDates(in: interval, timeZone: timeZone),
            timeZone: timeZone
        )

        return byKey.values
            .sorted { $0.date < $1.date }
            .filter { $0.date >= normalizedStart }
            .map { value in
                ResolvedScheduledDateEntry(
                    date: value.date,
                    dateKey: DateHelpers.dayIdentifier(for: value.date, timeZone: timeZone),
                    provenances: value.provenances.sorted { $0.label < $1.label }
                )
            }
    }

    func resolvedEntries(
        forHijriMonth key: HijriYearMonth,
        timeZone: TimeZone = .current
    ) -> [ResolvedScheduledDateEntry] {
        guard let interval = dateInterval(forHijriMonth: key, timeZone: timeZone) else { return [] }
        return resolvedEntries(in: interval, timeZone: timeZone)
    }

    func isActive(on date: Date, timeZone: TimeZone = .current) -> Bool {
        return provenance(for: date, timeZone: timeZone).isEmpty == false
    }

    func provenance(for date: Date, timeZone: TimeZone = .current) -> [ResolvedScheduledDateProvenance] {
        let normalized = DateHelpers.startOfDay(date, in: timeZone)
        let key = DateHelpers.dayIdentifier(for: normalized, timeZone: timeZone)
        return provenanceByDate(for: [normalized], timeZone: timeZone)[key] ?? []
    }

    func provenanceByDate(
        for dates: [Date],
        timeZone: TimeZone = .current
    ) -> [String: [ResolvedScheduledDateProvenance]] {
        guard !dates.isEmpty else { return [:] }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedDates = Array(Set(dates.map { calendar.startOfDay(for: $0) })).sorted()
        var results: [String: [ResolvedScheduledDateProvenance]] = Dictionary(
            uniqueKeysWithValues: normalizedDates.map {
                (DateHelpers.dayIdentifier(for: $0, timeZone: timeZone), [])
            }
        )

        for source in sourceStore.sources where source.isEnabled {
            for date in normalizedDates where sourceMatches(source, on: date, timeZone: timeZone) {
                let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
                guard suppressedDateStore.shouldSuppress(
                    dateKey: key,
                    sourceID: source.id,
                    groupID: source.groupID
                ) == false else { continue }
                results[key, default: []].append(
                    ResolvedScheduledDateProvenance(
                        sourceID: source.id,
                        groupID: source.groupID,
                        label: source.origin.label,
                        stopSeriesLabel: source.origin.stopSeriesLabel,
                        isExplicitOneOff: source.origin.isExplicitOneOff,
                        sourceOrigin: source.origin
                    )
                )
            }
        }

        for date in normalizedDates where adjustedHijriCalendar.isRamadan(date: date, timeZone: timeZone) {
            let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
            let ramadanSourceID = DateHelpers.stableUUID(from: "default-ramadan-\(key)")
            let ramadanGroupID = DateHelpers.stableUUID(from: "default-ramadan-group")
            guard suppressedDateStore.shouldSuppress(
                dateKey: key,
                sourceID: ramadanSourceID,
                groupID: ramadanGroupID
            ) == false else { continue }
            results[key, default: []].append(
                ResolvedScheduledDateProvenance(
                    sourceID: ramadanSourceID,
                    groupID: ramadanGroupID,
                    label: ScheduledDateSourceOrigin.defaultRamadan.label,
                    stopSeriesLabel: nil,
                    isExplicitOneOff: false,
                    sourceOrigin: .defaultRamadan
                )
            )
        }

        return results.mapValues { provenances in
            provenances.sorted { $0.label < $1.label }
        }
    }

    private func materializedDates(
        for source: ScheduledDateSource,
        startDate: Date,
        limit: Int,
        timeZone: TimeZone
    ) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedStart = calendar.startOfDay(for: startDate)

        switch source.kind {
        case .singleDay(let singleDay):
            let normalizedDate = calendar.startOfDay(for: singleDay.date)
            guard normalizedDate >= normalizedStart else { return [] }
            return [normalizedDate]
        case .gregorianRange(let range):
            let start = max(calendar.startOfDay(for: range.startDate), normalizedStart)
            let end = calendar.startOfDay(for: range.endDate)
            guard start <= end else { return [] }
            return DateHelpers.dates(from: start, to: end, calendar: calendar)
        case .recurringIslamic(let recurring):
            let lowerBound = max(calendar.startOfDay(for: recurring.startDate), normalizedStart)
            return materializedRecurringDates(for: recurring, startDate: lowerBound, limit: limit, calendar: calendar)
        case .hijriSingleDay(let hijri):
            let key = HijriYearMonth(hijriYear: hijri.hijriYear, month: hijri.month)
            guard let resolved = adjustedHijriCalendar.gregorianDate(for: key, dayOfMonth: hijri.day, timeZone: timeZone) else {
                return []
            }
            let normalizedDate = calendar.startOfDay(for: resolved)
            guard normalizedDate >= normalizedStart else { return [] }
            return [normalizedDate]
        }
    }

    private func materializedDates(
        for source: ScheduledDateSource,
        in interval: DateInterval,
        timeZone: TimeZone
    ) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedStart = calendar.startOfDay(for: interval.start)
        guard let normalizedEnd = inclusiveEndDate(for: interval, calendar: calendar) else { return [] }
        guard normalizedStart <= normalizedEnd else { return [] }

        switch source.kind {
        case .singleDay(let singleDay):
            let normalizedDate = calendar.startOfDay(for: singleDay.date)
            guard normalizedDate >= normalizedStart, normalizedDate <= normalizedEnd else { return [] }
            return [normalizedDate]
        case .gregorianRange(let range):
            let start = max(calendar.startOfDay(for: range.startDate), normalizedStart)
            let end = min(calendar.startOfDay(for: range.endDate), normalizedEnd)
            guard start <= end else { return [] }
            return DateHelpers.dates(from: start, to: end, calendar: calendar)
        case .recurringIslamic(let recurring):
            let lowerBound = max(calendar.startOfDay(for: recurring.startDate), normalizedStart)
            return materializedRecurringDates(
                for: recurring,
                startDate: lowerBound,
                endDate: normalizedEnd,
                limit: Int.max,
                calendar: calendar
            )
        case .hijriSingleDay(let hijri):
            let key = HijriYearMonth(hijriYear: hijri.hijriYear, month: hijri.month)
            guard let resolved = adjustedHijriCalendar.gregorianDate(for: key, dayOfMonth: hijri.day, timeZone: timeZone) else {
                return []
            }
            let normalizedDate = calendar.startOfDay(for: resolved)
            guard normalizedDate >= normalizedStart, normalizedDate <= normalizedEnd else { return [] }
            return [normalizedDate]
        }
    }

    private func materializedRecurringDates(
        for recurring: RecurringIslamicSource,
        startDate: Date,
        limit: Int,
        calendar: Calendar
    ) -> [Date] {
        guard let endDate = recurringEndDate(for: recurring, calendar: calendar) else { return [] }
        return materializedRecurringDates(
            for: recurring,
            startDate: startDate,
            endDate: endDate,
            limit: limit,
            calendar: calendar
        )
    }

    private func materializedRecurringDates(
        for recurring: RecurringIslamicSource,
        startDate: Date,
        endDate: Date,
        limit: Int,
        calendar: Calendar
    ) -> [Date] {
        var results: [Date] = []

        var currentDate = startDate
        while currentDate <= endDate {
            if matchesRecurringRule(recurring.rule, date: currentDate, calendar: calendar) {
                results.append(currentDate)
            }
            if results.count >= limit {
                break
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return results
    }

    private func matchesRecurringRule(
        _ rule: RecurringIslamicRule,
        date: Date,
        calendar: Calendar
    ) -> Bool {
        switch rule {
        case .mondayThursday:
            let weekday = calendar.component(.weekday, from: date)
            return weekday == 2 || weekday == 5
        case .whiteDays:
            guard let components = adjustedHijriCalendar.adjustedComponents(for: date, timeZone: calendar.timeZone) else {
                return false
            }
            return (13...15).contains(components.day)
        case .ramadan:
            return adjustedHijriCalendar.isRamadan(date: date, timeZone: calendar.timeZone)
        }
    }

    private func implicitRamadanDates(from startDate: Date, timeZone: TimeZone) -> [Date] {
        islamicQuickAddGenerator.currentOrNextRamadanMonth(
            startDate: startDate,
            timeZone: timeZone
        )
        .filter { $0 >= startDate }
    }

    private func implicitRamadanDates(
        in interval: DateInterval,
        timeZone: TimeZone
    ) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let inclusiveEnd = inclusiveEndDate(for: interval, calendar: calendar) else { return [] }
        return islamicQuickAddGenerator.currentOrNextRamadanMonth(
            startDate: interval.start,
            timeZone: timeZone
        )
        .filter { date in
            let normalizedDate = calendar.startOfDay(for: date)
            return normalizedDate >= calendar.startOfDay(for: interval.start) && normalizedDate <= inclusiveEnd
        }
    }

    private func sourceMatches(
        _ source: ScheduledDateSource,
        on date: Date,
        timeZone: TimeZone
    ) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedDate = calendar.startOfDay(for: date)

        switch source.kind {
        case .singleDay(let singleDay):
            return singleDay.dateKey == DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
        case .gregorianRange(let range):
            let start = calendar.startOfDay(for: range.startDate)
            let end = calendar.startOfDay(for: range.endDate)
            return normalizedDate >= start && normalizedDate <= end
        case .recurringIslamic(let recurring):
            let lowerBound = calendar.startOfDay(for: recurring.startDate)
            guard normalizedDate >= lowerBound else { return false }
            guard let endDate = recurringEndDate(for: recurring, calendar: calendar) else { return false }
            guard normalizedDate <= endDate else { return false }
            return matchesRecurringRule(recurring.rule, date: normalizedDate, calendar: calendar)
        case .hijriSingleDay(let hijri):
            let key = HijriYearMonth(hijriYear: hijri.hijriYear, month: hijri.month)
            guard let resolved = adjustedHijriCalendar.gregorianDate(for: key, dayOfMonth: hijri.day, timeZone: timeZone) else {
                return false
            }
            let resolvedKey = DateHelpers.dayIdentifier(for: resolved, timeZone: timeZone)
            return resolvedKey == DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
        }
    }

    private func recurringEndDate(
        for recurring: RecurringIslamicSource,
        calendar: Calendar
    ) -> Date? {
        let normalizedStart = calendar.startOfDay(for: recurring.startDate)
        guard let startComponents = adjustedHijriCalendar.adjustedComponents(
            for: normalizedStart,
            timeZone: calendar.timeZone
        ) else {
            return nil
        }

        let startMonth = HijriYearMonth(
            hijriYear: startComponents.hijriYear,
            month: startComponents.month
        )
        guard
            let monthAfterWindow = startMonth.advanced(byMonths: 12),
            let endExclusive = adjustedHijriCalendar.gregorianDate(
                for: monthAfterWindow,
                dayOfMonth: 1,
                timeZone: calendar.timeZone
            ),
            let inclusiveEnd = calendar.date(byAdding: .day, value: -1, to: endExclusive)
        else {
            return nil
        }

        return calendar.startOfDay(for: inclusiveEnd)
    }

    private func resolvedEntriesByKey(
        matchingDates: (ScheduledDateSource) -> [Date],
        implicitDates: [Date],
        timeZone: TimeZone
    ) -> [String: (date: Date, provenances: [ResolvedScheduledDateProvenance])] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var byKey: [String: (date: Date, provenances: [ResolvedScheduledDateProvenance])] = [:]

        for source in sourceStore.sources where source.isEnabled {
            for date in matchingDates(source) {
                let normalizedDate = calendar.startOfDay(for: date)
                let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
                guard suppressedDateStore.shouldSuppress(
                    dateKey: key,
                    sourceID: source.id,
                    groupID: source.groupID
                ) == false else { continue }

                let provenance = ResolvedScheduledDateProvenance(
                    sourceID: source.id,
                    groupID: source.groupID,
                    label: source.origin.label,
                    stopSeriesLabel: source.origin.stopSeriesLabel,
                    isExplicitOneOff: source.origin.isExplicitOneOff,
                    sourceOrigin: source.origin
                )

                if var existing = byKey[key] {
                    existing.provenances.append(provenance)
                    byKey[key] = existing
                } else {
                    byKey[key] = (normalizedDate, [provenance])
                }
            }
        }

        for date in implicitDates {
            let normalizedDate = calendar.startOfDay(for: date)
            let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
            let ramadanSourceID = DateHelpers.stableUUID(from: "default-ramadan-\(key)")
            let ramadanGroupID = DateHelpers.stableUUID(from: "default-ramadan-group")
            guard suppressedDateStore.shouldSuppress(
                dateKey: key,
                sourceID: ramadanSourceID,
                groupID: ramadanGroupID
            ) == false else { continue }

            let provenance = ResolvedScheduledDateProvenance(
                sourceID: ramadanSourceID,
                groupID: ramadanGroupID,
                label: ScheduledDateSourceOrigin.defaultRamadan.label,
                stopSeriesLabel: nil,
                isExplicitOneOff: false,
                sourceOrigin: .defaultRamadan
            )

            if var existing = byKey[key] {
                existing.provenances.append(provenance)
                byKey[key] = existing
            } else {
                byKey[key] = (normalizedDate, [provenance])
            }
        }

        return byKey
    }

    private func inclusiveEndDate(
        for interval: DateInterval,
        calendar: Calendar
    ) -> Date? {
        let normalizedEnd = calendar.startOfDay(for: interval.end)
        if interval.end == normalizedEnd {
            return calendar.date(byAdding: .day, value: -1, to: normalizedEnd)
        }
        return calendar.startOfDay(for: interval.end)
    }

    private func dateInterval(
        forHijriMonth key: HijriYearMonth,
        timeZone: TimeZone
    ) -> DateInterval? {
        guard
            let start = adjustedHijriCalendar.gregorianDate(for: key, dayOfMonth: 1, timeZone: timeZone),
            let nextMonth = key.advanced(byMonths: 1),
            let end = adjustedHijriCalendar.gregorianDate(for: nextMonth, dayOfMonth: 1, timeZone: timeZone)
        else {
            return nil
        }

        return DateInterval(start: start, end: end)
    }
}
