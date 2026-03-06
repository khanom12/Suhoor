import Foundation

enum QadaSetupPage: Int, CaseIterable, Hashable, Sendable {
    case intake
    case pace
    case preferences
}

enum QadaWizardLaunchMode: Hashable, Sendable {
    case fresh
    case nextBatch
    case adjustTotal
    case reviewCurrentBatch
    case recoverMissedDay

    var initialSetupPage: QadaSetupPage {
        switch self {
        case .fresh, .adjustTotal:
            return .intake
        case .nextBatch:
            return .pace
        case .reviewCurrentBatch, .recoverMissedDay:
            return .preferences
        }
    }

    var startsInReview: Bool {
        switch self {
        case .reviewCurrentBatch, .recoverMissedDay:
            return true
        case .fresh, .nextBatch, .adjustTotal:
            return false
        }
    }

    var returnsToCompanionOnBack: Bool {
        switch self {
        case .nextBatch, .adjustTotal, .reviewCurrentBatch, .recoverMissedDay:
            return true
        case .fresh:
            return false
        }
    }
}

struct QadaBacklogSuggestion: Equatable, Sendable {
    let suggestedOwed: Int
    let sourceSummary: String
}

struct QadaBatchSnapshot: Equatable, Sendable {
    let plannedDateKeys: Set<String>
    let targetCount: Int
    let completedCount: Int
    let remainingBacklog: Int
    let inputMode: QadaPlanInputMode
    let nextPlannedDate: Date?
    let missedDate: Date?
    let pace: QadaPlanPace
    let avoidShawwal: Bool
    let avoidImportantSunnah: Bool

    var completedProgressText: String {
        "\(min(completedCount, targetCount)) of \(targetCount) in this batch completed"
    }

    var remainingText: String {
        switch inputMode {
        case .exact:
            return "Remaining: \(remainingBacklog)"
        case .estimate:
            return "About \(remainingBacklog) remaining"
        }
    }
}

enum QadaExperienceState: Equatable, Sendable {
    case needsSetup(suggestion: QadaBacklogSuggestion?)
    case activeBatch(QadaBatchSnapshot)
    case batchCompleteNeedsNext(QadaBatchSnapshot)
    case needsRecovery(QadaBatchSnapshot)
}

enum QadaExperienceEngine {
    static func resolve(
        backlogState: QadaBacklogState,
        progress: QadaProgressSnapshot,
        batchState: QadaBatchState,
        logEntries: [String: FastLogEntry],
        suggestion: QadaBacklogSuggestion?,
        timeZone: TimeZone = .current,
        now: Date = Date()
    ) -> QadaExperienceState {
        guard !batchState.plannedDateKeys.isEmpty else {
            return .needsSetup(suggestion: backlogState.baselineOwed == 0 ? suggestion : nil)
        }

        let todayKey = DateHelpers.dayIdentifier(for: DateHelpers.startOfDay(now, in: timeZone), timeZone: timeZone)
        let completedKeys = logEntries.reduce(into: Set<String>()) { partialResult, item in
            let (key, entry) = item
            guard entry.status == .completed,
                  entry.intentSnapshot?.primaryIntent == .qadaMakeup,
                  batchState.plannedDateKeys.contains(key) else {
                return
            }
            partialResult.insert(key)
        }

        let unresolvedKeys = batchState.plannedDateKeys.subtracting(completedKeys)
        let upcomingKeys = unresolvedKeys.filter { $0 >= todayKey }
        let missedKeys = unresolvedKeys.filter { $0 < todayKey }

        let nextPlannedDate = upcomingKeys
            .compactMap { DateHelpers.date(fromDayIdentifier: $0, timeZone: timeZone) }
            .sorted()
            .first
        let missedDate = missedKeys
            .compactMap { DateHelpers.date(fromDayIdentifier: $0, timeZone: timeZone) }
            .sorted()
            .first

        let snapshot = QadaBatchSnapshot(
            plannedDateKeys: batchState.plannedDateKeys,
            targetCount: batchState.targetCount,
            completedCount: completedKeys.count,
            remainingBacklog: progress.remaining,
            inputMode: backlogState.inputMode,
            nextPlannedDate: nextPlannedDate,
            missedDate: missedDate,
            pace: batchState.pace,
            avoidShawwal: batchState.avoidShawwal,
            avoidImportantSunnah: batchState.avoidImportantSunnah
        )

        if !missedKeys.isEmpty {
            return .needsRecovery(snapshot)
        }
        if !upcomingKeys.isEmpty {
            return .activeBatch(snapshot)
        }
        return .batchCompleteNeedsNext(snapshot)
    }
}
