import Foundation
import Testing
@testable import Subh

@Suite
struct HijriMonthAdjustmentStoreTests {
    @Test
    func missingAdjustmentDefaultsToZero() {
        let suiteName = "HijriMonthAdjustmentStoreTests.Defaults"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HijriMonthAdjustmentStore(defaults: defaults)

        #expect(store.readAdjustment(for: HijriYearMonth(hijriYear: 1447, month: .ramadan)) == 0)
    }

    @Test
    func writesClampToSupportedRange() {
        let suiteName = "HijriMonthAdjustmentStoreTests.Clamp"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HijriMonthAdjustmentStore(defaults: defaults)
        let key = HijriYearMonth(hijriYear: 1447, month: .ramadan)

        store.setAdjustment(for: key, offsetDays: 4)
        #expect(store.readAdjustment(for: key) == 1)

        store.setAdjustment(for: key, offsetDays: -4)
        #expect(store.readAdjustment(for: key) == -1)
    }

    @Test
    func resetReturnsAdjustmentToZero() {
        let suiteName = "HijriMonthAdjustmentStoreTests.Reset"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HijriMonthAdjustmentStore(defaults: defaults)
        let key = HijriYearMonth(hijriYear: 1447, month: .shawwal)

        store.setAdjustment(for: key, offsetDays: 1)
        store.resetAdjustment(for: key)

        #expect(store.readAdjustment(for: key) == 0)
    }

    @Test
    func listAdjustmentsRoundTripsStoredValues() {
        let suiteName = "HijriMonthAdjustmentStoreTests.List"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = HijriMonthAdjustmentStore(defaults: defaults)

        store.setAdjustment(for: HijriYearMonth(hijriYear: 1447, month: .muharram), offsetDays: -1)
        store.setAdjustment(for: HijriYearMonth(hijriYear: 1447, month: .ramadan), offsetDays: 1)

        let adjustments = store.listAdjustments(for: 1447)
        #expect(adjustments.count == 2)
        #expect(adjustments.contains { $0.key == HijriYearMonth(hijriYear: 1447, month: .muharram) && $0.offsetDays == -1 })
        #expect(adjustments.contains { $0.key == HijriYearMonth(hijriYear: 1447, month: .ramadan) && $0.offsetDays == 1 })
    }
}
