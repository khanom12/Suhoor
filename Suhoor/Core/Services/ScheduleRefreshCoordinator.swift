import Foundation

enum ScheduleRefreshReason: Equatable, Sendable {
    case appLaunch
    case foreground
    case settingsChanged
    case locationUpdated
    case manual
}

struct PendingScheduleRefresh: Equatable, Sendable {
    let reason: ScheduleRefreshReason
    let force: Bool

    func merged(with other: PendingScheduleRefresh) -> PendingScheduleRefresh {
        PendingScheduleRefresh(reason: other.reason, force: force || other.force)
    }
}

@MainActor
final class ScheduleRefreshCoordinator {
    typealias RefreshHandler = @MainActor (PendingScheduleRefresh) async -> Void

    private let handler: RefreshHandler
    private var queuedRefresh: PendingScheduleRefresh?
    private var refreshTask: Task<Void, Never>?

    init(handler: @escaping RefreshHandler) {
        self.handler = handler
    }

    func requestRefresh(reason: ScheduleRefreshReason, force: Bool = true) {
        let request = PendingScheduleRefresh(reason: reason, force: force)
        queuedRefresh = queuedRefresh?.merged(with: request) ?? request
        guard refreshTask == nil else { return }
        scheduleQueuedRefresh()
    }

    func cancelAll() {
        refreshTask?.cancel()
        refreshTask = nil
        queuedRefresh = nil
    }

    private func scheduleQueuedRefresh() {
        guard let request = queuedRefresh else { return }
        queuedRefresh = nil
        refreshTask = Task { [weak self] in
            guard let self else { return }
            let delay = request.reason.debounceDurationNanoseconds
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else {
                await MainActor.run {
                    self.finishRefreshTask()
                }
                return
            }
            await handler(request)
            await MainActor.run {
                self.finishRefreshTask()
            }
        }
    }

    private func finishRefreshTask() {
        refreshTask = nil
        if queuedRefresh != nil {
            scheduleQueuedRefresh()
        }
    }
}

private extension ScheduleRefreshReason {
    var debounceDurationNanoseconds: UInt64 {
        switch self {
        case .appLaunch, .foreground, .manual:
            return 0
        case .settingsChanged:
            return 200_000_000
        case .locationUpdated:
            return 100_000_000
        }
    }
}
