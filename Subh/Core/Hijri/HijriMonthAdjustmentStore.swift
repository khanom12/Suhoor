import Foundation

final class HijriMonthAdjustmentStore {
    private let defaults: UserDefaults
    private let prefix = "Suhoor.HijriAdjustment."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func readAdjustment(for key: HijriYearMonth) -> Int {
        let storageKey = storageKey(for: key)
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(HijriMonthAdjustment.self, from: data) {
            return Self.clamp(decoded.offsetDays)
        }
        let legacyValue = defaults.object(forKey: storageKey) as? Int ?? 0
        return Self.clamp(legacyValue)
    }

    func setAdjustment(for key: HijriYearMonth, offsetDays: Int) {
        let adjustment = HijriMonthAdjustment(
            key: key,
            offsetDays: Self.clamp(offsetDays),
            updatedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(adjustment) else { return }
        defaults.set(data, forKey: storageKey(for: key))
    }

    func resetAdjustment(for key: HijriYearMonth) {
        setAdjustment(for: key, offsetDays: 0)
    }

    func listAdjustments(for hijriYear: Int) -> [HijriMonthAdjustment] {
        HijriMonth.adjustmentMonths.compactMap { month in
            let key = HijriYearMonth(hijriYear: hijriYear, month: month)
            guard let data = defaults.data(forKey: storageKey(for: key)),
                  let decoded = try? JSONDecoder().decode(HijriMonthAdjustment.self, from: data) else {
                return nil
            }
            return HijriMonthAdjustment(
                key: decoded.key,
                offsetDays: Self.clamp(decoded.offsetDays),
                updatedAt: decoded.updatedAt
            )
        }
    }

    func adjustmentsDictionary(for hijriYear: Int) -> [HijriMonth: Int] {
        Dictionary(uniqueKeysWithValues: HijriMonth.adjustmentMonths.map { month in
            let key = HijriYearMonth(hijriYear: hijriYear, month: month)
            return (month, readAdjustment(for: key))
        })
    }

    private func storageKey(for key: HijriYearMonth) -> String {
        prefix + key.persistenceKey
    }

    private static func clamp(_ value: Int) -> Int {
        max(-1, min(1, value))
    }
}
