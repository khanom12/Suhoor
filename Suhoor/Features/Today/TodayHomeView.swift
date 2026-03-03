import SwiftUI

struct TodayHomeView: View {
    var body: some View {
        List {
            Section {
                Text("Today")
                    .font(.headline.weight(.semibold))
                Text("This tab will become your real-time dashboard (countdowns, check-in, Ramadan progress).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
    }
}

