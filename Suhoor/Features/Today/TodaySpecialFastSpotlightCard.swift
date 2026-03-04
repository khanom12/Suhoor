import SwiftUI

struct TodaySpecialFastSpotlightCard: View {
    let mode: TodaySeasonalCardMode

    private let defaultPreviewColor = FastSecondaryVirtueTag.arafah.style.color

    var body: some View {
        let now = Date()
        let liveContext = TodayObservanceEngine.liveContext(now: now)
        let preview = TodayObservanceEngine.previewSample(now: now)

        if let content = content(liveContext: liveContext, preview: preview) {
            GlassCard(style: .header) {
                VStack(alignment: .leading, spacing: DesignTokens.dashboardCardInternalSpacing) {
                    HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sunnah Observances")
                                .font(DesignTokens.cardTitleFont)
                            Text(content.title)
                                .font(DesignTokens.cardSubtitleFont)
                                .foregroundStyle(content.accent)
                        }

                        Spacer()

                        TodaySeasonalBadge(
                            text: mode == .live ? content.liveBadgeText : "Preview",
                            accent: mode == .live ? content.accent : nil
                        )
                    }

                    if content.tags.isEmpty == false {
                        HStack(spacing: DesignTokens.spacingXS) {
                            ForEach(content.tags, id: \.self) { tag in
                                Text(tag.shortTitle)
                                    .font(DesignTokens.cardSubtitleFont)
                                    .foregroundStyle(tag.style.color)
                            }
                        }
                    }

                    Text(content.message)
                        .font(DesignTokens.cardSubtitleFont)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                        Button("Open Schedule") {
                            NotificationCenter.default.post(name: .switchToAlarmTab, object: nil)
                        }
                        .font(DesignTokens.cardMetaFont)

                        Spacer(minLength: 0)

                        NavigationLink {
                            FastHistoryView()
                        } label: {
                            Text("History")
                                .font(DesignTokens.cardMetaFont)
                                .foregroundStyle(content.accent)
                        }
                    }
                }
            }
        }
    }

    private func content(
        liveContext: TodayObservanceContext?,
        preview: TodayObservancePreview?
    ) -> SpotlightContent? {
        if mode == .live,
           let liveContext,
           liveContext.isRamadan == false,
           liveContext.warnings.isEmpty,
           let primaryTag = TodayObservanceEngine.primaryTag(for: liveContext) {
            return SpotlightContent(
                title: primaryTag.title,
                liveBadgeText: "Today",
                tags: liveContext.secondaryTags,
                message: tightenedReason(for: primaryTag, date: liveContext.now),
                accent: primaryTag.style.color
            )
        }

        if liveContext?.isRamadan == true {
            return SpotlightContent(
                title: "Preview only",
                liveBadgeText: "Preview",
                tags: [],
                message: "Special-day cards are inactive during Ramadan.",
                accent: defaultPreviewColor
            )
        }

        if let preview {
            return SpotlightContent(
                title: preview.primaryTag.title,
                liveBadgeText: "Preview",
                tags: preview.context.secondaryTags,
                message: "Previewing \(GregorianDateFormatter.shared.cardString(for: preview.date)). \(tightenedReason(for: preview.primaryTag, date: preview.date))",
                accent: preview.primaryTag.style.color
            )
        }

        return nil
    }

    private func tightenedReason(for tag: FastSecondaryVirtueTag, date: Date) -> String {
        switch tag {
        case .arafah:
            return "Arafah is today."
        case .ashura:
            return "Ashura falls on the 9th, 10th, or 11th of Muharram."
        case .dhulHijjahFirstNine:
            return FastIntentEngine.observanceReason(for: tag, on: date, timeZone: .current)
        case .whiteDays:
            return "White Days fall on the 13th, 14th, and 15th of the Hijri month."
        case .mondayThursday:
            return "This date falls on a Monday or Thursday."
        case .shawwalSix:
            return FastIntentEngine.observanceReason(for: tag, on: date, timeZone: .current)
        }
    }
}

private struct SpotlightContent {
    let title: String
    let liveBadgeText: String
    let tags: [FastSecondaryVirtueTag]
    let message: String
    let accent: Color
}
