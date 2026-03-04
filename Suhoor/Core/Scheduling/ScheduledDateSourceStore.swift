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

enum SuppressionScope: Equatable, Hashable, Sendable {
    case global
    case groupID(UUID)
    case sourceID(UUID)
}

struct SuppressedDateEntry: Codable, Hashable, Sendable {
    let dateKey: String
    var scopedToGroupIDs: Set<UUID>
    var scopedToSourceIDs: Set<UUID>
    var isGlobal: Bool

    init(
        dateKey: String,
        scopedToGroupIDs: Set<UUID> = [],
        scopedToSourceIDs: Set<UUID> = [],
        isGlobal: Bool = false
    ) {
        self.dateKey = dateKey
        self.scopedToGroupIDs = scopedToGroupIDs
        self.scopedToSourceIDs = scopedToSourceIDs
        self.isGlobal = isGlobal
    }

    var isEmpty: Bool {
        !isGlobal && scopedToGroupIDs.isEmpty && scopedToSourceIDs.isEmpty
    }
}

final class SuppressedScheduledDateStore {
    private let defaults: UserDefaults
    private let storageKey = "Suhoor.SuppressedScheduledDateKeys"
    private let migrationKey = "Suhoor.SuppressedScheduledDateMigrationVersion"
    private let currentMigrationVersion = 2
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.suppressed-scheduled-date-keys",
        delay: 0.2
    )

    private(set) var suppressedDateEntries: [String: SuppressedDateEntry]

    init(
        defaults: UserDefaults = .standard,
        legacyDeletedDateKeys: Set<String> = [],
        shouldMigrateLegacyData: Bool = false
    ) {
        self.defaults = defaults
        var needsPersist = false
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: SuppressedDateEntry].self, from: data) {
            self.suppressedDateEntries = decoded
        } else if let data = defaults.data(forKey: storageKey),
                  let decodedLegacy = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.suppressedDateEntries = Dictionary(
                uniqueKeysWithValues: decodedLegacy.map { key in
                    (key, SuppressedDateEntry(dateKey: key, isGlobal: true))
                }
            )
            needsPersist = true
        } else {
            self.suppressedDateEntries = [:]
        }

        if shouldMigrateLegacyData {
            needsPersist = performLegacyMigrationIfNeeded(legacyDeletedDateKeys: legacyDeletedDateKeys) || needsPersist
        }
        if needsPersist {
            persist()
        }
        if defaults.integer(forKey: migrationKey) < currentMigrationVersion {
            defaults.set(currentMigrationVersion, forKey: migrationKey)
        }
    }

    func contains(_ dateKey: String) -> Bool {
        suppressedDateEntries[dateKey] != nil
    }

    func shouldSuppress(dateKey: String, sourceID: UUID?, groupID: UUID?) -> Bool {
        guard let entry = suppressedDateEntries[dateKey] else { return false }
        if entry.isGlobal {
            return true
        }
        if let groupID, entry.scopedToGroupIDs.contains(groupID) {
            return true
        }
        if let sourceID, entry.scopedToSourceIDs.contains(sourceID) {
            return true
        }
        return false
    }

    func insert(_ dateKey: String, scope: SuppressionScope = .global) {
        var entry = suppressedDateEntries[dateKey] ?? SuppressedDateEntry(dateKey: dateKey)
        switch scope {
        case .global:
            entry.isGlobal = true
        case .groupID(let groupID):
            entry.scopedToGroupIDs.insert(groupID)
        case .sourceID(let sourceID):
            entry.scopedToSourceIDs.insert(sourceID)
        }
        suppressedDateEntries[dateKey] = entry
        persist()
    }

    func remove(_ dateKey: String) {
        suppressedDateEntries.removeValue(forKey: dateKey)
        persist()
    }

    func removeScope(_ dateKey: String, scope: SuppressionScope) {
        guard var entry = suppressedDateEntries[dateKey] else { return }
        switch scope {
        case .global:
            entry.isGlobal = false
        case .groupID(let groupID):
            entry.scopedToGroupIDs.remove(groupID)
        case .sourceID(let sourceID):
            entry.scopedToSourceIDs.remove(sourceID)
        }
        if entry.isEmpty {
            suppressedDateEntries.removeValue(forKey: dateKey)
        } else {
            suppressedDateEntries[dateKey] = entry
        }
        persist()
    }

    func clearScopes(for provenance: ResolvedScheduledDateProvenance) {
        guard !suppressedDateEntries.isEmpty else { return }
        let groupID = provenance.groupID
        let sourceID = provenance.sourceID
        var updated: [String: SuppressedDateEntry] = [:]

        for (key, var entry) in suppressedDateEntries {
            if let groupID {
                entry.scopedToGroupIDs.remove(groupID)
            }
            entry.scopedToSourceIDs.remove(sourceID)
            if !entry.isEmpty {
                updated[key] = entry
            }
        }
        suppressedDateEntries = updated
        persist()
    }

    func clearGroupID(_ groupID: UUID) {
        guard !suppressedDateEntries.isEmpty else { return }
        var updated: [String: SuppressedDateEntry] = [:]
        for (key, var entry) in suppressedDateEntries {
            entry.scopedToGroupIDs.remove(groupID)
            if !entry.isEmpty {
                updated[key] = entry
            }
        }
        suppressedDateEntries = updated
        persist()
    }

    func hasAnySuppression(_ dateKey: String) -> Bool {
        suppressedDateEntries[dateKey] != nil
    }

    func moveEntry(from oldKey: String, to newKey: String) {
        guard let entry = suppressedDateEntries.removeValue(forKey: oldKey) else { return }
        let updated = SuppressedDateEntry(
            dateKey: newKey,
            scopedToGroupIDs: entry.scopedToGroupIDs,
            scopedToSourceIDs: entry.scopedToSourceIDs,
            isGlobal: entry.isGlobal
        )
        suppressedDateEntries[newKey] = updated
        persist()
    }

    func reset() {
        persistence.cancelPending()
        suppressedDateEntries = [:]
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: migrationKey)
    }

    private func performLegacyMigrationIfNeeded(legacyDeletedDateKeys: Set<String>) -> Bool {
        let version = defaults.integer(forKey: migrationKey)
        guard version < 1 else { return false }
        for key in legacyDeletedDateKeys {
            suppressedDateEntries[key] = SuppressedDateEntry(dateKey: key, isGlobal: true)
        }
        return !legacyDeletedDateKeys.isEmpty
    }

    private func persist() {
        let snapshot = suppressedDateEntries
        persistence.schedule { [defaults, storageKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaults.set(data, forKey: storageKey)
        }
    }
}
