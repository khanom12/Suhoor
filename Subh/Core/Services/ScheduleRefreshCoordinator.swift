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
    private var scheduledRefresh: PendingScheduleRefresh?
    private var isExecutingRefresh = false

    init(handler: @escaping RefreshHandler) {
        self.handler = handler
    }

    var pendingRefreshForTesting: PendingScheduleRefresh? {
        scheduledRefresh ?? queuedRefresh
    }

    func requestRefresh(reason: ScheduleRefreshReason, force: Bool = true) {
        let request = PendingScheduleRefresh(reason: reason, force: force)
        if refreshTask != nil,
           request.reason.isLifecycleRefresh,
           queuedRefresh == nil,
           scheduledRefresh?.reason.isLifecycleRefresh == true || isExecutingRefresh {
            return
        }
        if refreshTask != nil,
           !isExecutingRefresh,
           let scheduledRefresh {
            self.scheduledRefresh = scheduledRefresh.merged(with: request)
            return
        }
        queuedRefresh = queuedRefresh?.merged(with: request) ?? request
        guard refreshTask == nil else { return }
        scheduleQueuedRefresh()
    }

    func cancelAll() {
        refreshTask?.cancel()
        refreshTask = nil
        queuedRefresh = nil
        scheduledRefresh = nil
        isExecutingRefresh = false
    }

    private func scheduleQueuedRefresh() {
        guard let request = queuedRefresh else { return }
        queuedRefresh = nil
        scheduledRefresh = request
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
            guard let refresh = await MainActor.run(body: {
                self.startScheduledRefresh()
            }) else { return }
            await handler(refresh)
            await MainActor.run {
                self.finishRefreshTask()
            }
        }
    }

    private func startScheduledRefresh() -> PendingScheduleRefresh? {
        let request = scheduledRefresh
        scheduledRefresh = nil
        isExecutingRefresh = request != nil
        return request
    }

    private func finishRefreshTask() {
        refreshTask = nil
        scheduledRefresh = nil
        isExecutingRefresh = false
        if queuedRefresh != nil {
            scheduleQueuedRefresh()
        }
    }
}

private extension ScheduleRefreshReason {
    var isLifecycleRefresh: Bool {
        switch self {
        case .appLaunch, .foreground:
            return true
        case .settingsChanged, .locationUpdated, .manual:
            return false
        }
    }

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
