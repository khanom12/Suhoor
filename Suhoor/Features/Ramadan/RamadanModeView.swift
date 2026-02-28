import SwiftUI

struct RamadanModeView: View {
    @Binding var settings: AppSettings

    var body: some View {
        Form {
            Section("Profile") {
                Toggle("Ramadan Mode", isOn: $settings.ramadanModeEnabled)

                if settings.ramadanModeEnabled {
                    HStack {
                        Text("Profile")
                        Spacer()
                        Text(settings.selectedRamadanProfile.displayName)
                            .foregroundStyle(.secondary)
                    }

                    Stepper(value: $settings.ramadanStartAdjustmentDays, in: -2...2, step: 1) {
                        Text("Start date adjustment: \(settings.ramadanStartAdjustmentDays)")
                    }

                    Stepper(value: $settings.ramadanEndAdjustmentDays, in: -2...2, step: 1) {
                        Text("End date adjustment: \(settings.ramadanEndAdjustmentDays)")
                    }

                    NavigationLink("Preview schedule") {
                        RamadanScheduleView(settings: $settings, showCustomOnly: false)
                    }
                }
            }

            if settings.ramadanModeEnabled {
                Section("Layers") {
                    Toggle("Weekend Boost", isOn: $settings.weekendBoostEnabled)

                    if settings.weekendBoostEnabled {
                        Stepper(value: $settings.weekendBoostMinutes, in: 5...120, step: 5) {
                            Text("Earlier by: \(settings.weekendBoostMinutes) min")
                        }
                    }

                    Toggle("Last 10 Nights", isOn: $settings.last10Enabled)

                    if settings.last10Enabled {
                        Stepper(value: $settings.last10BoostMinutes, in: 5...120, step: 5) {
                            Text("Earlier by: \(settings.last10BoostMinutes) min")
                        }
                    }

                    Toggle("Laylatul Qadr", isOn: $settings.lqEnabled)

                    if settings.lqEnabled {
                        Stepper(value: $settings.lqBoostMinutes, in: 5...180, step: 5) {
                            Text("Earlier by: \(settings.lqBoostMinutes) min")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Night selection")
                                .font(.footnote.weight(.semibold))

                            FlowLayout(spacing: 8) {
                                ForEach([21, 23, 25, 27, 29], id: \.self) { night in
                                    Button {
                                        toggleLqNight(night)
                                    } label: {
                                        Text("\(night)")
                                            .pillChipStyle(isSelected: settings.lqNightNumbers.contains(night))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Night \(night)")
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Section("Overrides") {
                    Text("Custom days: \(settings.perDayOverrideOffsets.count)")
                        .foregroundStyle(.secondary)

                    NavigationLink("Manage custom days") {
                        RamadanScheduleView(settings: $settings, showCustomOnly: true)
                    }
                }
            }
        }
        .navigationTitle("Ramadan Mode")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleLqNight(_ night: Int) {
        if settings.lqNightNumbers.contains(night) {
            settings.lqNightNumbers.remove(night)
        } else {
            settings.lqNightNumbers.insert(night)
        }
    }
}
