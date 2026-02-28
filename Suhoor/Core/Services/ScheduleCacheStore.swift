import Foundation

final class ScheduleCacheStore {
    private let cacheKey = "Suhoor.ScheduleCache"
    private let defaults: UserDefaults

    struct Cache: Codable {
        var lastScheduledDate: Date?
        var lastUpdated: Date?
        var schedulingMode: SchedulingMode
        var schedules: [DaySchedule]
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Cache {
        if let data = defaults.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode(Cache.self, from: data) {
            return decoded
        }
        return Cache(lastScheduledDate: nil, lastUpdated: nil, schedulingMode: .none, schedules: [])
    }

    func save(_ cache: Cache) {
        if let data = try? JSONEncoder().encode(cache) {
            defaults.set(data, forKey: cacheKey)
        }
    }

    func clear() {
        defaults.removeObject(forKey: cacheKey)
    }
}
