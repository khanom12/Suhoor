import SwiftUI

struct ProfileRootView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(value: ProfileDestination.settings) {
                    Label("Settings", systemImage: "gearshape")
                }
            }

            Section {
                Label("Stats (Coming soon)", systemImage: "chart.bar")
                Label("Badges (Coming soon)", systemImage: "seal")
                Label("Export/Import (Coming soon)", systemImage: "square.and.arrow.up")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    }
}

