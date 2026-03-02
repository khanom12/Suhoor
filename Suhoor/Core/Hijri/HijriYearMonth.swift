import Foundation

struct HijriYearMonth: Hashable, Codable {
    let hijriYear: Int
    let month: HijriMonth

    var persistenceKey: String {
        "\(hijriYear)-\(month.persistenceValue)"
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
