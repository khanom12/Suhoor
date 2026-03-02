import Foundation

struct DaySchedule: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let date: Date
    let fajrDate: Date
    let wakeDate: Date
    let reminderDate: Date?
    let boundaryDate: Date?
    let fajrSoundChoice: SoundChoice?
    let locationDescription: String
    let offsetMinutes: Int
    let calculationMethodName: String

    init(
        date: Date,
        fajrDate: Date,
        wakeDate: Date,
        reminderDate: Date?,
        boundaryDate: Date?,
        fajrSoundChoice: SoundChoice? = nil,
        locationDescription: String,
        offsetMinutes: Int,
        calculationMethodName: String,
        timeZone: TimeZone
    ) {
        self.date = date
        self.fajrDate = fajrDate
        self.wakeDate = wakeDate
        self.reminderDate = reminderDate
        self.boundaryDate = boundaryDate
        self.fajrSoundChoice = fajrSoundChoice
        self.locationDescription = locationDescription
        self.offsetMinutes = offsetMinutes
        self.calculationMethodName = calculationMethodName
        self.id = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
    }
}
