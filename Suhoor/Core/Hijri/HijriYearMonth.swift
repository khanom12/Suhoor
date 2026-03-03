import Foundation

struct HijriYearMonth: Hashable, Codable {
    let hijriYear: Int
    let month: HijriMonth

    var persistenceKey: String {
        "\(hijriYear)-\(month.persistenceValue)"
    }

    func advanced(byMonths offset: Int) -> HijriYearMonth? {
        guard offset != 0 else { return self }

        let monthIndex = month.rawValue - 1 + offset
        let yearDelta: Int
        let normalizedMonthIndex: Int

        if monthIndex >= 0 {
            yearDelta = monthIndex / 12
            normalizedMonthIndex = monthIndex % 12
        } else {
            yearDelta = Int(floor(Double(monthIndex) / 12.0))
            normalizedMonthIndex = (monthIndex % 12 + 12) % 12
        }

        guard let normalizedMonth = HijriMonth(rawValue: normalizedMonthIndex + 1) else {
            return nil
        }

        return HijriYearMonth(
            hijriYear: hijriYear + yearDelta,
            month: normalizedMonth
        )
    }
}

struct HijriMonthAdjustment: Codable, Equatable {
    let key: HijriYearMonth
    let offsetDays: Int
    let updatedAt: Date
}

struct HijriMonthBaselineStart: Equatable {
    let key: HijriYearMonth
    let gregorianStartDate: Date
    let source: String
    let generatedAt: Date?
}

struct HijriMonthResolvedStart: Equatable {
    let key: HijriYearMonth
    let baselineStart: Date
    let offsetDays: Int
    let resolvedStart: Date
}
