import SwiftUI

struct FastTagPickerSheet: View {
    let date: Date
    let initialSelection: FastIntentSelection
    let onSave: (FastIntentSelection) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("fiqhRuleset") private var ruleset: FiqhRuleset = .strict

    @State private var selection: FastIntentSelection
    @State private var inlineError: String?
    @State private var noteText: String?
    @State private var selectedAbout: FastTagAbout?

    init(date: Date, initialSelection: FastIntentSelection, onSave: @escaping (FastIntentSelection) -> Void) {
        self.date = date
        self.initialSelection = initialSelection
        self.onSave = onSave
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        let timeZone = TimeZone.current
        let suggestions = FastIntentEngine.suggestions(for: date, timeZone: timeZone)
        let warnings = FastIntentEngine.warnings(for: date, timeZone: timeZone)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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

                sectionHeader(title: "Purpose", suggestionAvailable: suggestions.suggestedPrimary != nil)

                if let suggestedPrimary = suggestions.suggestedPrimary {
                    HStack(spacing: 8) {
                        Text("Suggested")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Button {
                            applySuggestedPrimary(suggestedPrimary)
                        } label: {
                            TagChip(
                                title: suggestedPrimary.title,
                                shortTitle: suggestedPrimary.shortTitle,
                                systemImage: suggestedPrimary.style.systemImage,
                                color: suggestedPrimary.style.color,
                                isSelected: selection.primaryIntent == suggestedPrimary,
                                isPrimary: true,
                                isDisabled: false
                            )
                        }
                        .buttonStyle(.plain)
                        Button {
                            selectedAbout = suggestedPrimary.about
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("About \(suggestedPrimary.about.title)")
                    }
                }

                VStack(spacing: 12) {
                    ForEach(FastPrimaryIntent.allCases) { intent in
                        TagOptionRow(
                            title: intent.about.title,
                            subtitle: intent.about.subtitle,
                            chipTitle: intent.title,
                            chipShortTitle: intent.shortTitle,
                            systemImage: intent.style.systemImage,
                            color: intent.style.color,
                            isSelected: selection.primaryIntent == intent,
                            isPrimary: true,
                            isDisabled: false,
                            onSelect: { selectPrimary(intent) },
                            onInfo: { selectedAbout = intent.about }
                        )
                    }
                }

                sectionHeader(title: "This day also matches", suggestionAvailable: !suggestions.suggestedSecondary.isEmpty)

                if !suggestions.suggestedSecondary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("Suggested")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Button("Apply all") {
                                applySuggestedSecondary(suggestions.suggestedSecondary)
                            }
                            .font(.caption.weight(.semibold))
                            .buttonStyle(.borderless)
                        }
                        FlowLayout(spacing: 6) {
                            ForEach(suggestions.suggestedSecondary, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    TagChip(
                                        title: tag.title,
                                        shortTitle: tag.shortTitle,
                                        systemImage: tag.style.systemImage,
                                        color: tag.style.color,
                                        isSelected: selection.secondaryTags.contains(tag),
                                        isPrimary: false,
                                        isDisabled: !allowsSecondary
                                    )
                                    Button {
                                        selectedAbout = tag.about
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 24, height: 24)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("About \(tag.about.title)")
                                }
                            }
                        }
                    }
                }

                VStack(spacing: 12) {
                    ForEach(FastSecondaryVirtueTag.allCases) { tag in
                        TagOptionRow(
                            title: tag.about.title,
                            subtitle: tag.about.subtitle,
                            chipTitle: tag.title,
                            chipShortTitle: tag.shortTitle,
                            systemImage: tag.style.systemImage,
                            color: tag.style.color,
                            isSelected: selection.secondaryTags.contains(tag),
                            isPrimary: false,
                            isDisabled: !allowsSecondary,
                            onSelect: { toggleSecondary(tag) },
                            onInfo: { selectedAbout = tag.about }
                        )
                    }
                }

                rulesetInfoRow

                if let inlineError {
                    Text(inlineError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .transition(.opacity)
                }

                if let noteText {
                    Text(noteText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                if ruleset == .permissive, selection.primaryIntent.isObligatory, !selection.secondaryTags.isEmpty {
                    Text("Primary intention remains \\(selection.primaryIntent.shortTitle).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if ruleset == .strict, selection.primaryIntent.isObligatory {
                    Text("Secondary tags are disabled for obligatory intentions in Strict mode.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
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
            ToolbarItem(placement: .bottomBar) {
                Button("Clear") {
                    selection = .default
                    Haptics.light()
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

    private var allowsSecondary: Bool {
        FastIntentEngine.allowsSecondaryTags(primary: selection.primaryIntent, ruleset: ruleset)
    }

    private var rulesetInfoRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Ruleset")
                    .font(.footnote.weight(.semibold))
                Spacer()
                Button {
                    selectedAbout = FastTagAbout.rulesetAbout
                } label: {
                    Image(systemName: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("About ruleset")
            }
            Text("Strict (default): Obligatory and voluntary intentions are kept separate.")
            Text("Permissive: Allows voluntary tags alongside an obligatory primary intent.")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private func selectPrimary(_ intent: FastPrimaryIntent) {
        guard selection.primaryIntent != intent else { return }
        selection.primaryIntent = intent
        inlineError = nil
        Haptics.light()

        if ruleset == .strict, intent.isObligatory, !selection.secondaryTags.isEmpty {
            selection.secondaryTags = []
            showNote("Secondary tags cleared due to ruleset.")
        }
    }

    private func toggleSecondary(_ tag: FastSecondaryVirtueTag) {
        guard allowsSecondary else {
            inlineError = "Secondary tags are disabled for obligatory intentions in Strict mode."
            Haptics.medium()
            return
        }
        inlineError = nil
        if selection.secondaryTags.contains(tag) {
            selection.secondaryTags.remove(tag)
        } else {
            selection.secondaryTags.insert(tag)
        }
        Haptics.light()
    }

    private func applySuggestedPrimary(_ intent: FastPrimaryIntent) {
        selectPrimary(intent)
    }

    private func applySuggestedSecondary(_ tags: [FastSecondaryVirtueTag]) {
        guard allowsSecondary else {
            inlineError = "Secondary tags are disabled for obligatory intentions in Strict mode."
            Haptics.medium()
            return
        }
        inlineError = nil
        for tag in tags {
            selection.secondaryTags.insert(tag)
        }
        if selection.primaryIntent == .other {
            selection.primaryIntent = .voluntarySunnah
        }
        Haptics.light()
    }

    private func enforceRulesIfNeeded() {
        let normalized = FastIntentEngine.normalizedSelection(selection, ruleset: ruleset)
        if normalized != selection {
            selection = normalized
            showNote("Secondary tags cleared due to ruleset.")
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

    private func sectionHeader(title: String, suggestionAvailable: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.headline)
            if suggestionAvailable {
                Text("Suggested")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TagOptionRow: View {
    let title: String
    let subtitle: String?
    let chipTitle: String
    let chipShortTitle: String
    let systemImage: String?
    let color: Color
    let isSelected: Bool
    let isPrimary: Bool
    let isDisabled: Bool
    let onSelect: () -> Void
    let onInfo: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onSelect) {
                HStack(alignment: .top, spacing: 12) {
                    TagChip(
                        title: chipTitle,
                        shortTitle: chipShortTitle,
                        systemImage: systemImage,
                        color: color,
                        isSelected: isSelected,
                        isPrimary: isPrimary,
                        isDisabled: isDisabled
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let subtitle {
                            Text(subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
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
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About \(title)")
        }
        .opacity(isDisabled ? 0.6 : 1.0)
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

private struct TagChip: View {
    let title: String
    let shortTitle: String
    let systemImage: String?
    let color: Color
    let isSelected: Bool
    let isPrimary: Bool
    let isDisabled: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isAccessibility = dynamicTypeSize.isAccessibilitySize
        ViewThatFits(in: .horizontal) {
            chipLabel(text: title, useIconOnly: isAccessibility)
            chipLabel(text: shortTitle, useIconOnly: isAccessibility)
            chipLabel(text: "", useIconOnly: true)
        }
        .font(isPrimary ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
        .foregroundStyle(isSelected ? color : .secondary)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(borderColor, lineWidth: isSelected ? 1.2 : 0.8)
        )
        .opacity(isDisabled ? 0.4 : 1.0)
        .accessibilityLabel(title)
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

    @ViewBuilder
    private func chipLabel(text: String, useIconOnly: Bool) -> some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
            }
            if !useIconOnly, !text.isEmpty {
                Text(text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
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
