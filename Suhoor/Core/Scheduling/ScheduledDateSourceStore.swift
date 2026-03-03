import Foundation

final class ScheduledDateSourceStore {
    private let defaults: UserDefaults
    private let storageKey = "Suhoor.ScheduledDateSources"
    private let migrationKey = "Suhoor.ScheduledDateSourcesMigrationVersion"
    private let currentMigrationVersion = 4
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.scheduled-date-sources",
        delay: 0.2
    )

    private(set) var sources: [ScheduledDateSource]

    init(
        defaults: UserDefaults = .standard,
        legacyDefaults: DefaultAlarmConfig? = nil,
        shouldMigrateLegacyData: Bool = false,
        timeZone: TimeZone = .current
    ) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ScheduledDateSource].self, from: data) {
            self.sources = decoded
        } else {
            self.sources = []
        }

        if shouldMigrateLegacyData, let legacyDefaults {
            performLegacyMigrationIfNeeded(legacyDefaults: legacyDefaults, timeZone: timeZone)
        }
        performCleanupMigrationIfNeeded()
    }

    func setSources(_ newSources: [ScheduledDateSource]) {
        sources = newSources.sorted { $0.createdAt < $1.createdAt }
        persist()
    }

    func add(_ source: ScheduledDateSource) {
        sources.append(source)
        sources.sort { $0.createdAt < $1.createdAt }
        persist()
    }

    func remove(id: UUID) {
        sources.removeAll { $0.id == id }
        persist()
    }

    func remove(groupID: UUID) {
        sources.removeAll { $0.groupID == groupID }
        persist()
    }

    func removeAll(matching predicate: (ScheduledDateSource) -> Bool) {
        sources.removeAll(where: predicate)
        persist()
    }

    func reset() {
        persistence.cancelPending()
        sources = []
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: migrationKey)
    }

    private func performLegacyMigrationIfNeeded(legacyDefaults: DefaultAlarmConfig, timeZone: TimeZone) {
        let version = defaults.integer(forKey: migrationKey)
        guard version < 1 else { return }
        guard sources.isEmpty else {
            defaults.set(1, forKey: migrationKey)
            return
        }

        var migrated: [ScheduledDateSource] = []
        let now = Date()

        for key in legacyDefaults.extraOneOffDates.sorted() {
            guard let date = dateFromKey(key, timeZone: timeZone) else { continue }
            migrated.append(
                ScheduledDateSource(
                    id: UUID(),
                    kind: .singleDay(SingleDaySource(dateKey: key, date: date)),
                    createdAt: now,
                    isEnabled: true,
                    origin: .manualSingleDay,
                    groupID: nil
                )
            )
        }

        sources = deduplicatedSources(migrated)
        persist()
        defaults.set(1, forKey: migrationKey)
    }

    private func performCleanupMigrationIfNeeded() {
        let version = defaults.integer(forKey: migrationKey)
        guard version < currentMigrationVersion else { return }

        sources.removeAll { source in
            switch source.origin {
            case .migratedLegacyAlways, .migratedLegacyDateRange:
                return true
            case .islamicQuickAdd(let kind):
                return kind == .nextEidAlFitr
                    || kind == .nextEidAlAdha
                    || kind == .nextRamadanMonth
            case .recurringIslamic(let rule):
                return rule == .ramadan
            default:
                return false
            }
        }

        if version < 4 {
            let adjustmentStore = HijriMonthAdjustmentStore(defaults: defaults)
            let calendar = AdjustedHijriCalendar(
                calendarService: HijriCalendarService(adjustmentStore: adjustmentStore)
            )
            sources = sources.map { source in
                guard case .singleDay(let singleDay) = source.kind else { return source }
                guard case .islamicQuickAdd(let kind) = source.origin, kind.isHijriBased else { return source }
                guard let components = calendar.adjustedComponents(for: singleDay.date, timeZone: .current) else {
                    return source
                }
                let hijriSource = HijriSingleDaySource(
                    hijriYear: components.hijriYear,
                    month: components.month,
                    day: components.day
                )
                return ScheduledDateSource(
                    id: source.id,
                    kind: .hijriSingleDay(hijriSource),
                    createdAt: source.createdAt,
                    isEnabled: source.isEnabled,
                    origin: source.origin,
                    groupID: source.groupID
                )
            }
        }

        persist()
        defaults.set(currentMigrationVersion, forKey: migrationKey)
    }

    private func deduplicatedSources(_ input: [ScheduledDateSource]) -> [ScheduledDateSource] {
        var seenSingleKeys = Set<String>()
        return input.filter { source in
            guard case .singleDay(let single) = source.kind else { return true }
            if seenSingleKeys.contains(single.dateKey) {
                return false
            }
            seenSingleKeys.insert(single.dateKey)
            return true
        }
    }

    private func persist() {
        let snapshot = sources
        persistence.schedule { [defaults, storageKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaults.set(data, forKey: storageKey)
        }
    }

    private func dateFromKey(_ key: String, timeZone: TimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
}

final class SuppressedScheduledDateStore {
    private let defaults: UserDefaults
    private let storageKey = "Suhoor.SuppressedScheduledDateKeys"
    private let migrationKey = "Suhoor.SuppressedScheduledDateMigrationVersion"
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.suppressed-scheduled-date-keys",
        delay: 0.2
    )

    private(set) var suppressedDateKeys: Set<String>

    init(
        defaults: UserDefaults = .standard,
        legacyDeletedDateKeys: Set<String> = [],
        shouldMigrateLegacyData: Bool = false
    ) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.suppressedDateKeys = decoded
        } else {
            self.suppressedDateKeys = []
        }

        if shouldMigrateLegacyData {
            performLegacyMigrationIfNeeded(legacyDeletedDateKeys: legacyDeletedDateKeys)
        }
    }

    func contains(_ dateKey: String) -> Bool {
        suppressedDateKeys.contains(dateKey)
    }

    func insert(_ dateKey: String) {
        suppressedDateKeys.insert(dateKey)
        persist()
    }

    func remove(_ dateKey: String) {
        suppressedDateKeys.remove(dateKey)
        persist()
    }

    func reset() {
        persistence.cancelPending()
        suppressedDateKeys = []
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: migrationKey)
    }

    private func performLegacyMigrationIfNeeded(legacyDeletedDateKeys: Set<String>) {
        let version = defaults.integer(forKey: migrationKey)
        guard version < 1 else { return }
        suppressedDateKeys.formUnion(legacyDeletedDateKeys)
        persist()
        defaults.set(1, forKey: migrationKey)
    }

    private func persist() {
        let snapshot = suppressedDateKeys
        persistence.schedule { [defaults, storageKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaults.set(data, forKey: storageKey)
        }
    }
}
