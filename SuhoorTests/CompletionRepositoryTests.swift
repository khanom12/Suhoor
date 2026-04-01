import Foundation
import Testing
@testable import Suhoor

@Suite
struct CompletionRepositoryTests {
    @Test
    @MainActor
    func prayerWritesPersistCanonicalSourceMetadata() {
        let suiteName = "SuhoorTests.CompletionRepository.PrayerSource"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let repository = LegacyCompletionRepository(
            fajrLogStore: FajrLogStore(defaults: defaults),
            fastLogStore: FastLogStore(defaults: defaults),
            qadaBacklogStore: QadaBacklogStore(defaults: defaults)
        )

        let now = Date(timeIntervalSince1970: 100)
        let result = repository.perform(
            .setPrayerStatus(dateKey: "2026-03-03", status: .completed),
            source: .homeCard,
            now: now
        )
        let snapshot = repository.snapshot()
        let record = snapshot.records.first { $0.dateKey == "2026-03-03" && $0.kind == .fajr }

        #expect(result.prayerState.status == .completed)
        #expect(result.source == .homeCard)
        #expect(record?.source == CompletionMutationSource.homeCard.rawValue)
    }

    @Test
    @MainActor
    func completedQadaFastPersistsDurableQadaEffectMetadata() {
        let suiteName = "SuhoorTests.CompletionRepository.QadaEffect"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let qadaBacklogStore = QadaBacklogStore(defaults: defaults)
        qadaBacklogStore.setBaseline(owed: 3, trackingStartDateKey: "2026-03-01")
        let repository = LegacyCompletionRepository(
            fajrLogStore: FajrLogStore(defaults: defaults),
            fastLogStore: FastLogStore(defaults: defaults),
            qadaBacklogStore: qadaBacklogStore
        )

        let result = repository.perform(
            .setFastStatus(
                dateKey: "2026-03-03",
                status: .completed,
                intentSnapshot: FastIntentSnapshot(primaryIntent: .qadaMakeup, secondaryTags: [])
            ),
            source: .historyEdit,
            now: Date(timeIntervalSince1970: 200)
        )
        let snapshot = repository.snapshot()
        let record = snapshot.records.first { $0.dateKey == "2026-03-03" && $0.kind == .fast }

        #expect(result.fastState.status == .completed)
        #expect(result.qadaEffect?.countsTowardQada == true)
        #expect(result.qadaEffect?.remainingAfterEffect == 2)
        #expect(record?.metadata["qadaCountsToward"] == "true")
        #expect(record?.metadata["qadaRemainingAfterEffect"] == "2")
        #expect(snapshot.qadaLedgerSnapshot.remaining == 2)
    }

    @Test
    @MainActor
    func launchNormalizationRunsThroughRepositoryAndPreservesMetadata() {
        let suiteName = "SuhoorTests.CompletionRepository.NormalizeInProgress"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let fastLogStore = FastLogStore(defaults: defaults)
        fastLogStore.setStatus(
            .inProgress,
            for: "2026-03-02",
            intentSnapshot: FastIntentSnapshot(primaryIntent: .qadaMakeup, secondaryTags: []),
            now: Date(timeIntervalSince1970: 10)
        )
        let repository = LegacyCompletionRepository(
            fajrLogStore: FajrLogStore(defaults: defaults),
            fastLogStore: fastLogStore,
            qadaBacklogStore: QadaBacklogStore(defaults: defaults)
        )

        repository.normalizeStaleInProgress(
            todayKey: "2026-03-03",
            now: Date(timeIntervalSince1970: 30)
        )

        let entry = fastLogStore.entry(for: "2026-03-02")
        #expect(entry?.status == .completed)
        #expect(entry?.source == CompletionMutationSource.launchNormalization.rawValue)
        #expect(entry?.qadaEffect?.countsTowardQada == true)
    }

    @Test
    @MainActor
    func notificationHandlerUsesCompletionGateway() {
        let suiteName = "SuhoorTests.CompletionRepository.NotificationHandler"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStore = SuhoorSettingsStore(defaults: defaults)
        let alarmConfigStore = AlarmConfigStore(defaultsStore: defaults)
        let fastLogStore = FastLogStore(defaults: defaults)
        let manager = ScheduleManager(
            settingsStore: settingsStore,
            locationService: LocationService(),
            alarmConfigStore: alarmConfigStore,
            fastLogStore: fastLogStore,
            fajrLogStore: FajrLogStore(defaults: defaults),
            qadaBacklogStore: QadaBacklogStore(defaults: defaults),
            qadaBatchStore: QadaBatchStore(defaults: defaults),
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )
        let handler = ScheduleManagerFastCompletionPromptHandler(scheduleManager: manager)

        handler.handleIftarNotificationResponse(
            identifier: "iftar-notification-2026-03-03",
            actionIdentifier: FastCompletionNotificationAction.completed
        )

        let entry = fastLogStore.entry(for: "2026-03-03")
        #expect(entry?.status == .completed)
        #expect(entry?.source == CompletionMutationSource.notificationAction.rawValue)
    }

    @Test
    @MainActor
    func completionEditRefreshesCachedSurfacesWithoutBumpingScheduleRevision() {
        let suiteName = "SuhoorTests.CompletionRepository.SurfaceRefresh"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let manager = makeScheduleManager(defaults: defaults)
        let initialRevision = manager.currentRevision
        let initialSurfaceRevision = manager.completionSurfaceStore.state.revision

        manager.performCompletionEdit(
            .setPrayerStatus(dateKey: "2026-03-03", status: .completed),
            source: .homeCard,
            now: Date(timeIntervalSince1970: 300)
        )

        let state = manager.completionSurfaceStore.state
        let row = state.fajrHistorySnapshot.rows.first(where: { $0.dateKey == "2026-03-03" })

        #expect(manager.currentRevision == initialRevision)
        #expect(state.revision > initialSurfaceRevision)
        #expect(row?.status == .completed)
    }

    @Test
    @MainActor
    func completionEditRefreshesCachedFastProgressImmediately() {
        let suiteName = "SuhoorTests.CompletionRepository.FastSurfaceRefresh"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let manager = makeScheduleManager(defaults: defaults)
        let now = Date()
        let dateKey = DateHelpers.dayIdentifier(for: now, timeZone: .current)

        manager.performCompletionEdit(
            .setFastStatus(
                dateKey: dateKey,
                status: .completed,
                intentSnapshot: FastIntentSnapshot(primaryIntent: .other, secondaryTags: [])
            ),
            source: .homeCard,
            now: now
        )

        let state = manager.completionSurfaceStore.state
        let row = state.fastHistorySnapshot.rows.first(where: { $0.dateKey == dateKey })

        #expect(manager.completionSurfaceStore.fastStatus(for: dateKey) == .completed)
        #expect(row?.status == .completed)
        #expect(state.progressSnapshot.fastTodaySummary == "Completed")
    }

    @MainActor
    private func makeScheduleManager(defaults: UserDefaults) -> ScheduleManager {
        ScheduleManager(
            settingsStore: SuhoorSettingsStore(defaults: defaults),
            locationService: LocationService(),
            alarmConfigStore: AlarmConfigStore(defaultsStore: defaults),
            fastTagStore: FastTagStore(defaults: defaults),
            fastLogStore: FastLogStore(defaults: defaults),
            fajrLogStore: FajrLogStore(defaults: defaults),
            qadaBacklogStore: QadaBacklogStore(defaults: defaults),
            qadaBatchStore: QadaBatchStore(defaults: defaults),
            hijriAdjustmentStore: HijriMonthAdjustmentStore(defaults: defaults),
            hijriAdjustmentChangeStore: HijriAdjustmentChangeStore(defaults: defaults),
            cacheStore: ScheduleCacheStore(defaults: defaults)
        )
    }
}
