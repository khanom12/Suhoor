import Foundation

enum FajrWindowPeriod: String, CaseIterable, Identifiable, Hashable, Sendable {
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

enum FajrWindowOverlay: String, CaseIterable, Identifiable, Hashable, Sendable {
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
            return "Safer option"
        case .compareFasting:
            return "Fasting wake"
        case .compareTahajjud:
            return "Compare Tahajjud"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .myWake:
            return "Shows your planned wake across the selected mornings."
        case .compareSafe:
            return "Compares your wake with a safer option that keeps the same lead before the supported Fajr end."
        case .compareFasting:
            return "Compares your wake with the fasting wake when that plan differs."
        case .compareTahajjud:
            return "Compares your wake with the Tahajjud wake when that plan differs."
        }
    }
}

enum FajrWindowBoundaryTruth: Equatable, Hashable, Sendable {
    case canonicalEnd
    case solarSunrise
    case supportedFallback

    var boundaryLabel: String {
        switch self {
        case .canonicalEnd:
            return "Fajr ends"
        case .solarSunrise:
            return "Fajr ends"
        case .supportedFallback:
            return "Supported Fajr boundary"
        }
    }

    var explanationText: String {
        switch self {
        case .canonicalEnd:
            return "Subh is using the supported Fajr end for this date."
        case .solarSunrise:
            return "Fajr end is based on sunrise for this date."
        case .supportedFallback:
            return "Subh is using the closest supported Fajr boundary available for this date."
        }
    }
}

struct FajrWindowDatasetKey: Hashable, Sendable {
    let revision: Int
    let period: FajrWindowPeriod
    let timeZoneIdentifier: String
}

struct FajrWindowOverlayCacheKey: Hashable, Sendable {
    let datasetKey: FajrWindowDatasetKey
    let overlay: FajrWindowOverlay
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

struct FajrWindowCompactSummarySnapshot: Equatable, Sendable {
    let primaryText: String
    let secondaryText: String?
}

struct FajrWindowCompactSelectedDaySnapshot: Equatable, Sendable {
    let dateKey: String
    let relativeLabel: String
    let weekdayTitle: String
    let iconName: String
    let isAlarmActive: Bool
    let timeMain: String
    let timeSuffix: String?
    let accessibilityValue: String
}

enum FajrWindowActionIntent: Equatable, Sendable {
    case openSelectedMorning(dateKey: String)
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

struct FajrWindowOverlayValue: Equatable, Sendable {
    let wake: Date
    let wakeMinutes: Int
}

struct FajrWindowOverlaySeries: Equatable, Sendable {
    let overlay: FajrWindowOverlay
    let valuesByDateKey: [String: FajrWindowOverlayValue]

    var isAvailable: Bool {
        !valuesByDateKey.isEmpty
    }
}

struct FajrWindowDatasetRow: Identifiable, Equatable, Sendable {
    let dayOrdinal: Int
    let date: Date
    let dateKey: String
    let shortLabel: String
    let mediumLabel: String
    let longLabel: String
    let monthLabel: String
    let fajrStart: Date
    let fajrEndOrBoundary: Date
    let boundaryTruth: FajrWindowBoundaryTruth
    let primaryWake: Date
    let saferWake: Date
    let fajrStartMinutes: Int
    let fajrEndOrBoundaryMinutes: Int
    let primaryWakeMinutes: Int
    let saferWakeMinutes: Int
    let bufferBeforeBoundaryMinutes: Int
    let isSkipped: Bool
    let isOverride: Bool
    let isSpecialDay: Bool
    let isFastingContext: Bool
    let isTahajjudContext: Bool
    let contextTags: [String]
    let relationText: String

    var id: String { dateKey }
}

struct FajrWindowPoint: Identifiable, Equatable, Sendable {
    let dayOrdinal: Int
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
    let isSkipped: Bool
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

struct FajrWindowAxisLabel: Identifiable, Equatable, Sendable {
    let dateKey: String
    let title: String
    let dayOrdinal: Int

    var id: String { dateKey }
}

struct FajrWindowChartTick: Identifiable, Equatable, Sendable {
    let minutes: Int
    let label: String

    var id: Int { minutes }
}

struct FajrWindowChartSnapshot: Equatable, Sendable {
    let period: FajrWindowPeriod
    let activeOverlay: FajrWindowOverlay
    let points: [FajrWindowPoint]
    let renderPoints: [FajrWindowPoint]
    let selectedDateKey: String?
    let chartDomain: ClosedRange<Int>
    let xAxisLabels: [FajrWindowAxisLabel]
    let yTicks: [FajrWindowChartTick]
    let compactChartDomain: ClosedRange<Int>
    let compactYTicks: [FajrWindowChartTick]
}

struct FajrWindowDataset: Equatable, Sendable {
    let period: FajrWindowPeriod
    let rows: [FajrWindowDatasetRow]
    let renderDateKeys: [String]
    let compactInsight: String
    let primarySummary: FajrWindowSummarySnapshot?
    let supportSummaries: [FajrWindowSummarySnapshot]
    let insightItems: [FajrWindowInsightItem]
    let xAxisLabels: [FajrWindowAxisLabel]
}

struct FajrWindowCompactSnapshot: Equatable, Sendable {
    let period: FajrWindowPeriod
    let anchorDateKey: String?
    let chart: FajrWindowChartSnapshot
    let compactInsight: String
    let summary: FajrWindowCompactSummarySnapshot
    let selectedDay: FajrWindowCompactSelectedDaySnapshot

    var points: [FajrWindowPoint] { chart.points }
    var renderPoints: [FajrWindowPoint] { chart.renderPoints }
    var selectedDateKey: String? { chart.selectedDateKey }
    var chartDomain: ClosedRange<Int> { chart.chartDomain }
    var xAxisLabels: [FajrWindowAxisLabel] { chart.xAxisLabels }
    var yTicks: [FajrWindowChartTick] { chart.yTicks }
    var compactChartDomain: ClosedRange<Int> { chart.compactChartDomain }
    var compactYTicks: [FajrWindowChartTick] { chart.compactYTicks }

    static let empty = FajrWindowCompactSnapshot(
        period: .sevenDays,
        anchorDateKey: nil,
        chart: FajrWindowChartSnapshot(
            period: .sevenDays,
            activeOverlay: .myWake,
            points: [],
            renderPoints: [],
            selectedDateKey: nil,
            chartDomain: 0...1,
            xAxisLabels: [],
            yTicks: [],
            compactChartDomain: 0...1,
            compactYTicks: []
        ),
        compactInsight: "Subh will show the weekly Fajrcast once schedule data is available.",
        summary: FajrWindowCompactSummarySnapshot(
            primaryText: "Fajrcast is waiting for resolved mornings.",
            secondaryText: nil
        ),
        selectedDay: FajrWindowCompactSelectedDaySnapshot(
            dateKey: "",
            relativeLabel: "Pending",
            weekdayTitle: "Pending",
            iconName: "sun.haze",
            isAlarmActive: false,
            timeMain: "--",
            timeSuffix: nil,
            accessibilityValue: "Fajrcast is waiting for resolved mornings."
        )
    )
}

struct FajrWindowSurfaceSnapshot: Equatable, Sendable {
    let period: FajrWindowPeriod
    let activeOverlay: FajrWindowOverlay
    let availableOverlays: [FajrWindowOverlay]
    let chart: FajrWindowChartSnapshot
    let selectedDay: FajrWindowSelectedDaySnapshot?
    let compactInsight: String
    let primarySummary: FajrWindowSummarySnapshot?
    let supportSummaries: [FajrWindowSummarySnapshot]
    let insightItems: [FajrWindowInsightItem]
    let actionItems: [FajrWindowActionItem]

    var points: [FajrWindowPoint] { chart.points }
    var renderPoints: [FajrWindowPoint] { chart.renderPoints }
    var selectedDateKey: String? { chart.selectedDateKey }
    var chartDomain: ClosedRange<Int> { chart.chartDomain }
    var xAxisLabels: [FajrWindowAxisLabel] { chart.xAxisLabels }
    var yTicks: [FajrWindowChartTick] { chart.yTicks }
}

extension FajrWindowSelectedDaySnapshot {
    var accessibilitySummary: String {
        var parts = [title]

        if let statusText, !statusText.isEmpty {
            parts.append(statusText)
        }

        parts.append(contentsOf: primaryItems.map { "\($0.label): \($0.value)" })
        parts.append(contentsOf: secondaryItems.map { "\($0.label): \($0.value)" })

        if let comparisonItem {
            parts.append("\(comparisonItem.label): \(comparisonItem.value)")
        }

        if !contextTags.isEmpty {
            parts.append("Contexts: \(contextTags.joined(separator: ", "))")
        }

        return parts.joined(separator: ". ")
    }
}
