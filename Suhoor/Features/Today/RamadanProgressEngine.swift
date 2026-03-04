import Foundation

struct RamadanProgressEngine {
    struct Model: Equatable, Sendable {
        let hijriYear: Int
        let dayNumber: Int
        let totalDays: Int
        let daysUntilEid: Int
        let progress: Double
        let eidDateText: String?
    }

    static func model(
        now: Date,
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> Model? {
        guard calendar.isRamadan(date: now, timeZone: timeZone) else { return nil }
        guard let components = calendar.adjustedComponents(for: now, timeZone: timeZone), components.month == .ramadan else { return nil }

        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        let todayStart = gregorian.startOfDay(for: now)

        let year = components.hijriYear
        let ramadanKey = HijriYearMonth(hijriYear: year, month: .ramadan)
        let shawwalKey = HijriYearMonth(hijriYear: year, month: .shawwal)
        let ramadanStart = calendar.gregorianDate(for: ramadanKey, dayOfMonth: 1, timeZone: timeZone)
        let shawwalStart = calendar.gregorianDate(for: shawwalKey, dayOfMonth: 1, timeZone: timeZone)

        let totalDays: Int
        if let ramadanStart, let shawwalStart {
            let diff = gregorian.dateComponents([.day], from: gregorian.startOfDay(for: ramadanStart), to: gregorian.startOfDay(for: shawwalStart)).day
            totalDays = max(1, diff ?? 30)
        } else {
            totalDays = 30
        }

        let dayNumber = max(1, min(totalDays, components.day))
        let progress = Double(dayNumber) / Double(totalDays)

        let daysUntilEid: Int
        if let shawwalStart {
            let diff = gregorian.dateComponents([.day], from: todayStart, to: gregorian.startOfDay(for: shawwalStart)).day
            daysUntilEid = max(0, diff ?? 0)
        } else {
            daysUntilEid = 0
        }

        let eidDateText = shawwalStart.map { TimeFormatters.shortDate.string(from: $0) }

        return Model(
            hijriYear: year,
            dayNumber: dayNumber,
            totalDays: totalDays,
            daysUntilEid: daysUntilEid,
            progress: progress,
            eidDateText: eidDateText
        )
    }
}
