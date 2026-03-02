import Foundation

struct ActiveTagComputationSeed: Codable, Hashable, Sendable {
    let date: Date
    let dateKey: String
    let defaultPrimaryIntent: FastPrimaryIntent?
}

struct TagComputationResult: Codable, Hashable, Sendable {
    let computedPrimaryIntent: FastPrimaryIntent
    let computedSecondaryTags: Set<FastSecondaryVirtueTag>
    let secondaryDetails: [FastSecondaryVirtueTag: TagEvaluationDetail]
    let suppressedSecondaryTags: Set<FastSecondaryVirtueTag>

    static let empty = TagComputationResult(
        computedPrimaryIntent: .other,
        computedSecondaryTags: [],
        secondaryDetails: [:],
        suppressedSecondaryTags: []
    )
}

enum TagComputationEngine {
    static func results(
        schedules: [DaySchedule],
        selections: [String: FastIntentSelection],
        ruleset: FiqhRuleset,
        timeZone: TimeZone
    ) -> [String: TagComputationResult] {
        results(
            seeds: schedules.map {
                ActiveTagComputationSeed(
                    date: $0.date,
                    dateKey: DateHelpers.dayIdentifier(for: $0.date, timeZone: timeZone),
                    defaultPrimaryIntent: nil
                )
            },
            selections: selections,
            ruleset: ruleset,
            timeZone: timeZone
        )
    }

    static func results(
        seeds: [ActiveTagComputationSeed],
        selections: [String: FastIntentSelection],
        ruleset: FiqhRuleset,
        timeZone: TimeZone
    ) -> [String: TagComputationResult] {
        guard !seeds.isEmpty else { return [:] }

        var basePrimaryByKey: [String: FastPrimaryIntent] = [:]
        var suppressedByKey: [String: Set<FastSecondaryVirtueTag>] = [:]
        var compatibleByKey: [String: Set<FastSecondaryVirtueTag>] = [:]
        var shawwalCandidates: [(key: String, date: Date)] = []

        for seed in seeds.sorted(by: { $0.date < $1.date }) {
            let rawSelection = selections[seed.dateKey]
                ?? seed.defaultPrimaryIntent.map { FastIntentSelection(primaryIntent: $0, secondaryTags: []) }
                ?? .default
            let normalizedSelection = FastIntentEngine.normalizedSelection(
                rawSelection,
                for: seed.date,
                ruleset: ruleset,
                timeZone: timeZone
            )

            let basePrimary = resolvePrimaryIntent(date: seed.date, selection: normalizedSelection, timeZone: timeZone)
            basePrimaryByKey[seed.dateKey] = basePrimary

            let dateDerived = FastIntentEngine.dateDerivedObservanceTags(
                for: seed.date,
                timeZone: timeZone,
                includeShawwalPotential: false
            )

            if ruleset == .strict, basePrimary != .voluntarySunnah {
                suppressedByKey[seed.dateKey] = dateDerived
                compatibleByKey[seed.dateKey] = []
            } else {
                let compatible = FastIntentEngine.compatibleObservanceTags(from: dateDerived)
                compatibleByKey[seed.dateKey] = compatible
                suppressedByKey[seed.dateKey] = dateDerived.subtracting(compatible)
            }

            if isEligibleForShawwalTracking(date: seed.date, primary: basePrimary, timeZone: timeZone) {
                shawwalCandidates.append((key: seed.dateKey, date: seed.date))
            }
        }

        let shawwalFirstSix = Set(
            shawwalCandidates
                .sorted { $0.date < $1.date }
                .prefix(6)
                .map(\.key)
        )

        var results: [String: TagComputationResult] = [:]
        for seed in seeds {
            let primary = basePrimaryByKey[seed.dateKey] ?? .other
            var computedSecondary = compatibleByKey[seed.dateKey] ?? []
            var suppressedSecondary = suppressedByKey[seed.dateKey] ?? []
            let potentialShawwal = FastIntentEngine.isCalendarApplicable(tag: .shawwalSix, on: seed.date, timeZone: timeZone)
            var secondaryDetails: [FastSecondaryVirtueTag: TagEvaluationDetail] = [:]

            if potentialShawwal {
                if ruleset == .strict, primary != .voluntarySunnah {
                    suppressedSecondary.insert(.shawwalSix)
                } else if shawwalFirstSix.contains(seed.dateKey) {
                    computedSecondary.insert(.shawwalSix)
                }
            }

            for tag in computedSecondary {
                let reason: String
                if tag == .shawwalSix {
                    reason = "Counts toward your six Shawwal fasts."
                } else {
                    reason = FastIntentEngine.observanceReason(for: tag, on: seed.date, timeZone: timeZone)
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

            results[seed.dateKey] = TagComputationResult(
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
        result(
            for: date,
            seeds: schedules.map {
                ActiveTagComputationSeed(
                    date: $0.date,
                    dateKey: DateHelpers.dayIdentifier(for: $0.date, timeZone: timeZone),
                    defaultPrimaryIntent: nil
                )
            },
            selections: selections,
            ruleset: ruleset,
            timeZone: timeZone,
            overrideSelection: overrideSelection
        )
    }

    static func result(
        for date: Date,
        seeds: [ActiveTagComputationSeed],
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
            seeds: seedsIncluding(date: date, in: seeds, timeZone: timeZone),
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

    private static func seedsIncluding(
        date: Date,
        in seeds: [ActiveTagComputationSeed],
        timeZone: TimeZone
    ) -> [ActiveTagComputationSeed] {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
        if seeds.contains(where: { $0.dateKey == key }) {
            return seeds
        }

        return (seeds + [ActiveTagComputationSeed(date: date, dateKey: key, defaultPrimaryIntent: nil)]).sorted { $0.date < $1.date }
    }
}
