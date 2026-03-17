import Combine
import Foundation

struct CompletionSurfaceState: Sendable {
    let completionStateSnapshot: CompletionStateSnapshot
    let progressSnapshot: ProgressSurfaceSnapshot
    let fajrHistorySnapshot: FajrHistorySurfaceSnapshot
    let fastHistorySnapshot: FastHistorySurfaceSnapshot
    let revision: Int

    static let empty = CompletionSurfaceState(
        completionStateSnapshot: .empty,
        progressSnapshot: .empty,
        fajrHistorySnapshot: .empty,
        fastHistorySnapshot: .empty,
        revision: 0
    )
}

@MainActor
final class CompletionSurfaceStore: ObservableObject {
    struct HomeContext {
        let activeWindowSnapshot: ActiveAlarmWindowSnapshot
        let todaySchedule: DaySchedule?
        let nextWakeEventSummary: NextWakeEventSummary?
        let settings: AppSettings
        let permissionSnapshot: PermissionSnapshot

        static let empty = HomeContext(
            activeWindowSnapshot: .empty,
            todaySchedule: nil,
            nextWakeEventSummary: nil,
            settings: .default,
            permissionSnapshot: .empty
        )
    }

    @Published private(set) var state: CompletionSurfaceState = .empty

    private let homeSurfaceProvider = HomeSurfaceProvider()
    private let adjustedHijriCalendar: AdjustedHijriCalendar

    private(set) var homeContext: HomeContext = .empty

    init(adjustedHijriCalendar: AdjustedHijriCalendar) {
        self.adjustedHijriCalendar = adjustedHijriCalendar
    }

    func update(
        state: CompletionSurfaceState,
        homeContext: HomeContext
    ) {
        self.homeContext = homeContext
        self.state = state
    }

    func homeSurfaceSnapshot(
        now: Date,
        dismissedWarnings: Set<FastWarning>
    ) -> HomeSurfaceSnapshot {
        PerformanceTrace.measure(
            "completion.home-snapshot",
            metadata: "revision=\(state.revision)"
        ) {
            let timeZone = TimeZone.current
            let hijriComponents = adjustedHijriCalendar.adjustedComponents(for: now, timeZone: timeZone)
            let todayKey = DateHelpers.dayIdentifier(for: now, timeZone: timeZone)
            let currentDay = homeContext.activeWindowSnapshot.byDateKey[todayKey].map { day in
                day.replacing(
                    dailyCompletion: resolveDailyCompletion(for: day)
                )
            }
            let input = HomeSurfaceProvider.Input(
                now: now,
                currentDay: currentDay,
                todaySchedule: currentDay?.schedule ?? homeContext.todaySchedule,
                nextWakeEventSummary: homeContext.nextWakeEventSummary,
                hijriComponents: hijriComponents,
                supportDecision: CompletionProjectionBuilder.buildHome(
                    now: now,
                    currentDay: currentDay,
                    todaySchedule: currentDay?.schedule ?? homeContext.todaySchedule,
                    settings: homeContext.settings,
                    permissionSnapshot: homeContext.permissionSnapshot,
                    hijriComponents: hijriComponents,
                    dismissedWarnings: dismissedWarnings
                ).supportDecision
            )

            return homeSurfaceProvider.homeSurfaceSnapshot(
                input: input,
                settings: homeContext.settings,
                permissionSnapshot: homeContext.permissionSnapshot
            )
        }
    }

    func fastStatus(for dateKey: String) -> FastCompletionStatus {
        if let day = homeContext.activeWindowSnapshot.byDateKey[dateKey] {
            return resolveDailyCompletion(for: day).fast.status
        }

        let records = state.completionStateSnapshot.records(for: dateKey)
        guard let record = records.first(where: { $0.kind == .fast }) else {
            return .unknown
        }

        if let legacyStatus = record.metadata["legacyStatus"].flatMap(FastLogStatus.init(rawValue:)) {
            switch legacyStatus {
            case .unknown:
                return .unknown
            case .inProgress:
                return .inProgress
            case .completed:
                return .completed
            case .missed:
                return .notCompleted
            }
        }

        switch record.status {
        case .unknown:
            return .unknown
        case .completed:
            return .completed
        case .missed:
            return .notCompleted
        }
    }

    private func resolveDailyCompletion(for day: ActiveAlarmDay) -> DailyCompletionSnapshot {
        DailyCompletionResolver.resolve(
            dateKey: day.dateKey,
            resolvedDayContext: day.resolvedDayContext,
            completionState: state.completionStateSnapshot
        )
    }
}

private extension ActiveAlarmDay {
    func replacing(dailyCompletion: DailyCompletionSnapshot) -> ActiveAlarmDay {
        ActiveAlarmDay(
            date: date,
            dateKey: dateKey,
            schedule: schedule,
            effectiveConfig: effectiveConfig,
            provenances: provenances,
            isImplicitRamadan: isImplicitRamadan,
            isExplicitOneOff: isExplicitOneOff,
            tagResult: tagResult,
            primaryDisplay: primaryDisplay,
            sourceSummaryText: sourceSummaryText,
            resolvedDayContext: resolvedDayContext,
            scheduledEvents: scheduledEvents,
            decisionLog: decisionLog,
            dailyCompletion: dailyCompletion
        )
    }
}
