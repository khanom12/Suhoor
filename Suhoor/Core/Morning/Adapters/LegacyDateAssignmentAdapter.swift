import Foundation

struct LegacyDateAssignmentSnapshot: Sendable {
    let assignments: [PlanDateAssignment]
}

enum LegacyDateAssignmentAdapter {
    static func assignments(
        overridesByDay: [String: DailyAlarmOverride],
        provenancesByDateKey: [String: [ResolvedScheduledDateProvenance]],
        fastTagSelections: [String: FastIntentSelection],
        qadaBatchState: QadaBatchState
    ) -> LegacyDateAssignmentSnapshot {
        var assignments: [PlanDateAssignment] = []

        for dateKey in overridesByDay.keys.sorted() {
            assignments.append(PlanDateAssignment(dateKey: dateKey, planID: "override-\(dateKey)"))
        }

        for dateKey in qadaBatchState.plannedDateKeys.sorted() {
            assignments.append(PlanDateAssignment(dateKey: dateKey, planID: "qada-\(dateKey)"))
        }

        for (dateKey, selection) in fastTagSelections where selection.hasMeaningfulTags {
            let planID: String
            switch selection.primaryIntent {
            case .qadaMakeup:
                planID = "qada-\(dateKey)"
            case .ramadanObligatory, .kaffarahExpiation, .vowNadhr, .voluntary:
                planID = "context-\(dateKey)"
            case .forbidden, .other:
                planID = "context-\(dateKey)"
            }
            assignments.append(PlanDateAssignment(dateKey: dateKey, planID: planID))
        }

        for (dateKey, provenances) in provenancesByDateKey where provenances.contains(where: { $0.sourceOrigin != .defaultDailyPlan }) {
            assignments.append(PlanDateAssignment(dateKey: dateKey, planID: "source-\(dateKey)"))
        }

        let deduped = Dictionary(assignments.map { ("\($0.dateKey)|\($0.planID)", $0) }, uniquingKeysWith: { current, _ in current })
            .values
            .sorted { lhs, rhs in
                if lhs.dateKey == rhs.dateKey {
                    return lhs.planID < rhs.planID
                }
                return lhs.dateKey < rhs.dateKey
            }

        return LegacyDateAssignmentSnapshot(assignments: deduped)
    }
}
