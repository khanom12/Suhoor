import Foundation

enum CountdownSessionStatus: String, Codable {
    case running
    case ended
    case stoppedByUser
}

struct CountdownSession: Codable, Equatable {
    let sessionId: UUID
    let fajrDateTime: Date
    let startedAt: Date
    var status: CountdownSessionStatus
    var isUserStopped: Bool
    var associatedTestRunId: UUID?

    init(
        sessionId: UUID = UUID(),
        fajrDateTime: Date,
        startedAt: Date = Date(),
        status: CountdownSessionStatus = .running,
        isUserStopped: Bool = false,
        associatedTestRunId: UUID? = nil
    ) {
        self.sessionId = sessionId
        self.fajrDateTime = fajrDateTime
        self.startedAt = startedAt
        self.status = status
        self.isUserStopped = isUserStopped
        self.associatedTestRunId = associatedTestRunId
    }
}

final class CountdownSessionStore {
    private let sessionKey = "suhoor.countdown.session"
    private let activityIdKey = "suhoor.countdown.activityId"

    func loadSession() -> CountdownSession? {
        guard let data = UserDefaults.standard.data(forKey: sessionKey) else { return nil }
        return try? JSONDecoder().decode(CountdownSession.self, from: data)
    }

    func saveSession(_ session: CountdownSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: sessionKey)
    }

    func clearSession() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    func loadActivityId() -> String? {
        UserDefaults.standard.string(forKey: activityIdKey)
    }

    func saveActivityId(_ id: String?) {
        if let id {
            UserDefaults.standard.set(id, forKey: activityIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activityIdKey)
        }
    }
}
