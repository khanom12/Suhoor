import Foundation
import CoreLocation

struct PrayerTimeCalculator {
    private struct SolarTimeResult {
        let hour: Double
        let dayOfYear: Int
        let fallbackWasUsed: Bool
        let appliedHighLatitudeRule: PrayerHighLatitudeRule?
        let failureReason: String?
    }

    func fajrDate(for date: Date, location: CLLocationCoordinate2D, timeZone: TimeZone, method: CalculationMethod, adjustmentMinutes: Int) -> Date? {
        let latitude = location.latitude
        let longitude = location.longitude
        let fajrAngle = method.fajrAngle
        let rule: PrayerHighLatitudeRule = abs(latitude) > 55 ? .middleOfNight : .none

        guard let fajrTime = solarTimeResult(for: date, latitude: latitude, longitude: longitude, timeZone: timeZone, zenith: 90.0 + fajrAngle, isMorning: true, highLatitudeRule: rule)?.hour else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfDay = calendar.startOfDay(for: date)
        let fajrDate = startOfDay.addingTimeInterval(fajrTime * 3600)
        let adjusted = calendar.date(byAdding: .minute, value: adjustmentMinutes, to: fajrDate) ?? fajrDate
        return roundedDate(adjusted, policy: .nearestMinute)
    }

    func maghribDate(
        for date: Date,
        location: CLLocationCoordinate2D,
        timeZone: TimeZone,
        adjustmentMinutes: Int
    ) -> Date? {
        let latitude = location.latitude
        let longitude = location.longitude

        guard let sunsetTime = solarTimeResult(
            for: date,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone,
            zenith: 90.833,
            isMorning: false,
            highLatitudeRule: .none
        )?.hour else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfDay = calendar.startOfDay(for: date)
        let maghribDate = startOfDay.addingTimeInterval(sunsetTime * 3600)
        let adjusted = calendar.date(byAdding: .minute, value: adjustmentMinutes, to: maghribDate) ?? maghribDate
        return roundedDate(adjusted, policy: .nearestMinute)
    }

    func sunriseDate(
        for date: Date,
        location: CLLocationCoordinate2D,
        timeZone: TimeZone,
        adjustmentMinutes: Int
    ) -> Date? {
        let latitude = location.latitude
        let longitude = location.longitude

        guard let sunriseTime = solarTimeResult(
            for: date,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone,
            zenith: 90.833,
            isMorning: true,
            highLatitudeRule: .none
        )?.hour else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startOfDay = calendar.startOfDay(for: date)
        let sunriseDate = startOfDay.addingTimeInterval(sunriseTime * 3600)
        let adjusted = calendar.date(byAdding: .minute, value: adjustmentMinutes, to: sunriseDate) ?? sunriseDate
        return roundedDate(adjusted, policy: .nearestMinute)
    }

    func localPrayerWindow(
        for date: Date,
        location: CLLocationCoordinate2D,
        timeZone: TimeZone,
        method: CalculationMethod,
        fajrBeginAdjustmentMinutes: Int,
        fajrEndAdjustmentMinutes: Int,
        maghribAdjustmentMinutes: Int,
        highLatitudeRule: PrayerHighLatitudeRule,
        roundingPolicy: PrayerRoundingPolicy
    ) -> DailyPrayerWindow? {
        let latitude = location.latitude
        let longitude = location.longitude
        let profile = method.profile
        let requestedHighLatitudeRule = highLatitudeRule
        let resolvedHighLatitudeRule = highLatitudeRule == .automatic ? profile.defaultHighLatitudeRule : highLatitudeRule
        let fajrHighLatitudeRule: PrayerHighLatitudeRule = resolvedHighLatitudeRule == .automatic ? .middleOfNight : resolvedHighLatitudeRule

        guard let fajrResult = solarTimeResult(
            for: date,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone,
            zenith: 90.0 + profile.fajrAngleDegrees,
            isMorning: true,
            highLatitudeRule: fajrHighLatitudeRule
        ),
        let sunriseResult = solarTimeResult(
            for: date,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone,
            zenith: 90.833,
            isMorning: true,
            highLatitudeRule: .none
        ),
        let sunsetResult = solarTimeResult(
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
        let rawFajr = startOfDay.addingTimeInterval(fajrResult.hour * 3600)
        let rawSunrise = startOfDay.addingTimeInterval(sunriseResult.hour * 3600)
        let rawMaghrib = startOfDay.addingTimeInterval(sunsetResult.hour * 3600)

        let adjustedFajr = roundedDate(
            calendar.date(byAdding: .minute, value: fajrBeginAdjustmentMinutes, to: rawFajr) ?? rawFajr,
            policy: roundingPolicy
        )
        let adjustedSunrise = roundedDate(
            calendar.date(byAdding: .minute, value: fajrEndAdjustmentMinutes, to: rawSunrise) ?? rawSunrise,
            policy: roundingPolicy
        )
        let adjustedMaghrib = roundedDate(
            calendar.date(byAdding: .minute, value: maghribAdjustmentMinutes, to: rawMaghrib) ?? rawMaghrib,
            policy: roundingPolicy
        )

        var validationWarnings: [String] = []
        if adjustedFajr >= adjustedSunrise {
            validationWarnings.append("fajr_begin_not_before_fajr_end")
        }
        if adjustedSunrise > adjustedMaghrib {
            validationWarnings.append("fajr_end_after_maghrib")
        }
        guard validationWarnings.isEmpty else {
            return nil
        }

        let fallbackWasUsed = fajrResult.fallbackWasUsed || sunriseResult.fallbackWasUsed || sunsetResult.fallbackWasUsed
        let fallbackChain = [
            fajrResult.fallbackWasUsed ? "fajr_begin:\(fajrResult.appliedHighLatitudeRule?.rawValue ?? "unknown")" : nil,
            sunriseResult.fallbackWasUsed ? "fajr_end:\(sunriseResult.appliedHighLatitudeRule?.rawValue ?? "unknown")" : nil,
            sunsetResult.fallbackWasUsed ? "maghrib:\(sunsetResult.appliedHighLatitudeRule?.rawValue ?? "unknown")" : nil
        ].compactMap { $0 }

        return DailyPrayerWindow(
            date: calendar.startOfDay(for: date),
            fajrStart: adjustedFajr,
            fajrEnd: adjustedSunrise,
            maghrib: adjustedMaghrib,
            calculationSource: .localCalculated,
            methodID: profile.id,
            methodDisplayName: profile.displayName,
            authorityName: profile.authorityName,
            fajrAngleDegrees: profile.fajrAngleDegrees,
            highLatitudeRuleRequested: requestedHighLatitudeRule,
            highLatitudeRuleApplied: fallbackWasUsed ? (fajrResult.appliedHighLatitudeRule ?? sunriseResult.appliedHighLatitudeRule ?? sunsetResult.appliedHighLatitudeRule) : .none,
            highLatitudeFallbackWasUsed: fallbackWasUsed,
            fajrBeginSource: .localSolarAngle,
            fajrEndSource: .solarSunrise,
            maghribSource: .localSolarSunset,
            adjustmentsApplied: PrayerBoundaryAdjustments(
                fajrBeginMinutes: fajrBeginAdjustmentMinutes,
                fajrEndMinutes: fajrEndAdjustmentMinutes,
                maghribMinutes: maghribAdjustmentMinutes
            ),
            diagnostics: PrayerCalculationDiagnostics(
                engineVersion: 1,
                methodVersion: 1,
                inputLatitude: latitude,
                inputLongitude: longitude,
                inputTimeZoneIdentifier: timeZone.identifier,
                dayOfYearUsed: fajrResult.dayOfYear,
                solarAlgorithmName: "NOAA sunrise equation",
                rawFajrHour: fajrResult.hour,
                rawSunriseHour: sunriseResult.hour,
                rawSunsetHour: sunsetResult.hour,
                highLatitudeFailureReason: fajrResult.failureReason ?? sunriseResult.failureReason ?? sunsetResult.failureReason,
                validationWarnings: validationWarnings,
                fallbackChain: fallbackChain
            ),
            isValid: true
        )
    }

    private func solarTimeResult(for date: Date, latitude: Double, longitude: Double, timeZone: TimeZone, zenith: Double, isMorning: Bool, highLatitudeRule: PrayerHighLatitudeRule) -> SolarTimeResult? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let localDate = calendar.startOfDay(for: date)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: localDate) ?? 1
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
            if highLatitudeRule == .middleOfNight || highLatitudeRule == .automatic || highLatitudeRule == .angleBased || highLatitudeRule == .oneSeventhOfNight {
                guard let fallback = middleOfNightFallback(date: localDate, latitude: latitude, longitude: longitude, timeZone: timeZone, isMorning: isMorning) else {
                    return nil
                }
                return SolarTimeResult(
                    hour: fallback,
                    dayOfYear: dayOfYear,
                    fallbackWasUsed: true,
                    appliedHighLatitudeRule: .middleOfNight,
                    failureReason: "solar_angle_unavailable"
                )
            }
            return nil
        }

        let h = isMorning ? 360.0 - rad2deg(acos(cosH)) : rad2deg(acos(cosH))
        let hHours = h / 15.0

        let tLocal = hHours + ra - (0.06571 * t) - 6.622
        var ut = tLocal - lngHour
        ut = normalizeHours(ut)

        let offsetReferenceDate = localDate.addingTimeInterval(12 * 3600)
        let timeZoneHours = Double(timeZone.secondsFromGMT(for: offsetReferenceDate)) / 3600.0
        let localTime = ut + timeZoneHours
        return SolarTimeResult(
            hour: normalizeHours(localTime),
            dayOfYear: dayOfYear,
            fallbackWasUsed: false,
            appliedHighLatitudeRule: nil,
            failureReason: nil
        )
    }

    private func middleOfNightFallback(date: Date, latitude: Double, longitude: Double, timeZone: TimeZone, isMorning: Bool) -> Double? {
        guard let sunrise = solarTimeResult(for: date, latitude: latitude, longitude: longitude, timeZone: timeZone, zenith: 90.833, isMorning: true, highLatitudeRule: .none)?.hour,
              let sunset = solarTimeResult(for: date, latitude: latitude, longitude: longitude, timeZone: timeZone, zenith: 90.833, isMorning: false, highLatitudeRule: .none)?.hour else {
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

    private func roundedDate(_ date: Date, policy: PrayerRoundingPolicy) -> Date {
        let minutes = date.timeIntervalSinceReferenceDate / 60.0
        let roundedMinutes: Double
        switch policy {
        case .nearestMinute:
            roundedMinutes = minutes.rounded()
        case .floorMinute:
            roundedMinutes = floor(minutes)
        case .ceilMinute:
            roundedMinutes = ceil(minutes)
        }
        return Date(timeIntervalSinceReferenceDate: roundedMinutes * 60.0)
    }
}
