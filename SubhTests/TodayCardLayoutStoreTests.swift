import Foundation
import Testing
@testable import Subh

@Suite
struct TodayCardLayoutStoreTests {
    @Test
    func defaultLayoutIsStable() {
        let suiteName = "SuhoorTests.TodayCardLayout.Default"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = TodayCardLayoutStore(defaults: defaults)
        #expect(store.layout == .default)
        #expect(store.layout.hidden == [
            .shawwalSixProgress,
            .dhulHijjahNineProgress,
            .ashuraProgress,
            .eidAlFitrNotice,
            .eidAlAdhaNotice,
            .tashreeqNotice,
        ])
        #expect(store.layout.visibleOrderedCards() == [
            .countdown,
            .ramadanProgress,
            .eidMubarak,
            .whiteDaysProgress,
            .fastCheckIn
        ])
    }

    @Test
    func hideAndReorderPersistsRoundTrip() {
        let suiteName = "SuhoorTests.TodayCardLayout.RoundTrip"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = TodayCardLayoutStore(defaults: defaults)

        store.setVisible(false, for: .ramadanProgress)
        store.move(fromOffsets: IndexSet(integer: 0), toOffset: 2)
        store.flushPersistenceForTesting()

        let reloaded = TodayCardLayoutStore(defaults: defaults)
        #expect(reloaded.layout.hidden.contains(.ramadanProgress))
        #expect(reloaded.layout.ordered.count == TodayCardKind.allCases.count)
        #expect(reloaded.layout.visibleOrderedCards() == [
            .eidMubarak,
            .countdown,
            .whiteDaysProgress,
            .fastCheckIn
        ])
    }

    @Test
    func persistedUnknownCardsAreIgnoredDuringDecode() {
        let suiteName = "SuhoorTests.TodayCardLayout.LegacyDecode"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let legacyPayload = """
        {
          "ordered": ["countdown", "specialFastSpotlight", "shawwalPlan", "fastCheckIn"],
          "hidden": ["shawwalPlan", "eidAlFitrNotice"]
        }
        """.data(using: .utf8)
        defaults.set(legacyPayload, forKey: "Suhoor.TodayCardLayout")

        let store = TodayCardLayoutStore(defaults: defaults)

        #expect(store.layout.ordered.contains(.countdown))
        #expect(store.layout.ordered.contains(.fastCheckIn))
        #expect(store.layout.ordered.contains(where: { $0.rawValue == "specialFastSpotlight" }) == false)
        #expect(store.layout.hidden.contains(.eidAlFitrNotice))
    }
}
