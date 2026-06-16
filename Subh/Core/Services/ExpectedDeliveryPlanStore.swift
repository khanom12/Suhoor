import Foundation

struct ExpectedDeliveryRecord: Codable, Equatable, Sendable {
    let dateKey: String
    let eventID: String
    let eventType: ScheduledEventType
    let deliveryKind: ScheduleEventKind
    let fireDate: Date
    let channel: AlarmDeliveryChannel
    let notificationIdentifier: String
    let alarmIdentifier: UUID
    let wakeSessionID: String?
    let generatedAt: Date

    init(
        delivery: ExpectedAlarmDelivery,
        wakeSessionID: String?,
        generatedAt: Date
    ) {
        self.dateKey = delivery.dateKey
        self.eventID = delivery.eventID
        self.eventType = delivery.eventType
        self.deliveryKind = delivery.deliveryKind
        self.fireDate = delivery.fireDate
        self.channel = delivery.channel
        self.notificationIdentifier = delivery.notificationIdentifier
        self.alarmIdentifier = delivery.alarmIdentifier
        self.wakeSessionID = wakeSessionID
        self.generatedAt = generatedAt
    }

    var expectedDelivery: ExpectedAlarmDelivery {
        ExpectedAlarmDelivery(
            dateKey: dateKey,
            eventID: eventID,
            eventType: eventType,
            deliveryKind: deliveryKind,
            fireDate: fireDate,
            channel: channel,
            notificationIdentifier: notificationIdentifier,
            alarmIdentifier: alarmIdentifier
        )
    }
}

final class ExpectedDeliveryPlanStore {
    private let storageKey = "Subh.ExpectedDeliveryPlan"
    private let maxRecords = 240
    private let defaults: UserDefaults
    private let lock = NSLock()
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.expected-delivery-plan",
        delay: 0.2
    )
    private var cachedRecords: [ExpectedDeliveryRecord]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.cachedRecords = Self.loadRecords(from: defaults, key: storageKey)
    }

    func records() -> [ExpectedDeliveryRecord] {
        lock.lock()
        let snapshot = cachedRecords
        lock.unlock()
        return snapshot
    }

    func records(for dateKey: String) -> [ExpectedDeliveryRecord] {
        records().filter { $0.dateKey == dateKey }
    }

    func replace(with records: [ExpectedDeliveryRecord]) {
        lock.lock()
        cachedRecords = Array(records.sorted { $0.fireDate < $1.fireDate }.prefix(maxRecords))
        let snapshot = cachedRecords
        lock.unlock()
        persist(snapshot)
    }

    func clear() {
        persistence.cancelPending()
        lock.lock()
        cachedRecords.removeAll()
        lock.unlock()
        defaults.removeObject(forKey: storageKey)
    }

    private func persist(_ records: [ExpectedDeliveryRecord]) {
        persistence.schedule { [defaults, storageKey] in
            guard let data = try? JSONEncoder().encode(records) else { return }
            defaults.set(data, forKey: storageKey)
        }
    }

    private static func loadRecords(from defaults: UserDefaults, key: String) -> [ExpectedDeliveryRecord] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([ExpectedDeliveryRecord].self, from: data)) ?? []
    }
}

