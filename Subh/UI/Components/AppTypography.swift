import SwiftUI
import UIKit

enum AppTextRole {
    case eyebrow
    case heroTitle
    case cardTitle
    case cardBody
    case metricLabel
    case metricValue
    case summaryMetricValue
    case rowTitle
    case rowBody
    case rowMeta
    case navAccessory
    case badge
}

enum AppTextTone {
    case primary
    case secondary
    case tertiary

    var color: Color {
        switch self {
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        case .tertiary:
            return Color(UIColor.tertiaryLabel)
        }
    }
}

enum AppTypography {
    static let eyebrow = Font.caption.weight(.medium)
    static let heroTitle = Font.title3.weight(.regular)
    static let cardTitle = Font.body.weight(.medium)
    static let cardBody = Font.footnote
    static let metricLabel = Font.footnote.weight(.medium)
    static let metricValue = Font.footnote
    static let summaryMetricValue = Font.subheadline.weight(.medium)
    static let rowTitle = Font.body
    static let rowBody = Font.footnote
    static let rowMeta = Font.caption
    static let navAccessory = Font.footnote.weight(.medium)
    static let badge = Font.caption.weight(.medium)

    static let toolbarIcon = Font.body
    static let controlIcon = Font.callout.weight(.medium)
    static let compactControlIcon = Font.footnote.weight(.medium)
    static let cardSymbol = Font.title3.weight(.regular)
    static let bannerSymbol = Font.body.weight(.medium)

    static func calendarDayNumber(isSelected: Bool) -> Font {
        .subheadline.weight(isSelected ? .medium : .regular)
    }

    static func font(for role: AppTextRole) -> Font {
        switch role {
        case .eyebrow:
            return eyebrow
        case .heroTitle:
            return heroTitle
        case .cardTitle:
            return cardTitle
        case .cardBody:
            return cardBody
        case .metricLabel:
            return metricLabel
        case .metricValue:
            return metricValue
        case .summaryMetricValue:
            return summaryMetricValue
        case .rowTitle:
            return rowTitle
        case .rowBody:
            return rowBody
        case .rowMeta:
            return rowMeta
        case .navAccessory:
            return navAccessory
        case .badge:
            return badge
        }
    }

    static func defaultTone(for role: AppTextRole) -> AppTextTone {
        switch role {
        case .eyebrow, .cardBody, .metricLabel, .rowBody, .rowMeta, .navAccessory, .badge:
            return .secondary
        case .heroTitle, .cardTitle, .metricValue, .summaryMetricValue, .rowTitle:
            return .primary
        }
    }

    static func heroMetricFont(size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .default)
    }

    static func timeDisplayFont(
        size: CGFloat,
        weight: Font.Weight,
        design: Font.Design = .default
    ) -> Font {
        .system(size: size, weight: weight, design: design)
    }
}

extension Text {
    func appTextRole(
        _ role: AppTextRole,
        tone: AppTextTone? = nil
    ) -> some View {
        modifier(AppTextRoleModifier(role: role, tone: tone ?? AppTypography.defaultTone(for: role)))
    }
}

private struct AppTextRoleModifier: ViewModifier {
    let role: AppTextRole
    let tone: AppTextTone

    func body(content: Content) -> some View {
        let base = content
            .font(AppTypography.font(for: role))
            .foregroundStyle(tone.color)

        if role == .eyebrow {
            base
                .textCase(.uppercase)
                .tracking(DesignTokens.eyebrowTracking)
        } else {
            base
        }
    }
}

enum AppTimeDisplayStyle {
    case prominent
    case detail

    var suffixScale: CGFloat {
        switch self {
        case .prominent:
            return DesignTokens.timeDisplayProminentSuffixScale
        case .detail:
            return DesignTokens.timeDisplayDetailSuffixScale
        }
    }

    var spacing: CGFloat {
        switch self {
        case .prominent:
            return DesignTokens.inlineSpacingSmall
        case .detail:
            return DesignTokens.inlineSpacingMedium
        }
    }
}

struct AppTimeDisplay: View {
    let main: String
    let suffix: String?
    var style: AppTimeDisplayStyle = .prominent
    var mainWeight: Font.Weight = .regular
    var suffixWeight: Font.Weight = .regular
    var design: Font.Design = .default
    var mainColor: Color = .primary
    var suffixColor: Color? = nil
    var minimumScaleFactor: CGFloat = DesignTokens.timeDisplayMinScaleFactor

    @ScaledMetric(relativeTo: .largeTitle) private var prominentPointSize: CGFloat = DesignTokens.timeDisplayProminentPointSize
    @ScaledMetric(relativeTo: .largeTitle) private var detailPointSize: CGFloat = DesignTokens.timeDisplayDetailPointSize

    var body: some View {
        let pointSize = style == .prominent ? prominentPointSize : detailPointSize

        return HStack(alignment: .firstTextBaseline, spacing: style.spacing) {
            Text(main)
                .font(AppTypography.timeDisplayFont(size: pointSize, weight: mainWeight, design: design))
                .foregroundStyle(mainColor)
                .monospacedDigit()
                .minimumScaleFactor(minimumScaleFactor)

            if let suffix {
                Text(suffix)
                    .font(
                        AppTypography.timeDisplayFont(
                            size: pointSize * style.suffixScale,
                            weight: suffixWeight,
                            design: design
                        )
                    )
                    .foregroundStyle(suffixColor ?? mainColor.opacity(0.84))
                    .monospacedDigit()
                    .baselineOffset(DesignTokens.timeSuffixBaselineOffset)
            }
        }
    }
}
