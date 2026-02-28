import Foundation
import Combine

@MainActor
final class CountdownManager: ObservableObject {
    @Published private(set) var currentSession: CountdownSession?

    private let store: CountdownSessionStore
    private let activityManager: LiveActivityManaging
    private let timeProvider: TimeProviding
    private let eventLog: DebugEventLog

    init(
        store: CountdownSessionStore = CountdownSessionStore(),
        activityManager: LiveActivityManaging,
        timeProvider: TimeProviding = SystemTimeProvider(),
        eventLog: DebugEventLog = .shared
    ) {
        self.store = store
        self.activityManager = activityManager
        self.timeProvider = timeProvider
        self.eventLog = eventLog
        self.currentSession = store.loadSession()
    }

    func startCountdown(fajrDateTime: Date, testRunId: UUID? = nil) async {
        var session: CountdownSession
        if let existing = store.loadSession(), existing.fajrDateTime == fajrDateTime, existing.status == .running {
            session = existing
        } else {
            session = CountdownSession(
                fajrDateTime: fajrDateTime,
                startedAt: timeProvider.now(),
                status: .running,
                isUserStopped: false,
                associatedTestRunId: testRunId
            )
            store.saveSession(session)
            eventLog.record(
                .countdownStarted,
                metadata: [
                    "sessionId": session.sessionId.uuidString,
                    "fajrDateTime": fajrDateTime.description,
                    "testRunId": testRunId?.uuidString ?? ""
                ]
            )
        }

        if let activityId = store.loadActivityId() {
            await activityManager.update(session: session, activityId: activityId)
        } else if let activityId = await activityManager.start(session: session) {
            store.saveActivityId(activityId)
        }

        currentSession = session
    }

    func stopCountdownByUser() async {
        guard var session = currentSession else { return }
        session.status = .stoppedByUser
        session.isUserStopped = true
        store.saveSession(session)
        if let activityId = store.loadActivityId() {
            await activityManager.end(activityId: activityId)
            store.saveActivityId(nil)
        }
        currentSession = session
        eventLog.record(
            .countdownStoppedByUser,
            metadata: [
                "sessionId": session.sessionId.uuidString,
                "fajrDateTime": session.fajrDateTime.description
            ]
        )
    }

    func endCountdownIfNeeded(reason: String) async {
        guard var session = currentSession else { return }
        guard session.status == .running else { return }
        session.status = .ended
        session.isUserStopped = false
        store.saveSession(session)
        if let activityId = store.loadActivityId() {
            await activityManager.end(activityId: activityId)
            store.saveActivityId(nil)
        }
        currentSession = session
        eventLog.record(
            .countdownEnded,
            metadata: [
                "sessionId": session.sessionId.uuidString,
                "reason": reason
            ]
        )
    }

    func reconcileIfNeeded() async {
        guard let session = currentSession, session.status == .running else { return }
        if timeProvider.now() >= session.fajrDateTime {
            await endCountdownIfNeeded(reason: "time_reached")
        }
    }

    func cleanupLiveActivities() async -> Int {
        let activeId = store.loadActivityId()
        let ended = await activityManager.cleanupOrphans(activeActivityId: activeId)
        if activeId == nil, let session = currentSession, session.status == .running {
            if let newId = await activityManager.start(session: session) {
                store.saveActivityId(newId)
            }
        }
        eventLog.record(
            .cleanupLiveActivities,
            metadata: ["ended": "\(ended)"]
        )
        return ended
    }
}
