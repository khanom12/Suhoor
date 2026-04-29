import Foundation

struct DaySchedule: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let date: Date
    let fajrDate: Date
    let fajrEndDate: Date?
    let maghribDate: Date
    let wakeDate: Date
    let reminderDate: Date?
    let boundaryDate: Date?
    let iftarDate: Date?
    let fajrSoundChoice: SoundChoice?
    let iftarSoundChoice: SoundChoice?
    let locationDescription: String
    let offsetMinutes: Int
    let calculationMethodName: String

    init(
        date: Date,
        fajrDate: Date,
        fajrEndDate: Date? = nil,
        maghribDate: Date,
        wakeDate: Date,
        reminderDate: Date?,
        boundaryDate: Date?,
        iftarDate: Date?,
        fajrSoundChoice: SoundChoice? = nil,
        iftarSoundChoice: SoundChoice? = nil,
        locationDescription: String,
        offsetMinutes: Int,
        calculationMethodName: String,
        timeZone: TimeZone
    ) {
        self.date = date
        self.fajrDate = fajrDate
        self.fajrEndDate = fajrEndDate
        self.maghribDate = maghribDate
        self.wakeDate = wakeDate
        self.reminderDate = reminderDate
        self.boundaryDate = boundaryDate
        self.iftarDate = iftarDate
        self.fajrSoundChoice = fajrSoundChoice
        self.iftarSoundChoice = iftarSoundChoice
        self.locationDescription = locationDescription
        self.offsetMinutes = offsetMinutes
        self.calculationMethodName = calculationMethodName
        self.id = DateHelpers.dayIdentifier(for: date, timeZone: timeZone)
    }
}
