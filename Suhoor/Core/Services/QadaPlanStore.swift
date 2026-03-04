import Foundation
import Combine

enum QadaBucket: String, Codable, CaseIterable, Identifiable {
    case recent
    case older

    var id: String { rawValue }
}

struct QadaPlanState: Codable, Equatable, Sendable {
    var trackingStartDateKey: String
    var recentBaselineRemaining: Int
    var olderBaselineRemaining: Int
    var plannedRecentDateKeys: Set<String>
    var plannedOlderDateKeys: Set<String>
    var recentGroupID: UUID?
    var olderGroupID: UUID?

    static func empty(startDateKey: String) -> QadaPlanState {
        QadaPlanState(
            trackingStartDateKey: startDateKey,
            recentBaselineRemaining: 0,
            olderBaselineRemaining: 0,
            plannedRecentDateKeys: [],
            plannedOlderDateKeys: [],
            recentGroupID: nil,
            olderGroupID: nil
        )
    }
}

final class QadaPlanStore: ObservableObject {
    @Published private(set) var state: QadaPlanState

    private let defaults: UserDefaults
    private let storageKey = "Suhoor.QadaPlanState"
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.qada-plan-store",
        delay: 0.2
    )

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(QadaPlanState.self, from: data) {
            self.state = decoded
        } else {
            let todayKey = DateHelpers.dayIdentifier(for: Date(), timeZone: .current)
            self.state = QadaPlanState.empty(startDateKey: todayKey)
        }
    }

    func setBaselines(
        recent: Int,
        older: Int,
        trackingStartDateKey: String? = nil
    ) {
        let normalizedRecent = max(0, recent)
        let normalizedOlder = max(0, older)
        var updated = state
        updated.recentBaselineRemaining = normalizedRecent
        updated.olderBaselineRemaining = normalizedOlder
        if let trackingStartDateKey {
            updated.trackingStartDateKey = trackingStartDateKey
        }
        updateState(updated)
    }

    func setPlannedDates(
        _ dateKeys: Set<String>,
        for bucket: QadaBucket,
        groupID: UUID?
    ) {
        var updated = state
        switch bucket {
        case .recent:
            updated.plannedRecentDateKeys = dateKeys
            updated.recentGroupID = groupID
        case .older:
            updated.plannedOlderDateKeys = dateKeys
            updated.olderGroupID = groupID
        }
        updateState(updated)
    }

    func clearPlannedDates(for bucket: QadaBucket) {
        setPlannedDates([], for: bucket, groupID: nil)
    }

    private func updateState(_ newState: QadaPlanState) {
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
