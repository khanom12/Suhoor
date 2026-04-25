import Foundation
import os

enum Logging {
    static let scheduler = Logger(subsystem: "com.suhoor.app", category: "scheduler")
    static let location = Logger(subsystem: "com.suhoor.app", category: "location")
    static let diagnostics = Logger(subsystem: "com.suhoor.app", category: "diagnostics")
    static let notifications = Logger(subsystem: "com.suhoor.app", category: "notifications")
}

final class DebouncedPersistenceController {
    private let queue: DispatchQueue
    private let delay: TimeInterval
    private let lock = NSLock()
    private var pendingWorkItem: DispatchWorkItem?

    init(label: String, delay: TimeInterval = 0.25, qos: DispatchQoS = .utility) {
        self.queue = DispatchQueue(label: label, qos: qos)
        self.delay = delay
    }

    func schedule(_ work: @escaping () -> Void) {
        let item = DispatchWorkItem(block: work)
        lock.lock()
        pendingWorkItem?.cancel()
        pendingWorkItem = item
        lock.unlock()
        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func cancelPending() {
        lock.lock()
        let item = pendingWorkItem
        pendingWorkItem = nil
        lock.unlock()
        item?.cancel()
    }

    /// Executes the latest scheduled work item immediately (if any).
    ///
    /// Intended for deterministic unit tests where `asyncAfter` delays are undesirable.
    func flush() {
        lock.lock()
        let item = pendingWorkItem
        pendingWorkItem = nil
        lock.unlock()

        guard let item else { return }
        item.cancel()
        queue.sync {
            item.perform()
        }
    }
}

struct PerformanceTraceToken {
    let name: String
    let startedAt: CFAbsoluteTime
    let metadata: String?
}

final class PerformanceTraceRecorder {
    struct Entry: Equatable {
        let name: String
        let elapsedMs: Double
        let metadata: String?
    }

    static let shared = PerformanceTraceRecorder()

    private let lock = NSLock()
    private var entries: [Entry] = []

    private init() {}

    func record(name: String, elapsedMs: Double, metadata: String?) {
        lock.lock()
        entries.append(Entry(name: name, elapsedMs: elapsedMs, metadata: metadata))
        lock.unlock()
    }

    func snapshot() -> [Entry] {
        lock.lock()
        let snapshot = entries
        lock.unlock()
        return snapshot
    }

    func reset() {
        lock.lock()
        entries.removeAll(keepingCapacity: true)
        lock.unlock()
    }
}

enum PerformanceTrace {
    @discardableResult
    static func begin(_ name: String, metadata: String? = nil) -> PerformanceTraceToken {
        PerformanceTraceToken(name: name, startedAt: CFAbsoluteTimeGetCurrent(), metadata: metadata)
    }

    static func end(_ token: PerformanceTraceToken, metadata: String? = nil) {
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - token.startedAt) * 1000
        let metadataParts = [token.metadata, metadata].compactMap { $0 }.filter { !$0.isEmpty }
        #if DEBUG
        PerformanceTraceRecorder.shared.record(
            name: token.name,
            elapsedMs: elapsedMs,
            metadata: metadataParts.isEmpty ? nil : metadataParts.joined(separator: " | ")
        )
        let suffix = metadataParts.isEmpty ? "" : " [\(metadataParts.joined(separator: " | "))]"
        Logging.diagnostics.debug("[perf] \(token.name, privacy: .public) \(elapsedMs, format: .fixed(precision: 2))ms\(suffix, privacy: .public)")
        #endif
    }

    static func measure<T>(_ name: String, metadata: String? = nil, operation: () -> T) -> T {
        let token = begin(name, metadata: metadata)
        let result = operation()
        end(token)
        return result
    }

    static func measureAsync<T>(
        _ name: String,
        metadata: String? = nil,
        operation: () async -> T
    ) async -> T {
        let token = begin(name, metadata: metadata)
        let result = await operation()
        end(token)
        return result
    }
}
