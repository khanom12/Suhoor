import Foundation
import CryptoKit

enum DateHelpers {
    static func startOfToday(in timeZone: TimeZone = .current) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.startOfDay(for: Date())
    }

    static func startOfTomorrow(in timeZone: TimeZone = .current) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfToday = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
    }

    static func dayIdentifier(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func stableUUID(from string: String) -> UUID {
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        let bytes = Array(digest)
        let uuidBytes = Array(bytes[0..<16])
        return UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
            uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        ))
    }

    static func isSameDay(_ lhs: Date?, _ rhs: Date, in timeZone: TimeZone = .current) -> Bool {
        guard let lhs else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func dates(startingFrom start: Date, count: Int, calendar: Calendar) -> [Date] {
        guard count > 0 else { return [] }
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    static func dates(from start: Date, to end: Date, calendar: Calendar) -> [Date] {
        guard end >= start else { return [] }
        let dayCount = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
        return dates(startingFrom: start, count: dayCount, calendar: calendar)
    }
}
