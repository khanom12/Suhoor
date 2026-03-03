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

        var byKey: [String: (date: Date, provenances: [ResolvedScheduledDateProvenance])] = [:]
        for source in sourceStore.sources where source.isEnabled {
            for date in materializedDates(for: source, startDate: normalizedStart, limit: limit, timeZone: timeZone) {
                let normalizedDate = calendar.startOfDay(for: date)
                let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
                guard !suppressedDateStore.contains(key) else { continue }

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

        for date in implicitRamadanDates(from: normalizedStart, timeZone: timeZone) {
            let normalizedDate = calendar.startOfDay(for: date)
            let key = DateHelpers.dayIdentifier(for: normalizedDate, timeZone: timeZone)
            guard !suppressedDateStore.contains(key) else { continue }

            let provenance = ResolvedScheduledDateProvenance(
                sourceID: DateHelpers.stableUUID(from: "default-ramadan-\(key)"),
                groupID: DateHelpers.stableUUID(from: "default-ramadan-group"),
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

    func isActive(on date: Date, timeZone: TimeZone = .current) -> Bool {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        guard !suppressedDateStore.contains(key) else { return false }
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
                guard suppressedDateStore.contains(key) == false else { continue }
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
            guard suppressedDateStore.contains(key) == false else { continue }
            results[key, default: []].append(
                ResolvedScheduledDateProvenance(
                    sourceID: DateHelpers.stableUUID(from: "default-ramadan-\(key)"),
                    groupID: DateHelpers.stableUUID(from: "default-ramadan-group"),
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
            return materializedRecurringDates(for: recurring.rule, startDate: lowerBound, limit: limit, calendar: calendar)
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

    private func materializedRecurringDates(
        for rule: RecurringIslamicRule,
        startDate: Date,
        limit: Int,
        calendar: Calendar
    ) -> [Date] {
        let scanDays = 730
        var results: [Date] = []

        for offset in 0..<scanDays {
            let date = calendar.date(byAdding: .day, value: offset, to: startDate) ?? startDate
            if matchesRecurringRule(rule, date: date, calendar: calendar) {
                results.append(date)
            }
            if results.count >= limit {
                break
            }
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
}
