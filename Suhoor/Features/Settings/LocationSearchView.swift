import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var onlineResults: [LocationSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    let selectedName: String?
    let onSelectCity: (City) -> Void
    let onSelectMapItem: (MKMapItem) -> Void

    private var localResults: [City] {
        guard !query.isEmpty else { return City.all }
        return City.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        SettingsScrollPage {
            SettingsGroup(title: Strings.Settings.locationSearchLocalSection) {
                if localResults.isEmpty {
                    SettingsRow {
                        Text(Strings.Settings.locationSearchNoResults)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(Array(localResults.enumerated()), id: \.element.id) { index, city in
                        Button {
                            onSelectCity(city)
                            dismiss()
                        } label: {
                            SettingsRow {
                                HStack {
                                    Text(city.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if city.name == selectedName {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(DawnColor.accent)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        if index < localResults.count - 1 {
                            AppGroupDivider()
                        }
                    }
                }
            }

            SettingsGroup(title: Strings.Settings.locationSearchOnlineSection) {
                if isSearching {
                    SettingsRow {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else if let errorMessage {
                    SettingsRow {
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                    }
                } else if onlineResults.isEmpty {
                    SettingsRow {
                        Text(Strings.Settings.locationSearchPrompt)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(Array(onlineResults.enumerated()), id: \.element.id) { index, result in
                        Button {
                            onSelectMapItem(result.mapItem)
                            dismiss()
                        } label: {
                            SettingsRow {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(primaryLine(for: result.mapItem))
                                        .foregroundStyle(.primary)
                                    if let secondary = secondaryLine(for: result.mapItem) {
                                        Text(secondary)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)

                        if index < onlineResults.count - 1 {
                            AppGroupDivider()
                        }
                    }
                }
            }
        }
        .navigationTitle(Strings.Settings.locationSearchTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: Strings.Settings.locationSearchPlaceholder)
        .onSubmit(of: .search) {
            Task { await performSearch() }
        }
    }

    private func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onlineResults = []
            errorMessage = nil
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            guard let request = MKGeocodingRequest(addressString: trimmed) else {
                onlineResults = []
                errorMessage = Strings.Settings.locationSearchFailed
                isSearching = false
                return
            }

            let mapItems = try await request.mapItems
            onlineResults = mapItems.map(LocationSearchResult.init)
            if onlineResults.isEmpty {
                errorMessage = Strings.Settings.locationSearchNoResults
            }
        } catch {
            errorMessage = Strings.Settings.locationSearchFailed
        }

        isSearching = false
    }

    private func primaryLine(for mapItem: MKMapItem) -> String {
        if let city = mapItem.addressRepresentations?.cityName {
            return city
        }
        return mapItem.name ?? Strings.Settings.locationSearchUnknown
    }

    private func secondaryLine(for mapItem: MKMapItem) -> String? {
        if let context = mapItem.addressRepresentations?.cityWithContext, !context.isEmpty {
            return context
        }
        if let region = mapItem.addressRepresentations?.regionName {
            return region
        }
        return nil
    }
}

private struct LocationSearchResult: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem

    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
    }
}
