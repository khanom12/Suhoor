import SwiftUI
import MapKit

struct LocationSettingsView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @State private var selectedCityId: String = City.defaultCity.id
    @State private var showOnlineSearch = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DawnColor.bgWarmTop, DawnColor.bgWarmBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.spacingL) {
                    GlassCard(style: .normal) {
                        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                            SectionHeaderView(Strings.Settings.locationSection)

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
                                Text(Strings.Settings.locationHelper)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(Strings.Settings.locationSelected(cityName(for: selectedCityId)))
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                NavigationLink {
                                    CityPickerView(selectedCityId: $selectedCityId)
                                } label: {
                                    ActionRowView(title: cityName(for: selectedCityId), systemImage: "building.2")
                                }
                                .buttonStyle(PressableRowButtonStyle())

                                Button {
                                    showOnlineSearch = true
                                } label: {
                                    ActionRowView(title: Strings.Settings.locationSearchOnline, systemImage: "magnifyingglass")
                                }
                                .buttonStyle(PressableRowButtonStyle())

                                Text(Strings.Settings.locationSearchRequiresInternet)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Button(Strings.Settings.openAppSettings) { openAppSettings() }
                                .font(.footnote.weight(.semibold))
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.spacingL)
                .padding(.top, DesignTokens.spacingL)
                .padding(.bottom, DesignTokens.spacingM)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                SingleLineTitleView(titleLine: Strings.Settings.locationSection)
            }
        }
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
            .sheetMaterialBackground()
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
}
