import SwiftUI

struct TodayRamadanProgressCard: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        let hijriChangeCount = scheduleManager.hijriAdjustmentChanges.count
        if let model = RamadanProgressEngine.model(now: Date(), calendar: .shared, timeZone: .current) {
            GlassCard(style: .header) {
                VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
                        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                            Text("Ramadan \(model.hijriYear)")
                                .font(DesignTokens.cardTitleFont)

                            Spacer()

                            Text("Day \(model.dayNumber)")
                                .font(DesignTokens.cardMetaFont)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, DesignTokens.spacingS)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                        }

                        progressRow(progress: model.progress)

                        Text(progressSummary(for: model))
                            .font(DesignTokens.cardSubtitleFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear { _ = hijriChangeCount }
        } else {
            EmptyView()
        }
    }

    private func ramadanAdjustmentMenu() -> some View {
        Menu {
            Button {
                Task {
                    await scheduleManager.setHijriMonthAdjustment(for: .ramadan, hijriYear: scheduleManager.currentHijriAdjustmentYear, offsetDays: -1)
                }
            } label: {
                Label("Start Ramadan one day earlier", systemImage: "minus")
            }

            Button {
                Task {
                    await scheduleManager.setHijriMonthAdjustment(for: .ramadan, hijriYear: scheduleManager.currentHijriAdjustmentYear, offsetDays: 0)
                }
            } label: {
                Label("Use built-in start", systemImage: currentRamadanAdjustment == 0 ? "checkmark" : "arrow.uturn.backward")
            }

            Button {
                Task {
                    await scheduleManager.setHijriMonthAdjustment(for: .ramadan, hijriYear: scheduleManager.currentHijriAdjustmentYear, offsetDays: 1)
                }
            } label: {
                Label("Start Ramadan one day later", systemImage: "plus")
            }

            Divider()

            Button("Open Hijri Calendar Settings") {
                NotificationCenter.default.post(name: .switchToHijriCorrections, object: nil)
            }
        } label: {
            Image(systemName: "moonphase.new.moon")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Circle())
        }
        .accessibilityLabel("Adjust Ramadan start")
        .accessibilityValue(currentAdjustmentAccessibilityValue)
    }

    private func shawwalAdjustmentMenu() -> some View {
        Menu {
            Button {
                Task {
                    await scheduleManager.setHijriMonthAdjustment(for: .shawwal, hijriYear: scheduleManager.currentHijriAdjustmentYear, offsetDays: -1)
                }
            } label: {
                Label("Start Shawwal one day earlier", systemImage: "minus")
            }

            Button {
                Task {
                    await scheduleManager.setHijriMonthAdjustment(for: .shawwal, hijriYear: scheduleManager.currentHijriAdjustmentYear, offsetDays: 0)
                }
            } label: {
                Label("Use built-in start", systemImage: currentShawwalAdjustment == 0 ? "checkmark" : "arrow.uturn.backward")
            }

            Button {
                Task {
                    await scheduleManager.setHijriMonthAdjustment(for: .shawwal, hijriYear: scheduleManager.currentHijriAdjustmentYear, offsetDays: 1)
                }
            } label: {
                Label("Start Shawwal one day later", systemImage: "plus")
            }

            Divider()

            Button("Open Hijri Calendar Settings") {
                NotificationCenter.default.post(name: .switchToHijriCorrections, object: nil)
            }
        } label: {
            Image(systemName: "moon.stars.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Circle())
        }
        .accessibilityLabel("Adjust Shawwal start")
        .accessibilityValue(currentShawwalAdjustmentAccessibilityValue)
    }

    private func progressRow(progress: Double) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingS) {
            ramadanAdjustmentMenu()

            ProgressView(value: progress)
                .tint(DawnColor.accent)

            shawwalAdjustmentMenu()
        }
    }

    private func progressSummary(for model: RamadanProgressEngine.Model) -> String {
        guard shouldShowTotalDays else {
            return "\(model.dayNumber) days completed"
        }
        return "\(model.dayNumber) of \(model.totalDays) days completed"
    }

    private var currentRamadanAdjustment: Int {
        scheduleManager.hijriAdjustment(for: .ramadan, hijriYear: scheduleManager.currentHijriAdjustmentYear)
    }

    private var currentShawwalAdjustment: Int {
        scheduleManager.hijriAdjustment(for: .shawwal, hijriYear: scheduleManager.currentHijriAdjustmentYear)
    }

    private var shouldShowTotalDays: Bool {
        currentRamadanAdjustment == 0 && currentShawwalAdjustment == 0
    }

    private var currentAdjustmentAccessibilityValue: String {
        switch currentRamadanAdjustment {
        case -1:
            return "Ramadan starts one day earlier"
        case 1:
            return "Ramadan starts one day later"
        default:
            return "Using built-in Ramadan start"
        }
    }

    private var currentShawwalAdjustmentAccessibilityValue: String {
        switch currentShawwalAdjustment {
        case -1:
            return "Shawwal starts one day earlier"
        case 1:
            return "Shawwal starts one day later"
        default:
            return "Using built-in Shawwal start"
        }
    }
}
