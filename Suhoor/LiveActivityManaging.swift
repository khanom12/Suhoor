import Foundation

protocol LiveActivityManaging {
    func start(session: CountdownSession) async -> String?
    func update(session: CountdownSession, activityId: String) async
    func end(activityId: String) async
    func cleanupOrphans(activeActivityId: String?) async -> Int
}
