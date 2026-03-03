import Foundation
import Combine

final class TodayCardLayoutStore: ObservableObject {
    @Published private(set) var layout: TodayCardLayout

    private let defaults: UserDefaults
    private let storageKey = "Suhoor.TodayCardLayout"
    private let persistence = DebouncedPersistenceController(
        label: "com.suhoor.app.today-card-layout",
        delay: 0.2
    )

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(TodayCardLayout.self, from: data) {
            self.layout = decoded
        } else {
            self.layout = .default
        }
        normalizeLayoutIfNeeded()
    }

    func isVisible(_ card: TodayCardKind) -> Bool {
        layout.isVisible(card)
    }

    func setVisible(_ visible: Bool, for card: TodayCardKind) {
        var updated = layout
        if visible {
            updated.hidden.remove(card)
        } else {
            updated.hidden.insert(card)
        }
        setLayout(updated)
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        var updated = layout
        updated.ordered.moveElements(fromOffsets: fromOffsets, toOffset: toOffset)
        setLayout(updated)
    }

    func resetToDefault() {
        setLayout(.default)
    }

    private func setLayout(_ newLayout: TodayCardLayout) {
        guard layout != newLayout else { return }
        layout = newLayout
        persist()
    }

    private func normalizeLayoutIfNeeded() {
        var updated = layout

        let known = Set(TodayCardKind.allCases)
        updated.ordered = updated.ordered.filter { known.contains($0) }
        updated.hidden = updated.hidden.filter { known.contains($0) }

        for card in TodayCardKind.allCases where !updated.ordered.contains(card) {
            updated.ordered.append(card)
        }

        if updated != layout {
            layout = updated
            persist()
        }
    }

    private func persist() {
        let snapshot = layout
        persistence.schedule { [defaults, storageKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaults.set(data, forKey: storageKey)
        }
    }

#if DEBUG
    func flushPersistenceForTesting() {
        persistence.flush()
    }
#endif
}

private extension Array {
    mutating func moveElements(fromOffsets: IndexSet, toOffset: Int) {
        guard isEmpty == false, fromOffsets.isEmpty == false else { return }

        let moving = fromOffsets.map { self[$0] }
        for index in fromOffsets.sorted(by: >) {
            remove(at: index)
        }

        var destination = toOffset
        destination -= fromOffsets.filter { $0 < toOffset }.count
        destination = Swift.min(Swift.max(0, destination), count)
        insert(contentsOf: moving, at: destination)
    }
}
