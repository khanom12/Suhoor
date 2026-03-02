import Foundation

final class ScheduledDateSourceStore {
    private let defaults: UserDefaults
    private let storageKey = "Suhoor.ScheduledDateSources"
    private let migrationKey = "Suhoor.ScheduledDateSourcesMigrationVersion"

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
        let today = DateHelpers.startOfToday(in: timeZone)

        switch legacyDefaults.activationMode {
        case .alwaysOn:
            let end = dateByAddingDays(59, to: today, timeZone: timeZone)
            migrated.append(
                ScheduledDateSource(
                    id: UUID(),
                    kind: .gregorianRange(GregorianRangeSource(startDate: today, endDate: end, timeZone: timeZone)),
                    createdAt: now,
                    isEnabled: true,
                    origin: .migratedLegacyAlways,
                    groupID: nil
                )
            )
        case .dateRange:
            if let start = legacyDefaults.activeStartDate, let end = legacyDefaults.activeEndDate {
                migrated.append(
                    ScheduledDateSource(
                        id: UUID(),
                        kind: .gregorianRange(GregorianRangeSource(startDate: start, endDate: end, timeZone: timeZone)),
                        createdAt: now,
                        isEnabled: true,
                        origin: .migratedLegacyDateRange,
                        groupID: nil
                    )
                )
            }
        }

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
        guard let data = try? JSONEncoder().encode(sources) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func dateByAddingDays(_ value: Int, to date: Date, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(byAdding: .day, value: value, to: date) ?? date
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
        guard let data = try? JSONEncoder().encode(suppressedDateKeys) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
