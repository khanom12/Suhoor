import CoreLocation
import Foundation

enum BootstrapEvaluator {
    static func evaluate(
        settings: AppSettings,
        locationAuthorizationStatus: CLAuthorizationStatus,
        lastLocation: Date?,
        permissionSnapshot: PermissionSnapshot
    ) -> AppBootstrapState {
        guard settings.isConfigured else {
            return .welcome
        }

        let hasBlockingPermission = permissionSnapshot.presentations.values.contains(where: \.isBlocking)
        if hasBlockingPermission {
            return .permissions
        }

        if settings.locationMode == .auto {
            let isAuthorized = locationAuthorizationStatus == .authorizedAlways || locationAuthorizationStatus == .authorizedWhenInUse
            if !isAuthorized || lastLocation == nil {
                return .permissions
            }
        }

        return .home
    }
}
