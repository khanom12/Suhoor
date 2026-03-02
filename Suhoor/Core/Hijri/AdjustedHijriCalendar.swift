import Foundation

struct AdjustedHijriDateComponents: Hashable {
    let hijriYear: Int
    let month: HijriMonth
    let day: Int
    let monthTitle: String
    let isDerivedFromBaseline: Bool
}

struct HijriMonthStartPreview: Equatable {
    let key: HijriYearMonth
    let baselineStart: Date
    let adjustedStart: Date
    let offsetDays: Int
    let source: String
}

struct AdjustedHijriCalendar {
    static let shared = AdjustedHijriCalendar()

    let calendarService: HijriCalendarService

    init(calendarService: HijriCalendarService = HijriCalendarService(adjustmentStore: HijriMonthAdjustmentStore())) {
        self.calendarService = calendarService
    }

    func adjustedComponents(for gregorianDate: Date, timeZone: TimeZone = .current) -> AdjustedHijriDateComponents? {
        let normalized = normalizedGregorianDate(for: gregorianDate, timeZone: timeZone)
        if let baseline = baselineBackedComponents(for: normalized, timeZone: timeZone) {
            return baseline
        }
        return fallbackComponents(for: normalized, timeZone: timeZone)
    }

    func formattedHijriString(for gregorianDate: Date, timeZone: TimeZone = .current) -> String {
        let normalized = normalizedGregorianDate(for: gregorianDate, timeZone: timeZone)
        if let adjusted = baselineBackedComponents(for: normalized, timeZone: timeZone) {
            return "\(adjusted.day) \(adjusted.month.displayName) \(adjusted.hijriYear)"
        }

        let primaryText = formattedFallbackString(for: normalized, calendarIdentifier: .islamicUmmAlQura, timeZone: timeZone)
        if !primaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return primaryText
        }
        return formattedFallbackString(for: normalized, calendarIdentifier: .islamicCivil, timeZone: timeZone)
    }

    func monthTitle(for gregorianDate: Date, timeZone: TimeZone = .current) -> String? {
        guard let components = adjustedComponents(for: gregorianDate, timeZone: timeZone) else { return nil }
        return "\(components.monthTitle) \(components.hijriYear)"
    }

    func adjustedMonthKey(for gregorianDate: Date, timeZone: TimeZone = .current) -> HijriMonthKey? {
        guard let components = adjustedComponents(for: gregorianDate, timeZone: timeZone) else { return nil }
        return HijriMonthKey(
            year: components.hijriYear,
            month: components.month.rawValue,
            title: "\(components.monthTitle) \(components.hijriYear)"
        )
    }

    func isRamadan(date: Date, timeZone: TimeZone = .current) -> Bool {
        adjustedComponents(for: date, timeZone: timeZone)?.month == .ramadan
    }

    func isShawwal(date: Date, timeZone: TimeZone = .current) -> Bool {
        adjustedComponents(for: date, timeZone: timeZone)?.month == .shawwal
    }

    func gregorianDate(
        for hijriYearMonth: HijriYearMonth,
        dayOfMonth: Int,
        timeZone: TimeZone = .current
    ) -> Date? {
        let map = calendarService.buildMonthMap(hijriYear: hijriYearMonth.hijriYear, timeZone: timeZone)
        return calendarService.gregorianDate(for: hijriYearMonth, dayOfMonth: dayOfMonth, monthMap: map, timeZone: timeZone)
    }

    func monthStartPreview(
        for key: HijriYearMonth,
        timeZone: TimeZone = .current
    ) -> HijriMonthStartPreview? {
        let map = calendarService.buildMonthMap(hijriYear: key.hijriYear, timeZone: timeZone)
        guard let resolved = map.resolvedStart(for: key.month) else { return nil }
        let source = calendarService
            .baselineProvider(key.hijriYear, timeZone)
            .first(where: { $0.key == key })?
            .source ?? "LocalTable"
        return HijriMonthStartPreview(
            key: key,
            baselineStart: resolved.baselineStart,
            adjustedStart: resolved.resolvedStart,
            offsetDays: resolved.offsetDays,
            source: source
        )
    }

    private func baselineBackedComponents(for gregorianDate: Date, timeZone: TimeZone) -> AdjustedHijriDateComponents? {
        let normalized = normalizedGregorianDate(for: gregorianDate, timeZone: timeZone)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let candidates = HijriBaselineMonthStarts.supportedHijriYears.compactMap { hijriYear -> (Date, AdjustedHijriDateComponents)? in
            let map = calendarService.buildMonthMap(hijriYear: hijriYear, timeZone: timeZone)
            return map.resolvedStarts.values.compactMap { resolved -> (Date, AdjustedHijriDateComponents)? in
                let start = calendar.startOfDay(for: resolved.resolvedStart)
                let dayOffset = calendar.dateComponents([.day], from: start, to: normalized).day ?? Int.max
                guard (0...29).contains(dayOffset) else { return nil }
                return (
                    start,
                    AdjustedHijriDateComponents(
                        hijriYear: resolved.key.hijriYear,
                        month: resolved.key.month,
                        day: dayOffset + 1,
                        monthTitle: resolved.key.month.displayName,
                        isDerivedFromBaseline: true
                    )
                )
            }
            .max(by: { $0.0 < $1.0 })
        }

        return candidates.max(by: { $0.0 < $1.0 })?.1
    }

    private func fallbackComponents(for gregorianDate: Date, timeZone: TimeZone) -> AdjustedHijriDateComponents? {
        var calendar = Calendar(identifier: .islamicCivil)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: gregorianDate)
        guard
            let year = components.year,
            let monthValue = components.month,
            let day = components.day,
            let month = HijriMonth(rawValue: monthValue)
        else {
            return nil
        }

        return AdjustedHijriDateComponents(
            hijriYear: year,
            month: month,
            day: day,
            monthTitle: month.displayName,
            isDerivedFromBaseline: false
        )
    }

    private func normalizedGregorianDate(for gregorianDate: Date, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.startOfDay(for: gregorianDate)
    }

    private func formattedFallbackString(for date: Date, calendarIdentifier: Calendar.Identifier, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.timeZone = timeZone
        formatter.locale = .current
        var calendar = Calendar(identifier: calendarIdentifier)
        calendar.timeZone = timeZone
        formatter.calendar = calendar
        return formatter.string(from: date)
    }
}
