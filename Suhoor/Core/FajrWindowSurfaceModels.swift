import Foundation

enum FajrWindowPeriod: String, CaseIterable, Identifiable, Sendable {
    case sevenDays
    case thirtyDays
    case oneYear

    var id: String { rawValue }

    var dayCount: Int {
        switch self {
        case .sevenDays:
            return 7
        case .thirtyDays:
            return 30
        case .oneYear:
            return 365
        }
    }

    var shortTitle: String {
        switch self {
        case .sevenDays:
            return "7D"
        case .thirtyDays:
            return "30D"
        case .oneYear:
            return "1Y"
        }
    }

    var subtitle: String {
        switch self {
        case .sevenDays:
            return "This week"
        case .thirtyDays:
            return "This month"
        case .oneYear:
            return "Across the year"
        }
    }

    var summaryTitle: String {
        switch self {
        case .sevenDays:
            return "This week's pattern"
        case .thirtyDays:
            return "This month's pattern"
        case .oneYear:
            return "Across the year"
        }
    }
}

enum FajrWindowOverlay: String, CaseIterable, Identifiable, Sendable {
    case myWake
    case compareSafe
    case compareFasting
    case compareTahajjud

    var id: String { rawValue }

    var title: String {
        switch self {
        case .myWake:
            return "My wake"
        case .compareSafe:
            return "Compare safer"
        case .compareFasting:
            return "Compare fasting"
        case .compareTahajjud:
            return "Compare Tahajjud"
        }
    }
}

enum FajrWindowBoundaryTruth: Equatable, Sendable {
    case canonicalEnd
    case sunriseProxy
    case supportedFallback

    var boundaryLabel: String {
        switch self {
        case .canonicalEnd:
            return "Fajr ends"
        case .sunriseProxy:
            return "Fajr end (sunrise proxy)"
        case .supportedFallback:
            return "Supported boundary"
        }
    }

    var explanationText: String {
        switch self {
        case .canonicalEnd:
            return "This view is using the resolved Fajr boundary."
        case .sunriseProxy:
            return "This lower boundary uses the current sunrise-based proxy supported by Suhoor."
        case .supportedFallback:
            return "This lower boundary falls back to the closest supported morning boundary in the current model."
        }
    }
}

struct FajrWindowValueItem: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String
    let emphasis: Emphasis

    enum Emphasis: Equatable, Sendable {
        case primary
        case secondary
        case comparison
    }
}

struct FajrWindowMetric: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String
}

struct FajrWindowSummarySnapshot: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let body: String
    let metrics: [FajrWindowMetric]
}

struct FajrWindowInsightItem: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let detail: String
}

enum FajrWindowActionIntent: Equatable, Sendable {
    case openSelectedMorning(dateKey: String)
    case openDefaultMorningPlan
}

struct FajrWindowActionItem: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String?
    let intent: FajrWindowActionIntent
}

struct FajrWindowSelectedDaySnapshot: Equatable, Sendable {
    let dateKey: String
    let title: String
    let boundaryTruth: FajrWindowBoundaryTruth
    let statusText: String?
    let primaryItems: [FajrWindowValueItem]
    let secondaryItems: [FajrWindowValueItem]
    let comparisonItem: FajrWindowValueItem?
    let contextTags: [String]
    let explanationText: String
}

struct FajrWindowPoint: Identifiable, Equatable, Sendable {
    let date: Date
    let dateKey: String
    let shortLabel: String
    let mediumLabel: String
    let longLabel: String
    let fajrStart: Date
    let fajrEndOrBoundary: Date
    let boundaryTruth: FajrWindowBoundaryTruth
    let primaryWake: Date
    let saferWake: Date?
    let fastingWake: Date?
    let tahajjudWake: Date?
    let fajrStartMinutes: Int
    let fajrEndOrBoundaryMinutes: Int
    let primaryWakeMinutes: Int
    let saferWakeMinutes: Int?
    let fastingWakeMinutes: Int?
    let tahajjudWakeMinutes: Int?
    let bufferBeforeBoundaryMinutes: Int
    let isOverride: Bool
    let isSpecialDay: Bool
    let isFastingContext: Bool
    let isTahajjudContext: Bool
    let contextTags: [String]
    let relationText: String

    var id: String { dateKey }

    func overlayMinutes(for overlay: FajrWindowOverlay) -> Int? {
        switch overlay {
        case .myWake:
            return primaryWakeMinutes
        case .compareSafe:
            return saferWakeMinutes
        case .compareFasting:
            return fastingWakeMinutes
        case .compareTahajjud:
            return tahajjudWakeMinutes
        }
    }
}

struct FajrWindowSurfaceSnapshot: Equatable, Sendable {
    let period: FajrWindowPeriod
    let activeOverlay: FajrWindowOverlay
    let availableOverlays: [FajrWindowOverlay]
    let points: [FajrWindowPoint]
    let selectedDateKey: String?
    let selectedDay: FajrWindowSelectedDaySnapshot?
    let compactInsight: String
    let primarySummary: FajrWindowSummarySnapshot?
    let supportSummaries: [FajrWindowSummarySnapshot]
    let insightItems: [FajrWindowInsightItem]
    let actionItems: [FajrWindowActionItem]
    let chartDomain: ClosedRange<Int>
}
