import Foundation

struct TagComputationResult: Hashable {
    let computedPrimaryIntent: FastPrimaryIntent
    let computedSecondaryTags: Set<FastSecondaryVirtueTag>
    let secondaryDetails: [FastSecondaryVirtueTag: TagEvaluationDetail]
    let suppressedSecondaryTags: Set<FastSecondaryVirtueTag>
}

enum TagComputationEngine {
    static func results(
        schedules: [DaySchedule],
        selections: [String: FastIntentSelection],
        ruleset: FiqhRuleset,
        timeZone: TimeZone
    ) -> [String: TagComputationResult] {
        guard !schedules.isEmpty else { return [:] }

        var normalizedSelections: [String: FastIntentSelection] = [:]
        var basePrimaryByKey: [String: FastPrimaryIntent] = [:]
        var suppressedByKey: [String: Set<FastSecondaryVirtueTag>] = [:]
        var compatibleByKey: [String: Set<FastSecondaryVirtueTag>] = [:]
        var shawwalCandidates: [(key: String, date: Date)] = []

        for schedule in schedules {
            let key = DateHelpers.dayIdentifier(for: schedule.date, timeZone: timeZone)
            let rawSelection = selections[key] ?? .default
            let normalizedSelection = FastIntentEngine.normalizedSelection(
                rawSelection,
                for: schedule.date,
                ruleset: ruleset,
                timeZone: timeZone
            )
            if normalizedSelection.hasMeaningfulTags {
                normalizedSelections[key] = normalizedSelection
            }

            let basePrimary = resolvePrimaryIntent(date: schedule.date, selection: normalizedSelection, timeZone: timeZone)
            basePrimaryByKey[key] = basePrimary

            let dateDerived = FastIntentEngine.dateDerivedObservanceTags(
                for: schedule.date,
                timeZone: timeZone,
                includeShawwalPotential: false
            )

            if ruleset == .strict, basePrimary != .voluntarySunnah {
                suppressedByKey[key] = dateDerived
                compatibleByKey[key] = []
            } else {
                let compatible = FastIntentEngine.compatibleObservanceTags(from: dateDerived)
                compatibleByKey[key] = compatible
                suppressedByKey[key] = dateDerived.subtracting(compatible)
            }

            if isEligibleForShawwalTracking(date: schedule.date, primary: basePrimary, timeZone: timeZone) {
                shawwalCandidates.append((key: key, date: schedule.date))
            }
        }

        let shawwalFirstSix = Set(
            shawwalCandidates
                .sorted { $0.date < $1.date }
                .prefix(6)
                .map(\.key)
        )

        var results: [String: TagComputationResult] = [:]
        for schedule in schedules {
            let key = DateHelpers.dayIdentifier(for: schedule.date, timeZone: timeZone)
            let primary = basePrimaryByKey[key] ?? .other
            var computedSecondary = compatibleByKey[key] ?? []
            var suppressedSecondary = suppressedByKey[key] ?? []
            let potentialShawwal = FastIntentEngine.isCalendarApplicable(tag: .shawwalSix, on: schedule.date, timeZone: timeZone)
            var secondaryDetails: [FastSecondaryVirtueTag: TagEvaluationDetail] = [:]

            if potentialShawwal {
                if ruleset == .strict, primary != .voluntarySunnah {
                    suppressedSecondary.insert(.shawwalSix)
                } else if shawwalFirstSix.contains(key) {
                    computedSecondary.insert(.shawwalSix)
                }
            }

            for tag in computedSecondary {
                let reason: String
                if tag == .shawwalSix {
                    reason = "Counts toward your six Shawwal fasts."
                } else {
                    reason = FastIntentEngine.observanceReason(for: tag, on: schedule.date, timeZone: timeZone)
                }
                secondaryDetails[tag] = TagEvaluationDetail(tag: tag, source: .autoDerived, reason: reason)
            }

            for tag in suppressedSecondary {
                secondaryDetails[tag] = TagEvaluationDetail(
                    tag: tag,
                    source: .suppressedByPolicy,
                    reason: FastIntentEngine.suppressionReason(for: tag, primary: primary)
                )
            }

            results[key] = TagComputationResult(
                computedPrimaryIntent: primary,
                computedSecondaryTags: computedSecondary,
                secondaryDetails: secondaryDetails,
                suppressedSecondaryTags: suppressedSecondary
            )
        }

        return results
    }

    static func result(
        for date: Date,
        schedules: [DaySchedule],
        selections: [String: FastIntentSelection],
        ruleset: FiqhRuleset,
        timeZone: TimeZone,
        overrideSelection: FastIntentSelection?
    ) -> TagComputationResult {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        var mergedSelections = selections
        if let overrideSelection {
            mergedSelections[key] = overrideSelection
        } else {
            mergedSelections[key] = nil
        }

        let computed = results(
            schedules: schedulesIncluding(date: date, in: schedules, timeZone: timeZone),
            selections: mergedSelections,
            ruleset: ruleset,
            timeZone: timeZone
        )
        if let result = computed[key] {
            return result
        }

        let normalized = FastIntentEngine.normalizedSelection(
            overrideSelection ?? .default,
            for: date,
            ruleset: ruleset,
            timeZone: timeZone
        )
        let primary = resolvePrimaryIntent(date: date, selection: normalized, timeZone: timeZone)
        let dateDerived = FastIntentEngine.dateDerivedObservanceTags(
            for: date,
            timeZone: timeZone,
            includeShawwalPotential: false
        )

        var computedSecondary: Set<FastSecondaryVirtueTag> = []
        var suppressedSecondary: Set<FastSecondaryVirtueTag> = []
        if ruleset == .strict, primary != .voluntarySunnah {
            suppressedSecondary = dateDerived
            if FastIntentEngine.isCalendarApplicable(tag: .shawwalSix, on: date, timeZone: timeZone) {
                suppressedSecondary.insert(.shawwalSix)
            }
        } else {
            computedSecondary = FastIntentEngine.compatibleObservanceTags(from: dateDerived)
        }

        var secondaryDetails: [FastSecondaryVirtueTag: TagEvaluationDetail] = [:]
        for tag in computedSecondary {
            secondaryDetails[tag] = TagEvaluationDetail(
                tag: tag,
                source: .autoDerived,
                reason: FastIntentEngine.observanceReason(for: tag, on: date, timeZone: timeZone)
            )
        }
        for tag in suppressedSecondary {
            secondaryDetails[tag] = TagEvaluationDetail(
                tag: tag,
                source: .suppressedByPolicy,
                reason: FastIntentEngine.suppressionReason(for: tag, primary: primary)
            )
        }

        return TagComputationResult(
            computedPrimaryIntent: primary,
            computedSecondaryTags: computedSecondary,
            secondaryDetails: secondaryDetails,
            suppressedSecondaryTags: suppressedSecondary
        )
    }

    private static func resolvePrimaryIntent(
        date: Date,
        selection: FastIntentSelection,
        timeZone: TimeZone
    ) -> FastPrimaryIntent {
        if isRamadan(date: date, timeZone: timeZone) {
            return .ramadanObligatory
        }
        return selection.primaryIntent
    }

    private static func isEligibleForShawwalTracking(
        date: Date,
        primary: FastPrimaryIntent,
        timeZone: TimeZone
    ) -> Bool {
        guard primary == .voluntarySunnah else { return false }
        return FastIntentEngine.isCalendarApplicable(tag: .shawwalSix, on: date, timeZone: timeZone)
    }

    private static func isRamadan(date: Date, timeZone: TimeZone) -> Bool {
        FastIntentEngine.isRamadan(date, timeZone: timeZone)
    }

    private static func schedulesIncluding(
        date: Date,
        in schedules: [DaySchedule],
        timeZone: TimeZone
    ) -> [DaySchedule] {
        if schedules.contains(where: { DateHelpers.isSameDay($0.date, date, in: timeZone) }) {
            return schedules
        }

        let synthetic = DaySchedule(
            date: date,
            fajrDate: date,
            wakeDate: date,
            reminderDate: nil,
            boundaryDate: nil,
            locationDescription: "Derived",
            offsetMinutes: 0,
            calculationMethodName: "Derived",
            timeZone: timeZone
        )

        return (schedules + [synthetic]).sorted { $0.date < $1.date }
    }
}
