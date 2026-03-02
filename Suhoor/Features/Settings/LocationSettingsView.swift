import SwiftUI
import MapKit
import UIKit

struct LocationSettingsView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @State private var selectedCityId: String = City.defaultCity.id
    @State private var showOnlineSearch = false

    var body: some View {
        Form {
            Section(Strings.Settings.locationSection) {
                Picker("", selection: $settingsStore.settings.locationMode) {
                    Text("Auto").tag(LocationMode.auto)
                    Text("City").tag(LocationMode.fixed)
                }
                .pickerStyle(.segmented)
                .onChange(of: settingsStore.settings.locationMode) { _, _ in
                    if settingsStore.settings.locationMode == .fixed,
                       settingsStore.settings.fixedLocation == nil {
                        applySelectedCity()
                    }
                    Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
                }

                if settingsStore.settings.locationMode == .auto {
                    PermissionStackView(
                        kinds: [.location],
                        refreshKey: permissionRefreshKey,
                        showOnlyBlocking: false,
                        onOpenSettings: openAppSettings
                    )
                    .environmentObject(scheduleManager)
                } else {
                    Text(Strings.LocationAccess.manualOverride)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(Strings.Settings.locationSelected(cityName(for: selectedCityId)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    NavigationLink {
                        CityPickerView(selectedCityId: $selectedCityId)
                    } label: {
                        Text(cityName(for: selectedCityId))
                    }

                    Button(Strings.Settings.locationSearchOnline) {
                        showOnlineSearch = true
                    }

                    Text(Strings.Settings.locationSearchRequiresInternet)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

            }
        }
        .formStyle(.grouped)
        .navigationTitle(Strings.Settings.locationSection)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedCityId = currentCityId()
        }
        .onChange(of: selectedCityId) { _, _ in
            if settingsStore.settings.locationMode == .fixed {
                applySelectedCity()
                Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
            }
        }
        .sheet(isPresented: $showOnlineSearch) {
            OnlineCitySearchView { mapItem in
                applyMapItem(mapItem)
                Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
            }
        }
    }

    private func currentCityId() -> String {
        guard let fixed = settingsStore.settings.fixedLocation else {
            return City.defaultCity.id
        }
        if let city = cityForFixedLocation(fixed) {
            return city.id
        }
        return City.defaultCity.id
    }

    private func cityName(for id: String) -> String {
        City.all.first(where: { $0.id == id })?.name ?? City.defaultCity.name
    }

    private func cityForFixedLocation(_ fixed: FixedLocation) -> City? {
        City.all.first {
            abs($0.latitude - fixed.latitude) < 0.001 && abs($0.longitude - fixed.longitude) < 0.001
        }
    }

    private func applySelectedCity() {
        guard let city = City.all.first(where: { $0.id == selectedCityId }) else { return }
        locationService.locationName = city.name
        settingsStore.update { draft in
            draft.locationMode = .fixed
            draft.fixedLocation = FixedLocation(latitude: city.latitude, longitude: city.longitude)
        }
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
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var permissionRefreshKey: String {
        "\(locationService.authorizationStatus.rawValue)-\(locationService.lastLocation != nil)"
    }
}
