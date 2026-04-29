import Foundation

protocol TimeProviding: Sendable {
    nonisolated func now() -> Date
}

struct SystemTimeProvider: TimeProviding {
    nonisolated init() {}

    nonisolated func now() -> Date {
        Date()
    }
}

struct FixedTimeProvider: TimeProviding {
    let fixedNow: Date

    nonisolated init(fixedNow: Date) {
        self.fixedNow = fixedNow
    }

    nonisolated func now() -> Date {
        fixedNow
    }
}
