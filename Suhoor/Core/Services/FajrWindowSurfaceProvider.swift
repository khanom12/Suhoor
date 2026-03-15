import Foundation

struct FajrWindowSurfaceProvider {
    func snapshot(
        period: FajrWindowPeriod,
        requestedOverlay: FajrWindowOverlay,
        selectedDateKey: String?,
        activeDays: [ActiveAlarmDay],
        overrideDateKeys: Set<String>,
        comparisonDay: (ActiveAlarmDay, FajrWindowOverlay) -> ActiveAlarmDay?,
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> FajrWindowSurfaceSnapshot {
        let points = Array(activeDays.prefix(period.dayCount)).map { day in
            buildPoint(
                for: day,
                overrideDateKeys: overrideDateKeys,
                comparisonDay: comparisonDay,
                timeZone: timeZone
            )
        }

        let availableOverlays = availableOverlays(for: points)
        let activeOverlay = availableOverlays.contains(requestedOverlay) ? requestedOverlay : .myWake
        let selectedPoint = selectedPoint(
            from: points,
            selectedDateKey: selectedDateKey,
            now: now,
            timeZone: timeZone
        )

        return FajrWindowSurfaceSnapshot(
            period: period,
            activeOverlay: activeOverlay,
            availableOverlays: availableOverlays,
            points: points,
            selectedDateKey: selectedPoint?.dateKey,
            selectedDay: selectedPoint.map { buildSelectedDaySnapshot(point: $0, overlay: activeOverlay) },
            compactInsight: compactInsight(for: points, period: period),
            primarySummary: buildPrimarySummary(points: points, period: period),
            supportSummaries: buildSupportSummaries(points: points, period: period),
            insightItems: buildInsightItems(points: points, period: period),
            actionItems: buildActionItems(selectedPoint: selectedPoint, period: period, now: now, timeZone: timeZone),
            chartDomain: chartDomain(for: points)
        )
    }

    private func buildPoint(
        for day: ActiveAlarmDay,
        overrideDateKeys: Set<String>,
        comparisonDay: (ActiveAlarmDay, FajrWindowOverlay) -> ActiveAlarmDay?,
        timeZone: TimeZone
    ) -> FajrWindowPoint {
        let lowerBoundaryDate: Date
        let boundaryTruth: FajrWindowBoundaryTruth

        // The current resolver stores a sunrise-derived proxy in prayerWindow.fajrEnd.
        if let fajrEnd = day.decisionLog.prayerWindow.fajrEnd {
            lowerBoundaryDate = fajrEnd
            boundaryTruth = .sunriseProxy
        } else if let boundaryDate = day.schedule.boundaryDate {
            lowerBoundaryDate = boundaryDate
            boundaryTruth = .supportedFallback
        } else {
            lowerBoundaryDate = day.schedule.fajrDate
            boundaryTruth = .supportedFallback
        }

        let saferWake = safeWake(for: day, lowerBoundaryDate: lowerBoundaryDate)
        let fastingWake = comparisonDay(day, .compareFasting)?.schedule.wakeDate
        let tahajjudWake = comparisonDay(day, .compareTahajjud)?.schedule.wakeDate
        let secondaryTitles = ProductSurfacePresentation.meaningfulSecondaryContextTitles(from: day.resolvedDayContext)
        let primaryMeaning = ProductSurfacePresentation.dayMeaningText(for: day, style: .wakeRow)
        let tags = Array(
            NSOrderedSet(
                array: ([primaryMeaning] + secondaryTitles + (overrideDateKeys.contains(day.dateKey) ? ["Adjusted"] : []))
                    .filter { !$0.isEmpty }
            )
        ).compactMap { $0 as? String }

        let isFastingContext = day.resolvedDayContext.primaryContext == .fasting
            || day.resolvedDayContext.primaryContext == .qadaFast
            || day.resolvedDayContext.primaryContext == .sunnahFast
            || day.resolvedDayContext.supportingTags.contains(.ramadan)
            || day.resolvedDayContext.supportingTags.contains(.qada)
            || day.resolvedDayContext.supportingTags.contains(.voluntary)

        let isTahajjudContext = day.resolvedDayContext.primaryContext == .tahajjud
            || day.resolvedDayContext.secondaryContexts.contains(.tahajjud)

        return FajrWindowPoint(
            date: day.date,
            dateKey: day.dateKey,
            shortLabel: shortLabel(for: day.date, timeZone: timeZone),
            mediumLabel: mediumLabel(for: day.date, timeZone: timeZone),
            longLabel: longLabel(for: day.date, timeZone: timeZone),
            fajrStart: day.decisionLog.prayerWindow.fajrStart,
            fajrEndOrBoundary: lowerBoundaryDate,
            boundaryTruth: boundaryTruth,
            primaryWake: day.schedule.wakeDate,
            saferWake: saferWake,
            fastingWake: distinctComparisonDate(primary: day.schedule.wakeDate, comparison: fastingWake),
            tahajjudWake: distinctComparisonDate(primary: day.schedule.wakeDate, comparison: tahajjudWake),
            fajrStartMinutes: minutesFromMidnight(for: day.decisionLog.prayerWindow.fajrStart, timeZone: timeZone),
            fajrEndOrBoundaryMinutes: minutesFromMidnight(for: lowerBoundaryDate, timeZone: timeZone),
            primaryWakeMinutes: minutesFromMidnight(for: day.schedule.wakeDate, timeZone: timeZone),
            saferWakeMinutes: minutesFromMidnight(for: saferWake, timeZone: timeZone),
            fastingWakeMinutes: distinctComparisonDate(primary: day.schedule.wakeDate, comparison: fastingWake)
                .map { minutesFromMidnight(for: $0, timeZone: timeZone) },
            tahajjudWakeMinutes: distinctComparisonDate(primary: day.schedule.wakeDate, comparison: tahajjudWake)
                .map { minutesFromMidnight(for: $0, timeZone: timeZone) },
            bufferBeforeBoundaryMinutes: Int(round(lowerBoundaryDate.timeIntervalSince(day.schedule.wakeDate) / 60)),
            isOverride: overrideDateKeys.contains(day.dateKey),
            isSpecialDay: day.resolvedDayContext.primaryContext != .standard || !secondaryTitles.isEmpty,
            isFastingContext: isFastingContext,
            isTahajjudContext: isTahajjudContext,
            contextTags: tags,
            relationText: ProductSurfacePresentation.wakeRelationText(
                delta: day.decisionLog.resolvedDelta,
                anchor: day.decisionLog.resolvedAnchor.type
            )
        )
    }

    private func safeWake(
        for day: ActiveAlarmDay,
        lowerBoundaryDate: Date
    ) -> Date {
        lowerBoundaryDate.addingTimeInterval(TimeInterval(-day.decisionLog.resolvedDelta.minutes * 60))
    }

    private func distinctComparisonDate(primary: Date, comparison: Date?) -> Date? {
        guard let comparison else { return nil }
        return abs(comparison.timeIntervalSince(primary)) >= 60 ? comparison : nil
    }

    private func availableOverlays(for points: [FajrWindowPoint]) -> [FajrWindowOverlay] {
        var overlays: [FajrWindowOverlay] = [.myWake, .compareSafe]
        if points.contains(where: { $0.fastingWake != nil }) {
            overlays.append(.compareFasting)
        }
        if points.contains(where: { $0.tahajjudWake != nil }) {
            overlays.append(.compareTahajjud)
        }
        return overlays
    }

    private func selectedPoint(
        from points: [FajrWindowPoint],
        selectedDateKey: String?,
        now: Date,
        timeZone: TimeZone
    ) -> FajrWindowPoint? {
        if let selectedDateKey,
           let selected = points.first(where: { $0.dateKey == selectedDateKey }) {
            return selected
        }

        let todayKey = DateHelpers.dayIdentifier(for: now, timeZone: timeZone)
        if let today = points.first(where: { $0.dateKey == todayKey }) {
            return today
        }
        return points.first
    }

    private func buildSelectedDaySnapshot(
        point: FajrWindowPoint,
        overlay: FajrWindowOverlay
    ) -> FajrWindowSelectedDaySnapshot {
        let primaryItems = [
            FajrWindowValueItem(
                id: "fajr-begins",
                label: "Fajr begins",
                value: TimeFormatters.timeFormatter.string(from: point.fajrStart),
                emphasis: .secondary
            ),
            FajrWindowValueItem(
                id: "fajr-boundary",
                label: point.boundaryTruth.boundaryLabel,
                value: TimeFormatters.timeFormatter.string(from: point.fajrEndOrBoundary),
                emphasis: .secondary
            ),
            FajrWindowValueItem(
                id: "my-wake",
                label: "Your wake",
                value: TimeFormatters.timeFormatter.string(from: point.primaryWake),
                emphasis: .primary
            ),
        ]

        var secondaryItems = [
            FajrWindowValueItem(
                id: "buffer",
                label: "Buffer before boundary",
                value: bufferText(minutes: point.bufferBeforeBoundaryMinutes),
                emphasis: .secondary
            )
        ]

        if let fastingWake = point.fastingWake {
            secondaryItems.append(
                FajrWindowValueItem(
                    id: "fasting-wake",
                    label: "Fasting wake",
                    value: TimeFormatters.timeFormatter.string(from: fastingWake),
                    emphasis: .secondary
                )
            )
        }

        if let tahajjudWake = point.tahajjudWake {
            secondaryItems.append(
                FajrWindowValueItem(
                    id: "tahajjud-wake",
                    label: "Tahajjud wake",
                    value: TimeFormatters.timeFormatter.string(from: tahajjudWake),
                    emphasis: .secondary
                )
            )
        }

        let comparisonItem = comparisonItem(for: point, overlay: overlay)
        let statusText: String?
        if point.isOverride {
            statusText = "Adjusted for this date"
        } else if point.isSpecialDay {
            statusText = point.contextTags.first
        } else {
            statusText = "Morning window"
        }

        return FajrWindowSelectedDaySnapshot(
            dateKey: point.dateKey,
            title: point.longLabel,
            boundaryTruth: point.boundaryTruth,
            statusText: statusText,
            primaryItems: primaryItems,
            secondaryItems: secondaryItems,
            comparisonItem: comparisonItem,
            contextTags: point.contextTags,
            explanationText: [point.relationText, point.boundaryTruth.explanationText]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        )
    }

    private func comparisonItem(
        for point: FajrWindowPoint,
        overlay: FajrWindowOverlay
    ) -> FajrWindowValueItem? {
        let label: String
        let value: Date?

        switch overlay {
        case .myWake:
            return nil
        case .compareSafe:
            label = "Safer comparison"
            value = point.saferWake
        case .compareFasting:
            label = "Fasting comparison"
            value = point.fastingWake
        case .compareTahajjud:
            label = "Tahajjud comparison"
            value = point.tahajjudWake
        }

        guard let value else { return nil }
        return FajrWindowValueItem(
            id: "comparison-\(overlay.rawValue)",
            label: label,
            value: TimeFormatters.timeFormatter.string(from: value),
            emphasis: .comparison
        )
    }

    private func compactInsight(for points: [FajrWindowPoint], period: FajrWindowPeriod) -> String {
        guard !points.isEmpty else {
            return "Your morning window will appear once Suhoor has upcoming resolved mornings."
        }

        let averageBuffer = Int(round(Double(points.map(\.bufferBeforeBoundaryMinutes).reduce(0, +)) / Double(points.count)))
        let overrideCount = points.filter(\.isOverride).count
        let fastingCount = points.filter(\.isFastingContext).count

        switch period {
        case .sevenDays:
            if let tightest = points.min(by: { $0.bufferBeforeBoundaryMinutes < $1.bufferBeforeBoundaryMinutes }),
               tightest.bufferBeforeBoundaryMinutes <= 20 {
                return "\(tightest.mediumLabel) is your tightest morning, with \(bufferText(minutes: tightest.bufferBeforeBoundaryMinutes)) before the boundary."
            }
            return "Your next week keeps about \(bufferText(minutes: averageBuffer)) between wake and the supported lower boundary."
        case .thirtyDays:
            if overrideCount > 0 {
                return "\(overrideCount) morning\(overrideCount == 1 ? "" : "s") in this view are adjusted away from your usual plan."
            }
            return "Across this month, your wake keeps roughly \(bufferText(minutes: averageBuffer)) before the supported lower boundary."
        case .oneYear:
            if fastingCount > 0 {
                return "\(fastingCount) mornings across the year carry a fasting context, while your main wake pattern stays centered on Fajr."
            }
            return "Across the year, your wake pattern shifts with the season instead of staying flat."
        }
    }

    private func buildPrimarySummary(
        points: [FajrWindowPoint],
        period: FajrWindowPeriod
    ) -> FajrWindowSummarySnapshot? {
        guard !points.isEmpty else { return nil }

        let buffers = points.map(\.bufferBeforeBoundaryMinutes)
        let averageBuffer = Int(round(Double(buffers.reduce(0, +)) / Double(buffers.count)))
        let smallestBuffer = buffers.min() ?? 0
        let earliestWake = points.min(by: { $0.primaryWake < $1.primaryWake })?.primaryWake
        let latestWake = points.max(by: { $0.primaryWake < $1.primaryWake })?.primaryWake

        let body: String
        switch period {
        case .sevenDays:
            body = "Your next mornings stay centered on Fajr, with the selected day showing exactly how your wake sits inside the supported window."
        case .thirtyDays:
            body = "This view shows how your usual wake holds up as Fajr moves through the month, without turning your mornings into a dashboard."
        case .oneYear:
            body = "This view turns the year into one strategic picture, so you can see when your wake stays steady and when the season starts to tighten."
        }

        var metrics = [
            FajrWindowMetric(id: "average-buffer", label: "Average buffer", value: bufferText(minutes: averageBuffer)),
            FajrWindowMetric(id: "tightest-buffer", label: "Tightest day", value: bufferText(minutes: smallestBuffer))
        ]

        if let earliestWake {
            metrics.append(
                FajrWindowMetric(
                    id: "earliest-wake",
                    label: "Earliest wake",
                    value: TimeFormatters.timeFormatter.string(from: earliestWake)
                )
            )
        }

        if let latestWake, period != .sevenDays {
            metrics.append(
                FajrWindowMetric(
                    id: "latest-wake",
                    label: "Latest wake",
                    value: TimeFormatters.timeFormatter.string(from: latestWake)
                )
            )
        }

        return FajrWindowSummarySnapshot(
            id: "primary-summary",
            title: period.summaryTitle,
            body: body,
            metrics: metrics
        )
    }

    private func buildSupportSummaries(
        points: [FajrWindowPoint],
        period: FajrWindowPeriod
    ) -> [FajrWindowSummarySnapshot] {
        guard !points.isEmpty else { return [] }

        let adjustedCount = points.filter(\.isOverride).count
        let specialCount = points.filter(\.isSpecialDay).count
        let earliestBoundary = points.min(by: { $0.fajrEndOrBoundary < $1.fajrEndOrBoundary })?.fajrEndOrBoundary
        let latestBoundary = points.max(by: { $0.fajrEndOrBoundary < $1.fajrEndOrBoundary })?.fajrEndOrBoundary

        var summaries: [FajrWindowSummarySnapshot] = []

        summaries.append(
            FajrWindowSummarySnapshot(
                id: "stability-summary",
                title: period == .oneYear ? "Seasonality" : "Wake stability",
                body: period == .oneYear
                    ? "The lower boundary moves through the year, which is why a wake that feels roomy in one season can feel much tighter in another."
                    : "A calm timeline still needs a grounded explanation, so this block keeps the month anchored in actual timing instead of vague trend language.",
                metrics: [
                    FajrWindowMetric(id: "adjusted-count", label: "Adjusted mornings", value: "\(adjustedCount)"),
                    FajrWindowMetric(id: "special-count", label: "Special contexts", value: "\(specialCount)"),
                    FajrWindowMetric(
                        id: "earliest-boundary",
                        label: "Earliest boundary",
                        value: earliestBoundary.map(TimeFormatters.timeFormatter.string(from:)) ?? "--"
                    ),
                    FajrWindowMetric(
                        id: "latest-boundary",
                        label: "Latest boundary",
                        value: latestBoundary.map(TimeFormatters.timeFormatter.string(from:)) ?? "--"
                    )
                ]
            )
        )

        if period == .oneYear, let earliestWake = points.min(by: { $0.primaryWake < $1.primaryWake })?.primaryWake {
            summaries.append(
                FajrWindowSummarySnapshot(
                    id: "year-strategy",
                    title: "Steadier strategy",
                    body: "If you want one wake that holds together more smoothly across the year, start near the earliest wake your current plan already reaches and treat later seasons as extra room rather than the baseline.",
                    metrics: [
                        FajrWindowMetric(
                            id: "steady-wake",
                            label: "A steadier fixed wake",
                            value: TimeFormatters.timeFormatter.string(from: earliestWake)
                        )
                    ]
                )
            )
        }

        return summaries
    }

    private func buildInsightItems(
        points: [FajrWindowPoint],
        period: FajrWindowPeriod
    ) -> [FajrWindowInsightItem] {
        var insights: [FajrWindowInsightItem] = []

        if let tightest = points.min(by: { $0.bufferBeforeBoundaryMinutes < $1.bufferBeforeBoundaryMinutes }) {
            insights.append(
                FajrWindowInsightItem(
                    id: "tightest-day",
                    title: "Tightest morning",
                    detail: "\(tightest.mediumLabel) leaves \(bufferText(minutes: tightest.bufferBeforeBoundaryMinutes)) before the supported lower boundary."
                )
            )
        }

        if let adjusted = points.first(where: \.isOverride) {
            insights.append(
                FajrWindowInsightItem(
                    id: "adjusted-day",
                    title: "Adjusted morning",
                    detail: "\(adjusted.mediumLabel) is using a date-specific change instead of the usual morning plan."
                )
            )
        }

        if let fasting = points.first(where: { $0.fastingWake != nil || $0.isFastingContext }) {
            insights.append(
                FajrWindowInsightItem(
                    id: "fasting-context",
                    title: period == .oneYear ? "Fasting context stays secondary" : "Fasting context",
                    detail: "\(fasting.mediumLabel) shows how fasting-related meaning can stay visible without taking over the whole chart."
                )
            )
        }

        return Array(insights.prefix(3))
    }

    private func buildActionItems(
        selectedPoint: FajrWindowPoint?,
        period: FajrWindowPeriod,
        now: Date,
        timeZone: TimeZone
    ) -> [FajrWindowActionItem] {
        var items: [FajrWindowActionItem] = []

        if let selectedPoint {
            let todayKey = DateHelpers.dayIdentifier(for: now, timeZone: timeZone)
            let tomorrow = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: DateHelpers.startOfDay(now, in: timeZone))
            let tomorrowKey = tomorrow.map { DateHelpers.dayIdentifier(for: $0, timeZone: timeZone) }

            let title: String
            if selectedPoint.dateKey == tomorrowKey {
                title = "Edit tomorrow"
            } else if selectedPoint.dateKey == todayKey {
                title = "Edit this morning"
            } else {
                title = "Open selected morning"
            }

            items.append(
                FajrWindowActionItem(
                    id: "selected-day",
                    title: title,
                    subtitle: "Keep your day-detail flow intact.",
                    intent: .openSelectedMorning(dateKey: selectedPoint.dateKey)
                )
            )
        }

        items.append(
            FajrWindowActionItem(
                id: "default-plan",
                title: period == .oneYear ? "Adjust default wake strategy" : "Adjust default morning plan",
                subtitle: "Update the daily wake relation that shapes most mornings.",
                intent: .openDefaultMorningPlan
            )
        )

        return items
    }

    private func chartDomain(for points: [FajrWindowPoint]) -> ClosedRange<Int> {
        let values = points.flatMap { point in
            [
                point.fajrStartMinutes,
                point.fajrEndOrBoundaryMinutes,
                point.primaryWakeMinutes,
                point.saferWakeMinutes,
                point.fastingWakeMinutes,
                point.tahajjudWakeMinutes
            ].compactMap { $0 }
        }

        guard let minimum = values.min(), let maximum = values.max() else {
            return 240...420
        }

        let lower = max(0, ((minimum / 15) * 15) - 15)
        let upper = min((24 * 60) - 1, (((maximum + 14) / 15) * 15) + 15)
        return lower...max(lower + 15, upper)
    }

    private func bufferText(minutes: Int) -> String {
        if minutes <= 0 {
            return "No buffer"
        }
        return "\(minutes) min"
    }

    private func minutesFromMidnight(for date: Date, timeZone: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: date)
        return max(0, Int(round(date.timeIntervalSince(start) / 60)))
    }

    private func shortLabel(for date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter.string(from: date)
    }

    private func mediumLabel(for date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter.string(from: date)
    }

    private func longLabel(for date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.timeZone = timeZone
        formatter.locale = .current
        return formatter.string(from: date)
    }
}
