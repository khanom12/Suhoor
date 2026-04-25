import Foundation

final class ScheduleCacheStore {
    private let cacheKey = "Suhoor.ScheduleCache"
    private let defaults: UserDefaults
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.schedule-cache",
        delay: 0.35
    )

    struct Cache: Codable {
        var lastScheduledDate: Date?
        var lastUpdated: Date?
        var schedulingMode: SchedulingMode
        var schedules: [DaySchedule]
        var activeWindowSnapshot: ActiveAlarmWindowSnapshot?
        var tagSelectionRevision: Int?
        var wakeRuleSignature: String?
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Cache {
        if let data = defaults.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode(Cache.self, from: data) {
            return decoded
        }
        return Cache(
            lastScheduledDate: nil,
            lastUpdated: nil,
            schedulingMode: .none,
            schedules: [],
            activeWindowSnapshot: nil,
            tagSelectionRevision: nil,
            wakeRuleSignature: nil
        )
    }

    static func wakeRuleSignature(for defaults: DefaultAlarmConfig) -> String {
        let rule = defaults.defaultWakeRule
        return [
            "state=\(rule.state.rawValue)",
            "anchor=\(rule.anchorType?.rawValue ?? "none")",
            "delta=\(rule.deltaMinutes)",
            "fixed=\(rule.fixedWakeTimeMinutesFromMidnight.map(String.init) ?? "none")",
            "cap=\(rule.latestWakeCapMinutesFromMidnight.map(String.init) ?? "none")",
            "mode=\(defaults.defaultSuhoorTimeMode.rawValue)"
        ].joined(separator: "|")
    }

    func save(_ cache: Cache) {
        persistence.schedule { [defaults, cacheKey] in
            guard let data = try? JSONEncoder().encode(cache) else { return }
            defaults.set(data, forKey: cacheKey)
        }
    }

    func clear() {
        persistence.cancelPending()
        defaults.removeObject(forKey: cacheKey)
    }
}
