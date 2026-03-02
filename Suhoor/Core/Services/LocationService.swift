import Foundation
import CoreLocation
import MapKit
import SwiftUI
import Combine
import os

enum LocationPermissionState: Equatable {
    case notDetermined
    case authorizedNoFixYet
    case authorizedWithFix
    case denied
    case restricted
}

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var lastLocation: CLLocation?
    @Published var locationName: String = ""

    private let manager: CLLocationManager
    private let geocodeDistanceThreshold: CLLocationDistance = 1000
    private let geocodeCooldown: TimeInterval = 60
    private var lastGeocodeLocation: CLLocation?
    private var lastGeocodeDate: Date?

    override init() {
        self.manager = CLLocationManager()
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var permissionState: LocationPermissionState {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return lastLocation == nil ? .authorizedNoFixYet : .authorizedWithFix
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    var canRequestAuthorization: Bool {
        authorizationStatus == .notDetermined
    }

    var shouldOfferSettingsRedirect: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var hasUsableAutoLocation: Bool {
        permissionState == .authorizedWithFix
    }

    var shouldShowLocatingState: Bool {
        permissionState == .authorizedNoFixYet
    }

    var appPermissionState: AppPermissionState {
        switch permissionState {
        case .notDetermined:
            return .notDetermined
        case .authorizedNoFixYet:
            return .needsFollowUp
        case .authorizedWithFix:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        }
    }

#if targetEnvironment(simulator)
    var shouldShowSimulatorHint: Bool {
        permissionState == .authorizedNoFixYet
    }
#else
    var shouldShowSimulatorHint: Bool { false }
#endif

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
        guard let latest = lastLocation else { return }
        Task { await updateLocationNameIfNeeded(for: latest) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            return
        }
        if let clError = error as? CLError, clError.code == .denied {
            return
        }
        Logging.location.error("Location error: \(error.localizedDescription)")
    }

    private func shouldGeocode(_ location: CLLocation) -> Bool {
        if let lastLocation = lastGeocodeLocation,
           location.distance(from: lastLocation) < geocodeDistanceThreshold {
            if let lastDate = lastGeocodeDate,
               Date().timeIntervalSince(lastDate) < geocodeCooldown {
                return false
            }
        }
        return true
    }

    private func updateLocationNameIfNeeded(for location: CLLocation) async {
        guard shouldGeocode(location) else { return }
        lastGeocodeLocation = location
        lastGeocodeDate = Date()

        if #available(iOS 26.0, *) {
            if let request = MKReverseGeocodingRequest(location: location) {
                do {
                    let items = try await request.mapItems
                    if let item = items.first {
                        await MainActor.run {
                            locationName = item.addressRepresentations?.cityName
                                ?? item.name
                                ?? ""
                        }
                    }
                } catch {
                    Logging.location.error("Reverse geocode error: \(error.localizedDescription)")
                }
            }
        } else {
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    await MainActor.run {
                        locationName = placemark.locality ?? placemark.name ?? ""
                    }
                }
            } catch {
                Logging.location.error("Reverse geocode error: \(error.localizedDescription)")
            }
        }
    }
}
