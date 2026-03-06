import Foundation
import Combine

struct QadaBacklogState: Codable, Equatable, Sendable {
    var trackingStartDateKey: String
    var baselineOwed: Int
    var inputMode: QadaPlanInputMode

    enum CodingKeys: String, CodingKey {
        case trackingStartDateKey
        case baselineOwed
        case inputMode
    }

    static func empty(startDateKey: String) -> QadaBacklogState {
        QadaBacklogState(trackingStartDateKey: startDateKey, baselineOwed: 0, inputMode: .exact)
    }

    init(trackingStartDateKey: String, baselineOwed: Int, inputMode: QadaPlanInputMode) {
        self.trackingStartDateKey = trackingStartDateKey
        self.baselineOwed = baselineOwed
        self.inputMode = inputMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackingStartDateKey = try container.decode(String.self, forKey: .trackingStartDateKey)
        baselineOwed = try container.decode(Int.self, forKey: .baselineOwed)
        inputMode = try container.decodeIfPresent(QadaPlanInputMode.self, forKey: .inputMode) ?? .exact
    }
}

final class QadaBacklogStore: ObservableObject {
    @Published private(set) var state: QadaBacklogState

    private let defaults: UserDefaults
    private let storageKey = "Suhoor.QadaBacklogState"
    private let legacyKey = "Suhoor.QadaPlanState"
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.qada-backlog-store",
        delay: 0.2
    )

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(QadaBacklogState.self, from: data) {
            self.state = decoded
        } else if let migrated = QadaBacklogStore.migrateLegacy(defaults: defaults, legacyKey: legacyKey) {
            self.state = migrated
            persist()
        } else {
            let todayKey = DateHelpers.dayIdentifier(for: Date(), timeZone: .current)
            self.state = QadaBacklogState.empty(startDateKey: todayKey)
        }
    }

    func setBaseline(
        owed: Int,
        inputMode: QadaPlanInputMode? = nil,
        trackingStartDateKey: String? = nil
    ) {
        let normalized = max(0, owed)
        var updated = state
        updated.baselineOwed = normalized
        if let inputMode {
            updated.inputMode = inputMode
        }
        if let trackingStartDateKey {
            updated.trackingStartDateKey = trackingStartDateKey
        }
        updateState(updated)
    }

    private func updateState(_ newState: QadaBacklogState) {
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

    private static func migrateLegacy(
        defaults: UserDefaults,
        legacyKey: String
    ) -> QadaBacklogState? {
        guard let data = defaults.data(forKey: legacyKey),
              let legacy = try? JSONDecoder().decode(QadaPlanState.self, from: data) else {
            return nil
        }
        return QadaBacklogState(
            trackingStartDateKey: legacy.trackingStartDateKey,
            baselineOwed: max(0, legacy.recentBaselineRemaining + legacy.olderBaselineRemaining),
            inputMode: .exact
        )
    }
}
