import Foundation

struct AlarmRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: ScheduleEventKind
    let scheduledDate: Date
    let fajrDateTime: Date?
    let dateKey: String?
    let wakeSessionID: String?
    let soundRole: MorningSoundRole?
    let wakeSessionRole: WakeSessionEventRole?
    let fajrStartBehavior: FajrStartBehavior
    let isTest: Bool
    let testRunId: UUID?
    let label: String

    init(
        id: UUID,
        kind: ScheduleEventKind,
        scheduledDate: Date,
        fajrDateTime: Date? = nil,
        dateKey: String? = nil,
        wakeSessionID: String? = nil,
        soundRole: MorningSoundRole? = nil,
        wakeSessionRole: WakeSessionEventRole? = nil,
        fajrStartBehavior: FajrStartBehavior = .none,
        isTest: Bool = false,
        testRunId: UUID? = nil,
        label: String
    ) {
        self.id = id
        self.kind = kind
        self.scheduledDate = scheduledDate
        self.fajrDateTime = fajrDateTime
        self.dateKey = dateKey
        self.wakeSessionID = wakeSessionID
        self.soundRole = soundRole
        self.wakeSessionRole = wakeSessionRole
        self.fajrStartBehavior = fajrStartBehavior
        self.isTest = isTest
        self.testRunId = testRunId
        self.label = label
    }
}

final class AlarmRecordStore {
    private let storageKey = "suhoor.alarmRecordStore"

    func upsert(_ record: AlarmRecord) {
        var records = loadRecords()
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
        store(records: records)
    }

    func record(for id: UUID) -> AlarmRecord? {
        loadRecords().first(where: { $0.id == id })
    }

    func records() -> [AlarmRecord] {
        loadRecords()
    }

    func records(forWakeSessionID wakeSessionID: String) -> [AlarmRecord] {
        loadRecords().filter { $0.wakeSessionID == wakeSessionID }
    }

    func remove(id: UUID) {
        var records = loadRecords()
        records.removeAll { $0.id == id }
        store(records: records)
    }

    func removeTestRun(id: UUID?) {
        guard let id else { return }
        var records = loadRecords()
        records.removeAll { $0.testRunId == id }
        store(records: records)
    }

    func clearAllTests() {
        var records = loadRecords()
        records.removeAll { $0.isTest }
        store(records: records)
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func loadRecords() -> [AlarmRecord] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([AlarmRecord].self, from: data)) ?? []
    }

    private func store(records: [AlarmRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

enum WakeSessionTakeoverResolver {
    static func shouldTakeOverAtFajrStart(
        record: AlarmRecord,
        alarmState: AlarmKnownState
    ) -> Bool {
        guard record.fajrStartBehavior == .takeoverIfUnresolvedOtherwiseCue else { return false }
        switch alarmState {
        case .alerting, .countdown, .paused, .scheduled:
            return true
        case .dismissed, .unknown:
            return false
        }
    }
}
