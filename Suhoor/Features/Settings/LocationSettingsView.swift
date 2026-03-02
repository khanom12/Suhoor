import SwiftUI
import MapKit
import UIKit

struct LocationSettingsView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    var body: some View {
        Form {
            Section {
                Picker(Strings.Settings.locationMode, selection: $settingsStore.settings.locationMode) {
                    Text(Strings.Settings.locationAutomatic).tag(LocationMode.auto)
                    Text(Strings.Settings.locationChooseCity).tag(LocationMode.fixed)
                }
                .pickerStyle(.segmented)
                .onChange(of: settingsStore.settings.locationMode) { _, newValue in
                    if newValue == .fixed, settingsStore.settings.fixedLocation == nil {
                        applySelectedCity(City.defaultCity)
                    }
                    scheduleManager.requestRefresh(reason: .settingsChanged)
                }
            }

            if settingsStore.settings.locationMode == .auto {
                Section {
                    valueRow(
                        title: Strings.Settings.currentCityTitle,
                        value: locationService.locationName.isEmpty
                            ? Strings.Settings.locationWaiting
                            : locationService.locationName
                    )

                    HStack {
                        Text(Strings.Settings.locationStatus)
                        Spacer()
                        SettingsStatusBadge(text: permissionStatusText, tone: permissionBadgeTone)
                    }

                    Text(permissionMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let actionTitle = permissionActionTitle {
                        Button(actionTitle) {
                            handleLocationAction()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } header: {
                    Text(Strings.Settings.locationAutomatic)
                }
            } else {
                Section {
                    NavigationLink {
                        LocationSearchView(
                            selectedName: fixedLocationName,
                            onSelectCity: applySelectedCity,
                            onSelectMapItem: applyMapItem
                        )
                    } label: {
                        valueRow(
                            title: Strings.Settings.cityLabel,
                            value: fixedLocationName ?? City.defaultCity.name
                        )
                    }
                } header: {
                    Text(Strings.Settings.locationChooseCity)
                } footer: {
                    Text(Strings.Settings.fixedLocationHelper)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.Settings.locationSection)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if settingsStore.settings.locationMode == .fixed, settingsStore.settings.fixedLocation == nil {
                applySelectedCity(City.defaultCity)
            }
        }
    }

    private func valueRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var fixedLocationName: String? {
        SettingsSummaryFormatter.effectiveLocationName(settings: settingsStore.settings, locationService: locationService)
    }

    private var permissionStatusText: String {
        switch locationService.permissionState {
        case .authorizedWithFix:
            return Strings.Settings.badgeReady
        case .authorizedNoFixYet:
            return Strings.Settings.badgeLocating
        case .notDetermined, .denied, .restricted:
            return Strings.Settings.badgeNeedsAttention
        }
    }

    private var permissionBadgeTone: SettingsBadgeTone {
        switch locationService.permissionState {
        case .authorizedWithFix:
            return .success
        case .authorizedNoFixYet:
            return .warning
        case .notDetermined, .denied, .restricted:
            return .critical
        }
    }

    private var permissionMessage: String {
        switch locationService.permissionState {
        case .authorizedWithFix:
            return Strings.Settings.locationAutomaticReady
        case .authorizedNoFixYet:
            return Strings.Settings.locationAutomaticWaiting
        case .notDetermined:
            return Strings.Settings.locationAutomaticNeedsPermission
        case .denied, .restricted:
            return Strings.Settings.locationAutomaticDenied
        }
    }

    private var permissionActionTitle: String? {
        switch locationService.permissionState {
        case .authorizedWithFix:
            return nil
        case .authorizedNoFixYet:
            return Strings.LocationAccess.tryAgain
        case .notDetermined:
            return Strings.LocationAccess.allowLocation
        case .denied, .restricted:
            return Strings.LocationAccess.openSettings
        }
    }

    private func handleLocationAction() {
        switch locationService.permissionState {
        case .notDetermined:
            locationService.requestAuthorization()
        case .authorizedNoFixYet:
            locationService.requestLocation()
        case .denied, .restricted:
            openAppSettings()
        case .authorizedWithFix:
            break
        }
    }

    private func applySelectedCity(_ city: City) {
        locationService.locationName = city.name
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: city.latitude, longitude: city.longitude)
        }
        scheduleManager.requestRefresh(reason: .settingsChanged)
    }

    private func applyMapItem(_ mapItem: MKMapItem) {
        let coordinate = mapItem.location.coordinate
        if let city = mapItem.addressRepresentations?.cityName ?? mapItem.name {
            locationService.locationName = city
        }
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        scheduleManager.requestRefresh(reason: .settingsChanged)
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
