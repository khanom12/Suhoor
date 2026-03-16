import SwiftUI

enum AlarmTimingEditorMode: String, CaseIterable, Identifiable {
    case beforeFajr
    case fixedTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beforeFajr:
            return Strings.AlarmsTab.beforeFajrLabel
        case .fixedTime:
            return Strings.Settings.fixedTime
        }
    }
}

struct SettingsSectionHeader: View {
    let title: String
    var supportingText: String? = nil
    var meta: String? = nil

    var body: some View {
        AppSectionHeader(title, subtitle: supportingText) {
            if let meta {
                Text(meta)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SettingsInfoBanner<Action: View>: View {
    let title: String
    let message: String
    let systemImage: String
    @ViewBuilder let action: () -> Action

    init(
        title: String,
        message: String,
        systemImage: String = "info.circle",
        @ViewBuilder action: @escaping () -> Action = { EmptyView() }
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        AppGlassSurface(variant: .quiet, tint: DawnColor.lightGold200) {
            HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(DawnColor.accent)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.body.weight(.semibold))
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    action()
                }

                Spacer(minLength: 0)
            }
        }
    }
}

struct SettingsEditorCard<Content: View>: View {
    let title: String?
    let subtitle: String?
    let trailing: AnyView?
    let isExpanded: Bool
    let onToggleExpanded: (() -> Void)?
    @ViewBuilder let content: () -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        title: String? = nil,
        subtitle: String? = nil,
        trailing: AnyView? = nil,
        isExpanded: Bool = true,
        onToggleExpanded: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.isExpanded = isExpanded
        self.onToggleExpanded = onToggleExpanded
        self.content = content
    }

    var body: some View {
        AppGlassSurface(variant: .grouped, contentPadding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if title != nil || subtitle != nil || trailing != nil {
                    HStack(alignment: .top, spacing: DesignTokens.spacingM) {
                        if let onToggleExpanded {
                            Button(action: onToggleExpanded) {
                                HStack(alignment: .top, spacing: 12) {
                                    headerText
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                        .animation(Motion.standard(reduceMotion: reduceMotion), value: isExpanded)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .buttonStyle(.plain)
                        } else {
                            headerText
                            Spacer(minLength: 0)
                        }
                        trailing
                    }
                    .padding(DesignTokens.spacingM)
                }

                if onToggleExpanded == nil || isExpanded {
                    if title != nil || subtitle != nil || trailing != nil {
                        AppGroupDivider(inset: DesignTokens.spacingM)
                    }

                    content()
                        .padding(DesignTokens.spacingM)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    @ViewBuilder
    private var headerText: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title {
                Text(title)
                    .font(.body.weight(.semibold))
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct RelativeOffsetControl: View {
    let label: String
    let detail: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    var isDisabled: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacingM) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button {
                    value = max(range.lowerBound, value - step)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .appControlStyle(.secondary)
                .disabled(isDisabled || value <= range.lowerBound)

                Text("\(value)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(minWidth: 28)

                Button {
                    value = min(range.upperBound, value + step)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .appControlStyle(.secondary)
                .disabled(isDisabled || value >= range.upperBound)
            }
        }
    }
}

struct AlarmTimingEditor: View {
    let title: String
    let summary: String
    @Binding var isEnabled: Bool
    @Binding var mode: AlarmTimingEditorMode
    @Binding var relativeValue: Int
    @Binding var fixedTime: Date
    let relativeLabel: String
    let relativeDetail: String
    let fixedLabel: String
    let fixedDetail: String?
    let relativeRange: ClosedRange<Int>
    let relativeStep: Int
    let warningText: String?
    var isExpanded: Bool = true
    var onToggleExpanded: (() -> Void)? = nil
    var isDisabled: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        SettingsEditorCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                header

                if isEnabled && isExpanded {
                    Group {
                        Divider()

                        Picker(Strings.AlarmsTab.timeModeLabel, selection: $mode) {
                            ForEach(AlarmTimingEditorMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(isDisabled)

                        if mode == .fixedTime {
                            DatePicker(
                                selection: $fixedTime,
                                displayedComponents: [.hourAndMinute]
                            ) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fixedLabel)
                                    if let fixedDetail {
                                        Text(fixedDetail)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .disabled(isDisabled)
                        } else {
                            RelativeOffsetControl(
                                label: relativeLabel,
                                detail: relativeDetail,
                                value: $relativeValue,
                                range: relativeRange,
                                step: relativeStep,
                                isDisabled: isDisabled
                            )
                        }

                        if let warningText {
                            Text(warningText)
                                .font(.footnote)
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: toggleExpanded) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .foregroundStyle(.primary)
                        Text(summary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if onToggleExpanded != nil {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .animation(Motion.standard(reduceMotion: reduceMotion), value: isExpanded)
                    }
                }
            }
            .buttonStyle(.plain)

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
    }

    private func toggleExpanded() {
        onToggleExpanded?()
    }
}
