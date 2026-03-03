import SwiftUI

struct HijriAdjustmentReviewSheet: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss

    let changes: [HijriAdjustmentChange]

    var body: some View {
        NavigationStack {
            List {
                ForEach(changes) { change in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(hijriLabel(for: change))
                            .font(.headline)
                        Text(dateShiftText(for: change))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(change.sourceLabel)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(Strings.AlarmList.hijriAdjustmentsReviewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.AlarmList.hijriAdjustmentsMarkRead) {
                        scheduleManager.acknowledgeHijriAdjustmentChanges()
                        dismiss()
                    }
                }
            }
        }
    }

    private func hijriLabel(for change: HijriAdjustmentChange) -> String {
        "\(change.day) \(change.month.displayName) \(change.hijriYear)"
    }

    private func dateShiftText(for change: HijriAdjustmentChange) -> String {
        let oldDate = dateFromKey(change.oldDateKey)
        let newDate = dateFromKey(change.newDateKey)
        let oldText = oldDate.map { shortDate($0) } ?? change.oldDateKey
        let newText = newDate.map { shortDate($0) } ?? change.newDateKey
        return "\(oldText) → \(newText)"
    }

    private func dateFromKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }

    private func shortDate(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }
}
