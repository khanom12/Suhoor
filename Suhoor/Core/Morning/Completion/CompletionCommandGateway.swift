import Foundation

@MainActor
final class CompletionCommandGateway {
    private let fajrLogStore: FajrLogStore
    private let fastLogStore: FastLogStore

    init(
        fajrLogStore: FajrLogStore,
        fastLogStore: FastLogStore
    ) {
        self.fajrLogStore = fajrLogStore
        self.fastLogStore = fastLogStore
    }

    func perform(_ intent: CompletionEditIntent, now: Date = Date()) {
        switch intent {
        case let .setPrayerStatus(dateKey, status):
            fajrLogStore.setStatus(fajrStatus(from: status), for: dateKey, now: now)
        case let .clearPrayerStatus(dateKey):
            fajrLogStore.clear(for: dateKey)
        case let .setFastStatus(dateKey, status, intentSnapshot):
            let logStatus = fastStatus(from: status)
            if logStatus == .unknown {
                fastLogStore.clear(for: dateKey)
            } else {
                fastLogStore.setStatus(logStatus, for: dateKey, intentSnapshot: intentSnapshot, now: now)
            }
        case let .clearFastStatus(dateKey):
            fastLogStore.clear(for: dateKey)
        }
    }

    private func fajrStatus(from status: PrayerCompletionStatus) -> FajrCompletionStatus {
        switch status {
        case .unknown:
            return .unknown
        case .completed:
            return .completed
        case .missed:
            return .missed
        }
    }

    private func fastStatus(from status: FastCompletionStatus) -> FastLogStatus {
        switch status {
        case .notRequired, .unknown:
            return .unknown
        case .inProgress:
            return .inProgress
        case .completed:
            return .completed
        case .notCompleted:
            return .missed
        }
    }
}
