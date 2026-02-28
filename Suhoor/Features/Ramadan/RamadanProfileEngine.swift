import Foundation

struct RamadanRange: Equatable {
    let startDate: Date
    let endDate: Date
    let dayCount: Int
}

struct RamadanProfileEngine {
    func computeRamadanRange(
        forGregorianYear year: Int,
        startAdjustmentDays: Int,
        endAdjustmentDays: Int,
        timeZone: TimeZone = .current
    ) -> RamadanRange? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        var islamic = Calendar(identifier: .islamicCivil)
        islamic.timeZone = timeZone

        guard let startOfYear = gregorian.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = gregorian.date(from: DateComponents(year: year, month: 12, day: 31)) else {
            return nil
        }

        var current = startOfYear
        var ramadanStart: Date?
        var ramadanEnd: Date?
        var ramadanYear: Int?

        while current <= endOfYear {
            let components = islamic.dateComponents([.year, .month, .day], from: current)
            if components.month == 9 {
                if ramadanStart == nil {
                    ramadanStart = current
                    ramadanYear = components.year
                }
                ramadanEnd = current
            } else if let ramadanStart, let ramadanYear, let yearComponent = components.year, yearComponent == ramadanYear {
                break
            }

            guard let next = gregorian.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        guard let rawStart = ramadanStart, let rawEnd = ramadanEnd else { return nil }
        let adjustedStart = gregorian.date(byAdding: .day, value: startAdjustmentDays, to: rawStart) ?? rawStart
        let adjustedEnd = gregorian.date(byAdding: .day, value: endAdjustmentDays, to: rawEnd) ?? rawEnd

        guard adjustedStart <= adjustedEnd else { return nil }
        let dayCount = (gregorian.dateComponents([.day], from: gregorian.startOfDay(for: adjustedStart), to: gregorian.startOfDay(for: adjustedEnd)).day ?? 0) + 1
        return RamadanRange(startDate: adjustedStart, endDate: adjustedEnd, dayCount: max(0, dayCount))
    }

    func computeRamadanDayNumber(for date: Date, range: RamadanRange, timeZone: TimeZone = .current) -> Int? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        let start = gregorian.startOfDay(for: range.startDate)
        let target = gregorian.startOfDay(for: date)
        guard target >= start, target <= gregorian.startOfDay(for: range.endDate) else { return nil }
        let days = gregorian.dateComponents([.day], from: start, to: target).day ?? 0
        return days + 1
    }
}
