import Foundation

enum ResolvedDayContextResolver {
    static func candidateContexts(
        tagResult: TagComputationResult,
        provenances: [ResolvedScheduledDateProvenance]
    ) -> [MorningContextType] {
        var contexts: [MorningContextType] = [.standard]
        let meaningfulProvenances = provenances.filter { $0.sourceOrigin != .defaultDailyPlan }
        switch tagResult.computedPrimaryIntent {
        case .ramadanObligatory, .kaffarahExpiation, .vowNadhr:
            contexts.append(.fasting)
        case .qadaMakeup:
            contexts.append(.qadaFast)
        case .voluntary:
            contexts.append(.sunnahFast)
        case .forbidden, .other:
            break
        }

        if meaningfulProvenances.contains(where: { $0.sourceOrigin == .defaultRamadan }) {
            contexts.append(.fasting)
        }
        if !tagResult.computedSecondaryTags.isEmpty {
            contexts.append(.specialDay)
        }
        return Array(NSOrderedSet(array: contexts).compactMap { $0 as? MorningContextType })
    }

    static func resolve(
        date: Date,
        provenances: [ResolvedScheduledDateProvenance],
        tagResult: TagComputationResult,
        defaultConfig: DefaultAlarmConfig,
        effectiveConfig: EffectiveDailyConfig,
        timeZone: TimeZone,
        wakeTime: Date
    ) -> ResolvedDayContext {
        let supportingTags = resolvedTags(
            date: date,
            provenances: provenances,
            tagResult: tagResult,
            defaultConfig: defaultConfig,
            effectiveConfig: effectiveConfig,
            timeZone: timeZone
        )
        let warnings = FastIntentEngine.warnings(for: date, timeZone: timeZone)
        let primaryContext: MorningContextType
        switch tagResult.computedPrimaryIntent {
        case .qadaMakeup:
            primaryContext = .qadaFast
        case .ramadanObligatory, .kaffarahExpiation, .vowNadhr:
            primaryContext = .fasting
        case .voluntary:
            primaryContext = tagResult.computedSecondaryTags.isEmpty ? .fasting : .sunnahFast
        case .forbidden, .other:
            primaryContext = .standard
        }

        var secondaryContexts: [MorningContextType] = []
        if wakeTime < date.addingTimeInterval(24 * 60 * 60),
           wakeTime < date.addingTimeInterval(6 * 60 * 60) {
            secondaryContexts.append(.suhoor)
        }
        if primaryContext == .standard,
           provenances.contains(where: { $0.sourceOrigin == .defaultRamadan }) == false,
           !warnings.isEmpty {
            secondaryContexts.append(.specialDay)
        }
        if !tagResult.computedSecondaryTags.isEmpty || !warnings.isEmpty {
            secondaryContexts.append(.specialDay)
        }

        return ResolvedDayContext(
            primaryContext: primaryContext,
            secondaryContexts: Array(NSOrderedSet(array: secondaryContexts).compactMap { $0 as? MorningContextType }),
            supportingTags: supportingTags,
            explanation: ContextExplanation(
                summary: contextSummary(primaryContext: primaryContext, supportingTags: supportingTags),
                details: contextDetails(
                    provenances: provenances,
                    defaultConfig: defaultConfig,
                    effectiveConfig: effectiveConfig,
                    supportingTags: supportingTags
                )
            )
        )
    }

    private static func contextSummary(
        primaryContext: MorningContextType,
        supportingTags: [DayTag]
    ) -> String {
        switch primaryContext {
        case .standard:
            return "Using the default morning plan."
        case .fasting:
            if supportingTags.contains(.ramadan) {
                return "Ramadan context is shaping today's wake."
            }
            return "A fasting context is shaping today's wake."
        case .qadaFast:
            return "A Qada plan is shaping today's wake."
        case .sunnahFast:
            return "A Sunnah observance is shaping today's wake."
        case .tahajjud:
            return "Tahajjud context is shaping today's wake."
        case .suhoor:
            return "Fasting context is shaping today's wake."
        case .jamaah:
            return "A jama'ah context is shaping today's wake."
        case .specialDay:
            return "A special-day context is shaping today's wake."
        }
    }

    private static func contextDetails(
        provenances: [ResolvedScheduledDateProvenance],
        defaultConfig: DefaultAlarmConfig,
        effectiveConfig: EffectiveDailyConfig,
        supportingTags: [DayTag]
    ) -> [String] {
        var details: [String] = []
        if provenances.contains(where: { $0.sourceOrigin == .defaultDailyPlan }) {
            details.append("The daily morning plan applies to this date.")
        }
        if effectiveConfig.hasOverrides {
            details.append("A date-specific override is active.")
        }
        for tag in supportingTags where tag != .dailyPlan && tag != .locationBased {
            details.append("\(tag.title) contributes labels and progress metadata.")
        }
        if defaultConfig.defaultSuhoorTimeMode == .fixedTime || effectiveConfig.suhoorTimeMode == .fixedTime {
            details.append("Fixed wake compatibility is being used for this date.")
        }
        return details
    }

    private static func resolvedTags(
        date: Date,
        provenances: [ResolvedScheduledDateProvenance],
        tagResult: TagComputationResult,
        defaultConfig: DefaultAlarmConfig,
        effectiveConfig: EffectiveDailyConfig,
        timeZone: TimeZone
    ) -> [DayTag] {
        var tags: [DayTag] = [.locationBased]

        if provenances.contains(where: { $0.sourceOrigin == .defaultDailyPlan }) {
            tags.append(.dailyPlan)
        }

        for provenance in provenances {
            switch provenance.sourceOrigin {
            case .defaultRamadan:
                tags.append(.ramadan)
            case .manualSingleDay:
                tags.append(.manualDay)
            case .manualGregorianRange:
                tags.append(.manualRange)
            case .islamicQuickAdd, .recurringIslamic, .migratedLegacyAlways, .migratedLegacyDateRange:
                break
            case .defaultDailyPlan:
                tags.append(.dailyPlan)
            }
        }

        switch tagResult.computedPrimaryIntent {
        case .ramadanObligatory:
            tags.append(.ramadan)
        case .qadaMakeup:
            tags.append(.qada)
        case .kaffarahExpiation:
            tags.append(.kaffarah)
        case .vowNadhr:
            tags.append(.vow)
        case .voluntary:
            tags.append(.voluntary)
        case .forbidden, .other:
            break
        }

        for tag in tagResult.computedSecondaryTags {
            switch tag {
            case .shawwalSix:
                tags.append(.shawwalSix)
            case .arafah:
                tags.append(.arafah)
            case .ashura:
                tags.append(.ashura)
            case .whiteDays:
                tags.append(.whiteDays)
            case .mondayThursday:
                tags.append(.mondayThursday)
            case .dhulHijjahFirstNine:
                tags.append(.dhulHijjahFirstNine)
            }
        }

        if tagResult.computedPrimaryIntent == .forbidden {
            let warnings = FastIntentEngine.warnings(for: date, timeZone: timeZone)
            if warnings.contains(.eidAlFitr) || warnings.contains(.eidAlAdha) {
                tags.append(.eid)
            }
            if warnings.contains(.tashreeq) {
                tags.append(.tashreeq)
            }
        }

        if defaultConfig.defaultSuhoorTimeMode == .fixedTime || effectiveConfig.suhoorTimeMode == .fixedTime {
            tags.append(.fixedTimeCompatibility)
        }

        return Array(NSOrderedSet(array: tags).compactMap { $0 as? DayTag })
    }
}
