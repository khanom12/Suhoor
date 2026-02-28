import Foundation

struct RamadanPreviewDay: Identifiable, Equatable {
    let id: String
    let date: Date
    let dayNumber: Int
    let fajrDate: Date
    let wakeDate: Date
    let badges: [RamadanBadge]
    let offsetMinutes: Int
}
