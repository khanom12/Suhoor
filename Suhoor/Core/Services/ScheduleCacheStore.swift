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
            tagSelectionRevision: nil
        )
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
