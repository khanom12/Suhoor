import SwiftUI

struct ExceptionsListView: View {
    @Binding var settings: AppSettings

    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        List {
            if sortedExceptions.isEmpty {
                Text("No exceptions yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(sortedExceptions, id: \.key) { item in
                NavigationLink {
                    AddExceptionView(settings: $settings, initialDate: item.date)
                } label: {
                    HStack {
                        Text(TimeFormatters.shortDate.string(from: item.date))
                        Spacer()
                        Text(item.label)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteExceptions)
        }
        .navigationTitle("Exceptions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AddExceptionView(settings: $settings, initialDate: Date())
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var sortedExceptions: [(key: String, date: Date, label: String)] {
        let timeZone = TimeZone.current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"

        let items = settings.perDayExceptions.compactMap { key, exception -> (String, Date, String)? in
            guard let date = formatter.date(from: key) else { return nil }
            let label: String
            if exception.disabledForDay {
                label = "Off"
            } else if let minutes = exception.wakeOffsetOverrideMinutes {
                label = "Wake offset \(minutes) min"
            } else if exception.reminderEnabledOverride != nil
                        || exception.atFajrEnabledOverride != nil
                        || exception.reminderMinutesOverride != nil
                        || exception.atFajrSoundOverride != nil {
                label = "Custom"
            } else {
                label = "Custom"
            }
            return (key, date, label)
        }

        return items.sorted { $0.1 < $1.1 }
    }

    private func deleteExceptions(at offsets: IndexSet) {
        let items = sortedExceptions
        for index in offsets {
            let key = items[index].key
            settings.perDayExceptions.removeValue(forKey: key)
        }
        Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
    }
}

struct AddExceptionView: View {
    @Binding var settings: AppSettings
    let initialDate: Date
    let showsDatePicker: Bool

    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var offsetMinutes: Int
    @State private var skipDay: Bool
    @State private var originalException: DayException?
    @State private var originalDateKey: String = ""

    init(settings: Binding<AppSettings>, initialDate: Date, showsDatePicker: Bool = false) {
        _settings = settings
        self.initialDate = initialDate
        self.showsDatePicker = showsDatePicker
        _date = State(initialValue: initialDate)
        _offsetMinutes = State(initialValue: settings.wrappedValue.baseWakeOffsetMinutes)
        _skipDay = State(initialValue: false)
    }

    var body: some View {
        Form {
            Section(Strings.ExceptionEditor.dateSection) {
                if showsDatePicker {
                    DatePicker("", selection: $date, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                } else {
                    Text(TimeFormatters.shortDate.string(from: date))
                        .foregroundStyle(.secondary)
                }
            }

            Section(Strings.ExceptionEditor.exceptionSection) {
                Toggle(Strings.DayDetail.skipDay, isOn: $skipDay)

                if !skipDay {
                    OffsetPickerView(baseMinutes: $offsetMinutes)
                }
            }

        }
        .navigationTitle(Strings.ExceptionEditor.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Strings.ExceptionEditor.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(Strings.ExceptionEditor.save) {
                    saveException()
                    dismiss()
                }
                .disabled(!isDirty)
            }
        }
        .onAppear {
            let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
            originalDateKey = key
            originalException = settings.perDayExceptions[key]
            if let existing = settings.perDayExceptions[key] {
                skipDay = existing.disabledForDay
                if let override = existing.wakeOffsetOverrideMinutes {
                    offsetMinutes = override
                }
            } else if let legacy = settings.perDayOverrideOffsets[key] {
                offsetMinutes = legacy
            }
        }
    }

    private var isDirty: Bool {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
        if key != originalDateKey { return true }
        let current = buildException()
        return current != originalException
    }

    private func saveException() {
        let key = DateHelpers.dayIdentifier(for: date, timeZone: .current)
        let exception = buildException()
        settings.perDayExceptions[key] = exception
        Task { await scheduleManager.ensureScheduleWindow(reason: .settingsChanged) }
    }

    private func buildException() -> DayException {
        return DayException(
            disabledForDay: skipDay,
            wakeOffsetOverrideMinutes: skipDay ? nil : offsetMinutes,
            reminderEnabledOverride: nil,
            atFajrEnabledOverride: nil,
            reminderMinutesOverride: nil,
            atFajrSoundOverride: nil
        )
    }
}
