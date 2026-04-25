import Foundation
import ActivityKit
import os

struct CountdownActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var fajrDateTime: Date
        var status: CountdownSessionStatus
    }

    var sessionId: String
}

@MainActor
final class CountdownLiveActivityManager: LiveActivityManaging {
    func start(session: CountdownSession) async -> String? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }
        let attributes = CountdownActivityAttributes(sessionId: session.sessionId.uuidString)
        let state = CountdownActivityAttributes.ContentState(
            fajrDateTime: session.fajrDateTime,
            status: session.status
        )
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: state,
                pushType: nil
            )
            return activity.id
        } catch {
            Logging.diagnostics.error("Countdown Live Activity start failed: \(error.localizedDescription)")
            return nil
        }
    }

    func update(session: CountdownSession, activityId: String) async {
        let state = CountdownActivityAttributes.ContentState(
            fajrDateTime: session.fajrDateTime,
            status: session.status
        )
        guard let activity = Activity<CountdownActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
            return
        }
        await activity.update(ActivityContent(state: state, staleDate: session.fajrDateTime))
    }

    func end(activityId: String) async {
        guard let activity = Activity<CountdownActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
            return
        }
        let state = activity.content.state
        await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
    }

    func cleanupOrphans(activeActivityId: String?) async -> Int {
        let activities = Activity<CountdownActivityAttributes>.activities
        var ended = 0
        for activity in activities where activity.id != activeActivityId {
            let state = activity.content.state
            await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
            ended += 1
        }
        return ended
    }
}

@MainActor
final class NoopLiveActivityManager: LiveActivityManaging {
    func start(session: CountdownSession) async -> String? { nil }
    func update(session: CountdownSession, activityId: String) async {}
    func end(activityId: String) async {}
    func cleanupOrphans(activeActivityId: String?) async -> Int { 0 }
}
