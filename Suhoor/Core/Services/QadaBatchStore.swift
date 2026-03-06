import Foundation
import Combine

struct QadaBatchState: Codable, Equatable, Sendable {
    var plannedDateKeys: Set<String>
    var targetCount: Int
    var pace: QadaPlanPace
    var avoidShawwal: Bool
    var avoidImportantSunnah: Bool
    var backlogInputMode: QadaPlanInputMode
    var createdAt: Date?
    var updatedAt: Date?

    static let empty = QadaBatchState(
        plannedDateKeys: [],
        targetCount: 0,
        pace: .steady,
        avoidShawwal: true,
        avoidImportantSunnah: true,
        backlogInputMode: .exact,
        createdAt: nil,
        updatedAt: nil
    )
}

final class QadaBatchStore: ObservableObject {
    @Published private(set) var state: QadaBatchState

    private let defaults: UserDefaults
    private let storageKey = "Suhoor.QadaBatchState"
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.qada-batch-store",
        delay: 0.2
    )

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(QadaBatchState.self, from: data) {
            self.state = decoded
        } else {
            self.state = .empty
        }
    }

    func saveBatch(dateKeys: Set<String>, draft: QadaPlanDraft, now: Date = Date()) {
        var updated = state
        let createdAt = updated.createdAt ?? now
        updated.plannedDateKeys = dateKeys
        updated.targetCount = draft.planBatchCount
        updated.pace = draft.pace
        updated.avoidShawwal = draft.avoidShawwal
        updated.avoidImportantSunnah = draft.avoidImportantSunnah
        updated.backlogInputMode = draft.inputMode
        updated.createdAt = createdAt
        updated.updatedAt = now
        updateState(updated)
    }

    func clearBatch() {
        updateState(.empty)
    }

    private func updateState(_ newState: QadaBatchState) {
        guard newState != state else { return }
        state = newState
        persist()
    }

    private func persist() {
        let snapshot = state
        persistence.schedule { [defaults, storageKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaults.set(data, forKey: storageKey)
        }
    }
}
