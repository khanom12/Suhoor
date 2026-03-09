import Foundation

enum WakeRowDeleteCapability: Equatable {
    case ramadan
    case explicitOneOff
    case series
    case mixed
}

enum WakeRowActionResolver {
    static func makeEntry(
        activeDay: ActiveAlarmDay,
        overrideDateKeys: Set<String>
    ) -> WakeRowEntry {
        let secondaryTags = FastIntentEngine.displaySecondaryTags(activeDay.tagResult.computedSecondaryTags)
        let provenances = activeDay.provenances
        let hasExplicit = provenances.contains(where: \.isExplicitOneOff)
        let nonExplicit = provenances.filter { !$0.isExplicitOneOff }
        let deleteCapability: WakeRowDeleteCapability
        if activeDay.isImplicitRamadan {
            deleteCapability = .ramadan
        } else if activeDay.isExplicitOneOff && nonExplicit.isEmpty {
            deleteCapability = .explicitOneOff
        } else if hasExplicit && !nonExplicit.isEmpty {
            deleteCapability = .mixed
        } else {
            deleteCapability = .series
        }

        return WakeRowEntry(
            activeDay: activeDay,
            secondaryTags: secondaryTags,
            deleteCapability: deleteCapability,
            stoppableProvenances: uniqueStoppableProvenances(from: provenances),
            excludableProvenances: nonExplicit,
            hasExplicitOneOff: hasExplicit,
            hasDayOverride: overrideDateKeys.contains(activeDay.dateKey),
            rowPresentation: ProductSurfacePresentation.scheduleRowPresentation(
                for: activeDay,
                hasDayOverride: overrideDateKeys.contains(activeDay.dateKey)
            )
        )
    }

    static func suppressionScope(for provenance: ResolvedScheduledDateProvenance) -> SuppressionScope {
        if let groupID = provenance.groupID {
            return .groupID(groupID)
        }
        return .sourceID(provenance.sourceID)
    }

    private static func uniqueStoppableProvenances(
        from provenances: [ResolvedScheduledDateProvenance]
    ) -> [ResolvedScheduledDateProvenance] {
        var seen = Set<String>()
        return provenances.filter { provenance in
            guard provenance.canStopSeries else { return false }
            let key = "\(provenance.groupID?.uuidString ?? provenance.sourceID.uuidString)-\(provenance.stopSeriesLabel ?? "")"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
}

struct WakeRowEntry: Identifiable {
    let activeDay: ActiveAlarmDay
    let secondaryTags: [FastSecondaryVirtueTag]
    let deleteCapability: WakeRowDeleteCapability
    let stoppableProvenances: [ResolvedScheduledDateProvenance]
    let excludableProvenances: [ResolvedScheduledDateProvenance]
    let hasExplicitOneOff: Bool
    let hasDayOverride: Bool
    let rowPresentation: ScheduleRowPresentation

    var schedule: DaySchedule { activeDay.schedule }
    var config: EffectiveDailyConfig { activeDay.effectiveConfig }
    var primaryIntent: FastPrimaryIntent { activeDay.tagResult.computedPrimaryIntent }
    var isEnabled: Bool { !config.skipDay && config.hasAnyEnabled }
    var primaryTimeDate: Date { schedule.wakeDate }
    var id: String { activeDay.dateKey }

    func matches(filter: WakeTagFilter) -> Bool {
        guard filter.isActive else { return true }
        return filter.matches(
            entryPrimaryIntent: primaryIntent,
            entrySecondaryTags: secondaryTags
        )
    }
}
