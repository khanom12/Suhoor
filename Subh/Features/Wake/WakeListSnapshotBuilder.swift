import Foundation

struct WakeListSnapshot {
    let nextWakeEntries: [WakeRowEntry]
    let sections: [WakeMonthSection]
    let defaultExpandedSectionID: String?

    static let empty = WakeListSnapshot(nextWakeEntries: [], sections: [], defaultExpandedSectionID: nil)

    func defaultCollapsedState(for identifier: String) -> Bool {
        guard let defaultExpandedSectionID else { return true }
        return identifier != defaultExpandedSectionID
    }
}

struct WakeListSnapshotBuildResult {
    let snapshot: WakeListSnapshot
    let pinnedEntryIDs: [String]
}

struct WakeMonthSection: Identifiable {
    let key: HijriMonthKey
    let entries: [WakeRowEntry]
    let preview: WakeMonthPreview?
    let isLoaded: Bool
    let visibleAlarmCount: Int
    let totalAlarmCount: Int

    var id: String { "\(key.year)-\(key.month)" }
}

struct WakeMonthPreview {
    let key: HijriMonthKey
    let startDate: Date
    let offsetDays: Int
}

enum WakeListSnapshotBuilder {
    static func build(
        wakeSnapshot: WakeSurfaceSnapshot,
        tagFilter: WakeTagFilter,
        pinnedEntryIDs: [String],
        timeZone: TimeZone = .current,
        totalScheduledCount: (HijriMonthKey) -> Int,
        rollingHijriMonths: () -> [HijriYearMonth],
        monthPreview: (HijriYearMonth) -> HijriMonthStartPreview?,
        cachedMonthEntries: (HijriMonthKey) -> [ActiveAlarmDay]?
    ) -> WakeListSnapshotBuildResult {
        let nearTermEntries = wakeSnapshot.visibleDays.map {
            WakeRowActionResolver.makeEntry(activeDay: $0, overrideDateKeys: wakeSnapshot.overrideDateKeys)
        }

        let sanitizedPinnedEntryIDs = WakeListSelection.sanitizedPinnedEntryIDs(
            pinnedEntryIDs: pinnedEntryIDs,
            availableEntries: nearTermEntries
        )
        let nextWakeEntries = WakeListSelection.nextWakeEntries(
            from: nearTermEntries,
            pinnedEntryIDs: sanitizedPinnedEntryIDs
        )

        guard !nextWakeEntries.isEmpty else {
            return WakeListSnapshotBuildResult(
                snapshot: WakeListSnapshot(nextWakeEntries: [], sections: [], defaultExpandedSectionID: nil),
                pinnedEntryIDs: sanitizedPinnedEntryIDs
            )
        }

        let nextEntryIDs = Set(nextWakeEntries.map(\.id))
        var nearTermGrouped: [HijriMonthKey: [WakeRowEntry]] = [:]
        for entry in nearTermEntries {
            guard !nextEntryIDs.contains(entry.id) else { continue }
            guard let key = FastIntentEngine.hijriMonthKey(for: entry.schedule.date, timeZone: timeZone) else { continue }
            nearTermGrouped[key, default: []].append(entry)
        }

        let previewMonths = rollingHijriMonths()
        var sections: [WakeMonthSection] = []
        let pinnedCountsByMonth = Dictionary(
            grouping: nextWakeEntries.compactMap { entry in
                FastIntentEngine.hijriMonthKey(for: entry.schedule.date, timeZone: timeZone)
            },
            by: { $0 }
        ).mapValues(\.count)

        for yearMonth in previewMonths {
            let key = HijriMonthKey(
                year: yearMonth.hijriYear,
                month: yearMonth.month.rawValue,
                title: "\(yearMonth.month.displayName) \(yearMonth.hijriYear)"
            )
            let totalCount = totalScheduledCount(key)
            guard totalCount > 0 else { continue }
            let pinnedCount = pinnedCountsByMonth[key, default: 0]
            guard totalCount > pinnedCount else { continue }
            guard let preview = monthPreview(yearMonth) else { continue }
            let previewInfo = WakeMonthPreview(key: key, startDate: preview.adjustedStart, offsetDays: preview.offsetDays)
            let cachedEntries = cachedMonthEntries(key)?.map {
                WakeRowActionResolver.makeEntry(activeDay: $0, overrideDateKeys: wakeSnapshot.overrideDateKeys)
            }
            let unfilteredEntries = cachedEntries ?? nearTermGrouped[key] ?? []
            let entries = unfilteredEntries.filter { $0.matches(filter: tagFilter) }
            let isLoaded = cachedEntries != nil || !unfilteredEntries.isEmpty
            let visibleCount = tagFilter.isActive ? entries.count : max(totalCount - pinnedCount, 0)
            sections.append(
                WakeMonthSection(
                    key: key,
                    entries: entries,
                    preview: previewInfo,
                    isLoaded: isLoaded,
                    visibleAlarmCount: visibleCount,
                    totalAlarmCount: totalCount
                )
            )
        }

        let extraSectionKeys = Set(nearTermGrouped.keys).union(
            wakeSnapshot.visibleDays.compactMap { day in
                FastIntentEngine.hijriMonthKey(for: day.schedule.date, timeZone: timeZone)
            }
        )
        let extraSections = extraSectionKeys
            .filter { key in sections.contains(where: { $0.key == key }) == false }
            .sorted { lhs, rhs in
                (nearTermGrouped[lhs]?.first?.schedule.date ?? .distantPast) <
                (nearTermGrouped[rhs]?.first?.schedule.date ?? .distantPast)
            }
            .compactMap { key -> WakeMonthSection? in
                let totalCount = totalScheduledCount(key)
                let pinnedCount = pinnedCountsByMonth[key, default: 0]
                guard totalCount > 0 else { return nil }
                guard totalCount > pinnedCount else { return nil }
                let filteredEntries = (nearTermGrouped[key] ?? []).filter { $0.matches(filter: tagFilter) }
                return WakeMonthSection(
                    key: key,
                    entries: filteredEntries,
                    preview: nil,
                    isLoaded: true,
                    visibleAlarmCount: tagFilter.isActive ? filteredEntries.count : max(totalCount - pinnedCount, 0),
                    totalAlarmCount: totalCount
                )
            }

        let resolvedSections = (sections + extraSections).sorted {
            ($0.preview?.startDate ?? $0.entries.first?.schedule.date ?? .distantPast) <
            ($1.preview?.startDate ?? $1.entries.first?.schedule.date ?? .distantPast)
        }

        return WakeListSnapshotBuildResult(
            snapshot: WakeListSnapshot(
                nextWakeEntries: nextWakeEntries,
                sections: resolvedSections,
                defaultExpandedSectionID: nil
            ),
            pinnedEntryIDs: sanitizedPinnedEntryIDs
        )
    }
}

enum WakeListSelection {
    static func sanitizedPinnedEntryIDs(
        pinnedEntryIDs: [String],
        availableEntries: [WakeRowEntry]
    ) -> [String] {
        let availableEntryIDs = Set(availableEntries.map(\.id))
        return pinnedEntryIDs.filter { availableEntryIDs.contains($0) }
    }

    static func pinnedEntryIDs(
        afterToggling entryID: String,
        isOn: Bool,
        currentPinnedEntryIDs: [String]
    ) -> [String] {
        if isOn {
            guard let index = currentPinnedEntryIDs.firstIndex(of: entryID) else {
                return currentPinnedEntryIDs
            }
            return Array(currentPinnedEntryIDs.prefix(index + 1))
        }

        guard !currentPinnedEntryIDs.contains(entryID) else {
            return currentPinnedEntryIDs
        }
        return currentPinnedEntryIDs + [entryID]
    }

    static func nextWakeEntries(
        from entries: [WakeRowEntry],
        pinnedEntryIDs: [String],
        now: Date = Date()
    ) -> [WakeRowEntry] {
        let sanitizedPinnedEntryIDs = sanitizedPinnedEntryIDs(
            pinnedEntryIDs: pinnedEntryIDs,
            availableEntries: entries
        )
        let entriesByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        let pinnedEntries = sanitizedPinnedEntryIDs.compactMap { entriesByID[$0] }

        if pinnedEntries.contains(where: \.isEnabled) {
            return pinnedEntries
        }

        let pinnedEntryIDSet = Set(sanitizedPinnedEntryIDs)
        let remainingEntries = entries.filter { !pinnedEntryIDSet.contains($0.id) }
        guard let nextEntry = nextWakeEntry(from: remainingEntries, now: now) else {
            return pinnedEntries
        }
        return pinnedEntries + [nextEntry]
    }

    static func nextWakeEntry(from entries: [WakeRowEntry], now: Date = Date()) -> WakeRowEntry? {
        let enabledEntries = entries.filter(\.isEnabled)
        if let upcoming = enabledEntries.first(where: { $0.primaryTimeDate >= now }) {
            return upcoming
        }
        return enabledEntries.first
    }
}
