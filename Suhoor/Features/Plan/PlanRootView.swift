import SwiftUI

struct PlanRootView: View {
    var body: some View {
        List {
            Section {
                Text("Plan")
                    .font(.headline.weight(.semibold))
                Text("This tab will focus on upcoming recommendations and planning flows.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.large)
    }
}

