import CoreLocation
import Foundation
import Testing
@testable import Subh

@Suite
@MainActor
struct OnboardingActivationTests {
    @Test
    func readinessRequiresAlarmKitEvenWhenNotificationsAreAuthorized() {
        let readiness = OnboardingReadiness(
            locationReady: true,
            prayerTimeReady: true,
            alarmKitState: .unavailable,
            notificationState: .authorized
        )

        #expect(readiness.canCompleteOnboarding == false)
        #expect(readiness.blockedReason == .missingAlarmKit)
        #expect(readiness.readyState == .blocked)
    }

    @Test
    func notificationsDeniedDoNotBlockCompletionWhenAlarmKitIsReady() {
        let readiness = OnboardingReadiness(
            locationReady: true,
            prayerTimeReady: true,
            alarmKitState: .authorized,
            notificationState: .denied
        )

        #expect(readiness.canCompleteOnboarding)
        #expect(readiness.blockedReason == nil)
        #expect(readiness.readyState == .readyNotificationsOff)
    }

    @Test
    func missingLocationTakesPrecedenceOverOtherBlockedReasons() {
        let readiness = OnboardingReadiness(
            locationReady: false,
            prayerTimeReady: false,
            alarmKitState: .denied,
            notificationState: .authorized
        )

        #expect(readiness.canCompleteOnboarding == false)
        #expect(readiness.blockedReason == .missingLocation)
    }

    @Test
    func missingPrayerTimeBlocksAfterLocationAndAlarmKitAreReady() {
        let readiness = OnboardingReadiness(
            locationReady: true,
            prayerTimeReady: false,
            alarmKitState: .authorized,
            notificationState: .authorized
        )

        #expect(readiness.canCompleteOnboarding == false)
        #expect(readiness.blockedReason == .missingPrayerTime)
    }

    @Test
    func configuredUserWithDeniedAlarmKitRoutesToRepair() {
        let state = BootstrapEvaluator.evaluate(
            settings: Self.configuredFixedCitySettings(),
            locationAuthorizationStatus: .denied,
            lastLocation: nil,
            permissionSnapshot: Self.permissionSnapshot(
                location: .authorized,
                alarmKit: .denied,
                notifications: .authorized
            )
        )

        #expect(state == .permissions)
    }

    @Test
    func configuredUserWithUnavailableAlarmKitRoutesToRepair() {
        let state = BootstrapEvaluator.evaluate(
            settings: Self.configuredFixedCitySettings(),
            locationAuthorizationStatus: .denied,
            lastLocation: nil,
            permissionSnapshot: Self.permissionSnapshot(
                location: .authorized,
                alarmKit: .unavailable,
                notifications: .authorized
            )
        )

        #expect(state == .permissions)
    }

    @Test
    func configuredUserWithNotificationsDeniedStillRoutesHome() {
        let state = BootstrapEvaluator.evaluate(
            settings: Self.configuredFixedCitySettings(),
            locationAuthorizationStatus: .denied,
            lastLocation: nil,
            permissionSnapshot: Self.permissionSnapshot(
                location: .authorized,
                alarmKit: .authorized,
                notifications: .denied
            )
        )

        #expect(state == .home)
    }

    private static func configuredFixedCitySettings() -> AppSettings {
        var settings = AppSettings.default
        settings.isConfigured = true
        settings.locationMode = .fixed
        settings.fixedLocation = FixedLocation(latitude: 43.6532, longitude: -79.3832)
        return settings
    }

    private static func permissionSnapshot(
        location: AppPermissionState,
        alarmKit: AppPermissionState,
        notifications: AppPermissionState
    ) -> PermissionSnapshot {
        PermissionSnapshot(
            summaryText: "",
            alarmAuthorizationText: "",
            notificationAuthorizationText: "",
            presentations: [
                .location: presentation(kind: .location, state: location, isBlocking: location != .authorized),
                .alarmKit: presentation(kind: .alarmKit, state: alarmKit, isBlocking: alarmKit != .authorized),
                .notifications: presentation(kind: .notifications, state: notifications, isBlocking: false)
            ]
        )
    }

    private static func presentation(
        kind: AppPermissionKind,
        state: AppPermissionState,
        isBlocking: Bool
    ) -> PermissionPresentation {
        PermissionPresentation(
            kind: kind,
            state: state,
            title: kind.rawValue,
            statusText: "",
            message: "",
            actionTitle: nil,
            secondaryActionTitle: nil,
            showsProgress: false,
            showsSimulatorHint: false,
            isBlocking: isBlocking
        )
    }
}
