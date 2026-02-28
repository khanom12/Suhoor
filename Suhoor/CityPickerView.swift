import SwiftUI

struct CityPickerView: View {
    @Binding var selectedCityId: String

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredCities: [City] {
        if searchText.isEmpty { return City.all }
        return City.all.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        List(filteredCities) { city in
            HStack {
                Text(city.name)
                Spacer()
                if city.id == selectedCityId {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedCityId = city.id
                dismiss()
            }
        }
        .navigationTitle("Choose City")
        .searchable(text: $searchText)
    }
}
