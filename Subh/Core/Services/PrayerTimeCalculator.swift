import Foundation
import CoreLocation

struct PrayerTimeCalculator {
    enum HighLatitudeRule {
        case none
        case middleOfNight
    }

    func fajrDate(for date: Date, location: CLLocationCoordinate2D, timeZone: TimeZone, method: CalculationMethod, adjustmentMinutes: Int) -> Date? {
        let latitude = location.latitude
        let longitude = location.longitude
        let fajrAngle = method.fajrAngle
        let rule: HighLatitudeRule = abs(latitude) > 55 ? .middleOfNight : .none

        guard let fajrTime = solarTime(for: date, latitude: latitude, longitude: longitude, timeZone: timeZone, zenith: 90.0 + fajrAngle, isMorning: true, highLatitudeRule: rule) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfDay = calendar.startOfDay(for: date)
        let fajrDate = startOfDay.addingTimeInterval(fajrTime * 3600)
        let adjusted = calendar.date(byAdding: .minute, value: adjustmentMinutes, to: fajrDate) ?? fajrDate
        return adjusted
    }

    func maghribDate(
        for date: Date,
        location: CLLocationCoordinate2D,
        timeZone: TimeZone,
        adjustmentMinutes: Int
    ) -> Date? {
        let latitude = location.latitude
        let longitude = location.longitude

        guard let sunsetTime = solarTime(
            for: date,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone,
            zenith: 90.833,
            isMorning: false,
            highLatitudeRule: .none
        ) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfDay = calendar.startOfDay(for: date)
        let maghribDate = startOfDay.addingTimeInterval(sunsetTime * 3600)
        let adjusted = calendar.date(byAdding: .minute, value: adjustmentMinutes, to: maghribDate) ?? maghribDate
        return adjusted
    }

    func sunriseDate(
        for date: Date,
        location: CLLocationCoordinate2D,
        timeZone: TimeZone,
        adjustmentMinutes: Int
    ) -> Date? {
        let latitude = location.latitude
        let longitude = location.longitude

        guard let sunriseTime = solarTime(
            for: date,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone,
            zenith: 90.833,
            isMorning: true,
            highLatitudeRule: .none
        ) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfDay = calendar.startOfDay(for: date)
        let sunriseDate = startOfDay.addingTimeInterval(sunriseTime * 3600)
        let adjusted = calendar.date(byAdding: .minute, value: adjustmentMinutes, to: sunriseDate) ?? sunriseDate
        return adjusted
    }

    private func solarTime(for date: Date, latitude: Double, longitude: Double, timeZone: TimeZone, zenith: Double, isMorning: Bool, highLatitudeRule: HighLatitudeRule) -> Double? {
        let calendar = Calendar(identifier: .gregorian)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let lngHour = longitude / 15.0
        let t = isMorning ? Double(dayOfYear) + ((6.0 - lngHour) / 24.0) : Double(dayOfYear) + ((18.0 - lngHour) / 24.0)

        let m = (0.9856 * t) - 3.289
        var l = m + (1.916 * sin(deg2rad(m))) + (0.020 * sin(deg2rad(2.0 * m))) + 282.634
        l = normalizeDegrees(l)

        var ra = rad2deg(atan(0.91764 * tan(deg2rad(l))))
        ra = normalizeDegrees(ra)

        let lQuadrant = floor(l / 90.0) * 90.0
        let raQuadrant = floor(ra / 90.0) * 90.0
        ra = ra + (lQuadrant - raQuadrant)
        ra = ra / 15.0

        let sinDec = 0.39782 * sin(deg2rad(l))
        let cosDec = cos(asin(sinDec))

        let cosH = (cos(deg2rad(zenith)) - (sinDec * sin(deg2rad(latitude)))) / (cosDec * cos(deg2rad(latitude)))

        if cosH > 1 || cosH < -1 {
            if highLatitudeRule == .middleOfNight {
                return middleOfNightFallback(date: date, latitude: latitude, longitude: longitude, timeZone: timeZone, isMorning: isMorning)
            }
            return nil
        }

        let h = isMorning ? 360.0 - rad2deg(acos(cosH)) : rad2deg(acos(cosH))
        let hHours = h / 15.0

        let tLocal = hHours + ra - (0.06571 * t) - 6.622
        var ut = tLocal - lngHour
        ut = normalizeHours(ut)

        let timeZoneHours = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        let localTime = ut + timeZoneHours
        return normalizeHours(localTime)
    }

    private func middleOfNightFallback(date: Date, latitude: Double, longitude: Double, timeZone: TimeZone, isMorning: Bool) -> Double? {
        guard let sunrise = solarTime(for: date, latitude: latitude, longitude: longitude, timeZone: timeZone, zenith: 90.833, isMorning: true, highLatitudeRule: .none),
              let sunset = solarTime(for: date, latitude: latitude, longitude: longitude, timeZone: timeZone, zenith: 90.833, isMorning: false, highLatitudeRule: .none) else {
            return nil
        }
        let nightLength = (24.0 - sunset) + sunrise
        let adjustment = nightLength / 2.0
        return isMorning ? sunrise - adjustment : sunset + adjustment
    }

    private func deg2rad(_ degrees: Double) -> Double {
        degrees * Double.pi / 180.0
    }

    private func rad2deg(_ radians: Double) -> Double {
        radians * 180.0 / Double.pi
    }

    private func normalizeDegrees(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360.0)
        if value < 0 { value += 360.0 }
        return value
    }

    private func normalizeHours(_ hours: Double) -> Double {
        var value = hours.truncatingRemainder(dividingBy: 24.0)
        if value < 0 { value += 24.0 }
        return value
    }
}
