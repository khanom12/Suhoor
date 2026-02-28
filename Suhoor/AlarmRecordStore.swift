import Foundation

struct AlarmRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: ScheduleEventKind
    let scheduledDate: Date
    let fajrDateTime: Date?
    let isTest: Bool
    let testRunId: UUID?
    let label: String

    init(
        id: UUID,
        kind: ScheduleEventKind,
        scheduledDate: Date,
        fajrDateTime: Date? = nil,
        isTest: Bool = false,
        testRunId: UUID? = nil,
        label: String
    ) {
        self.id = id
        self.kind = kind
        self.scheduledDate = scheduledDate
        self.fajrDateTime = fajrDateTime
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
