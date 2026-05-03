import Foundation

enum OnboardingStep: Int, CaseIterable, Hashable, Sendable {
    case valuePreview
    case location
    case permissions
    case success
}

enum OnboardingBlockedReason: Equatable, Sendable {
    case missingLocation
    case missingPrayerTime
    case missingAlarmKit
}

enum OnboardingReadyState: Equatable, Sendable {
    case ready
    case readyNotificationsOff
    case blocked
}

struct OnboardingReadiness: Equatable, Sendable {
    let locationReady: Bool
    let prayerTimeReady: Bool
    let alarmKitState: AppPermissionState
    let notificationState: AppPermissionState

    var alarmKitReady: Bool {
        alarmKitState == .authorized
    }

    var notificationsReady: Bool {
        notificationState == .authorized
    }

    var notificationsRecommended: Bool {
        !notificationsReady
    }

    var canCompleteOnboarding: Bool {
        locationReady && prayerTimeReady && alarmKitReady
    }

    var blockedReason: OnboardingBlockedReason? {
        if !locationReady {
            return .missingLocation
        }
        if !alarmKitReady {
            return .missingAlarmKit
        }
        if !prayerTimeReady {
            return .missingPrayerTime
        }
        return nil
    }

    var readyState: OnboardingReadyState {
        guard canCompleteOnboarding else { return .blocked }
        return notificationsReady ? .ready : .readyNotificationsOff
    }
}

struct OnboardingTomorrowPreview: Equatable {
    let previewLabelText: String
    let dateText: String
    let locationText: String?
    let isExample: Bool
    let targetDate: Date?
    let fajrDate: Date?
    let fajrEndDate: Date?
    let wakeDate: Date?
    let fajrTimeText: String?
    let fajrEndTimeText: String?
    let wakeTimeText: String?
    let statusText: String?
    let alarmStatusText: String?
    let notificationStatusText: String?

    init(
        previewLabelText: String = Strings.Onboarding.previewLabelActual,
        dateText: String,
        locationText: String? = nil,
        isExample: Bool = false,
        targetDate: Date?,
        fajrDate: Date?,
        fajrEndDate: Date? = nil,
        wakeDate: Date?,
        fajrTimeText: String?,
        fajrEndTimeText: String? = nil,
        wakeTimeText: String?,
        statusText: String?,
        alarmStatusText: String? = nil,
        notificationStatusText: String? = nil
    ) {
        self.previewLabelText = previewLabelText
        self.dateText = dateText
        self.locationText = locationText
        self.isExample = isExample
        self.targetDate = targetDate
        self.fajrDate = fajrDate
        self.fajrEndDate = fajrEndDate
        self.wakeDate = wakeDate
        self.fajrTimeText = fajrTimeText
        self.fajrEndTimeText = fajrEndTimeText
        self.wakeTimeText = wakeTimeText
        self.statusText = statusText
        self.alarmStatusText = alarmStatusText
        self.notificationStatusText = notificationStatusText
    }
}
