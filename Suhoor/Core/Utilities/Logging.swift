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
}

struct PerformanceTraceToken {
    let name: String
    let startedAt: CFAbsoluteTime
    let metadata: String?
}

enum PerformanceTrace {
    @discardableResult
    static func begin(_ name: String, metadata: String? = nil) -> PerformanceTraceToken {
        PerformanceTraceToken(name: name, startedAt: CFAbsoluteTimeGetCurrent(), metadata: metadata)
    }

    static func end(_ token: PerformanceTraceToken, metadata: String? = nil) {
        #if DEBUG
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - token.startedAt) * 1000
        let metadataParts = [token.metadata, metadata].compactMap { $0 }.filter { !$0.isEmpty }
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
