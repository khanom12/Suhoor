import Foundation

enum MorningHeroUIIdentifier {
    static let location = "morningHero.location"
    static let relativeDay = "morningHero.relativeDay"
    static let primaryWakeTime = "morningHero.primaryWakeTime"
    static let relation = "morningHero.relation"
    static let fajrWindow = "morningHero.fajrWindow"
    static let fajrWindowBeginTime = "morningHero.fajrWindow.beginTime"
    static let fajrWindowTrack = "morningHero.fajrWindow.track"
    static let fajrWindowMarker = "morningHero.fajrWindow.marker"
    static let fajrWindowEndTime = "morningHero.fajrWindow.endTime"
    static let quickWakeModeSelector = "morningHero.quickWakeMode"
    static func quickWakeModeSegment(_ mode: QuickWakeMode) -> String {
        "morningHero.quickWakeMode.\(mode.rawValue)"
    }
}
