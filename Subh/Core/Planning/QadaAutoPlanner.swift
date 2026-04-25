import Foundation

enum QadaPlanStrategy: String, CaseIterable, Identifiable {
    case focused
    case balanced
    case gentle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focused:
            return "Focused"
        case .balanced:
            return "Balanced"
        case .gentle:
            return "Gentle"
        }
    }

    var description: String {
        switch self {
        case .focused:
            return "Plan early with short breaks after blocks of 10."
        case .balanced:
            return "Add a day off between Qada days."
        case .gentle:
            return "Spread out with two days between Qada days."
        }
    }
}

struct QadaAutoPlanOptions: Equatable, Sendable {
    let strategy: QadaPlanStrategy
    let avoidShawwal: Bool
    let avoidMajorSunnah: Bool
}

struct QadaAutoPlanResult: Equatable, Sendable {
    let dates: [Date]
    let options: QadaAutoPlanOptions
    let fallbackNote: String?
}

enum QadaAutoPlanner {
    static func generate(
        desiredCount: Int,
        startDate: Date,
        endDate: Date,
        options: QadaAutoPlanOptions,
        existingDateKeys: Set<String>,
        existingQadaKeys: Set<String>,
        calendar: AdjustedHijriCalendar = .shared,
        timeZone: TimeZone = .current
    ) -> QadaAutoPlanResult {
        let baseline = plan(
            desiredCount: desiredCount,
            startDate: startDate,
            endDate: endDate,
            options: options,
            existingDateKeys: existingDateKeys,
            existingQadaKeys: existingQadaKeys,
            calendar: calendar,
            timeZone: timeZone
        )

        if baseline.count == desiredCount {
            return QadaAutoPlanResult(dates: baseline, options: options, fallbackNote: nil)
        }

        if options.avoidMajorSunnah {
            let relaxedMajor = QadaAutoPlanOptions(
                strategy: options.strategy,
                avoidShawwal: options.avoidShawwal,
                avoidMajorSunnah: false
            )
            let relaxedDates = plan(
                desiredCount: desiredCount,
                startDate: startDate,
                endDate: endDate,
                options: relaxedMajor,
                existingDateKeys: existingDateKeys,
                existingQadaKeys: existingQadaKeys,
                calendar: calendar,
                timeZone: timeZone
            )
            if relaxedDates.count == desiredCount {
                return QadaAutoPlanResult(
                    dates: relaxedDates,
                    options: relaxedMajor,
                    fallbackNote: "Expanded the plan beyond major Sunnah dates to reach your target."
                )
            }
        }

        if options.avoidShawwal {
            let relaxedAll = QadaAutoPlanOptions(
                strategy: options.strategy,
                avoidShawwal: false,
                avoidMajorSunnah: false
            )
            let relaxedDates = plan(
                desiredCount: desiredCount,
                startDate: startDate,
                endDate: endDate,
                options: relaxedAll,
                existingDateKeys: existingDateKeys,
                existingQadaKeys: existingQadaKeys,
                calendar: calendar,
                timeZone: timeZone
            )
            if !relaxedDates.isEmpty {
                return QadaAutoPlanResult(
                    dates: relaxedDates,
                    options: relaxedAll,
                    fallbackNote: "Expanded the plan to include Shawwal to reach your target."
                )
            }
        }

        return QadaAutoPlanResult(dates: baseline, options: options, fallbackNote: "Not enough eligible days were found before the next Ramadan.")
    }

    private static func plan(
        desiredCount: Int,
        startDate: Date,
        endDate: Date,
        options: QadaAutoPlanOptions,
        existingDateKeys: Set<String>,
        existingQadaKeys: Set<String>,
        calendar: AdjustedHijriCalendar,
        timeZone: TimeZone
    ) -> [Date] {
        guard desiredCount > 0 else { return [] }
        var results: [Date] = []
        var calendarGregorian = Calendar(identifier: .gregorian)
        calendarGregorian.timeZone = timeZone
        let start = calendarGregorian.startOfDay(for: startDate)
        let end = calendarGregorian.startOfDay(for: endDate)

        var current = start
        var currentStreak = 0
        var cooldownUntil: Date?
        var lastSelected: Date?

        while current <= end && results.count < desiredCount {
            let key = DateHelpers.dayIdentifier(for: current, timeZone: timeZone)
            let eligible = isEligible(
                date: current,
                key: key,
                options: options,
                existingDateKeys: existingDateKeys,
                existingQadaKeys: existingQadaKeys,
                calendar: calendar,
                timeZone: timeZone
            )

            let spacingOK: Bool
            switch options.strategy {
            case .focused:
                if let cooldownUntil {
                    spacingOK = current >= cooldownUntil
                } else {
                    spacingOK = true
                }
            case .balanced:
                spacingOK = meetsGapRequirement(current: current, lastSelected: lastSelected, minGapDays: 1, calendar: calendarGregorian)
            case .gentle:
                spacingOK = meetsGapRequirement(current: current, lastSelected: lastSelected, minGapDays: 2, calendar: calendarGregorian)
            }

            if eligible && spacingOK {
                results.append(current)
                lastSelected = current
                switch options.strategy {
                case .focused:
                    currentStreak += 1
                    if currentStreak >= 10 {
                        let breakDays = 1
                        cooldownUntil = calendarGregorian.date(byAdding: .day, value: breakDays + 1, to: current)
                        currentStreak = 0
                    }
                case .balanced, .gentle:
                    break
                }
            }

            guard let next = calendarGregorian.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
            if let cooldownUntilDate = cooldownUntil, current >= cooldownUntilDate {
                cooldownUntil = nil
            }
        }

        return results
    }

    private static func meetsGapRequirement(
        current: Date,
        lastSelected: Date?,
        minGapDays: Int,
        calendar: Calendar
    ) -> Bool {
        guard let lastSelected else { return true }
        guard let nextAllowed = calendar.date(byAdding: .day, value: minGapDays + 1, to: lastSelected) else { return true }
        return current >= nextAllowed
    }

    private static func isEligible(
        date: Date,
        key: String,
        options: QadaAutoPlanOptions,
        existingDateKeys: Set<String>,
        existingQadaKeys: Set<String>,
        calendar: AdjustedHijriCalendar,
        timeZone: TimeZone
    ) -> Bool {
        if existingDateKeys.contains(key) || existingQadaKeys.contains(key) {
            return false
        }
        if FastIntentEngine.isForbiddenToFast(date, timeZone: timeZone) {
            return false
        }
        if FastIntentEngine.isRamadan(date, timeZone: timeZone) {
            return false
        }
        if options.avoidShawwal {
            if let components = calendar.adjustedComponents(for: date, timeZone: timeZone),
               components.month == .shawwal {
                return false
            }
        }
        if options.avoidMajorSunnah {
            let tags = FastIntentEngine.dateDerivedObservanceTags(
                for: date,
                timeZone: timeZone,
                includeShawwalPotential: true
            )
            if tags.contains(.ashura) || tags.contains(.arafah) || tags.contains(.dhulHijjahFirstNine) || tags.contains(.whiteDays) || tags.contains(.shawwalSix) {
                return false
            }
        }
        return true
    }
}
