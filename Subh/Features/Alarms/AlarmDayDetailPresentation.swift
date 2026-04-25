import Foundation

struct AlarmDayDetailPresentation: Equatable {
    struct WakeSummary: Equatable {
        let title: String
        let detail: String?

        var combinedText: String {
            guard let detail, detail.isEmpty == false, detail != title else { return title }
            return "\(title), \(detail)"
        }
    }

    struct WhySection: Equatable {
        let statusTitle: String
        let rows: [WakeReasonRow]
    }

    let heroPurposeText: String
    let dayPurposeTitle: String
    let dayPurposeDetails: String?
    let heroSummaryText: String
    let heroSummaryDetailText: String?
    let adjustStatusText: String
    let why: WhySection
    let advancedSourceText: String
    let accessibilitySummary: String

    init(
        day: ActiveAlarmDay,
        computedIntentSelection: FastIntentSelection,
        warnings: [FastWarning],
        draftSelection: DayWakeRuleSelection,
        draftAnchor: WakeAnchorType,
        draftDeltaMinutes: Int,
        draftFixedWakeMinutes: Int
    ) {
        let currentSummary = Self.currentWakeSummary(
            for: day,
            draftSelection: draftSelection,
            draftAnchor: draftAnchor,
            draftDeltaMinutes: draftDeltaMinutes,
            draftFixedWakeMinutes: draftFixedWakeMinutes
        )
        let usualPlanSummary = Self.usualPlanSummary(for: day)
        let isAdjusted = draftSelection != .defaultPlan

        heroPurposeText = ProductSurfacePresentation.dayMeaningText(for: day, style: .wakeRow)
        dayPurposeTitle = Self.dayPurposePrimaryTitle(
            for: day,
            selection: computedIntentSelection
        )
        dayPurposeDetails = Self.dayPurposeDetails(
            selection: computedIntentSelection,
            includesTahajjud: day.effectiveConfig.tahajjudRefinement
        )
        heroSummaryText = currentSummary.combinedText
        heroSummaryDetailText = Self.heroSecondaryText(
            day: day,
            draftSelection: draftSelection
        )
        adjustStatusText = isAdjusted ? "Adjusted for this date" : "Using your usual plan"
        why = Self.whySection(
            for: day,
            currentSummary: currentSummary,
            usualPlanSummary: usualPlanSummary,
            draftSelection: draftSelection
        )
        advancedSourceText = Self.advancedSourceText(for: day)
        accessibilitySummary = Self.accessibilitySummary(
            day: day,
            heroPurposeText: heroPurposeText,
            heroSummaryText: heroSummaryText,
            heroSummaryDetailText: heroSummaryDetailText,
            warnings: warnings
        )
    }

    private static func heroSecondaryText(
        day: ActiveAlarmDay,
        draftSelection: DayWakeRuleSelection
    ) -> String? {
        if day.effectiveConfig.skipDay {
            return "Wake and extra morning cues are off for this date."
        }
        if day.decisionLog.latestWakeCapApplied {
            return "Moved earlier by your latest wake"
        }
        if draftSelection != .defaultPlan {
            return "Adjusted for this date"
        }
        return nil
    }

    private static func whySection(
        for day: ActiveAlarmDay,
        currentSummary: WakeSummary,
        usualPlanSummary: WakeSummary,
        draftSelection: DayWakeRuleSelection
    ) -> WhySection {
        let isSkippingDay = day.effectiveConfig.skipDay
        let isAdjusted = draftSelection != .defaultPlan

        var rows: [WakeReasonRow] = []

        if isSkippingDay {
            rows.append(
                WakeReasonRow(
                    id: "current",
                    title: "Current",
                    detail: "No wake on this date."
                )
            )
            rows.append(
                WakeReasonRow(
                    id: "usual-plan",
                    title: "Usual plan",
                    detail: usualPlanSummary.combinedText
                )
            )
        } else if isAdjusted {
            rows.append(
                WakeReasonRow(
                    id: "current",
                    title: "Current",
                    detail: currentSummary.combinedText
                )
            )
            rows.append(
                WakeReasonRow(
                    id: "usual-plan",
                    title: "Usual plan",
                    detail: usualPlanSummary.combinedText
                )
            )
        } else {
            rows.append(
                WakeReasonRow(
                    id: "usual-plan",
                    title: "Usual plan",
                    detail: usualPlanSummary.combinedText
                )
            )
        }

        if let latestWakeCap = day.decisionLog.latestWakeCapMinutesFromMidnight {
            rows.append(
                WakeReasonRow(
                    id: "latest-wake",
                    title: "Latest wake limit",
                    detail: "No later than \(SettingsSummaryFormatter.timeText(minutesFromMidnight: latestWakeCap))"
                )
            )
        }

        if day.decisionLog.latestWakeCapApplied {
            rows.append(
                WakeReasonRow(
                    id: "latest-wake-applied",
                    title: "Moved earlier",
                    detail: "Your current wake would have landed later, so your latest wake pulled it earlier."
                )
            )
        }

        let tags = Set(day.resolvedDayContext.supportingTags)
        if tags.contains(.qada) || day.resolvedDayContext.primaryContext == .qadaFast {
            rows.append(
                WakeReasonRow(
                    id: "day-purpose-qada",
                    title: "Day purpose",
                    detail: "This date is planned as Qadāʾ."
                )
            )
        } else if tags.contains(.ramadan) {
            rows.append(
                WakeReasonRow(
                    id: "day-purpose-ramadan",
                    title: "Day purpose",
                    detail: "This date is planned as Ramadan."
                )
            )
        } else if day.resolvedDayContext.primaryContext == .sunnahFast
            || day.resolvedDayContext.primaryContext == .fasting
            || day.resolvedDayContext.primaryContext == .suhoor {
            rows.append(
                WakeReasonRow(
                    id: "day-purpose-fasting",
                    title: "Day purpose",
                    detail: "This date is planned as a fast."
                )
            )
        }

        if day.resolvedDayContext.primaryContext == .tahajjud || day.effectiveConfig.tahajjudRefinement {
            rows.append(
                WakeReasonRow(
                    id: "day-purpose-tahajjud",
                    title: "Tahajjud",
                    detail: "This date includes Tahajjud refinement."
                )
            )
        }

        let statusTitle: String
        if isSkippingDay {
            statusTitle = "No wake on this date"
        } else if isAdjusted {
            statusTitle = "This date is adjusted"
        } else {
            statusTitle = "Using your usual morning plan"
        }

        return WhySection(
            statusTitle: statusTitle,
            rows: rows
        )
    }

    private static func currentWakeSummary(
        for day: ActiveAlarmDay,
        draftSelection: DayWakeRuleSelection,
        draftAnchor: WakeAnchorType,
        draftDeltaMinutes: Int,
        draftFixedWakeMinutes: Int
    ) -> WakeSummary {
        if day.effectiveConfig.skipDay {
            return WakeSummary(title: "No wake on this date", detail: nil)
        }

        switch draftSelection {
        case .defaultPlan:
            return resolvedWakeSummary(for: day)
        case .preFajr:
            return WakeSummary(
                title: "Before Fajr",
                detail: ProductSurfacePresentation.wakeOffsetText(
                    state: .preFajr,
                    anchor: .fajrStart,
                    deltaMinutes: draftDeltaMinutes,
                    fixedTimeMinutes: nil
                )
            )
        case .inFajr:
            return WakeSummary(
                title: "During Fajr",
                detail: ProductSurfacePresentation.wakeOffsetText(
                    state: .inFajr,
                    anchor: draftAnchor == .fajrEnd ? .fajrEnd : .fajrStart,
                    deltaMinutes: draftDeltaMinutes,
                    fixedTimeMinutes: nil
                )
            )
        case .postFajr:
            return WakeSummary(
                title: "After Fajr",
                detail: ProductSurfacePresentation.wakeOffsetText(
                    state: .postFajr,
                    anchor: .fajrEnd,
                    deltaMinutes: draftDeltaMinutes,
                    fixedTimeMinutes: nil
                )
            )
        case .fixedWake:
            return WakeSummary(
                title: "Fixed wake",
                detail: SettingsSummaryFormatter.timeText(minutesFromMidnight: draftFixedWakeMinutes)
            )
        }
    }

    private static func resolvedWakeSummary(for day: ActiveAlarmDay) -> WakeSummary {
        let decision = day.decisionLog

        if decision.plannedWakeState == .fixedWake {
            return WakeSummary(title: "Fixed wake", detail: nil)
        }

        return WakeSummary(
            title: ProductSurfacePresentation.wakeStateLabel(for: day),
            detail: ProductSurfacePresentation.wakeOffsetText(for: day)
        )
    }

    private static func usualPlanSummary(for day: ActiveAlarmDay) -> WakeSummary {
        let rule = day.effectiveConfig.defaultWakeRule
        let title: String
        switch rule.state {
        case .preFajr:
            title = "Before Fajr"
        case .inFajr:
            title = "During Fajr"
        case .postFajr:
            title = "After Fajr"
        case .fixedWake:
            title = "Fixed wake"
        }

        let detail: String?
        if rule.state == .fixedWake {
            detail = rule.fixedWakeTimeMinutesFromMidnight.map { minutes in
                Self.fixedTimeText(minutesFromMidnight: minutes)
            }
        } else {
            detail = ProductSurfacePresentation.wakeOffsetText(
                state: rule.state,
                anchor: rule.anchorType ?? .fajrStart,
                deltaMinutes: rule.deltaMinutes,
                fixedTimeMinutes: rule.fixedWakeTimeMinutesFromMidnight
            )
        }

        return WakeSummary(title: title, detail: detail)
    }

    private static func dayPurposePrimaryTitle(
        for day: ActiveAlarmDay,
        selection: FastIntentSelection
    ) -> String {
        let primary = selection.primaryIntent
        if primary != .other {
            return primary.about.title
        }
        if day.resolvedDayContext.primaryContext == .tahajjud || day.effectiveConfig.tahajjudRefinement {
            return "Tahajjud"
        }
        return ProductSurfacePresentation.ordinaryDaySummaryText
    }

    private static func dayPurposeDetails(
        selection: FastIntentSelection,
        includesTahajjud: Bool
    ) -> String? {
        var details = selection.secondaryTags
            .sorted { $0.title < $1.title }
            .map(\.title)

        if includesTahajjud {
            details.append("Tahajjud")
        }

        guard details.isEmpty == false else { return nil }
        return details.joined(separator: " • ")
    }

    private static func advancedSourceText(for day: ActiveAlarmDay) -> String {
        let source = ProductSurfacePresentation.wakeSourceSummaryText(for: day)

        return source
            .replacingOccurrences(
                of: "Provided by your daily morning plan",
                with: "Based on your usual morning plan"
            )
            .replacingOccurrences(
                of: "Usual morning plan",
                with: "Based on your usual morning plan"
            )
    }

    private static func accessibilitySummary(
        day: ActiveAlarmDay,
        heroPurposeText: String,
        heroSummaryText: String,
        heroSummaryDetailText: String?,
        warnings: [FastWarning]
    ) -> String {
        var parts = [
            "Wake.",
            "Day purpose: \(heroPurposeText).",
            "\(heroSummaryText).",
            Strings.AlarmsTab.fajrTime(TimeFormatters.timeFormatter.string(from: day.schedule.fajrDate)) + "."
        ]

        if let heroSummaryDetailText {
            parts.append("\(heroSummaryDetailText).")
        }

        if warnings.isEmpty == false {
            parts.append("Warnings: \(warnings.map(\.title).joined(separator: ", ")).")
        }

        return parts.joined(separator: " ")
    }

    private static func fixedTimeText(minutesFromMidnight: Int) -> String {
        let startOfDay = Calendar(identifier: .gregorian).startOfDay(for: Date())
        let date = Calendar(identifier: .gregorian).date(byAdding: .minute, value: minutesFromMidnight, to: startOfDay) ?? startOfDay
        return TimeFormatters.timeFormatter.string(from: date)
    }
}
