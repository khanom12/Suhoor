import SwiftUI

struct PlanAheadTiles: View {
    let entitlement: SubhEntitlementSnapshot
    let onSelect: (MonthPlanningCalendarMode) -> Void
    let onLockedSelect: (MonthPlanningCalendarMode) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: DesignTokens.spacingS) {
                    tile(.gregorian)
                    tile(.hijri)
                }
            } else {
                HStack(spacing: DesignTokens.spacingS) {
                    tile(.gregorian)
                    tile(.hijri)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func tile(_ mode: MonthPlanningCalendarMode) -> some View {
        let isLocked = !entitlement.allows(.monthPlanning)
        return Button {
            if isLocked {
                onLockedSelect(mode)
            } else {
                onSelect(mode)
            }
        } label: {
            AppGlassSurface(
                variant: WakeGlassTheme.homeSurfaceVariant,
                contentPadding: 14
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: mode == .gregorian ? "calendar" : "moon.stars")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.90))
                            .accessibilityHidden(true)

                        Spacer(minLength: 6)

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(WakeGlassTheme.tertiaryText)
                                .accessibilityHidden(true)
                        }
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.pickerTitle)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.94))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(mode == .gregorian ? "Plan by Gregorian month" : "Plan by Islamic month")
                            .font(.footnote)
                            .foregroundStyle(WakeGlassTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        if isLocked {
                            Text("Locked preview")
                                .font(AppTypography.badge)
                                .foregroundStyle(WakeGlassTheme.tertiaryText)
                                .padding(.top, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .aspectRatio(dynamicTypeSize.isAccessibilitySize ? nil : 1.08, contentMode: .fit)
                .frame(minHeight: 116)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mode.pickerTitle), \(mode == .gregorian ? "Plan by Gregorian month" : "Plan by Islamic month")\(isLocked ? ", locked preview" : "")")
        .accessibilityHint(isLocked ? "Double-tap to preview Month Planning." : "Double-tap to choose a month.")
    }
}

struct MonthPlanningPickerView: View {
    let mode: MonthPlanningCalendarMode

    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject private var entitlementStore = SubhEntitlementStore.shared
    @State private var months: [MonthPlanningPickerMonth] = []
    @State private var isLoading = true

    private let timeZone: TimeZone = .current

    var body: some View {
        ZStack {
            AppPageBackground()
                .ignoresSafeArea()

            AppHomeContrastOverlay()
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    header

                    if !entitlementStore.effectiveSnapshot.allows(.monthPlanning) {
                        MonthPlanningLockedCard(mode: mode, entitlement: entitlementStore.effectiveSnapshot)
                    } else if isLoading {
                        MonthPlanningLoadingCard()
                    } else {
                        LazyVGrid(columns: monthGridColumns, alignment: .center, spacing: DesignTokens.spacingS) {
                            ForEach(months) { month in
                                if month.availability.isAvailable {
                                    NavigationLink {
                                        MonthPlanningDetailView(identity: month.identity)
                                    } label: {
                                        MonthPlanningPickerMonthCard(month: month)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    MonthPlanningPickerMonthCard(month: month)
                                        .opacity(0.72)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.spacingM)
                .padding(.top, DesignTokens.spacingM)
                .padding(.bottom, 104)
            }
        }
        .navigationTitle(mode.pickerTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        .task(id: reloadKey) {
            await loadMonths()
        }
    }

    private var reloadKey: String {
        "\(mode.rawValue)-\(scheduleManager.currentRevision)-\(entitlementStore.effectiveSnapshot.tier.rawValue)"
    }

    private var monthGridColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: DesignTokens.spacingS)]
        }
        return [
            GridItem(.flexible(), spacing: DesignTokens.spacingS),
            GridItem(.flexible(), spacing: DesignTokens.spacingS)
        ]
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(mode.pickerTitle)
                .font(.title2.weight(.semibold))
                .foregroundStyle(WakeGlassTheme.primaryText)

            Text(mode.pickerSubtitle)
                .font(.subheadline)
                .foregroundStyle(WakeGlassTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }

    @MainActor
    private func loadMonths() async {
        guard entitlementStore.effectiveSnapshot.allows(.monthPlanning) else {
            isLoading = false
            months = []
            return
        }

        isLoading = true
        let now = scheduleManager.currentDate
        switch mode {
        case .gregorian:
            months = MonthPlanningPresentation.gregorianPickerMonths(
                now: now,
                timeZone: timeZone,
                hijriRangeTextProvider: hijriRangeText(for:)
            ) { date in
                scheduleManager.activeDay(for: date, timeZone: timeZone)
            }
        case .hijri:
            let hijriMonths = scheduleManager.rollingHijriMonths(
                count: MonthPlanningPresentation.horizonMonthCount,
                timeZone: timeZone,
                date: now
            )
            months = MonthPlanningPresentation.hijriPickerMonths(
                months: hijriMonths,
                now: now,
                timeZone: timeZone,
                dateRangeProvider: hijriDateRange(for:)
            ) { date in
                scheduleManager.activeDay(for: date, timeZone: timeZone)
            }
        }
        isLoading = false
    }

    private func hijriDateRange(for yearMonth: HijriYearMonth) -> MonthPlanningDateRange? {
        MonthPlanningPresentation.hijriDateRange(
            for: yearMonth,
            startProvider: { key in
                scheduleManager.hijriMonthStartPreview(
                    for: key.month,
                    hijriYear: key.hijriYear,
                    timeZone: timeZone
                )?.adjustedStart
            },
            timeZone: timeZone
        )
    }

    private func hijriRangeText(for range: MonthPlanningDateRange) -> String? {
        guard
            let start = AdjustedHijriCalendar.shared.adjustedComponents(for: range.start, timeZone: timeZone),
            let end = AdjustedHijriCalendar.shared.adjustedComponents(for: range.end, timeZone: timeZone)
        else {
            return nil
        }

        if start.hijriYear == end.hijriYear, start.month == end.month {
            return "\(start.month.displayName) \(start.day)-\(end.day)"
        }

        return "\(start.month.displayName) \(start.day) - \(end.month.displayName) \(end.day)"
    }
}

struct MonthPlanningDetailView: View {
    let identity: MonthPlanningMonthIdentity

    @EnvironmentObject private var scheduleManager: ScheduleManager
    @ObservedObject private var entitlementStore = SubhEntitlementStore.shared
    @State private var snapshot: MonthPlanningSnapshot?
    @State private var isLoading = true

    private let timeZone: TimeZone = .current

    var body: some View {
        ZStack {
            AppPageBackground()
                .ignoresSafeArea()

            AppHomeContrastOverlay()
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    if !entitlementStore.effectiveSnapshot.allows(.monthPlanning) {
                        MonthPlanningLockedCard(mode: identity.mode, entitlement: entitlementStore.effectiveSnapshot)
                    } else if isLoading {
                        MonthPlanningLoadingCard()
                    } else if let snapshot {
                        MonthlyFajrcastPlaceholderCard(snapshot: snapshot.monthlyFajrcast)

                        Text(snapshot.sectionTitle)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(WakeGlassTheme.tertiaryText)
                            .textCase(.uppercase)
                            .tracking(0.4)
                            .padding(.horizontal, 2)
                            .accessibilityAddTraits(.isHeader)

                        if let empty = snapshot.emptyStateText {
                            MonthPlanningEmptyCard(text: empty)
                        } else {
                            AppGlassSurface(
                                variant: WakeGlassTheme.homeSurfaceVariant,
                                contentPadding: 0
                            ) {
                                VStack(spacing: 0) {
                                    ForEach(Array(snapshot.rows.enumerated()), id: \.element.id) { index, row in
                                        NavigationLink {
                                            AlarmDayDetailView(
                                                schedule: row.entry.schedule,
                                                sourceContext: MonthPlanningDayDetailSourceContext(
                                                    mode: snapshot.mode,
                                                    monthIdentity: snapshot.identity,
                                                    entitlement: entitlementStore.effectiveSnapshot
                                                )
                                            )
                                        } label: {
                                            MonthPlanningMorningRowView(row: row)
                                        }
                                        .buttonStyle(.plain)

                                        if index < snapshot.rows.count - 1 {
                                            Rectangle()
                                                .fill(WakeGlassTheme.divider)
                                                .frame(height: 1)
                                                .padding(.leading, DesignTokens.spacingM)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.spacingM)
                .padding(.top, DesignTokens.spacingM)
                .padding(.bottom, 104)
            }
        }
        .navigationTitle(snapshot?.navigationTitle ?? fallbackTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        .task(id: reloadKey) {
            await loadSnapshot()
        }
    }

    private var reloadKey: String {
        "\(identity.id)-\(scheduleManager.currentRevision)-\(entitlementStore.effectiveSnapshot.tier.rawValue)"
    }

    private var fallbackTitle: String {
        switch identity {
        case .gregorian:
            return "Calendar Month"
        case .hijri(let year, let month):
            return "\(month.displayName) \(year)"
        }
    }

    @MainActor
    private func loadSnapshot() async {
        guard entitlementStore.effectiveSnapshot.allows(.monthPlanning) else {
            isLoading = false
            snapshot = nil
            return
        }

        isLoading = true
        let now = scheduleManager.currentDate
        switch identity {
        case .gregorian:
            let range = MonthPlanningPresentation.dateRange(for: identity, timeZone: timeZone)
            let activeDays = range.map {
                MonthPlanningPresentation.dates(in: $0, timeZone: timeZone)
                    .compactMap { scheduleManager.activeDay(for: $0, timeZone: timeZone) }
            } ?? []
            snapshot = MonthPlanningPresentation.detailSnapshot(
                identity: identity,
                dateRange: range,
                activeDays: activeDays,
                now: now,
                timeZone: timeZone,
                entitlement: entitlementStore.effectiveSnapshot,
                hijriComponentsProvider: hijriComponents(for:timeZone:)
            )
        case .hijri(let year, let month):
            let yearMonth = HijriYearMonth(hijriYear: year, month: month)
            let range = hijriDateRange(for: yearMonth)
            let key = HijriMonthKey(year: year, month: month.rawValue, title: "\(month.displayName) \(year)")
            let activeDays = await scheduleManager.monthEntries(for: key, timeZone: timeZone)
            snapshot = MonthPlanningPresentation.detailSnapshot(
                identity: identity,
                dateRange: range,
                activeDays: activeDays,
                now: now,
                timeZone: timeZone,
                entitlement: entitlementStore.effectiveSnapshot,
                hijriComponentsProvider: hijriComponents(for:timeZone:),
                hijriAdjustmentText: hijriAdjustmentText(for: yearMonth)
            )
        }
        isLoading = false
    }

    private func hijriDateRange(for yearMonth: HijriYearMonth) -> MonthPlanningDateRange? {
        MonthPlanningPresentation.hijriDateRange(
            for: yearMonth,
            startProvider: { key in
                scheduleManager.hijriMonthStartPreview(
                    for: key.month,
                    hijriYear: key.hijriYear,
                    timeZone: timeZone
                )?.adjustedStart
            },
            timeZone: timeZone
        )
    }

    private func hijriAdjustmentText(for yearMonth: HijriYearMonth) -> String? {
        guard let preview = scheduleManager.hijriMonthStartPreview(
            for: yearMonth.month,
            hijriYear: yearMonth.hijriYear,
            timeZone: timeZone
        ), preview.offsetDays != 0 else {
            return nil
        }

        return preview.offsetDays > 0
            ? "Hijri adjustment +\(preview.offsetDays) day\(preview.offsetDays == 1 ? "" : "s")"
            : "Hijri adjustment \(preview.offsetDays) day\(preview.offsetDays == -1 ? "" : "s")"
    }

    private func hijriComponents(for date: Date, timeZone: TimeZone) -> AdjustedHijriDateComponents? {
        AdjustedHijriCalendar.shared.adjustedComponents(for: date, timeZone: timeZone)
    }
}

struct MonthPlanningFeaturePreviewSheet: View {
    let mode: MonthPlanningCalendarMode
    let entitlement: SubhEntitlementSnapshot

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppPageBackground()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
                    AppGlassSurface(
                        variant: WakeGlassTheme.homeSurfaceVariant,
                        contentPadding: 18
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(WakeGlassTheme.secondaryText)
                                .accessibilityHidden(true)

                            Text(mode.pickerTitle)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(WakeGlassTheme.primaryText)

                            Text("Month Planning helps you browse upcoming Subh mornings by Gregorian or Hijri month. It is available with Subh Plus and Complete.")
                                .font(.subheadline)
                                .foregroundStyle(WakeGlassTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Current access: \(entitlement.displayName)")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(WakeGlassTheme.tertiaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(DesignTokens.spacingM)
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct MonthPlanningPickerMonthCard: View {
    let month: MonthPlanningPickerMonth

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        AppGlassSurface(
            variant: WakeGlassTheme.homeSurfaceVariant,
            contentPadding: 14
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: month.identity.mode == .gregorian ? "calendar" : "moon.stars")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(WakeGlassTheme.primaryText.opacity(month.availability.isAvailable ? 0.90 : 0.58))
                        .accessibilityHidden(true)

                    Spacer(minLength: 6)

                    Image(systemName: month.availability.isAvailable ? "chevron.right" : "minus.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WakeGlassTheme.tertiaryText)
                        .accessibilityHidden(true)
                }

                Spacer(minLength: 4)

                VStack(alignment: .leading, spacing: 5) {
                    Text(month.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(WakeGlassTheme.primaryText.opacity(month.availability.isAvailable ? 0.94 : 0.68))
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle = month.subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(WakeGlassTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(month.countText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(month.availability.isAvailable ? WakeGlassTheme.secondaryText : WakeGlassTheme.tertiaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .aspectRatio(dynamicTypeSize.isAccessibilitySize ? nil : 1.02, contentMode: .fit)
            .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 128 : 142, alignment: .topLeading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(month.accessibilityLabel)
        .accessibilityHint(month.availability.isAvailable ? "Double-tap to open Month Detail." : "No planning mornings remain in this month.")
    }
}

private struct MonthlyFajrcastPlaceholderCard: View {
    let snapshot: MonthlyFajrcastPlaceholderSnapshot

    var body: some View {
        AppGlassSurface(
            variant: WakeGlassTheme.homeSurfaceVariant,
            contentPadding: 16
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: DesignTokens.spacingS) {
                    Text("Monthly Fajrcast")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.94))

                    Spacer(minLength: DesignTokens.spacingS)

                    Text(snapshot.entitlement.allows(.monthlyFajrcast) ? "Preview" : "Slot")
                        .font(AppTypography.badge)
                        .foregroundStyle(WakeGlassTheme.tertiaryText)
                }

                Text("A month-level Fajr pattern will appear here when the full chart is ready.")
                    .font(.footnote)
                    .foregroundStyle(WakeGlassTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                FlowLayout(spacing: 8) {
                    placeholderChip(snapshot.mode == .gregorian ? "Calendar" : "Hijri")
                    placeholderChip("\(snapshot.morningCount) \(snapshot.morningCount == 1 ? "morning" : "mornings")")
                    if let visibleRangeText = snapshot.visibleRangeText {
                        placeholderChip(visibleRangeText)
                    } else if let dateRangeText = snapshot.dateRangeText {
                        placeholderChip(dateRangeText)
                    }
                    if let hijriAdjustmentText = snapshot.hijriAdjustmentText {
                        placeholderChip(hijriAdjustmentText)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Monthly Fajrcast placeholder for \(snapshot.monthTitle), \(snapshot.morningCount) \(snapshot.morningCount == 1 ? "morning" : "mornings").")
    }

    private func placeholderChip(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.badge)
            .foregroundStyle(WakeGlassTheme.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(WakeGlassTheme.chipFill)
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(WakeGlassTheme.chipStroke, lineWidth: 0.8)
                    }
            }
            .accessibilityHidden(true)
    }
}

private struct MonthPlanningMorningRowView: View {
    let row: MonthPlanningMorningRow

    @ScaledMetric(relativeTo: .body) private var rowMinHeight: CGFloat = 64

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            dateLane
                .frame(width: 118, alignment: .leading)

            Spacer(minLength: DesignTokens.spacingS)

            NextTenMorningsTagCluster(tags: row.contextTags, isDisabled: row.isInactive)
                .frame(minWidth: 52, maxWidth: .infinity, alignment: .center)

            Spacer(minLength: DesignTokens.spacingS)

            trailingLockup
                .frame(width: 92, alignment: .trailing)
        }
        .padding(.horizontal, DesignTokens.spacingM)
        .padding(.vertical, DesignTokens.compactRowVerticalPadding)
        .frame(minHeight: rowMinHeight, alignment: .center)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
        .accessibilityHint("Double-tap for details.")
    }

    private var dateLane: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(row.primaryDateLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WakeGlassTheme.primaryText.opacity(row.isInactive ? 0.68 : 0.94))
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(row.secondaryDateLabel)
                .font(.footnote)
                .foregroundStyle(WakeGlassTheme.secondaryText.opacity(row.isInactive ? 0.78 : 1.0))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }

    @ViewBuilder
    private var trailingLockup: some View {
        if let trailingTime = row.trailingTime {
            NextTenMorningsTimeLockup(date: trailingTime, isDisabled: row.isInactive)
                .fixedSize(horizontal: true, vertical: false)
        } else if let trailingStatusText = row.trailingStatusText {
            Text(trailingStatusText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(WakeGlassTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct MonthPlanningModeChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppTypography.badge)
            .foregroundStyle(WakeGlassTheme.secondaryText)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(WakeGlassTheme.chipFill)
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(WakeGlassTheme.chipStroke, lineWidth: 0.8)
                    }
            }
            .accessibilityHidden(true)
    }
}

private struct MonthPlanningStatusChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppTypography.badge)
            .foregroundStyle(WakeGlassTheme.tertiaryText)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    }
            }
            .accessibilityHidden(true)
    }
}

private struct MonthPlanningLockedCard: View {
    let mode: MonthPlanningCalendarMode
    let entitlement: SubhEntitlementSnapshot

    var body: some View {
        AppGlassSurface(
            variant: WakeGlassTheme.homeSurfaceVariant,
            contentPadding: 16
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(WakeGlassTheme.secondaryText)
                    .accessibilityHidden(true)

                Text("\(mode.pickerTitle) is locked")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(WakeGlassTheme.primaryText.opacity(0.94))

                Text("Month Planning is available with Subh Plus and Complete.")
                    .font(.subheadline)
                    .foregroundStyle(WakeGlassTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Current access: \(entitlement.displayName)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(WakeGlassTheme.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mode.pickerTitle) is locked. Month Planning is available with Subh Plus and Complete. Current access: \(entitlement.displayName).")
    }
}

private struct MonthPlanningEmptyCard: View {
    let text: String

    var body: some View {
        AppGlassSurface(
            variant: WakeGlassTheme.homeSurfaceVariant,
            contentPadding: 16
        ) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(WakeGlassTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

private struct MonthPlanningLoadingCard: View {
    var body: some View {
        AppGlassSurface(
            variant: WakeGlassTheme.homeSurfaceVariant,
            contentPadding: 16
        ) {
            HStack(spacing: DesignTokens.spacingS) {
                ProgressView()
                    .tint(WakeGlassTheme.secondaryText)
                Text("Resolving month mornings...")
                    .font(.subheadline)
                    .foregroundStyle(WakeGlassTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Resolving month mornings.")
    }
}
