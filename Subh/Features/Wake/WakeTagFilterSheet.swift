import SwiftUI

struct WakeTagFilterSheet: View {
    @Binding var filter: WakeTagFilter

    @Environment(\.dismiss) private var dismiss
    @State private var draftFilter: WakeTagFilter

    init(filter: Binding<WakeTagFilter>) {
        self._filter = filter
        self._draftFilter = State(initialValue: filter.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        draftFilter.setPrimaryIntent(nil)
                    } label: {
                        filterRow(
                            title: Strings.AlarmsTab.filterAnyPurpose,
                            subtitle: nil,
                            style: nil,
                            isEnabled: true,
                            isSelected: draftFilter.primaryIntent == nil
                        )
                    }
                    .buttonStyle(.plain)

                    ForEach(FastPrimaryIntent.allCases) { intent in
                        Button {
                            draftFilter.setPrimaryIntent(intent)
                        } label: {
                            filterRow(
                                title: intent.about.title,
                                subtitle: intent.about.subtitle,
                                style: intent.style,
                                isEnabled: true,
                                isSelected: draftFilter.primaryIntent == intent
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(Strings.AlarmsTab.filterPurposeSection)
                }

                Section {
                    ForEach(FastSecondaryVirtueTag.allCases) { tag in
                        let isSelected = draftFilter.secondaryTags.contains(tag)
                        let isEnabled = isSelected || draftFilter.allowsSecondaryTag(tag)
                        Button {
                            draftFilter.toggleSecondaryTag(tag)
                        } label: {
                            filterRow(
                                title: tag.about.title,
                                subtitle: isEnabled ? tag.about.subtitle : draftFilter.incompatibilityReason(for: tag),
                                style: tag.style,
                                isEnabled: isEnabled,
                                isSelected: isSelected
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isEnabled)
                    }
                } header: {
                    Text(Strings.AlarmsTab.filterObservancesSection)
                } footer: {
                    Text(Strings.AlarmsTab.filterMatchAllFooter)
                }
            }
            .navigationTitle(Strings.AlarmsTab.filterTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Settings.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.AlarmsTab.filterApply) {
                        filter = draftFilter
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    if draftFilter.isActive {
                        Button(Strings.AlarmsTab.filterClear) {
                            draftFilter.clear()
                        }
                    }
                }
            }
        }
    }

    private func filterRow(
        title: String,
        subtitle: String?,
        style: FastTagStyle?,
        isEnabled: Bool,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: DesignTokens.spacingS) {
            filterRowIcon(style: style, isEnabled: isEnabled)

            VStack(alignment: .leading, spacing: DesignTokens.textSpacingTight) {
                Text(title)
                    .font(AppTypography.rowTitle)
                    .foregroundStyle(isEnabled ? .primary : .secondary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.rowBody)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(AppTypography.controlIcon)
                    .foregroundStyle(DawnColor.accent)
            }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func filterRowIcon(style: FastTagStyle?, isEnabled: Bool) -> some View {
        let tint = style?.color ?? .secondary

        ZStack {
            Circle()
                .fill(tint.opacity(isEnabled ? 0.12 : 0.08))
                .frame(width: DesignTokens.smallControlFrame, height: DesignTokens.smallControlFrame)

            if let systemImage = style?.systemImage {
                Image(systemName: systemImage)
                    .font(AppTypography.compactControlIcon)
                    .foregroundStyle(isEnabled ? tint : .secondary)
            } else {
                Circle()
                    .fill(isEnabled ? tint : Color.secondary)
                    .frame(width: DesignTokens.inlineSpacingMedium, height: DesignTokens.inlineSpacingMedium)
            }
        }
        .frame(width: DesignTokens.smallControlFrame, height: DesignTokens.smallControlFrame)
    }
}
