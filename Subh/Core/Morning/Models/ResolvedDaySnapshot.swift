import Foundation

struct ResolvedDaySnapshot: Sendable {
    let date: Date
    let dateKey: String
    let prayerWindow: DailyPrayerWindow
    let resolvedDayContext: ResolvedDayContext
    let selectedPlan: MorningPlan
    let resolvedBehaviorProfile: MorningBehaviorProfile
    let materializedEvents: [ScheduledEvent]
    let decisionLog: RuleDecisionLog
    let completionRecords: [CompletionRecord]
    let dailyCompletion: DailyCompletionSnapshot
    let completionSummary: String?
    let resolvedDayPurpose: ResolvedDayPurpose
}
