import SwiftUI

struct RamadanSettingsView: View {
    @Binding var settings: AppSettings
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss

    @State private var useSpecificDate: Bool = false
    @State private var lqDate: Date = Date()

    var body: some View {
        Form {
            Section("Ramadan") {
                Text(rangeText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Profile")
                    Spacer()
                    Text(settings.selectedRamadanProfile.displayName)
                        .foregroundStyle(.secondary)
                }

                Stepper(value: $settings.ramadanStartAdjustmentDays, in: -2...2, step: 1) {
                    Text("Start adjustment: \(settings.ramadanStartAdjustmentDays) day")
                }

                Stepper(value: $settings.ramadanEndAdjustmentDays, in: -2...2, step: 1) {
                    Text("End adjustment: \(settings.ramadanEndAdjustmentDays) day")
                }
            }

            Section("Exceptions") {
                Toggle("Weekends", isOn: $settings.weekendBoostEnabled)

                if settings.weekendBoostEnabled {
                    Stepper(value: $settings.weekendBoostMinutes, in: 0...180, step: 5) {
                        Text("Wake earlier by: \(settings.weekendBoostMinutes) min")
                    }
                }

                Toggle("Last 10 nights", isOn: $settings.last10Enabled)

                if settings.last10Enabled {
                    Stepper(value: $settings.last10BoostMinutes, in: 0...180, step: 5) {
                        Text("Wake earlier by: \(settings.last10BoostMinutes) min")
                    }
                }

                Toggle("Laylatul Qadr", isOn: $settings.lqEnabled)

                if settings.lqEnabled {
                    Stepper(value: $settings.lqBoostMinutes, in: 0...180, step: 5) {
                        Text("Wake earlier by: \(settings.lqBoostMinutes) min")
                    }

                    Toggle("Pick specific date", isOn: $useSpecificDate)

                    if useSpecificDate {
                        DatePicker("", selection: $lqDate, in: dateRange ?? Date.distantPast...Date.distantFuture, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                    } else {
                        Picker("Night", selection: selectedNightBinding) {
                            ForEach([21, 23, 25, 27, 29], id: \.self) { night in
                                Text("\(night)th night").tag(night)
                            }
                        }
                    }
                }

                NavigationLink("Per-day exceptions") {
                    ExceptionsListView(settings: $settings)
                }
            }
        }
        .navigationTitle("Ramadan Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    persistLqSelection()
                    Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
                    dismiss()
                }
            }
        }
        .onAppear {
            useSpecificDate = settings.lqSpecificDateKey != nil
            if let key = settings.lqSpecificDateKey,
               let date = dateFromKey(key) {
                lqDate = date
            } else if let range = dateRange {
                lqDate = range.lowerBound
            }
        }
    }

    private var rangeText: String {
        guard let range = dateRange else { return "Range unavailable" }
        let start = TimeFormatters.shortDate.string(from: range.lowerBound)
        let end = TimeFormatters.shortDate.string(from: range.upperBound)
        return "Ramadan: \(start) – \(end)"
    }

    private var dateRange: ClosedRange<Date>? {
        let engine = RamadanProfileEngine()
        guard let range = engine.computeRamadanRange(
            forGregorianYear: settings.selectedRamadanProfile.gregorianYear,
            startAdjustmentDays: settings.ramadanStartAdjustmentDays,
            endAdjustmentDays: settings.ramadanEndAdjustmentDays,
            timeZone: .current
        ) else { return nil }

        let start = Calendar.current.startOfDay(for: range.startDate)
        let end = Calendar.current.startOfDay(for: range.endDate)
        return start...end
    }

    private var selectedNightBinding: Binding<Int> {
        Binding {
            settings.lqNightNumbers.first ?? 27
        } set: { newValue in
            settings.lqNightNumbers = [newValue]
        }
    }

    private func persistLqSelection() {
        if useSpecificDate {
            settings.lqSpecificDateKey = DateHelpers.dayIdentifier(for: lqDate, timeZone: .current)
        } else {
            settings.lqSpecificDateKey = nil
        }
    }

    private func dateFromKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
}
