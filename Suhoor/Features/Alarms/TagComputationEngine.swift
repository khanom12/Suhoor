import Foundation

struct TagComputationResult: Hashable {
    let computedPrimaryIntent: FastPrimaryIntent
    let computedSecondaryTags: Set<FastSecondaryVirtueTag>
    let autoSecondaryTags: Set<FastSecondaryVirtueTag>
}

enum TagComputationEngine {
    static func results(
        schedules: [DaySchedule],
        selections: [String: FastIntentSelection],
        ruleset: FiqhRuleset,
        timeZone: TimeZone
    ) -> [String: TagComputationResult] {
        guard !schedules.isEmpty else { return [:] }

        let normalizedSelections = selections.filter { $0.value.hasMeaningfulTags }
        var baseAutoTagsByKey: [String: Set<FastSecondaryVirtueTag>] = [:]
        var basePrimaryByKey: [String: FastPrimaryIntent] = [:]
        var shawwalCandidates: [(key: String, date: Date)] = []

        for schedule in schedules {
            let key = DateHelpers.dayIdentifier(for: schedule.date, timeZone: timeZone)
            let selection = normalizedSelections[key]
            let baseAutoTags = autoTags(for: schedule.date, timeZone: timeZone, includeShawwal: false)
            let basePrimary = resolvePrimaryIntent(
                date: schedule.date,
                selection: selection,
                autoTags: baseAutoTags,
                timeZone: timeZone
            )
            baseAutoTagsByKey[key] = baseAutoTags
            basePrimaryByKey[key] = basePrimary

            if isShawwal(date: schedule.date, timeZone: timeZone), !basePrimary.isObligatory {
                shawwalCandidates.append((key: key, date: schedule.date))
            }
        }

        let shawwalFirstSix = Set(
            shawwalCandidates
                .sorted { $0.date < $1.date }
                .prefix(6)
                .map { $0.key }
        )

        var results: [String: TagComputationResult] = [:]
        for schedule in schedules {
            let key = DateHelpers.dayIdentifier(for: schedule.date, timeZone: timeZone)
            let selection = normalizedSelections[key]
            var autoTags = baseAutoTagsByKey[key] ?? []
            if shawwalFirstSix.contains(key) {
                autoTags.insert(.shawwalSix)
            }

            let computedPrimary = resolvePrimaryIntent(
                date: schedule.date,
                selection: selection,
                autoTags: autoTags,
                timeZone: timeZone
            )
            var computedSecondary = autoTags
            if let selection {
                computedSecondary.formUnion(selection.secondaryTags)
            }

            if ruleset == .strict, computedPrimary.isObligatory {
                computedSecondary = []
            }

            let autoSecondary = (ruleset == .strict && computedPrimary.isObligatory) ? [] : autoTags
            results[key] = TagComputationResult(
                computedPrimaryIntent: computedPrimary,
                computedSecondaryTags: computedSecondary,
                autoSecondaryTags: autoSecondary
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
        if let overrideSelection, overrideSelection.hasMeaningfulTags {
            mergedSelections[key] = overrideSelection
        } else {
            mergedSelections[key] = nil
        }

        let computed = results(
            schedules: schedules,
            selections: mergedSelections,
            ruleset: ruleset,
            timeZone: timeZone
        )
        if let result = computed[key] {
            return result
        }

        let baseAutoTags = autoTags(for: date, timeZone: timeZone, includeShawwal: false)
        let primary = resolvePrimaryIntent(date: date, selection: overrideSelection, autoTags: baseAutoTags, timeZone: timeZone)
        var computedSecondary = baseAutoTags
        if let overrideSelection {
            computedSecondary.formUnion(overrideSelection.secondaryTags)
        }
        if ruleset == .strict && primary.isObligatory {
            computedSecondary = []
        }
        let autoSecondary = (ruleset == .strict && primary.isObligatory) ? [] : baseAutoTags
        return TagComputationResult(
            computedPrimaryIntent: primary,
            computedSecondaryTags: computedSecondary,
            autoSecondaryTags: autoSecondary
        )
    }

    private static func resolvePrimaryIntent(
        date: Date,
        selection: FastIntentSelection?,
        autoTags: Set<FastSecondaryVirtueTag>,
        timeZone: TimeZone
    ) -> FastPrimaryIntent {
        if isRamadan(date: date, timeZone: timeZone) {
            return .ramadanObligatory
        }
        if let selection {
            return selection.primaryIntent
        }
        if !autoTags.isEmpty {
            return .voluntarySunnah
        }
        return .other
    }

    private static func autoTags(for date: Date, timeZone: TimeZone, includeShawwal: Bool) -> Set<FastSecondaryVirtueTag> {
        var tags: Set<FastSecondaryVirtueTag> = []
        let hijri = hijriComponents(for: date, timeZone: timeZone)
        let month = hijri.month ?? 0
        let day = hijri.day ?? 0

        if isMondayOrThursday(date, timeZone: timeZone) {
            tags.insert(.mondayThursday)
        }
        if [13, 14, 15].contains(day) {
            tags.insert(.whiteDays)
        }
        if month == 12, day == 9 {
            tags.insert(.arafah)
        }
        if month == 1, [9, 10, 11].contains(day) {
            tags.insert(.ashura)
        }
        if month == 12, (1...9).contains(day) {
            tags.insert(.dhulHijjahFirstNine)
        }
        if includeShawwal, month == 10 {
            tags.insert(.shawwalSix)
        }

        return tags
    }

    private static func isMondayOrThursday(_ date: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 2 || weekday == 5
    }

    private static func isRamadan(date: Date, timeZone: TimeZone) -> Bool {
        hijriComponents(for: date, timeZone: timeZone).month == 9
    }

    private static func isShawwal(date: Date, timeZone: TimeZone) -> Bool {
        hijriComponents(for: date, timeZone: timeZone).month == 10
    }

    private static func hijriComponents(for date: Date, timeZone: TimeZone) -> DateComponents {
        var calendar = Calendar(identifier: .islamicCivil)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
