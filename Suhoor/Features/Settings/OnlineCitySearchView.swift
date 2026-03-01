import SwiftUI
import MapKit

struct OnlineCitySearchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    let onSelect: (MKMapItem) -> Void

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                }

                ForEach(results) { result in
                    Button {
                        onSelect(result.mapItem)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(primaryLine(for: result.mapItem))
                                .font(.headline)
                            if let secondary = secondaryLine(for: result.mapItem) {
                                Text(secondary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle(Strings.Settings.locationSearchTitle)
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
            .searchable(text: $query, prompt: Strings.Settings.locationSearchPlaceholder)
            .onSubmit(of: .search) {
                Task { await performSearch() }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Settings.cancel) { dismiss() }
                }
            }
        }
    }

    private func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            guard let request = MKGeocodingRequest(addressString: trimmed) else {
                results = []
                errorMessage = Strings.Settings.locationSearchFailed
                isSearching = false
                return
            }
            let mapItems = try await request.mapItems
            results = mapItems.map { SearchResult(mapItem: $0) }
            if results.isEmpty {
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

private struct SearchResult: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
}
