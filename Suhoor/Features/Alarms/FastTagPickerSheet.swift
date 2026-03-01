import SwiftUI

struct FastTagPickerSheet: View {
    let date: Date
    let initialSelection: FastIntentSelection
    let schedules: [DaySchedule]
    let selections: [String: FastIntentSelection]
    let onSave: (FastIntentSelection) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selection: FastIntentSelection
    @State private var noteText: String?
    @State private var selectedAbout: FastTagAbout?

    init(
        date: Date,
        initialSelection: FastIntentSelection,
        schedules: [DaySchedule],
        selections: [String: FastIntentSelection],
        onSave: @escaping (FastIntentSelection) -> Void
    ) {
        self.date = date
        self.initialSelection = initialSelection
        self.schedules = schedules
        self.selections = selections
        self.onSave = onSave
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        let timeZone = TimeZone.current
        let suggestions = FastIntentEngine.suggestions(for: date, timeZone: timeZone)
        let warnings = FastIntentEngine.warnings(for: date, timeZone: timeZone)
        let computedResult = TagComputationEngine.result(
            for: date,
            schedules: schedules,
            selections: selections,
            ruleset: .strict,
            timeZone: timeZone,
            overrideSelection: selection.hasMeaningfulTags ? selection : nil
        )
        let policy = TagEditPolicy(
            date: date,
            effectivePrimary: computedResult.computedPrimaryIntent,
            timeZone: timeZone
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let note = suggestions.note {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !warnings.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(warnings, id: \.self) { warning in
                            WarningChipWithInfo(
                                warning: warning,
                                onInfo: { selectedAbout = warning.about }
                            )
                        }
                    }
                }

                Text("Purpose")
                    .font(.headline)
                if let purposeHelper = policy.purposeHelperText {
                    Text(purposeHelper)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 0) {
                    ForEach(FastPrimaryIntent.allCases) { intent in
                        TagOptionRow(
                            title: intent.about.title,
                            subtitle: intent.about.subtitle,
                            systemImage: intent.style.systemImage,
                            color: intent.style.color,
                            isSelected: policy.isPurposeLocked ? intent == .ramadanObligatory : computedResult.computedPrimaryIntent == intent,
                            isPrimary: true,
                            isDisabled: policy.isPurposeLocked && intent != .ramadanObligatory,
                            isSuggested: intent == suggestions.suggestedPrimary,
                            isAutoApplied: false,
                            onSelect: { selectPrimary(intent) },
                            onInfo: { selectedAbout = intent.about }
                        )
                    }
                }

                Text("Also matches")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let secondaryHelper = policy.secondaryHelperText {
                    Text(secondaryHelper)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 0) {
                    ForEach(FastSecondaryVirtueTag.allCases) { tag in
                        TagOptionRow(
                            title: tag.about.title,
                            subtitle: tag.about.subtitle,
                            systemImage: tag.style.systemImage,
                            color: tag.style.color,
                            isSelected: computedResult.computedSecondaryTags.contains(tag),
                            isPrimary: false,
                            isDisabled: policy.areSecondaryTagsLocked,
                            isSuggested: suggestions.suggestedSecondary.contains(tag),
                            isAutoApplied: computedResult.autoSecondaryTags.contains(tag),
                            onSelect: { toggleSecondary(tag) },
                            onInfo: { selectedAbout = tag.about }
                        )
                    }
                }

                if let noteText {
                    Text(noteText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                Button("Clear Selection") {
                    selection = .default
                    Haptics.light()
                }
                .font(.footnote)
                .foregroundStyle(.red)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(selection)
                    dismiss()
                }
            }
        }
        .sheet(item: $selectedAbout) { about in
            AboutTagSheet(about: about)
        }
        .onAppear {
            enforceRulesIfNeeded()
        }
    }

    private func selectPrimary(_ intent: FastPrimaryIntent) {
        let policy = TagEditPolicy(
            date: date,
            effectivePrimary: TagComputationEngine.result(
                for: date,
                schedules: schedules,
                selections: selections,
                ruleset: .strict,
                timeZone: TimeZone.current,
                overrideSelection: selection.hasMeaningfulTags ? selection : nil
            ).computedPrimaryIntent,
            timeZone: TimeZone.current
        )
        if policy.isPurposeLocked, intent != .ramadanObligatory {
            Haptics.medium()
            return
        }
        guard selection.primaryIntent != intent else { return }
        selection.primaryIntent = intent
        Haptics.light()

        if intent.isObligatory, !selection.secondaryTags.isEmpty {
            selection.secondaryTags = []
            showNote("Secondary tags cleared.")
        }
    }

    private func toggleSecondary(_ tag: FastSecondaryVirtueTag) {
        let policy = TagEditPolicy(
            date: date,
            effectivePrimary: TagComputationEngine.result(
                for: date,
                schedules: schedules,
                selections: selections,
                ruleset: .strict,
                timeZone: TimeZone.current,
                overrideSelection: selection.hasMeaningfulTags ? selection : nil
            ).computedPrimaryIntent,
            timeZone: TimeZone.current
        )
        guard !policy.areSecondaryTagsLocked else {
            Haptics.medium()
            return
        }
        if selection.secondaryTags.contains(tag) {
            selection.secondaryTags.remove(tag)
        } else {
            selection.secondaryTags.insert(tag)
        }
        Haptics.light()
    }

    private func enforceRulesIfNeeded() {
        let normalized = FastIntentEngine.normalizedSelection(selection, ruleset: .strict)
        if normalized != selection {
            selection = normalized
            showNote("Secondary tags cleared.")
        }
    }

    private func showNote(_ text: String) {
        noteText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                noteText = nil
            }
        }
    }

}

private struct TagOptionRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    let color: Color
    let isSelected: Bool
    let isPrimary: Bool
    let isDisabled: Bool
    let isSuggested: Bool
    let isAutoApplied: Bool
    let onSelect: () -> Void
    let onInfo: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 12) {
                    TagIconCapsule(
                        systemImage: systemImage,
                        color: color,
                        isSelected: isSelected,
                        isPrimary: isPrimary
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let subtitle {
                            Text(subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if isSuggested {
                            Text("Suggested for this date")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if isAutoApplied {
                            Text("Auto-applied for this date")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)

            Spacer(minLength: 8)

            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .font(dynamicTypeSize.isAccessibilitySize ? .body : .footnote)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About \(title)")
        }
        .padding(.vertical, 12)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

private struct TagIconCapsule: View {
    let systemImage: String?
    let color: Color
    let isSelected: Bool
    let isPrimary: Bool

    var body: some View {
        let imageName = systemImage ?? "tag"
        Image(systemName: imageName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? color : .secondary)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: isSelected ? 1.2 : 0.8)
            )
    }

    private var backgroundColor: Color {
        if isSelected {
            return color.opacity(isPrimary ? 0.22 : 0.16)
        }
        return Color(.secondarySystemBackground)
    }

    private var borderColor: Color {
        if isSelected {
            return color.opacity(0.55)
        }
        return Color(.tertiaryLabel)
    }
}

private struct WarningChipWithInfo: View {
    let warning: FastWarning
    let onInfo: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            FastWarningCapsule(warning: warning)
            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About \(warning.title)")
        }
    }
}

private struct TagEditPolicy {
    let isRamadanDate: Bool
    let isObligatoryPrimarySelected: Bool
    let isPurposeLocked: Bool
    let areSecondaryTagsLocked: Bool
    let purposeHelperText: String?
    let secondaryHelperText: String?

    init(date: Date, effectivePrimary: FastPrimaryIntent, timeZone: TimeZone) {
        let isRamadan = TagEditPolicy.isRamadan(date: date, timeZone: timeZone)
        let isObligatoryPrimary = effectivePrimary.isObligatory
        self.isRamadanDate = isRamadan
        self.isObligatoryPrimarySelected = isObligatoryPrimary
        self.isPurposeLocked = isRamadan
        self.areSecondaryTagsLocked = isRamadan || isObligatoryPrimary

        if isRamadan {
            self.purposeHelperText = "Locked for Ramadan: this fast is obligatory."
            self.secondaryHelperText = "Voluntary tags are unavailable during Ramadan."
        } else if isObligatoryPrimary {
            self.purposeHelperText = nil
            self.secondaryHelperText = "Voluntary tags can’t be combined with an obligatory fast."
        } else {
            self.purposeHelperText = nil
            self.secondaryHelperText = nil
        }
    }

    private static func isRamadan(date: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .islamicCivil)
        calendar.timeZone = timeZone
        return calendar.component(.month, from: date) == 9
    }
}

private struct FastWarningCapsule: View {
    let warning: FastWarning

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: warning.systemImage)
                .font(.caption2.weight(.semibold))
            Text(warning.title)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.red)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.clear)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.red.opacity(0.6), lineWidth: 0.8)
        )
    }
}
