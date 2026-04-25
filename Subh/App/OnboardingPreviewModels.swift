import Foundation

enum OnboardingPath: String, Equatable, Sendable {
    case ramadan
    case fajr

    static func resolve(currentHijriMonth: HijriMonth?) -> Self {
        currentHijriMonth == .ramadan ? .ramadan : .fajr
    }

    var flowSteps: [OnboardingStep] {
        switch self {
        case .ramadan:
            return [.valuePreview, .location, .relationship, .futureVisualization, .permissions, .success]
        case .fajr:
            return [.valuePreview, .location, .relationship, .supportBehavior, .permissions, .success]
        }
    }

    var previewWakeLabel: String {
        switch self {
        case .ramadan:
            return "Subh wake"
        case .fajr:
            return "Next wake"
        }
    }

    var valueTitle: String {
        switch self {
        case .ramadan:
            return "Wake in time for suhoor"
        case .fajr:
            return "Wake for and around Fajr"
        }
    }

    var valueBody: String {
        switch self {
        case .ramadan:
            return "Subh keeps your wake aligned with local Fajr so you have time to prepare and begin the morning with confidence."
        case .fajr:
            return "Build a morning plan that keeps your next wake anchored to Fajr and adapts automatically as local prayer times shift."
        }
    }

    func valuePrimaryActionTitle(for dayLabel: String) -> String {
        switch self {
        case .ramadan:
            return dayLabel == "Today" ? "Set today’s suhoor wake" : "Set tomorrow’s suhoor wake"
        case .fajr:
            return "Set my morning plan"
        }
    }

    var locationTitle: String {
        switch self {
        case .ramadan:
            return "Get your local Fajr time"
        case .fajr:
            return "Trust your local prayer times"
        }
    }

    var locationBody: String {
        switch self {
        case .ramadan:
            return "Use your location or choose a city so your suhoor wake stays accurate as Fajr shifts."
        case .fajr:
            return "Your morning plan follows local Fajr times. Use your location or choose a city, and change the calculation method if needed."
        }
    }

    var locationTrustBullets: [String] {
        switch self {
        case .ramadan:
            return []
        case .fajr:
            return [
                "Used to calculate accurate local prayer times",
                "Change your city or method anytime"
            ]
        }
    }

    var showsCalculationMethodSummary: Bool {
        self == .fajr
    }

    var relationshipTitle: String {
        switch self {
        case .ramadan:
            return "How much time do you want before Fajr?"
        case .fajr:
            return "Choose your wake relation to Fajr"
        }
    }

    var relationshipBody: String {
        switch self {
        case .ramadan:
            return "Choose the buffer you want before Fajr so suhoor feels practical and unhurried."
        case .fajr:
            return "Decide how much space you want before Fajr so your mornings start the way you intend."
        }
    }

    func relationshipSentence(_ minutes: Int) -> String {
        switch self {
        case .ramadan:
            return "Subh wake \(minutes) min before Fajr."
        case .fajr:
            return "Your default wake is \(minutes) min before Fajr."
        }
    }

    var relationshipPresetLabels: [Int: String] {
        switch self {
        case .ramadan:
            return [
                30: "Quick morning",
                45: "Comfortable",
                60: "Recommended",
                75: "Unhurried",
                90: "Relaxed"
            ]
        case .fajr:
            return [
                30: "Close to Fajr",
                45: "Buffer",
                60: "Recommended",
                75: "More time",
                90: "Long buffer"
            ]
        }
    }

    var futureVisualizationTitle: String {
        switch self {
        case .ramadan:
            return "Your Ramadan wake stays on time"
        case .fajr:
            return "Your morning plan adapts automatically"
        }
    }

    var futureVisualizationCardTitle: String {
        switch self {
        case .ramadan:
            return "Next 5 Ramadan mornings"
        case .fajr:
            return "Next 5 mornings"
        }
    }

    func futureVisualizationOffsetLine(_ minutes: Int) -> String {
        switch self {
        case .ramadan:
            return "Your suhoor wake stays \(minutes) minutes before Fajr as Fajr shifts through the month."
        case .fajr:
            return "Your wake stays \(minutes) minutes before Fajr as Fajr shifts day to day."
        }
    }

    func futureVisualizationTableOffset(_ minutes: Int) -> String {
        switch self {
        case .ramadan:
            return "Subh wake: \(minutes)m before Fajr"
        case .fajr:
            return "Wake relation: \(minutes)m before Fajr"
        }
    }

    var supportBehaviorTitle: String {
        "Choose the support around your wake"
    }

    var supportBehaviorBody: String {
        "Your main wake follows the relation you chose. Add a reminder before Fajr or a follow-up after your wake if that helps."
    }

    var permissionsTitle: String {
        switch self {
        case .ramadan:
            return "Make your Ramadan wake reliable"
        case .fajr:
            return "Keep your wake reliable"
        }
    }

    var permissionsBody: String {
        switch self {
        case .ramadan:
            return "Alarm access helps your pre-dawn wake ring even in Silent Mode."
        case .fajr:
            return "Alarm access helps your main wake ring reliably around Fajr. Notifications support reminders and fallback delivery where needed."
        }
    }

    var alwaysShowNotificationsRow: Bool {
        self == .fajr
    }

    var successTitle: String {
        switch self {
        case .ramadan:
            return "Your Ramadan wake is ready"
        case .fajr:
            return "Your morning plan is ready"
        }
    }

    var successBody: String {
        switch self {
        case .ramadan:
            return "Your next wake is set before Fajr. Subh can support you through Fajr, fasting contexts, and ordinary mornings after Ramadan."
        case .fajr:
            return "Your next wake is set around Fajr. You can add fasting days, Qada days, and other special mornings later in Plans."
        }
    }

    var successPrimaryActionTitle: String {
        "Go to Home"
    }

    var successSecondaryActionTitle: String? {
        switch self {
        case .ramadan:
            return nil
        case .fajr:
            return "Add fasting support in Plans"
        }
    }
}

enum OnboardingStep: Int, CaseIterable, Hashable, Sendable {
    case valuePreview
    case location
    case relationship
    case supportBehavior
    case futureVisualization
    case permissions
    case success
}

struct OnboardingTomorrowPreview: Equatable {
    let dateText: String
    let targetDate: Date?
    let fajrDate: Date?
    let suhoorDate: Date?
    let fajrTimeText: String?
    let suhoorTimeText: String?
    let statusText: String?

    var wakeDate: Date? { suhoorDate }
    var wakeTimeText: String? { suhoorTimeText }
}

struct SchedulePreviewRow: Identifiable, Equatable {
    let id: String
    let date: Date
    let dayLabel: String
    let fajr: Date
    let suhoor: Date

    var wake: Date { suhoor }
}

enum OnboardingActivationState: Equatable {
    case idle
    case attempting
    case succeeded(schedule: DaySchedule)
    case failed(message: String)
}
