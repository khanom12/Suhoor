import Foundation
import Testing
@testable import Subh

@Suite
struct FastLogStoreTests {
    @Test
    func setGetClearStatus() {
        let suiteName = "SuhoorTests.FastLog.SetGetClear"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = FastLogStore(defaults: defaults)
        let dateKey = "2026-03-03"

        #expect(store.status(for: dateKey) == .unknown)
        store.setStatus(.completed, for: dateKey, now: Date(timeIntervalSince1970: 1))
        #expect(store.status(for: dateKey) == .completed)

        store.setStatus(.missed, for: dateKey, now: Date(timeIntervalSince1970: 2))
        #expect(store.status(for: dateKey) == .missed)

        store.setStatus(.unknown, for: dateKey, now: Date(timeIntervalSince1970: 3))
        #expect(store.status(for: dateKey) == .unknown)
        #expect(store.entry(for: dateKey) == nil)
    }

    @Test
    func updatedAtOverwritesWhenStatusChanges() {
        let suiteName = "SuhoorTests.FastLog.UpdatedAt"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = FastLogStore(defaults: defaults)
        let dateKey = "2026-03-03"

        let first = Date(timeIntervalSince1970: 10)
        let second = Date(timeIntervalSince1970: 20)
        store.setStatus(.completed, for: dateKey, now: first)
        #expect(store.entry(for: dateKey)?.updatedAt == first)

        store.setStatus(.missed, for: dateKey, now: second)
        #expect(store.entry(for: dateKey)?.updatedAt == second)
    }

    @Test
    func persistenceRoundTrip() {
        let suiteName = "SuhoorTests.FastLog.RoundTrip"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = FastLogStore(defaults: defaults)
        let dateKey = "2026-03-03"
        store.setStatus(.completed, for: dateKey, now: Date(timeIntervalSince1970: 1_000))
        store.flushPersistenceForTesting()

        let reloaded = FastLogStore(defaults: defaults)
        #expect(reloaded.status(for: dateKey) == .completed)
        #expect(reloaded.entry(for: dateKey) != nil)
    }

    @Test
    func inProgressPersistsRoundTrip() {
        let suiteName = "SuhoorTests.FastLog.InProgressRoundTrip"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = FastLogStore(defaults: defaults)
        let dateKey = "2026-03-03"
        store.setStatus(.inProgress, for: dateKey, now: Date(timeIntervalSince1970: 100))
        store.flushPersistenceForTesting()

        let reloaded = FastLogStore(defaults: defaults)
        #expect(reloaded.status(for: dateKey) == .inProgress)
    }

    @Test
    func normalizeStaleInProgressCompletesPriorDays() {
        let suiteName = "SuhoorTests.FastLog.NormalizeInProgress"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = FastLogStore(defaults: defaults)
        store.setStatus(.inProgress, for: "2026-03-02", now: Date(timeIntervalSince1970: 10))
        store.setStatus(.inProgress, for: "2026-03-03", now: Date(timeIntervalSince1970: 20))

        store.normalizeStaleInProgress(todayKey: "2026-03-03", now: Date(timeIntervalSince1970: 30))

        #expect(store.status(for: "2026-03-02") == .completed)
        #expect(store.status(for: "2026-03-03") == .inProgress)
        #expect(store.entry(for: "2026-03-02")?.updatedAt == Date(timeIntervalSince1970: 30))
    }
}
