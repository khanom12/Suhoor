import Foundation

enum WakeDeleteScope: Equatable, Sendable {
    case currentDay
    case allPlans
    case series
}

enum WakeIntent: Equatable, Sendable {
    case openDay(dateKey: String)
    case adjustDay(dateKey: String)
    case deleteDay(dateKey: String, scope: WakeDeleteScope)
    case toggleDayEnabled(dateKey: String, enabled: Bool)
    case openFilter
    case expandMonth(monthKey: HijriMonthKey)
}

enum PlansObservanceDestination: Equatable, Sendable {
    case qada
    case shawwal
    case sunnah
}

enum PlansIntent: Equatable, Sendable {
    case openDefaultMorningPlan
    case openPlanByDate
    case openQadaPlanner
    case openObservance(PlansObservanceDestination)
}

enum CalendarPlanningIntent: Equatable, Sendable {
    case previewDate(Date)
    case planDate(Date)
    case markFastingDay(Date)
    case openExistingDatePlan(Date)
}
