import SwiftUI

struct HijriMonthAdjustmentMenu: View {
    let month: HijriMonth
    let iconSystemName: String
    let accent: Color

    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        Menu {
            Button {
                Task {
                    await scheduleManager.setHijriMonthAdjustment(
                        for: month,
                        hijriYear: scheduleManager.currentHijriAdjustmentYear,
                        offsetDays: -1
                    )
                }
            } label: {
                Label("\(month.displayName) starts one day earlier", systemImage: "minus")
            }

            Button {
                Task {
                    await scheduleManager.setHijriMonthAdjustment(
                        for: month,
                        hijriYear: scheduleManager.currentHijriAdjustmentYear,
                        offsetDays: 0
                    )
                }
            } label: {
                Label("Use built-in start", systemImage: currentAdjustment == 0 ? "checkmark" : "arrow.uturn.backward")
            }

            Button {
                Task {
                    await scheduleManager.setHijriMonthAdjustment(
                        for: month,
                        hijriYear: scheduleManager.currentHijriAdjustmentYear,
                        offsetDays: 1
                    )
                }
            } label: {
                Label("\(month.displayName) starts one day later", systemImage: "plus")
            }

            Divider()

            Button("Open Hijri Calendar Settings") {
                NotificationCenter.default.post(name: .switchToHijriCorrections, object: nil)
            }
        } label: {
            Image(systemName: iconSystemName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
        .accessibilityLabel("Adjust \(month.displayName) start")
        .accessibilityValue(accessibilityValue)
    }

    private var currentAdjustment: Int {
        scheduleManager.hijriAdjustment(
            for: month,
            hijriYear: scheduleManager.currentHijriAdjustmentYear
        )
    }

    private var accessibilityValue: String {
        switch currentAdjustment {
        case -1:
            return "\(month.displayName) starts one day earlier"
        case 1:
            return "\(month.displayName) starts one day later"
        default:
            return "Using built-in \(month.displayName) start"
        }
    }
}
