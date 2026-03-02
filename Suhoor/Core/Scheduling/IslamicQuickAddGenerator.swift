import Foundation

struct IslamicQuickAddGenerator {
    private let adjustedHijriCalendar: AdjustedHijriCalendar
    private let scanLimitDays = 730

    init(adjustedHijriCalendar: AdjustedHijriCalendar = .shared) {
        self.adjustedHijriCalendar = adjustedHijriCalendar
    }

    func preview(
        for kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> IslamicQuickAddPreview? {
        let dates = dates(for: kind, startDate: startDate, timeZone: timeZone)
        guard !dates.isEmpty else { return nil }
        return IslamicQuickAddPreview(
            kind: kind,
            dates: dates,
            previewText: previewText(for: dates, timeZone: timeZone),
            availabilityText: availabilityText(for: dates, timeZone: timeZone)
        )
    }

    func dates(
        for kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> [Date] {
        let start = DateHelpers.startOfDay(startDate, in: timeZone)
        switch kind {
        case .nextAshura:
            return nextMatchingDates(start: start, timeZone: timeZone) { components in
                components.month == .muharram && components.day == 10
            }
        case .nextArafah:
            return nextMatchingDates(start: start, timeZone: timeZone) { components in
                components.month == .dhulHijjah && components.day == 9
            }
        case .nextEidAlFitr:
            return nextMatchingDates(start: start, timeZone: timeZone) { components in
                components.month == .shawwal && components.day == 1
            }
        case .nextEidAlAdha:
            return nextMatchingDates(start: start, timeZone: timeZone) { components in
                components.month == .dhulHijjah && components.day == 10
            }
        case .nextWhiteDays:
            return nextWhiteDays(start: start, timeZone: timeZone)
        case .nextRamadanMonth:
            return nextRamadanMonth(start: start, timeZone: timeZone)
        case .nextMondayThursdayPair:
            return nextMondayThursdayPair(start: start, timeZone: timeZone)
        }
    }

    private func nextMatchingDates(
        start: Date,
        timeZone: TimeZone,
        matcher: (AdjustedHijriDateComponents) -> Bool
    ) -> [Date] {
        guard let date = firstMatchingDate(start: start, timeZone: timeZone, matcher: matcher) else { return [] }
        return [date]
    }

    private func nextWhiteDays(start: Date, timeZone: TimeZone) -> [Date] {
        guard let day13 = firstMatchingDate(start: start, timeZone: timeZone, matcher: { $0.day == 13 }) else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let day14 = calendar.date(byAdding: .day, value: 1, to: day13) ?? day13
        let day15 = calendar.date(byAdding: .day, value: 2, to: day13) ?? day13
        return [day13, day14, day15]
    }

    private func nextRamadanMonth(start: Date, timeZone: TimeZone) -> [Date] {
        guard let firstDay = firstMatchingDate(start: start, timeZone: timeZone, matcher: {
            $0.month == .ramadan && $0.day == 1
        }) else {
            return []
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var dates: [Date] = []
        var current = firstDay
        while dates.count < 30,
              let components = adjustedHijriCalendar.adjustedComponents(for: current, timeZone: timeZone),
              components.month == .ramadan {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return dates
    }

    private func nextMondayThursdayPair(start: Date, timeZone: TimeZone) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startDay = calendar.startOfDay(for: start)
        var monday: Date?
        var thursday: Date?

        for offset in 0..<14 {
            let date = calendar.date(byAdding: .day, value: offset, to: startDay) ?? startDay
            let weekday = calendar.component(.weekday, from: date)
            if monday == nil, weekday == 2 {
                monday = date
            }
            if thursday == nil, weekday == 5 {
                thursday = date
            }
            if monday != nil, thursday != nil {
                break
            }
        }

        return [monday, thursday].compactMap { $0 }.sorted()
    }

    private func firstMatchingDate(
        start: Date,
        timeZone: TimeZone,
        matcher: (AdjustedHijriDateComponents) -> Bool
    ) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let normalizedStart = calendar.startOfDay(for: start)
        for offset in 0..<scanLimitDays {
            let candidate = calendar.date(byAdding: .day, value: offset, to: normalizedStart) ?? normalizedStart
            guard let components = adjustedHijriCalendar.adjustedComponents(for: candidate, timeZone: timeZone) else { continue }
            if matcher(components) {
                return candidate
            }
        }
        return nil
    }

    private func previewText(for dates: [Date], timeZone: TimeZone) -> String {
        dates.map { GregorianDateFormatter.shared.headerString(for: $0) }
            .joined(separator: " • ")
    }

    private func availabilityText(for dates: [Date], timeZone: TimeZone) -> String {
        dates.compactMap { date in
            adjustedHijriCalendar.formattedHijriString(for: date, timeZone: timeZone)
        }
        .joined(separator: " • ")
    }
}
