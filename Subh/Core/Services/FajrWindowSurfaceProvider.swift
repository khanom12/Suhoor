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
        let selectedPoint = compactSelectedPoint(
            from: points,
            selectedDateKey: selectedDateKey,
            now: now,
            timeZone: timeZone
        )
        let chart = chartSnapshot(
            period: dataset.period,
            activeOverlay: .myWake,
            points: points,
            renderDateKeys: dataset.renderDateKeys,
            selectedDateKey: selectedPoint?.dateKey,
            xAxisLabels: dataset.xAxisLabels
        )
        let summary = buildCompactSummary(
            rows: dataset.rows,
            selectedPoint: selectedPoint,
            now: now,
            timeZone: timeZone
        )
        let selectedDay = selectedPoint.map {
            buildCompactSelectedDaySnapshot(
                point: $0,
                now: now,
                timeZone: timeZone
            )
        } ?? FajrWindowCompactSelectedDaySnapshot(
            dateKey: "",
            relativeLabel: "TODAY",
            weekdayTitle: "",
            iconName: "alarm.fill",
            isAlarmActive: false,
            timeMain: "--",
            timeSuffix: nil,
            accessibilityValue: "No upcoming morning"
        )

        return FajrWindowCompactSnapshot(
            period: dataset.period,
            chart: chart,
            compactInsight: summary.primaryText,
            summary: summary,
            selectedDay: selectedDay
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
        let primaryMeaning = ProductSurfacePresentation.dayMeaningText(for: day)
        let tags = Array(
            NSOrderedSet(
                array: ([primaryMeaning] + secondaryTitles + (overrideDateKeys.contains(day.dateKey) ? ["Changed"] : []))
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
            isSkipped: day.effectiveConfig.skipDay,
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
                isSkipped: row.isSkipped,
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
        let compactScale = compactChartScale(for: points)

        return FajrWindowChartSnapshot(
            period: period,
            activeOverlay: activeOverlay,
            points: points,
            renderPoints: renderPoints.isEmpty ? points : renderPoints,
            selectedDateKey: selectedDateKey,
            chartDomain: domain,
            xAxisLabels: xAxisLabels,
            yTicks: chartTicks(for: domain),
            compactChartDomain: compactScale.domain,
            compactYTicks: compactScale.ticks
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

    private func compactSelectedPoint(
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
        if let todayIndex = points.firstIndex(where: { $0.dateKey == todayKey }) {
            let today = points[todayIndex]
            if now <= today.primaryWake {
                return today
            }
            let tomorrowIndex = min(todayIndex + 1, points.count - 1)
            return points[tomorrowIndex]
        }

        return points.first(where: { $0.date >= now }) ?? points.first
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
                label: point.isSkipped ? "Alarm" : "Your wake",
                value: point.isSkipped ? "Off for this date" : TimeFormatters.timeFormatter.string(from: point.primaryWake),
                emphasis: .primary
            ),
        ]

        var secondaryItems: [FajrWindowValueItem] = []

        if !point.isSkipped {
            secondaryItems.append(
                FajrWindowValueItem(
                    id: "buffer",
                    label: "Space before end",
                    value: bufferText(minutes: point.bufferBeforeBoundaryMinutes),
                    emphasis: .secondary
                )
            )
        }

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
        if point.isSkipped {
            statusText = "Off for this date"
        } else if point.isOverride {
            statusText = "Changed for this date"
        } else if point.isSpecialDay {
            statusText = point.contextTags.first
        } else {
            statusText = nil
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
            explanationText: point.isSkipped
                ? "This morning is off for this date. \(point.boundaryTruth.explanationText)"
                : [point.relationText, point.boundaryTruth.explanationText]
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
            label = "Safer option"
            value = point.saferWake
        case .compareFasting:
            label = "Fasting wake"
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

    private func buildCompactSummary(
        rows: [FajrWindowDatasetRow],
        selectedPoint: FajrWindowPoint?,
        now: Date,
        timeZone: TimeZone
    ) -> FajrWindowCompactSummarySnapshot {
        guard let selectedPoint else {
            return FajrWindowCompactSummarySnapshot(
                primaryText: "This week's mornings will appear once Subh has upcoming resolved mornings.",
                secondaryText: nil
            )
        }

        let meaningfulSummary = compactSecondarySummaryLine(rows: rows, timeZone: timeZone)

        return FajrWindowCompactSummarySnapshot(
            primaryText: meaningfulSummary ?? "Usual plan this week.",
            secondaryText: nil
        )
    }

    private func buildCompactSelectedDaySnapshot(
        point: FajrWindowPoint,
        now: Date,
        timeZone: TimeZone
    ) -> FajrWindowCompactSelectedDaySnapshot {
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        weekdayFormatter.timeZone = timeZone
        weekdayFormatter.locale = .current

        let timeParts = point.isSkipped ? ("Off", nil) : splitTimeDisplay(for: point.primaryWake)

        return FajrWindowCompactSelectedDaySnapshot(
            dateKey: point.dateKey,
            relativeLabel: compactSubject(for: point, now: now, timeZone: timeZone).uppercased(),
            weekdayTitle: weekdayFormatter.string(from: point.date),
            iconName: point.isSkipped ? "bell.slash.fill" : "alarm.fill",
            isAlarmActive: !point.isSkipped,
            timeMain: timeParts.0,
            timeSuffix: timeParts.1,
            accessibilityValue: point.isSkipped
                ? "\(compactSubject(for: point, now: now, timeZone: timeZone)), off for this date."
                : "\(compactSubject(for: point, now: now, timeZone: timeZone)), \(TimeFormatters.timeFormatter.string(from: point.primaryWake))."
        )
    }

    private func compactSubject(
        for point: FajrWindowPoint,
        now: Date,
        timeZone: TimeZone
    ) -> String {
        let todayKey = DateHelpers.dayIdentifier(for: now, timeZone: timeZone)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        let tomorrowKey = tomorrow.map { DateHelpers.dayIdentifier(for: $0, timeZone: timeZone) }

        if point.dateKey == todayKey {
            return "Today"
        }
        if point.dateKey == tomorrowKey {
            return "Tomorrow"
        }

        return point.longLabel.components(separatedBy: ",").first ?? point.longLabel
    }

    private func compactRelationClause(for point: FajrWindowPoint) -> String {
        if point.isSkipped {
            return "off for this date"
        }

        if point.relationText == "Fixed wake" {
            return "set for \(TimeFormatters.timeFormatter.string(from: point.primaryWake))"
        }

        if point.relationText == "At Fajr" {
            return "at Fajr begins"
        }

        if point.relationText.hasSuffix(" before Fajr") {
            return point.relationText.replacingOccurrences(of: " before Fajr", with: " before Fajr begins").lowercasedFirstCharacter()
        }

        if point.relationText.hasSuffix(" after Fajr") {
            return point.relationText.replacingOccurrences(of: " after Fajr", with: " after Fajr begins").lowercasedFirstCharacter()
        }

        return point.relationText.lowercasedFirstCharacter()
    }

    private func compactSecondarySummaryLine(
        rows: [FajrWindowDatasetRow],
        timeZone: TimeZone
    ) -> String? {
        guard !rows.isEmpty else { return nil }

        if daylightSavingShiftOccurs(in: rows, timeZone: timeZone) {
            return "Daylight saving time shifts this week's schedule."
        }

        let adjustedCount = rows.filter(\.isOverride).count
        if adjustedCount > 0 {
            return adjustedCount == 1
                ? "1 morning is adjusted this week."
                : "\(adjustedCount) mornings are adjusted this week."
        }

        let fastingCount = rows.filter(\.isFastingContext).count
        if fastingCount >= 2 {
            return "\(fastingCount) fasting mornings are in this week."
        }

        return nil
    }

    private func daylightSavingShiftOccurs(
        in rows: [FajrWindowDatasetRow],
        timeZone: TimeZone
    ) -> Bool {
        let offsets = Set(rows.map { timeZone.secondsFromGMT(for: $0.date) })
        return offsets.count > 1
    }

    private func compactInsight(for rows: [FajrWindowDatasetRow], period: FajrWindowPeriod) -> String {
        guard !rows.isEmpty else {
            return "Your morning window will appear once Subh has upcoming resolved mornings."
        }

        let averageBuffer = Int(round(Double(rows.map(\.bufferBeforeBoundaryMinutes).reduce(0, +)) / Double(rows.count)))
        let overrideCount = rows.filter(\.isOverride).count
        let fastingCount = rows.filter(\.isFastingContext).count

        switch period {
        case .sevenDays:
            if let tightest = rows.min(by: { $0.bufferBeforeBoundaryMinutes < $1.bufferBeforeBoundaryMinutes }),
               tightest.bufferBeforeBoundaryMinutes <= 20 {
                return "\(tightest.mediumLabel) is your tightest morning, with \(bufferText(minutes: tightest.bufferBeforeBoundaryMinutes)) before the current supported end."
            }
            return "Your next week keeps about \(bufferText(minutes: averageBuffer)) between your wake and the current supported end."
        case .thirtyDays:
            if overrideCount > 0 {
                return "\(overrideCount) morning\(overrideCount == 1 ? "" : "s") in this view are adjusted away from your usual plan."
            }
            return "Across this month, your wake keeps roughly \(bufferText(minutes: averageBuffer)) before the current supported end."
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
            FajrWindowMetric(id: "average-buffer", label: "Average space", value: bufferText(minutes: averageBuffer)),
            FajrWindowMetric(id: "tightest-buffer", label: "Tightest morning", value: bufferText(minutes: smallestBuffer))
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
                title: period == .oneYear ? "Across the year" : "Wake steadiness",
                body: period == .oneYear
                    ? "The supported end moves through the year, which is why a wake that feels roomy in one season can feel much tighter in another."
                    : "This keeps the month grounded in real timing, so the pattern stays readable without turning your mornings into a dashboard.",
                metrics: [
                    FajrWindowMetric(id: "adjusted-count", label: "Changed mornings", value: "\(adjustedCount)"),
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
                    title: "Steadier rhythm",
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
                    detail: "\(tightest.mediumLabel) leaves \(bufferText(minutes: tightest.bufferBeforeBoundaryMinutes)) before the current supported end."
                )
            )
        }

        if let adjusted = rows.first(where: \.isOverride) {
            insights.append(
                FajrWindowInsightItem(
                    id: "adjusted-day",
                    title: "Changed morning",
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
                title = "Open tomorrow"
            } else if selectedPoint.dateKey == todayKey {
                title = "Open this morning"
            } else {
                title = "Open selected morning"
            }

            items.append(
                FajrWindowActionItem(
                    id: "selected-day",
                    title: title,
                    subtitle: "Review how this morning resolves.",
                    intent: .openSelectedMorning(dateKey: selectedPoint.dateKey)
                )
            )
        }

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

    private func compactChartScale(for points: [FajrWindowPoint]) -> CompactChartScale {
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
            let ticks = stride(from: 270, through: 360, by: 30).map {
                FajrWindowChartTick(minutes: $0, label: compactTimeLabel(for: $0))
            }
            return CompactChartScale(domain: 270...360, ticks: ticks)
        }

        for step in stride(from: 10, through: 120, by: 10) {
            if let scale = compactChartScale(minimum: minimum, maximum: maximum, step: step) {
                return scale
            }
        }

        let fallbackStart = tensAlignedFallbackStart(for: minimum)
        let fallbackTicks = stride(
            from: fallbackStart,
            through: min((24 * 60), tensAlignedFallbackEnd(for: maximum)),
            by: 10
        )
        .prefix(4)
        .map { FajrWindowChartTick(minutes: $0, label: compactTimeLabel(for: $0)) }

        let fallbackEnd = fallbackTicks.last?.minutes ?? fallbackStart
        return CompactChartScale(domain: fallbackStart...fallbackEnd, ticks: fallbackTicks)
    }

    private func compactChartScale(
        minimum: Int,
        maximum: Int,
        step: Int
    ) -> CompactChartScale? {
        let dayLimit = 24 * 60
        let visibleBuffer = 10
        let maxVisibleEnd = dayLimit
        let bufferedMinimum = max(0, minimum - visibleBuffer)
        let bufferedMaximum = min(dayLimit, maximum + visibleBuffer)
        let maxStart = max(0, maxVisibleEnd - (4 * step))
        let start = min((bufferedMinimum / step) * step, maxStart)
        let visibleEnd = start + (4 * step)

        guard bufferedMaximum <= visibleEnd else { return nil }

        let end = start + (3 * step)
        let ticks = stride(from: start, through: end, by: step).map {
            FajrWindowChartTick(minutes: $0, label: compactTimeLabel(for: $0))
        }

        return CompactChartScale(domain: start...end, ticks: ticks)
    }

    private func tensAlignedFallbackStart(for minimum: Int) -> Int {
        max(0, ((max(0, minimum - 30)) / 10) * 10)
    }

    private func tensAlignedFallbackEnd(for maximum: Int) -> Int {
        min((24 * 60), ((((maximum + 29) / 10) * 10) + 30))
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

    private func compactTimeLabel(for minutes: Int) -> String {
        SettingsSummaryFormatter.timeText(minutesFromMidnight: minutes)
    }

    private func splitTimeDisplay(for date: Date) -> (String, String?) {
        let formatted = TimeFormatters.timeFormatter.string(from: date)
        guard localeUsesMeridiem else { return (formatted, nil) }

        let tokens = formatted.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard tokens.count >= 2 else { return (formatted, nil) }

        let suffix = tokens.last
        let main = tokens.dropLast().joined(separator: " ")
        return (main.isEmpty ? formatted : main, suffix)
    }

    private var localeUsesMeridiem: Bool {
        DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current)?.contains("a") == true
    }

    private func possessive(_ subject: String) -> String {
        "\(subject)'s"
    }
}

private struct CompactChartScale {
    let domain: ClosedRange<Int>
    let ticks: [FajrWindowChartTick]
}

private extension String {
    func lowercasedFirstCharacter() -> String {
        guard let first else { return self }
        return String(first).lowercased() + dropFirst()
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
