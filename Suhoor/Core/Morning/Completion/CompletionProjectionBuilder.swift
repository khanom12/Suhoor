import Foundation

struct HomeSupportDecision: Equatable, Sendable {
    let presentation: HomeSupportCardPresentation
    let reason: String
    let isDismissible: Bool

    var kind: HomeSupportCardKind { presentation.kind }
    var phase: HomeSupportCardPhase { presentation.phase }
}

struct HomeCompletionProjection: Equatable, Sendable {
    let dailyCompletion: DailyCompletionSnapshot?
    let supportDecision: HomeSupportDecision?
}

enum CompletionProjectionBuilder {
    static func buildHome(
        now: Date,
        currentDay: ActiveAlarmDay?,
        todaySchedule: DaySchedule?,
        permissionSnapshot: PermissionSnapshot,
        hijriComponents: AdjustedHijriDateComponents?,
        dismissedWarnings: Set<FastWarning>
    ) -> HomeCompletionProjection {
        let blockingPriority: [AppPermissionKind] = [.location, .notifications, .alarmKit]
        for kind in blockingPriority {
            if permissionSnapshot.presentations[kind]?.isBlocking == true {
                return HomeCompletionProjection(
                    dailyCompletion: currentDay?.dailyCompletion,
                    supportDecision: HomeSupportDecision(
                        presentation: .blockingIssue(kind),
                        reason: "A blocking system issue needs attention first.",
                        isDismissible: false
                    )
                )
            }
        }

        let dailyCompletion = currentDay?.dailyCompletion
        let forbiddenWarning = activeForbiddenWarning(
            for: hijriComponents,
            dismissedWarnings: dismissedWarnings
        )
        if dailyCompletion?.isMeaningfullyResolved == true, forbiddenWarning == nil {
            return HomeCompletionProjection(
                dailyCompletion: dailyCompletion,
                supportDecision: nil
            )
        }
        let fastingPresentation = currentDay.flatMap { day in
            fastingHomePresentation(
                now: now,
                day: day,
                dailyCompletion: day.dailyCompletion
            )
        }
        let fajrPrompt = currentDay.flatMap { day in
            fajrPromptPresentation(
                now: now,
                schedule: todaySchedule,
                dailyCompletion: day.dailyCompletion
            )
        }

        if let todaySchedule {
            switch dayPhase(now: now, schedule: todaySchedule) {
            case .beforeFajr:
                if let forbiddenWarning {
                    return HomeCompletionProjection(
                        dailyCompletion: dailyCompletion,
                        supportDecision: HomeSupportDecision(
                            presentation: .forbiddenFastNotice(forbiddenWarning),
                            reason: "Forbidden-fast guidance is more immediate before Fajr.",
                            isDismissible: true
                        )
                    )
                }
                if let fastingPresentation {
                    return HomeCompletionProjection(
                        dailyCompletion: dailyCompletion,
                        supportDecision: HomeSupportDecision(
                            presentation: .fasting(fastingPresentation),
                            reason: "This day still needs fasting status confirmation.",
                            isDismissible: false
                        )
                    )
                }
            case .fajrMorning:
                if let fajrPrompt {
                    return HomeCompletionProjection(
                        dailyCompletion: dailyCompletion,
                        supportDecision: HomeSupportDecision(
                            presentation: .fajrCompletionPrompt(fajrPrompt),
                            reason: "Fajr completion is the most immediate unresolved act.",
                            isDismissible: false
                        )
                    )
                }
                if let forbiddenWarning {
                    return HomeCompletionProjection(
                        dailyCompletion: dailyCompletion,
                        supportDecision: HomeSupportDecision(
                            presentation: .forbiddenFastNotice(forbiddenWarning),
                            reason: "Forbidden-fast guidance is still relevant this morning.",
                            isDismissible: true
                        )
                    )
                }
                if let fastingPresentation {
                    return HomeCompletionProjection(
                        dailyCompletion: dailyCompletion,
                        supportDecision: HomeSupportDecision(
                            presentation: .fasting(fastingPresentation),
                            reason: "Fasting status is still relevant after wake.",
                            isDismissible: false
                        )
                    )
                }
            case .daytime:
                if let forbiddenWarning {
                    return HomeCompletionProjection(
                        dailyCompletion: dailyCompletion,
                        supportDecision: HomeSupportDecision(
                            presentation: .forbiddenFastNotice(forbiddenWarning),
                            reason: "Forbidden-fast guidance is still more relevant than later prompts.",
                            isDismissible: true
                        )
                    )
                }
                if let fastingPresentation {
                    return HomeCompletionProjection(
                        dailyCompletion: dailyCompletion,
                        supportDecision: HomeSupportDecision(
                            presentation: .fasting(fastingPresentation),
                            reason: "Fasting remains the most relevant in-day observance state.",
                            isDismissible: false
                        )
                    )
                }
                if let fajrPrompt {
                    return HomeCompletionProjection(
                        dailyCompletion: dailyCompletion,
                        supportDecision: HomeSupportDecision(
                            presentation: .fajrCompletionPrompt(fajrPrompt),
                            reason: "Fajr is still unresolved, but lower priority than active fasting state.",
                            isDismissible: false
                        )
                    )
                }
            case .afterMaghrib:
                if let fastingPresentation {
                    return HomeCompletionProjection(
                        dailyCompletion: dailyCompletion,
                        supportDecision: HomeSupportDecision(
                            presentation: .fasting(fastingPresentation),
                            reason: "Fast completion takes priority after Maghrib.",
                            isDismissible: false
                        )
                    )
                }
                if let fajrPrompt {
                    return HomeCompletionProjection(
                        dailyCompletion: dailyCompletion,
                        supportDecision: HomeSupportDecision(
                            presentation: .fajrCompletionPrompt(fajrPrompt),
                            reason: "Fajr is still unresolved after the day’s primary fasting action.",
                            isDismissible: false
                        )
                    )
                }
            }
        }

        if let forbiddenWarning {
            return HomeCompletionProjection(
                dailyCompletion: dailyCompletion,
                supportDecision: HomeSupportDecision(
                    presentation: .forbiddenFastNotice(forbiddenWarning),
                    reason: "Forbidden-fast guidance is the only remaining relevant support.",
                    isDismissible: true
                )
            )
        }

        return HomeCompletionProjection(
            dailyCompletion: dailyCompletion,
            supportDecision: nil
        )
    }

    static func buildProgress(
        todayCompletion: DailyCompletionSnapshot,
        recentDateKeys: [String],
        completionState: CompletionStateSnapshot,
        wakeProgress: WakeProgressSnapshot
    ) -> ProgressSurfaceSnapshot {
        let recentRecords = recentDateKeys.flatMap { completionState.records(for: $0) }
        let recentFajrCompletedCount = recentRecords.filter { $0.kind == .fajr && $0.status == .completed }.count
        let recentFajrMissedCount = recentRecords.filter { $0.kind == .fajr && $0.status == .missed }.count
        let recentFastCompletedCount = recentRecords.filter { $0.kind == .fast && $0.status == .completed }.count
        let recentFastMissedCount = recentRecords.filter { $0.kind == .fast && $0.status == .missed }.count
        let qadaProgress = QadaProgressSnapshot(
            remaining: completionState.qadaLedgerSnapshot.remaining,
            completed: completionState.qadaLedgerSnapshot.completed,
            baselineOwed: completionState.qadaLedgerSnapshot.baselineOwed
        )
        let history = CompletionHistoryProjection(
            todayCompletion: todayCompletion,
            recentFajrCompletedCount: recentFajrCompletedCount,
            recentFajrMissedCount: recentFajrMissedCount,
            recentFastCompletedCount: recentFastCompletedCount,
            recentFastMissedCount: recentFastMissedCount,
            qadaProgress: qadaProgress
        )

        return ProgressSurfaceSnapshot(
            fajrTodaySummary: history.todayCompletion.prayer.status.title,
            fajrSummary: historySummary(
                completed: history.recentFajrCompletedCount,
                missed: history.recentFajrMissedCount,
                empty: "No logged mornings yet",
                completedLabel: "made it"
            ),
            fastTodaySummary: fastTodaySummary(from: history.todayCompletion),
            fastSummary: historySummary(
                completed: history.recentFastCompletedCount,
                missed: history.recentFastMissedCount,
                empty: "No logged fasts yet",
                completedLabel: "completed"
            ),
            qadaProgress: history.qadaProgress,
            wakeProgress: wakeProgress
        )
    }

    private static func fastTodaySummary(
        from completion: DailyCompletionSnapshot
    ) -> String {
        guard completion.fast.status != .notRequired else {
            return "Not a fasting day"
        }

        let isQada = completion.fast.intentSnapshot?.primaryIntent == .qadaMakeup
            || completion.qadaEffect.countsTowardQada

        switch completion.fast.status {
        case .notRequired:
            return "Not a fasting day"
        case .unknown:
            return "Not logged"
        case .inProgress:
            return isQada ? "Qada in progress" : "In progress"
        case .completed:
            return isQada ? "Qada completed" : "Completed"
        case .notCompleted:
            return isQada ? "Qada not completed" : "Not completed"
        }
    }

    private static func historySummary(
        completed: Int,
        missed: Int,
        empty: String,
        completedLabel: String
    ) -> String {
        if completed == 0 && missed == 0 {
            return empty
        }
        return "\(completed) \(completedLabel) · \(missed) missed"
    }

    private static func activeForbiddenWarning(
        for components: AdjustedHijriDateComponents?,
        dismissedWarnings: Set<FastWarning>
    ) -> FastWarning? {
        guard let components else { return nil }

        let orderedWarnings: [FastWarning] = [.eidAlFitr, .eidAlAdha, .tashreeq]
        for warning in orderedWarnings where !dismissedWarnings.contains(warning) {
            switch warning {
            case .eidAlFitr where components.month == .shawwal && components.day == 1:
                return warning
            case .eidAlAdha where components.month == .dhulHijjah && components.day == 10:
                return warning
            case .tashreeq where components.month == .dhulHijjah && (11...13).contains(components.day):
                return warning
            default:
                continue
            }
        }

        return nil
    }

    private static func dayPhase(
        now: Date,
        schedule: DaySchedule
    ) -> DayPhase {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let midday = calendar.date(
            bySettingHour: 12,
            minute: 0,
            second: 0,
            of: schedule.date
        ) ?? schedule.fajrDate.addingTimeInterval(60 * 60 * 12)
        let earlyWindowEnd = schedule.fajrDate.addingTimeInterval(60 * 60 * 3)
        let morningCutoff = min(midday, earlyWindowEnd)

        if now < schedule.fajrDate {
            return .beforeFajr
        }
        if now <= morningCutoff {
            return .fajrMorning
        }
        if now < schedule.maghribDate {
            return .daytime
        }
        return .afterMaghrib
    }

    private static func fajrPromptPresentation(
        now: Date,
        schedule: DaySchedule?,
        dailyCompletion: DailyCompletionSnapshot
    ) -> FajrHomeSupportPresentation? {
        guard let schedule,
              dailyCompletion.prayer.status == .unknown,
              now >= schedule.fajrDate else {
            return nil
        }

        return FajrHomeSupportPresentation(
            dateKey: dailyCompletion.dateKey,
            title: "Did you pray Fajr?",
            detail: "Fajr was at \(TimeFormatters.timeFormatter.string(from: schedule.fajrDate))."
        )
    }

    private static func fastingHomePresentation(
        now: Date,
        day: ActiveAlarmDay,
        dailyCompletion: DailyCompletionSnapshot
    ) -> FastingHomeSupportPresentation? {
        guard dailyCompletion.fast.status != .notRequired else { return nil }

        let intent = dailyCompletion.fast.intentSnapshot ?? .empty
        let isQada = intent.primaryIntent == .qadaMakeup || day.dailyCompletion.qadaEffect.countsTowardQada
        let schedule = day.schedule
        let phase = dayPhase(now: now, schedule: schedule)
        let dateKey = day.dateKey

        switch phase {
        case .beforeFajr, .fajrMorning, .daytime:
            switch dailyCompletion.fast.status {
            case .unknown:
                return FastingHomeSupportPresentation(
                    phase: .fastingStatusPrompt,
                    dateKey: dateKey,
                    intentSnapshot: intent,
                    title: isQada ? "Fasting for Qada today?" : "Fasting today?",
                    detail: isQada ? "Start this Qada day now." : "Mark this day when you start.",
                    primaryActionTitle: isQada ? "Start Qada" : "Yes",
                    secondaryActionTitle: "Not today",
                    statusTitle: nil,
                    showsUndo: false
                )
            case .inProgress:
                return FastingHomeSupportPresentation(
                    phase: .fastingInProgress,
                    dateKey: dateKey,
                    intentSnapshot: intent,
                    title: isQada ? "Qada fast in progress" : "Fasting today",
                    detail: "Mark it completed after Maghrib.",
                    primaryActionTitle: nil,
                    secondaryActionTitle: nil,
                    statusTitle: isQada ? "Qada in progress" : "Fasting in progress",
                    showsUndo: true
                )
            case .completed:
                return FastingHomeSupportPresentation(
                    phase: .fastCompletionLogged,
                    dateKey: dateKey,
                    intentSnapshot: intent,
                    title: isQada ? "Qada fast completed" : "Fast completed",
                    detail: isQada ? "Counts toward what you still owe." : "Logged for today.",
                    primaryActionTitle: nil,
                    secondaryActionTitle: nil,
                    statusTitle: isQada ? "Qada completed" : "Fast completed",
                    showsUndo: true
                )
            case .notCompleted:
                return FastingHomeSupportPresentation(
                    phase: .fastCompletionLogged,
                    dateKey: dateKey,
                    intentSnapshot: intent,
                    title: isQada ? "Qada fast not completed" : "Fast not completed",
                    detail: isQada ? "Your Qada balance stays the same." : "You can change this later in Progress.",
                    primaryActionTitle: nil,
                    secondaryActionTitle: nil,
                    statusTitle: "Not completed",
                    showsUndo: true
                )
            case .notRequired:
                return nil
            }
        case .afterMaghrib:
            switch dailyCompletion.fast.status {
            case .unknown:
                return FastingHomeSupportPresentation(
                    phase: .fastCompletionPrompt,
                    dateKey: dateKey,
                    intentSnapshot: intent,
                    title: isQada ? "Did you complete the Qada fast?" : "Did you complete the fast?",
                    detail: isQada ? "Completed Qada fasts reduce what remains." : "Log the result for today.",
                    primaryActionTitle: "Completed",
                    secondaryActionTitle: "Not completed",
                    statusTitle: nil,
                    showsUndo: false
                )
            case .inProgress, .completed:
                return FastingHomeSupportPresentation(
                    phase: .fastCompletionLogged,
                    dateKey: dateKey,
                    intentSnapshot: intent,
                    title: isQada ? "Qada fast completed" : "Fast completed",
                    detail: isQada ? "Counts toward what you still owe." : "Logged for today.",
                    primaryActionTitle: nil,
                    secondaryActionTitle: nil,
                    statusTitle: isQada ? "Qada completed" : "Fast completed",
                    showsUndo: true
                )
            case .notCompleted:
                return FastingHomeSupportPresentation(
                    phase: .fastCompletionLogged,
                    dateKey: dateKey,
                    intentSnapshot: intent,
                    title: isQada ? "Qada fast not completed" : "Fast not completed",
                    detail: isQada ? "Your Qada balance stays the same." : "You can change this later in Progress.",
                    primaryActionTitle: nil,
                    secondaryActionTitle: nil,
                    statusTitle: "Not completed",
                    showsUndo: true
                )
            case .notRequired:
                return nil
            }
        }
    }
}

private enum DayPhase {
    case beforeFajr
    case fajrMorning
    case daytime
    case afterMaghrib
}
