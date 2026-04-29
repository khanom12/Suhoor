import CoreGraphics
import Foundation

enum MorningHeroWakeAdjustmentMapper {
    static func wakeTime(
        forX x: CGFloat,
        width: CGFloat,
        minTime: Date,
        maxTime: Date,
        stepMinutes: Int
    ) -> Date {
        guard width > 0 else {
            return roundedWakeTime(minTime, minTime: minTime, maxTime: maxTime, stepMinutes: stepMinutes)
        }

        let endpointSnapDistance = endpointSnapDistance(for: width)
        if x <= endpointSnapDistance {
            return minTime
        }
        if x >= width - endpointSnapDistance {
            return maxTime
        }

        let ratio = min(max(x / width, 0), 1)
        let duration = maxTime.timeIntervalSince(minTime)
        let rawTime = minTime.addingTimeInterval(duration * Double(ratio))
        return roundedWakeTime(rawTime, minTime: minTime, maxTime: maxTime, stepMinutes: stepMinutes)
    }

    private static func endpointSnapDistance(for width: CGFloat) -> CGFloat {
        min(max(6, width * 0.02), width * 0.10)
    }

    static func roundedWakeTime(
        _ wakeTime: Date,
        minTime: Date,
        maxTime: Date,
        stepMinutes: Int
    ) -> Date {
        let step = max(1, stepMinutes)
        let stepSeconds = Double(step * 60)
        let offset = wakeTime.timeIntervalSince(minTime)
        let roundedOffset = (offset / stepSeconds).rounded() * stepSeconds
        let rounded = minTime.addingTimeInterval(roundedOffset)
        return min(max(rounded, minTime), maxTime)
    }
}
