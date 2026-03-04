import Foundation
import Testing
@testable import Suhoor

@Suite
struct TodayCardLayoutStoreTests {
    @Test
    func defaultLayoutIsStable() {
        let suiteName = "SuhoorTests.TodayCardLayout.Default"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = TodayCardLayoutStore(defaults: defaults)
        #expect(store.layout == .default)
        #expect(store.layout.hidden == [.eidAlFitrNotice, .eidAlAdhaNotice, .tashreeqNotice])
        #expect(store.layout.visibleOrderedCards() == [
            .countdown,
            .ramadanProgress,
            .specialFastSpotlight,
            .shawwalSixProgress,
            .shawwalPlan,
            .dhulHijjahNineProgress,
            .ashuraProgress,
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
            .specialFastSpotlight,
            .countdown,
            .shawwalSixProgress,
            .shawwalPlan,
            .dhulHijjahNineProgress,
            .ashuraProgress,
            .whiteDaysProgress,
            .fastCheckIn
        ])
    }
}
