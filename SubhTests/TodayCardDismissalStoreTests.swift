import Foundation
import Testing
@testable import Subh

@Suite
struct TodayCardDismissalStoreTests {
    @Test
    func dismissalIsScopedToTheSameDateKey() {
        let suiteName = "TodayCardDismissalStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TodayCardDismissalStore(defaults: defaults)
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 4))!
        let tomorrow = calendar.date(from: DateComponents(year: 2026, month: 3, day: 5))!

        store.dismiss(.eidAlFitr, on: today, timeZone: timeZone)

        #expect(store.isDismissed(.eidAlFitr, on: today, timeZone: timeZone))
        #expect(store.isDismissed(.eidAlFitr, on: tomorrow, timeZone: timeZone) == false)
    }

    @Test
    func supportCardDismissalIsScopedToTheSameDateKey() {
        let suiteName = "TodayCardDismissalStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = TodayCardDismissalStore(defaults: defaults)
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 4))!
        let tomorrow = calendar.date(from: DateComponents(year: 2026, month: 3, day: 5))!

        store.dismissSupportCard("fajr-2026-03-04", on: today, timeZone: timeZone)

        #expect(store.isSupportCardDismissed("fajr-2026-03-04", on: today, timeZone: timeZone))
        #expect(store.isSupportCardDismissed("fajr-2026-03-04", on: tomorrow, timeZone: timeZone) == false)
    }
}
