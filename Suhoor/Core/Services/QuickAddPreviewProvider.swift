import Foundation

struct QuickAddPreviewProvider {
    func previewIslamicQuickAdd(
        alarmConfigStore: AlarmConfigStore,
        kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> IslamicQuickAddPreview? {
        alarmConfigStore.previewIslamicQuickAdd(kind, startDate: startDate, timeZone: timeZone)
    }

    func previewAshuraQuickAdd(
        alarmConfigStore: AlarmConfigStore,
        pattern: AshuraQuickAddPattern,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> AshuraQuickAddPreview? {
        alarmConfigStore.previewAshuraQuickAdd(pattern, startDate: startDate, timeZone: timeZone)
    }

    func previewGregorianRangeAdd(
        alarmConfigStore: AlarmConfigStore,
        startDate: Date,
        endDate: Date,
        timeZone: TimeZone = .current
    ) -> AddScheduledDatesResult {
        alarmConfigStore.previewGregorianRangeAdd(startDate: startDate, endDate: endDate, timeZone: timeZone)
    }

    func islamicQuickAddAvailability(
        alarmConfigStore: AlarmConfigStore,
        kind: IslamicQuickAddKind,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> IslamicQuickAddAvailability {
        alarmConfigStore.islamicQuickAddAvailability(kind, startDate: startDate, timeZone: timeZone)
    }

    func recommendedAshuraQuickAddPattern(
        alarmConfigStore: AlarmConfigStore,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> AshuraQuickAddPattern {
        alarmConfigStore.recommendedAshuraQuickAddPattern(startDate: startDate, timeZone: timeZone)
    }

    func ashuraQuickAddAvailability(
        alarmConfigStore: AlarmConfigStore,
        pattern: AshuraQuickAddPattern,
        startDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> AshuraQuickAddAvailability {
        alarmConfigStore.ashuraQuickAddAvailability(pattern, startDate: startDate, timeZone: timeZone)
    }
}
