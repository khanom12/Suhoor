import Foundation

struct HijriMonthMap: Equatable {
    let hijriYear: Int
    let resolvedStarts: [HijriMonth: HijriMonthResolvedStart]

    func resolvedStart(for month: HijriMonth) -> HijriMonthResolvedStart? {
        resolvedStarts[month]
    }
}
