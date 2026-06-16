import Foundation

enum AlarmDeliveryLedgerAction: String, Codable, Sendable {
    case scheduleDecision
    case cancelDecision
    case reconciliation
    case repairDecision
}

struct AlarmDeliveryLedgerEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let action: AlarmDeliveryLedgerAction
    let dateKey: String?
    let eventID: String?
    let eventType: String?
    let deliveryKind: String?
    let fireDate: Date?
    let channel: String
    let platformIdentifier: String?
    let permissionMode: String
    let wakeRuleSignature: String
    let refreshReason: String
    let result: String
    let message: String?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        action: AlarmDeliveryLedgerAction,
        dateKey: String?,
        eventID: String?,
        eventType: String?,
        deliveryKind: String?,
        fireDate: Date?,
        channel: String,
        platformIdentifier: String?,
        permissionMode: String,
        wakeRuleSignature: String,
        refreshReason: String,
        result: String,
        message: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.dateKey = dateKey
        self.eventID = eventID
        self.eventType = eventType
        self.deliveryKind = deliveryKind
        self.fireDate = fireDate
        self.channel = channel
        self.platformIdentifier = platformIdentifier
        self.permissionMode = permissionMode
        self.wakeRuleSignature = wakeRuleSignature
        self.refreshReason = refreshReason
        self.result = result
        self.message = message
    }
}

final class AlarmDeliveryLedgerStore {
    static let shared = AlarmDeliveryLedgerStore()

    private let storageKey = "Subh.AlarmDeliveryLedger"
    private let maxEntries = 300
    private let defaults: UserDefaults
    private let lock = NSLock()
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.alarm-delivery-ledger",
        delay: 0.5
    )
    private var cachedEntries: [AlarmDeliveryLedgerEntry]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.cachedEntries = Self.loadEntries(from: defaults, key: storageKey)
    }

    func record(_ entry: AlarmDeliveryLedgerEntry) {
        record([entry])
    }

    func record(_ entries: [AlarmDeliveryLedgerEntry]) {
        guard !entries.isEmpty else { return }
        lock.lock()
        cachedEntries.append(contentsOf: entries)
        if cachedEntries.count > maxEntries {
            cachedEntries = Array(cachedEntries.suffix(maxEntries))
        }
        let snapshot = cachedEntries
        lock.unlock()
        schedulePersist(snapshot)
    }

    func entries(limit: Int? = nil) -> [AlarmDeliveryLedgerEntry] {
        lock.lock()
        let snapshot = cachedEntries.reversed()
        lock.unlock()
        let entries = Array(snapshot)
        guard let limit else { return entries }
        return Array(entries.prefix(max(0, limit)))
    }

    func diagnosticsText(limit: Int = 8) -> String {
        let entries = entries(limit: limit)
        guard !entries.isEmpty else {
            return "Alarm delivery ledger: no entries"
        }

        let formatter = ISO8601DateFormatter()
        let lines = entries.map { entry in
            [
                formatter.string(from: entry.timestamp),
                entry.action.rawValue,
                entry.result,
                entry.dateKey ?? "--",
                entry.eventID ?? "--",
                entry.deliveryKind ?? "--",
                entry.channel
            ].joined(separator: " | ")
        }
        return (["Alarm delivery ledger (latest \(entries.count)):"] + lines).joined(separator: "\n")
    }

    func clear() {
        persistence.cancelPending()
        lock.lock()
        cachedEntries.removeAll()
        lock.unlock()
        defaults.removeObject(forKey: storageKey)
    }

    private func schedulePersist(_ entries: [AlarmDeliveryLedgerEntry]) {
        persistence.schedule { [defaults, storageKey] in
            guard let data = try? JSONEncoder().encode(entries) else { return }
            defaults.set(data, forKey: storageKey)
        }
    }

    private static func loadEntries(
        from defaults: UserDefaults,
        key: String
    ) -> [AlarmDeliveryLedgerEntry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([AlarmDeliveryLedgerEntry].self, from: data)) ?? []
    }
}
