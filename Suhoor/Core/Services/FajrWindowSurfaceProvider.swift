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
        let dataset = buildDataset(
            period: period,
            activeDays: activeDays,
            overrideDateKeys: overrideDateKeys,
            timeZone: timeZone
        )
        let overlays = [FajrWindowOverlay.compareFasting, .compareTahajjud].compactMap { overlay in
            buildOverlaySeries(
                period: period,
                overlay: overlay,
                activeDays: activeDays,
                comparisonDay: comparisonDay,
                timeZone: timeZone
            )
        }

        return surfaceSnapshot(
            dataset: dataset,
            requestedOverlay: requestedOverlay,
            selectedDateKey: selectedDateKey,
            overlaySeries: overlays,
            now: now,
            timeZone: timeZone
        )
    }

    func buildDataset(
        period: FajrWindowPeriod,
        activeDays: [ActiveAlarmDay],
        overrideDateKeys: Set<String>,
        timeZone: TimeZone = .current
    ) -> FajrWindowDataset {
        let days = Array(activeDays.prefix(period.dayCount))
        let formatters = LabelFormatterBundle(timeZone: timeZone)
        let rows = days.enumerated().map { index, day in
            buildDatasetRow(
                for: day,
                ordinal: index,
                overrideDateKeys: overrideDateKeys,
                formatters: formatters,
                timeZone: timeZone
            )
        }

        return FajrWindowDataset(
            period: period,
            rows: rows,
            renderDateKeys: renderDateKeys(for: rows, period: period, timeZone: timeZone),
            compactInsight: compactInsight(for: rows, period: period),
            primarySummary: buildPrimarySummary(rows: rows, period: period),
            supportSummaries: buildSupportSummaries(rows: rows, period: period),
            insightItems: buildInsightItems(rows: rows, period: period),
            xAxisLabels: xAxisLabels(for: rows, period: period)
        )
    }

    func buildOverlaySeries(
        period: FajrWindowPeriod,
        overlay: FajrWindowOverlay,
        activeDays: [ActiveAlarmDay],
        comparisonDay: (ActiveAlarmDay, FajrWindowOverlay) -> ActiveAlarmDay?,
        timeZone: TimeZone = .current
    ) -> FajrWindowOverlaySeries? {
        guard overlay == .compareFasting || overlay == .compareTahajjud else {
            return nil
        }

        var valuesByDateKey: [String: FajrWindowOverlayValue] = [:]
        for day in Array(activeDays.prefix(period.dayCount)) {
            guard let comparison = comparisonDay(day, overlay),
                  let distinctWake = distinctComparisonDate(
                    primary: day.schedule.wakeDate,
                    comparison: comparison.schedule.wakeDate
                  ) else {
                continue
            }

            valuesByDateKey[day.dateKey] = FajrWindowOverlayValue(
                wake: distinctWake,
                wakeMinutes: minutesFromMidnight(for: distinctWake, timeZone: timeZone)
            )
        }

        guard valuesByDateKey.isEmpty == false else { return nil }
        return FajrWindowOverlaySeries(overlay: overlay, valuesByDateKey: valuesByDateKey)
    }

    func surfaceSnapshot(
        dataset: FajrWindowDataset,
        requestedOverlay: FajrWindowOverlay,
        selectedDateKey: String?,
        overlaySeries: [FajrWindowOverlaySeries],
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> FajrWindowSurfaceSnapshot {
        let overlayLookup = Dictionary(uniqueKeysWithValues: overlaySeries.map { ($0.overlay, $0) })
        let availableOverlays = availableOverlays(with: overlayLookup)
        let activeOverlay = availableOverlays.contains(requestedOverlay) ? requestedOverlay : .myWake
        let points = projectedPoints(rows: dataset.rows, overlayLookup: overlayLookup)
        let selectedPoint = selectedPoint(
            from: points,
            selectedDateKey: selectedDateKey,
            now: now,
            timeZone: timeZone
        )

        return FajrWindowSurfaceSnapshot(
            period: dataset.period,
            activeOverlay: activeOverlay,
            availableOverlays: availableOverlays,
            chart: chartSnapshot(
                period: dataset.period,
                activeOverlay: activeOverlay,
                points: points,
                renderDateKeys: dataset.renderDateKeys,
                selectedDateKey: selectedPoint?.dateKey,
                xAxisLabels: dataset.xAxisLabels
            ),
            selectedDay: selectedPoint.map { buildSelectedDaySnapshot(point: $0, overlay: activeOverlay) },
            compactInsight: dataset.compactInsight,
            primarySummary: dataset.primarySummary,
            supportSummaries: dataset.supportSummaries,
            insightItems: dataset.insightItems,
            actionItems: buildActionItems(
                selectedPoint: selectedPoint,
                period: dataset.period,
                now: now,
                timeZone: timeZone
            )
        )
    }

    func compactSnapshot(
        dataset: FajrWindowDataset,
        selectedDateKey: String? = nil,
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> FajrWindowCompactSnapshot {
        let points = projectedPoints(rows: dataset.rows, overlayLookup: [:])
        let selectedPoint = selectedPoint(
            from: points,
            selectedDateKey: selectedDateKey,
            now: now,
            timeZone: timeZone
        )

        return FajrWindowCompactSnapshot(
            period: dataset.period,
            chart: chartSnapshot(
                period: dataset.period,
                activeOverlay: .myWake,
                points: points,
                renderDateKeys: dataset.renderDateKeys,
                selectedDateKey: selectedPoint?.dateKey,
                xAxisLabels: dataset.xAxisLabels
            ),
            compactInsight: dataset.compactInsight
        )
    }

    private func buildDatasetRow(
        for day: ActiveAlarmDay,
        ordinal: Int,
        overrideDateKeys: Set<String>,
        formatters: LabelFormatterBundle,
        timeZone: TimeZone
    ) -> FajrWindowDatasetRow {
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

        return FajrWindowDatasetRow(
            dayOrdinal: ordinal,
            date: day.date,
            dateKey: day.dateKey,
            shortLabel: formatters.short.string(from: day.date),
            mediumLabel: formatters.medium.string(from: day.date),
            longLabel: formatters.long.string(from: day.date),
            monthLabel: formatters.month.string(from: day.date),
            fajrStart: day.decisionLog.prayerWindow.fajrStart,
            fajrEndOrBoundary: lowerBoundaryDate,
            boundaryTruth: boundaryTruth,
            primaryWake: day.schedule.wakeDate,
            saferWake: saferWake,
            fajrStartMinutes: minutesFromMidnight(for: day.decisionLog.prayerWindow.fajrStart, timeZone: timeZone),
            fajrEndOrBoundaryMinutes: minutesFromMidnight(for: lowerBoundaryDate, timeZone: timeZone),
            primaryWakeMinutes: minutesFromMidnight(for: day.schedule.wakeDate, timeZone: timeZone),
            saferWakeMinutes: minutesFromMidnight(for: saferWake, timeZone: timeZone),
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

    private func projectedPoints(
        rows: [FajrWindowDatasetRow],
        overlayLookup: [FajrWindowOverlay: FajrWindowOverlaySeries]
    ) -> [FajrWindowPoint] {
        rows.map { row in
            let fastingValue = overlayLookup[.compareFasting]?.valuesByDateKey[row.dateKey]
            let tahajjudValue = overlayLookup[.compareTahajjud]?.valuesByDateKey[row.dateKey]

            return FajrWindowPoint(
                dayOrdinal: row.dayOrdinal,
                date: row.date,
                dateKey: row.dateKey,
                shortLabel: row.shortLabel,
                mediumLabel: row.mediumLabel,
                longLabel: row.longLabel,
                fajrStart: row.fajrStart,
                fajrEndOrBoundary: row.fajrEndOrBoundary,
                boundaryTruth: row.boundaryTruth,
                primaryWake: row.primaryWake,
                saferWake: row.saferWake,
                fastingWake: fastingValue?.wake,
                tahajjudWake: tahajjudValue?.wake,
                fajrStartMinutes: row.fajrStartMinutes,
                fajrEndOrBoundaryMinutes: row.fajrEndOrBoundaryMinutes,
                primaryWakeMinutes: row.primaryWakeMinutes,
                saferWakeMinutes: row.saferWakeMinutes,
                fastingWakeMinutes: fastingValue?.wakeMinutes,
                tahajjudWakeMinutes: tahajjudValue?.wakeMinutes,
                bufferBeforeBoundaryMinutes: row.bufferBeforeBoundaryMinutes,
                isOverride: row.isOverride,
                isSpecialDay: row.isSpecialDay,
                isFastingContext: row.isFastingContext,
                isTahajjudContext: row.isTahajjudContext,
                contextTags: row.contextTags,
                relationText: row.relationText
            )
        }
    }

    private func chartSnapshot(
        period: FajrWindowPeriod,
        activeOverlay: FajrWindowOverlay,
        points: [FajrWindowPoint],
        renderDateKeys: [String],
        selectedDateKey: String?,
        xAxisLabels: [FajrWindowAxisLabel]
    ) -> FajrWindowChartSnapshot {
        let renderDateKeySet = Set(renderDateKeys)
        let renderPoints = points.filter { renderDateKeySet.contains($0.dateKey) }
        let domain = chartDomain(for: points)

        return FajrWindowChartSnapshot(
            period: period,
            activeOverlay: activeOverlay,
            points: points,
            renderPoints: renderPoints.isEmpty ? points : renderPoints,
            selectedDateKey: selectedDateKey,
            chartDomain: domain,
            xAxisLabels: xAxisLabels,
            yTicks: chartTicks(for: domain)
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

    private func availableOverlays(
        with overlayLookup: [FajrWindowOverlay: FajrWindowOverlaySeries]
    ) -> [FajrWindowOverlay] {
        var overlays: [FajrWindowOverlay] = [.myWake, .compareSafe]
        if overlayLookup[.compareFasting]?.isAvailable == true {
            overlays.append(.compareFasting)
        }
        if overlayLookup[.compareTahajjud]?.isAvailable == true {
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

    private func compactInsight(for rows: [FajrWindowDatasetRow], period: FajrWindowPeriod) -> String {
        guard !rows.isEmpty else {
            return "Your morning window will appear once Suhoor has upcoming resolved mornings."
        }

        let averageBuffer = Int(round(Double(rows.map(\.bufferBeforeBoundaryMinutes).reduce(0, +)) / Double(rows.count)))
        let overrideCount = rows.filter(\.isOverride).count
        let fastingCount = rows.filter(\.isFastingContext).count

        switch period {
        case .sevenDays:
            if let tightest = rows.min(by: { $0.bufferBeforeBoundaryMinutes < $1.bufferBeforeBoundaryMinutes }),
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
        rows: [FajrWindowDatasetRow],
        period: FajrWindowPeriod
    ) -> FajrWindowSummarySnapshot? {
        guard !rows.isEmpty else { return nil }

        let buffers = rows.map(\.bufferBeforeBoundaryMinutes)
        let averageBuffer = Int(round(Double(buffers.reduce(0, +)) / Double(buffers.count)))
        let smallestBuffer = buffers.min() ?? 0
        let earliestWake = rows.min(by: { $0.primaryWake < $1.primaryWake })?.primaryWake
        let latestWake = rows.max(by: { $0.primaryWake < $1.primaryWake })?.primaryWake

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
        rows: [FajrWindowDatasetRow],
        period: FajrWindowPeriod
    ) -> [FajrWindowSummarySnapshot] {
        guard !rows.isEmpty else { return [] }

        let adjustedCount = rows.filter(\.isOverride).count
        let specialCount = rows.filter(\.isSpecialDay).count
        let earliestBoundary = rows.min(by: { $0.fajrEndOrBoundary < $1.fajrEndOrBoundary })?.fajrEndOrBoundary
        let latestBoundary = rows.max(by: { $0.fajrEndOrBoundary < $1.fajrEndOrBoundary })?.fajrEndOrBoundary

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

        if period == .oneYear, let earliestWake = rows.min(by: { $0.primaryWake < $1.primaryWake })?.primaryWake {
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
        rows: [FajrWindowDatasetRow],
        period: FajrWindowPeriod
    ) -> [FajrWindowInsightItem] {
        var insights: [FajrWindowInsightItem] = []

        if let tightest = rows.min(by: { $0.bufferBeforeBoundaryMinutes < $1.bufferBeforeBoundaryMinutes }) {
            insights.append(
                FajrWindowInsightItem(
                    id: "tightest-day",
                    title: "Tightest morning",
                    detail: "\(tightest.mediumLabel) leaves \(bufferText(minutes: tightest.bufferBeforeBoundaryMinutes)) before the supported lower boundary."
                )
            )
        }

        if let adjusted = rows.first(where: \.isOverride) {
            insights.append(
                FajrWindowInsightItem(
                    id: "adjusted-day",
                    title: "Adjusted morning",
                    detail: "\(adjusted.mediumLabel) is using a date-specific change instead of the usual morning plan."
                )
            )
        }

        if let fasting = rows.first(where: \.isFastingContext) {
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

    private func chartTicks(for domain: ClosedRange<Int>) -> [FajrWindowChartTick] {
        let start = (domain.lowerBound / 60) * 60
        let end = ((domain.upperBound + 59) / 60) * 60
        var ticks: [FajrWindowChartTick] = []
        var current = start
        while current <= end {
            ticks.append(FajrWindowChartTick(minutes: current, label: timeLabel(for: current)))
            current += 60
        }

        if ticks.isEmpty {
            return [
                FajrWindowChartTick(minutes: domain.lowerBound, label: timeLabel(for: domain.lowerBound)),
                FajrWindowChartTick(minutes: domain.upperBound, label: timeLabel(for: domain.upperBound))
            ]
        }
        return ticks
    }

    private func xAxisLabels(
        for rows: [FajrWindowDatasetRow],
        period: FajrWindowPeriod
    ) -> [FajrWindowAxisLabel] {
        switch period {
        case .sevenDays:
            return rows.map { row in
                FajrWindowAxisLabel(dateKey: row.dateKey, title: row.shortLabel, dayOrdinal: row.dayOrdinal)
            }
        case .thirtyDays:
            let stride = max(1, rows.count / 5)
            return rows.enumerated().compactMap { index, row in
                guard index == 0 || index == rows.count - 1 || index % stride == 0 else { return nil }
                return FajrWindowAxisLabel(dateKey: row.dateKey, title: row.mediumLabel, dayOrdinal: row.dayOrdinal)
            }
        case .oneYear:
            var labels: [FajrWindowAxisLabel] = []
            var previousLabel: String?
            for row in rows {
                guard row.monthLabel != previousLabel else { continue }
                labels.append(FajrWindowAxisLabel(dateKey: row.dateKey, title: row.monthLabel, dayOrdinal: row.dayOrdinal))
                previousLabel = row.monthLabel
            }
            return labels
        }
    }

    private func renderDateKeys(
        for rows: [FajrWindowDatasetRow],
        period: FajrWindowPeriod,
        timeZone: TimeZone
    ) -> [String] {
        guard period == .oneYear, rows.count > 40 else {
            return rows.map(\.dateKey)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        return rows.compactMap { row in
            let monthDay = calendar.component(.day, from: row.date)
            let isMonthStart = monthDay == 1
            let isWeeklySample = row.dayOrdinal % 7 == 0
            let isEdge = row.dayOrdinal == 0 || row.dayOrdinal == rows.count - 1
            return (isMonthStart || isWeeklySample || isEdge) ? row.dateKey : nil
        }
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

    private func timeLabel(for minutes: Int) -> String {
        let hour = minutes / 60
        let suffix = hour >= 12 ? "PM" : "AM"
        let normalizedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(normalizedHour) \(suffix)"
    }
}

private struct LabelFormatterBundle {
    let short: DateFormatter
    let medium: DateFormatter
    let long: DateFormatter
    let month: DateFormatter

    init(timeZone: TimeZone) {
        short = DateFormatter()
        short.dateFormat = "EEE"
        short.timeZone = timeZone
        short.locale = .current

        medium = DateFormatter()
        medium.dateFormat = "MMM d"
        medium.timeZone = timeZone
        medium.locale = .current

        long = DateFormatter()
        long.dateFormat = "EEEE, MMM d"
        long.timeZone = timeZone
        long.locale = .current

        month = DateFormatter()
        month.dateFormat = "MMM"
        month.timeZone = timeZone
        month.locale = .current
    }
}
