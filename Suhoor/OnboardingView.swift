import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @EnvironmentObject private var settingsStore: SuhoorSettingsStore
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var locationService: LocationService

    @State private var step: Step = .welcome
    @State private var showHowItWorks = false
    @State private var showLocationRequired = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 0)
                stepView
                Spacer(minLength: 0)
            }
            .padding(24)
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showHowItWorks) {
                HowItWorksView()
            }
        }
        .onChange(of: locationService.authorizationStatus) { _, newValue in
            if newValue == .authorizedAlways || newValue == .authorizedWhenInUse {
                if step == .location {
                    withAnimation(.easeInOut) {
                        step = .offset
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case .welcome:
            WelcomeStep(
                onGetStarted: { step = .location },
                onHowItWorks: { showHowItWorks = true }
            )
        case .location:
            LocationStep(
                showLocationRequired: showLocationRequired,
                onAllow: {
                    showLocationRequired = false
                    scheduleManager.requestLocationAuthorization()
                },
                onNotNow: { showLocationRequired = true }
            )
        case .offset:
            OffsetStep(
                baseMinutes: $settingsStore.settings.baseWakeOffsetMinutes,
                onEnable: {
                    Task { _ = await scheduleManager.enableFromUserAction() }
                    withAnimation(.easeInOut) {
                        step = .confirmation
                    }
                }
            )
        case .confirmation:
            ConfirmationStep(
                nextAlarmText: nextAlarmText,
                onDone: {
                    settingsStore.update { draft in
                        draft.isConfigured = true
                    }
                }
            )
        }
    }

    private var nextAlarmText: String {
        guard let schedule = scheduleManager.schedules.first else {
            return "Next alarm: --"
        }
        let weekday = TimeFormatters.dayFormatter.string(from: schedule.wakeDate)
        let time = TimeFormatters.timeFormatter.string(from: schedule.wakeDate)
        return "Next alarm: \(weekday) \(time)"
    }
}

private enum Step {
    case welcome
    case location
    case offset
    case confirmation
}

private struct WelcomeStep: View {
    let onGetStarted: () -> Void
    let onHowItWorks: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wake up before Fajr")
                .font(.largeTitle.weight(.bold))
            Text("Set it once. We’ll update your alarm daily.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Get started", action: onGetStarted)
                .buttonStyle(.borderedProminent)

            Button("How it works", action: onHowItWorks)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct LocationStep: View {
    let showLocationRequired: Bool
    let onAllow: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Use your location")
                .font(.title2.weight(.bold))
            Text("We use it to calculate tomorrow’s Fajr time for your area.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Allow location", action: onAllow)
                .buttonStyle(.borderedProminent)

            Button("Not now", action: onNotNow)
                .foregroundStyle(.secondary)

            if showLocationRequired {
                Text("Location is required to calculate Fajr.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct OffsetStep: View {
    @Binding var baseMinutes: Int
    let onEnable: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How early?")
                .font(.title2.weight(.bold))

            OffsetPickerView(baseMinutes: $baseMinutes)

            Text("Wake me \(baseMinutes) min before Fajr.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Enable Suhoor", action: onEnable)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct ConfirmationStep: View {
    let nextAlarmText: String
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("All set", systemImage: "checkmark.circle.fill")
                .font(.title2.weight(.bold))

            Text(nextAlarmText)
                .font(.body)

            Text("We’ll keep this updated every day.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct HowItWorksView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How it works")
                        .font(.title2.weight(.bold))
                    Text("Suhoor calculates Fajr time for your location and updates your wake alarm every day.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .navigationTitle("How it works")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
