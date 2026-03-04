import SwiftUI

struct FastTagPickerSheet: View {
    let date: Date
    let initialSelection: FastIntentSelection
    let seeds: [ActiveTagComputationSeed]
    let selections: [String: FastIntentSelection]
    let onSave: (FastIntentSelection) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: FastIntentSelection
    @State private var noteText: String?
    @State private var selectedAbout: FastTagAbout?

    init(
        date: Date,
        initialSelection: FastIntentSelection,
        seeds: [ActiveTagComputationSeed],
        selections: [String: FastIntentSelection],
        onSave: @escaping (FastIntentSelection) -> Void
    ) {
        self.date = date
        self.initialSelection = initialSelection
        self.seeds = seeds
        self.selections = selections
        self.onSave = onSave
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        let timeZone = TimeZone.current
        let suggestions = FastIntentEngine.suggestions(for: date, timeZone: timeZone)
        let warnings = FastIntentEngine.warnings(for: date, timeZone: timeZone)
        let computedResult = computedResult(for: selection, timeZone: timeZone)
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
                        let isCalendarSelectable = FastIntentEngine.isPrimarySelectable(intent, on: date, timeZone: timeZone)
                        PrimaryOptionRow(
                            title: intent.about.title,
                            subtitle: intent.about.subtitle,
                            systemImage: intent.style.systemImage,
                            color: intent.style.color,
                            isSelected: policy.isPurposeLocked ? intent == policy.lockedPrimaryIntent : computedResult.computedPrimaryIntent == intent,
                            isPrimary: true,
                            isDisabled: (policy.isPurposeLocked && intent != policy.lockedPrimaryIntent) || !isCalendarSelectable,
                            statusText: FastIntentEngine.primaryStatusText(
                                for: intent,
                                on: date,
                                timeZone: timeZone,
                                isSuggested: intent == suggestions.suggestedPrimary
                            ),
                            onSelect: { selectPrimary(intent) },
                            onInfo: { selectedAbout = intent.about }
                        )
                    }
                }

                Text("Also matches Sunnah observences")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let secondaryHelper = policy.secondaryHelperText {
                    Text(secondaryHelper)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 0) {
                    ForEach(FastSecondaryVirtueTag.allCases) { tag in
                        let isApplicable = FastIntentEngine.isCalendarApplicable(tag: tag, on: date, timeZone: timeZone)
                        let isSuppressed = computedResult.suppressedSecondaryTags.contains(tag)
                        let isEligibleButNotCounted = tag == .shawwalSix && isApplicable && !isSuppressed && !computedResult.computedSecondaryTags.contains(tag)
                        ObservanceStatusRow(
                            title: tag.about.title,
                            subtitle: tag.about.subtitle,
                            systemImage: tag.style.systemImage,
                            color: tag.style.color,
                            isSelected: computedResult.computedSecondaryTags.contains(tag),
                            statusText: statusText(for: tag, computedResult: computedResult, timeZone: timeZone),
                            isSuppressed: isSuppressed,
                            isDimmed: !computedResult.computedSecondaryTags.contains(tag) && !isEligibleButNotCounted,
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
        guard FastIntentEngine.isPrimarySelectable(intent, on: date, timeZone: .current) else {
            Haptics.medium()
            return
        }
        let policy = TagEditPolicy(
            date: date,
            effectivePrimary: computedResult(
                for: selection,
                timeZone: .current
            ).computedPrimaryIntent,
            timeZone: TimeZone.current
        )
        if policy.isPurposeLocked, intent != policy.lockedPrimaryIntent {
            Haptics.medium()
            return
        }
        guard selection.primaryIntent != intent else { return }
        selection.primaryIntent = intent
        selection.secondaryTags = []
        Haptics.light()
    }

    private func enforceRulesIfNeeded() {
        let normalized = FastIntentEngine.normalizedSelection(
            selection,
            for: date,
            ruleset: .strict,
            timeZone: .current
        )
        if normalized != selection {
            selection = normalized
            showNote("Tag rules updated for this date.")
        }
    }

    private func statusText(
        for tag: FastSecondaryVirtueTag,
        computedResult: TagComputationResult,
        timeZone: TimeZone
    ) -> String {
        if computedResult.computedSecondaryTags.contains(tag) {
            if tag == .shawwalSix {
                return "Counts toward your six Shawwal fasts"
            }
            return "Applies automatically on this date"
        }
        if let detail = computedResult.secondaryDetails[tag], detail.source == .suppressedByPolicy {
            return detail.reason
        }
        if FastIntentEngine.isCalendarApplicable(tag: tag, on: date, timeZone: timeZone), tag == .shawwalSix {
            return "Eligible Shawwal date, but only the first six voluntary days count"
        }
        return "Not applicable on this date"
    }

    private func showNote(_ text: String) {
        noteText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(Motion.fade(reduceMotion: reduceMotion)) {
                noteText = nil
            }
        }
    }

    private func computedResult(
        for selection: FastIntentSelection,
        timeZone: TimeZone
    ) -> TagComputationResult {
        TagComputationEngine.result(
            for: date,
            seeds: seeds,
            selections: selections,
            ruleset: .strict,
            timeZone: timeZone,
            overrideSelection: selection.hasMeaningfulTags ? selection : nil
        )
    }

}

private struct PrimaryOptionRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    let color: Color
    let isSelected: Bool
    let isPrimary: Bool
    let isDisabled: Bool
    let statusText: String?
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
                        if let statusText {
                            Text(statusText)
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

private struct ObservanceStatusRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    let color: Color
    let isSelected: Bool
    let statusText: String
    let isSuppressed: Bool
    let isDimmed: Bool
    let onInfo: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TagIconCapsule(
                systemImage: systemImage,
                color: color,
                isSelected: isSelected,
                isPrimary: false
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isDimmed ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(isDimmed ? .tertiary : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(isSuppressed ? .secondary : (isDimmed ? .tertiary : .secondary))
                    .fixedSize(horizontal: false, vertical: true)
            }

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
        .opacity(isDimmed ? 0.55 : 1.0)
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
    let isForbiddenDate: Bool
    let isObligatoryPrimarySelected: Bool
    let lockedPrimaryIntent: FastPrimaryIntent?
    let isPurposeLocked: Bool
    let areSecondaryTagsLocked: Bool
    let purposeHelperText: String?
    let secondaryHelperText: String?

    init(date: Date, effectivePrimary: FastPrimaryIntent, timeZone: TimeZone) {
        let isRamadan = TagEditPolicy.isRamadan(date: date, timeZone: timeZone)
        let isForbidden = FastIntentEngine.isForbiddenToFast(date, timeZone: timeZone)
        let isObligatoryPrimary = effectivePrimary.isObligatory
        let lockedPrimaryIntent: FastPrimaryIntent?
        if isForbidden {
            lockedPrimaryIntent = .forbidden
        } else if isRamadan {
            lockedPrimaryIntent = .ramadanObligatory
        } else {
            lockedPrimaryIntent = nil
        }
        self.isRamadanDate = isRamadan
        self.isForbiddenDate = isForbidden
        self.isObligatoryPrimarySelected = isObligatoryPrimary
        self.lockedPrimaryIntent = lockedPrimaryIntent
        self.isPurposeLocked = lockedPrimaryIntent != nil
        self.areSecondaryTagsLocked = lockedPrimaryIntent != nil || isObligatoryPrimary

        if isForbidden {
            self.purposeHelperText = "Locked: fasting is forbidden on this date."
            self.secondaryHelperText = "Sunnah observence tags are hidden on forbidden dates."
        } else if isRamadan {
            self.purposeHelperText = "Locked for Ramadan: this fast is obligatory."
            self.secondaryHelperText = "Sunnah observence tags are hidden during Ramadan."
        } else if isObligatoryPrimary {
            self.purposeHelperText = nil
            self.secondaryHelperText = "Sunnah observence tags are suppressed when the purpose is obligatory."
        } else if effectivePrimary == .other {
            self.purposeHelperText = nil
            self.secondaryHelperText = "Choose Voluntary to see date-derived Sunnah observences."
        } else {
            self.purposeHelperText = nil
            self.secondaryHelperText = nil
        }
    }

    private static func isRamadan(date: Date, timeZone: TimeZone) -> Bool {
        FastIntentEngine.isRamadan(date, timeZone: timeZone)
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
