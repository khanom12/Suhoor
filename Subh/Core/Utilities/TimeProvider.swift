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

final class MutableTimeProvider: TimeProviding, @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var storedNow: Date

    init(now: Date = Date()) {
        self.storedNow = now
    }

    nonisolated func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return storedNow
    }

    func setNow(_ now: Date) {
        lock.lock()
        storedNow = now
        lock.unlock()
    }

    func advance(by interval: TimeInterval) {
        lock.lock()
        storedNow = storedNow.addingTimeInterval(interval)
        lock.unlock()
    }
}
