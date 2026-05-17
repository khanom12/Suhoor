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
        let overlays = [FajrWindowOverlay.compareFasting].compactMap { overlay in
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
        guard overlay == .compareFasting else {
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
        anchorDateKey: String? = nil,
        selectedDateKey: String? = nil,
        liveWakeAdjustment: FajrWindowLiveWakeAdjustment? = nil,
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> FajrWindowCompactSnapshot {
        let effectiveLiveWakeAdjustment = liveWakeAdjustment.flatMap { adjustment in
            dataset.rows.contains(where: { $0.dateKey == adjustment.dateKey }) ? adjustment : nil
        }
        let rows = compactRows(
            from: dataset.rows,
            applying: effectiveLiveWakeAdjustment,
            timeZone: timeZone
        )
        let points = projectedPoints(rows: rows, overlayLookup: [:])
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
            rows: rows,
            timeZone: timeZone
        )
        let compactInsight = compactSecondarySummaryLine(rows: rows, timeZone: timeZone)
            ?? dataset.compactInsight
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
            anchorDateKey: anchorDateKey ?? compactAnchorPoint(from: points)?.dateKey ?? selectedPoint?.dateKey,
            liveWakeAdjustment: effectiveLiveWakeAdjustment,
            chart: chart,
            compactInsight: compactInsight,
            summary: summary,
            selectedDay: selectedDay
        )
    }

    private func compactRows(
        from rows: [FajrWindowDatasetRow],
        applying liveWakeAdjustment: FajrWindowLiveWakeAdjustment?,
        timeZone: TimeZone
    ) -> [FajrWindowDatasetRow] {
        guard let liveWakeAdjustment,
              liveWakeAdjustment.phase == .changing,
              rows.contains(where: { $0.dateKey == liveWakeAdjustment.dateKey })
        else {
            return rows
        }

        return rows.map { row in
            guard row.dateKey == liveWakeAdjustment.dateKey else { return row }
            return compactRow(row, applyingWake: liveWakeAdjustment.provisionalWakeTime, timeZone: timeZone)
        }
    }

    private func compactRow(
        _ row: FajrWindowDatasetRow,
        applyingWake wakeTime: Date,
        timeZone: TimeZone
    ) -> FajrWindowDatasetRow {
        FajrWindowDatasetRow(
            dayOrdinal: row.dayOrdinal,
            date: row.date,
            dateKey: row.dateKey,
            shortLabel: row.shortLabel,
            mediumLabel: row.mediumLabel,
            longLabel: row.longLabel,
            monthLabel: row.monthLabel,
            fajrStart: row.fajrStart,
            fajrEndOrBoundary: row.fajrEndOrBoundary,
            boundaryTruth: row.boundaryTruth,
            primaryWake: wakeTime,
            saferWake: row.saferWake,
            fajrStartMinutes: row.fajrStartMinutes,
            fajrEndOrBoundaryMinutes: row.fajrEndOrBoundaryMinutes,
            primaryWakeMinutes: minutesFromMidnight(for: wakeTime, timeZone: timeZone),
            saferWakeMinutes: row.saferWakeMinutes,
            bufferBeforeBoundaryMinutes: Int(round(row.fajrEndOrBoundary.timeIntervalSince(wakeTime) / 60)),
            isSkipped: row.isSkipped,
            isOverride: row.isOverride,
            isSpecialDay: row.isSpecialDay,
            isFastingContext: row.isFastingContext,
            contextTags: row.contextTags,
            relationText: row.relationText
        )
    }

    private func compactAnchorPoint(from points: [FajrWindowPoint]) -> FajrWindowPoint? {
        points.first
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

        if let fajrEnd = day.decisionLog.prayerWindow.fajrEnd {
            lowerBoundaryDate = fajrEnd
            boundaryTruth = day.decisionLog.prayerWindow.fajrEndSource == .solarSunrise ? .solarSunrise : .canonicalEnd
        } else if let fajrEnd = day.schedule.fajrEndDate {
            lowerBoundaryDate = fajrEnd
            boundaryTruth = .solarSunrise
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
                fajrStartMinutes: row.fajrStartMinutes,
                fajrEndOrBoundaryMinutes: row.fajrEndOrBoundaryMinutes,
                primaryWakeMinutes: row.primaryWakeMinutes,
                saferWakeMinutes: row.saferWakeMinutes,
                fastingWakeMinutes: fastingValue?.wakeMinutes,
                bufferBeforeBoundaryMinutes: row.bufferBeforeBoundaryMinutes,
                isSkipped: row.isSkipped,
                isOverride: row.isOverride,
                isSpecialDay: row.isSpecialDay,
                isFastingContext: row.isFastingContext,
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
                    label: "Suhoor wake",
                    value: TimeFormatters.timeFormatter.string(from: fastingWake),
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
            label = "Suhoor wake"
            value = point.fastingWake
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
        timeZone: TimeZone
    ) -> FajrWindowCompactSummarySnapshot {
        guard !rows.isEmpty else {
            return FajrWindowCompactSummarySnapshot(
                primaryText: "Weekly Fajrcast will appear once Fajr times are available.",
                secondaryText: nil
            )
        }

        return FajrWindowCompactSummarySnapshot(
            primaryText: compactWeekFajrTrendLine(for: rows),
            secondaryText: compactSpecialFastingOpportunityLine(for: rows, timeZone: timeZone)
        )
    }

    private func compactFajrBoundaryLine(
        for point: FajrWindowPoint,
        state: CompactFajrWindowState
    ) -> String {
        let beginTime = TimeFormatters.timeFormatter.string(from: point.fajrStart)
        let endTime = TimeFormatters.timeFormatter.string(from: point.fajrEndOrBoundary)

        switch state {
        case .upcoming:
            return "Fajr begins at \(beginTime) • Fajr ends at \(endTime)"
        case .inProgress:
            return "Fajr began at \(beginTime) • Fajr ends at \(endTime)"
        case .completed:
            return "Fajr began at \(beginTime) • Fajr ended at \(endTime)"
        }
    }

    private func compactFajrWindowState(
        for point: FajrWindowPoint,
        now: Date
    ) -> CompactFajrWindowState {
        if now < point.fajrStart {
            return .upcoming
        }

        if now < point.fajrEndOrBoundary {
            return .inProgress
        }

        return .completed
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
            accessibilityValue: compactFocusedAccessibilityValue(
                for: point,
                now: now,
                timeZone: timeZone
            )
        )
    }

    private func compactFocusedAccessibilityValue(
        for point: FajrWindowPoint,
        now: Date,
        timeZone: TimeZone
    ) -> String {
        let subject = compactSubject(for: point, now: now, timeZone: timeZone)
        let state = compactFajrWindowState(for: point, now: now)
        let alarmText: String
        if point.isSkipped {
            alarmText = state == .completed
                ? "Alarm was off for this date."
                : "Alarm is off for this date."
        } else {
            let wakeTime = TimeFormatters.timeFormatter.string(from: point.primaryWake)
            alarmText = state == .completed
                ? "Alarm was at \(wakeTime)."
                : "Alarm is at \(wakeTime)."
        }

        return "\(subject) focused. \(alarmText) \(compactFajrBoundaryAccessibilityLine(for: point, state: state))"
    }

    private func compactFajrBoundaryAccessibilityLine(
        for point: FajrWindowPoint,
        state: CompactFajrWindowState
    ) -> String {
        let beginTime = TimeFormatters.timeFormatter.string(from: point.fajrStart)
        let endTime = TimeFormatters.timeFormatter.string(from: point.fajrEndOrBoundary)

        switch state {
        case .upcoming:
            return "Fajr begins at \(beginTime). Fajr ends at \(endTime)."
        case .inProgress:
            return "Fajr began at \(beginTime). Fajr ends at \(endTime)."
        case .completed:
            return "Fajr began at \(beginTime). Fajr ended at \(endTime)."
        }
    }

    private func compactSubject(
        for point: FajrWindowPoint,
        now: Date,
        timeZone: TimeZone
    ) -> String {
        let todayKey = DateHelpers.dayIdentifier(for: now, timeZone: timeZone)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))
        let yesterdayKey = yesterday.map { DateHelpers.dayIdentifier(for: $0, timeZone: timeZone) }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        let tomorrowKey = tomorrow.map { DateHelpers.dayIdentifier(for: $0, timeZone: timeZone) }

        if point.dateKey == todayKey {
            return "Today"
        }
        if point.dateKey == yesterdayKey {
            return "Yesterday"
        }
        if point.dateKey == tomorrowKey {
            return "Tomorrow"
        }

        return point.longLabel.components(separatedBy: ",").first ?? point.longLabel
    }

    private func compactWeekFajrTrendLine(for rows: [FajrWindowDatasetRow]) -> String {
        let visibleRows = rows.sorted { $0.date < $1.date }
        guard let first = visibleRows.first, let last = visibleRows.last else {
            return "Fajr trend will appear once times are available."
        }

        let delta = last.fajrStartMinutes - first.fajrStartMinutes
        let absoluteDelta = abs(delta)
        guard absoluteDelta >= 2 else {
            return "Fajr begins around the same time this week."
        }

        let minuteUnit = absoluteDelta == 1 ? "minute" : "minutes"
        if delta < 0 {
            return "Fajr begins \(absoluteDelta) \(minuteUnit) earlier by week’s end."
        }

        return "Fajr begins \(absoluteDelta) \(minuteUnit) later by week’s end."
    }

    private func compactSpecialFastingOpportunityLine(
        for rows: [FajrWindowDatasetRow],
        timeZone: TimeZone
    ) -> String? {
        let candidates = rows
            .filter { !isRamadanContext($0) }
            .compactMap { row -> CompactSpecialFastingOpportunity? in
                compactSpecialFastingOpportunity(for: row)
            }
            .sorted { lhs, rhs in
                if lhs.priority == rhs.priority {
                    return lhs.row.date < rhs.row.date
                }
                return lhs.priority < rhs.priority
            }

        guard let first = candidates.first else {
            return nil
        }

        let matching = candidates.filter { $0.name == first.name }
        let plannedCount = matching.filter(\.isPlanned).count
        if first.name == "Dhul Hijjah days", matching.count > 1 {
            if plannedCount > 0 {
                return "Fasting planned on \(plannedCount) special days this week."
            }
            return "Fasting opportunity: Dhul Hijjah days this week."
        }

        let weekday = compactWeekdayList(for: [first.row], timeZone: timeZone)
        if first.isPlanned {
            return "Fasting planned: \(first.name) on \(weekday)."
        }

        return "Fasting opportunity: \(first.name) on \(weekday)."
    }

    private func compactSpecialFastingOpportunity(
        for row: FajrWindowDatasetRow
    ) -> CompactSpecialFastingOpportunity? {
        let normalizedTags = row.contextTags.map { $0.lowercased() }
        if normalizedTags.contains(where: { $0.contains("arafah") }) {
            return CompactSpecialFastingOpportunity(
                row: row,
                name: "Arafah",
                isPlanned: row.isFastingContext,
                priority: 0
            )
        }

        if normalizedTags.contains(where: { $0.contains("ashura") }) {
            return CompactSpecialFastingOpportunity(
                row: row,
                name: "Ashura",
                isPlanned: row.isFastingContext,
                priority: 1
            )
        }

        if normalizedTags.contains(where: { $0.contains("dhul hijjah") || $0.contains("dhulhijjah") }) {
            return CompactSpecialFastingOpportunity(
                row: row,
                name: "Dhul Hijjah days",
                isPlanned: row.isFastingContext,
                priority: 2
            )
        }

        return nil
    }

    private func isRamadanContext(_ row: FajrWindowDatasetRow) -> Bool {
        row.contextTags.contains { $0.lowercased().contains("ramadan") }
    }

    private func compactWeekdayList(
        for rows: [FajrWindowDatasetRow],
        timeZone: TimeZone
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = timeZone
        formatter.locale = .current

        let names = rows
            .sorted { $0.date < $1.date }
            .map { formatter.string(from: $0.date) }

        switch names.count {
        case 0:
            return ""
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) and \(names[1])"
        default:
            return "\(names.dropLast().joined(separator: ", ")), and \(names.last ?? "")"
        }
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
                return "\(tightest.mediumLabel) is your tightest morning, with \(bufferText(minutes: tightest.bufferBeforeBoundaryMinutes)) before the supported Fajr end."
            }
            return "Your next week keeps about \(bufferText(minutes: averageBuffer)) between your wake and the supported Fajr end."
        case .thirtyDays:
            if overrideCount > 0 {
                return "\(overrideCount) morning\(overrideCount == 1 ? "" : "s") in this view are adjusted away from your usual plan."
            }
            return "Across this month, your wake keeps roughly \(bufferText(minutes: averageBuffer)) before the supported Fajr end."
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
            body = "Your next mornings stay centered on Fajr, with the selected day showing exactly how your wake sits inside the supported Fajr wake window."
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
                    ? "The supported Fajr end moves through the year, which is why a wake that feels roomy in one season can feel much tighter in another."
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
                    detail: "\(tightest.mediumLabel) leaves \(bufferText(minutes: tightest.bufferBeforeBoundaryMinutes)) before the supported Fajr end."
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
                point.fastingWakeMinutes
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
                point.fastingWakeMinutes
            ].compactMap { $0 }
        }

        guard let minimum = values.min(), let maximum = values.max() else {
            let ticks = stride(from: 270, through: 360, by: 30).map {
                FajrWindowChartTick(minutes: $0, label: compactTimeLabel(for: $0))
            }
            return CompactChartScale(domain: 270...360, ticks: ticks)
        }

        for step in [15, 30, 45, 60, 75, 90, 105, 120, 10, 20, 40, 50, 70, 80, 100, 110] {
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

}

private struct CompactChartScale {
    let domain: ClosedRange<Int>
    let ticks: [FajrWindowChartTick]
}

private enum CompactFajrWindowState {
    case upcoming
    case inProgress
    case completed
}

private struct CompactSpecialFastingOpportunity {
    let row: FajrWindowDatasetRow
    let name: String
    let isPlanned: Bool
    let priority: Int
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
