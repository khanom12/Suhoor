# Next 7 Mornings Wake Forecast Specification v2

| Field | Value |
| --- | --- |
| Canonical filename | `subh-next-7-mornings-wake-forecast-spec-v2.md` |
| Version | 2 |
| Spec status | Product / implementation direction; canonical update to v1 |
| Supersedes | `subh-next-7-days-wake-forecast-spec-v1.md`; `subh-next-10-mornings-wake-forecast-spec-v4.md` |
| Related specs | `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-quick-wake-mode-intent-mutation-contract-v2.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`, `subh-alarm-detail-view-screen-spec-v7.md`, `subh-month-planning-gregorian-hijri-spec-v2.md` |
| Owning domain / surface | Home / Plan ahead / Next 7 Mornings forecast surface |
| Implementation audit status | Needs implementation audit after v2 implementation |

---

## 0. V2 change summary

This v2 update keeps the core forecast concept from v1 but locks the following changes:

1. Rename the visible surface from **Next 7 Days** to **Next 7 Mornings** wherever the product surface is being described.
2. Place this card inside the Home **Plan ahead** section, above the Calendar Months and Hijri Months tiles.
3. Add collapsed helper copy under the header: **View and plan your next seven mornings**.
4. Keep row height static across all row states, especially Quiet mode.
5. Change the middle tag lane from a wake-state tag lane to an **opportunity/context tag lane**.
6. Remove routine state tags from the middle lane, including `Fajr`, `Fasting`, `Suhoor`, `Tahajjud`, and `Quiet mode`.
7. Quiet mode appears in the trailing status area as `Quiet`, replacing the wake time/status for that compact row.
8. Ramadan remains visible as a context tag.
9. Eid and fasting-unavailable contexts appear in the middle lane.
10. Monday/Thursday tags do not appear in this compact surface, including as opportunity-only tags.
11. Preserve the three-lane row model: **date | opportunity/context tags | wake time/status**.

This spec is intended to be implementation-ready while preserving v1’s core principles: no second wake engine, no local tag invention in SwiftUI rows, no row subtitles, no inline editing, and no scheduling/persistence side effects from viewing the forecast.

---

## 1. Purpose

Define the compact and expanded forecast card that previews the next seven resolved Fajr-centered **mornings** without becoming a second wake engine.

The component helps the user understand:

- which upcoming mornings are coming next;
- when the user will wake, or whether delivery is quiet;
- whether a morning carries a meaningful Islamic calendar context, fasting opportunity, Eid, Ramadan, or fasting-unavailable state;
- where to tap to review or change that morning in the existing detail surface.

The component must not explain the whole scheduling decision tree in the row.

---

## 2. What this spec owns

This spec owns:

- Home placement of the Next 7 Mornings card inside **Plan ahead**;
- collapsed and expanded card behavior;
- visible card naming and helper copy;
- row anatomy, row grid, row height, and row visual stability;
- opportunity/context tag display rules;
- Quiet trailing-status display in the compact row;
- routing from a row to the existing detail view;
- accessibility wording for the compact forecast;
- implementation guardrails for avoiding duplicate wake, Fajr, Hijri, fasting, or observance logic.

This spec does **not** own:

- the full Day Detail screen;
- the full Month Planning feature;
- the full Monthly Fajrcast card;
- the full Weekly Fajrcast chart;
- alarm delivery reliability;
- prayer-time calculation logic;
- Hijri date calculation logic;
- final pricing/paywall behavior;
- fasting history/progress architecture except as resolver input for contextual display.

---

## 3. Product mental model

Subh is a **Fajr-centered morning system**.

The Next 7 Mornings card is a near-term planning preview. It should answer:

```text
What are my next seven mornings, what time will I wake, and which of them carry meaningful context?
```

It should not look like a debugging table or full scheduling explanation.

The row should remain visually restrained:

```text
Date label | Opportunity/context tags | Wake time/status
```

---

## 4. Home placement

### 4.1 Section placement

The Home screen should include a **Plan ahead** section.

Within that section, the order is:

```text
Plan ahead
  1. Next 7 Mornings card
  2. Calendar Months tile
  3. Hijri Months tile
```

The Next 7 Mornings card appears above the month-planning tiles because it is the immediate planning surface. Calendar/Hijri month planning appears below it as longer-range planning.

### 4.2 Section heading contrast

The visible **Plan ahead** heading must have strong contrast against the Home background.

Required behavior:

- Use white or the approved high-contrast Home heading token.
- Do not use a low-opacity foreground that becomes difficult to read over the dark/tinted dawn background.
- The heading should visually belong to the Home section system, not to any one card.

---

## 5. Naming and visible copy

### 5.1 Visible card header

The visible card header is:

```text
NEXT 7 MORNINGS
```

Use `mornings` instead of `days` wherever this surface is visible to the user.

### 5.2 Collapsed helper copy

In the collapsed Home state, show a short helper line under the header:

```text
View and plan your next seven mornings
```

Rules:

- The helper copy is allowed in collapsed and expanded headers.
- It must be visually subordinate to the eyebrow/header text.
- It must not become a second title competing with the header.
- It must not reintroduce old copy such as `7-Day Wake Forecast`.

### 5.3 Removed visible copy

Do not show:

```text
NEXT 7 DAYS
7-DAY WAKE FORECAST
Next 7 Days
Historical removed copy: Next 10 mornings
10-DAY WAKE FORECAST
```

as visible product copy for this component.

### 5.4 Internal naming

Recommended internal names may use:

```swift
NextSevenMorningsCard
NextSevenMorningsRowView
NextSevenMorningsPresentation
NextSevenMorningsTagResolver
NextSevenMorningsSnapshot
```

If existing code still uses `NextSevenDays` or similar names, migration may be staged. User-facing copy must still say **mornings**.

---

## 6. Card anatomy

The card has two presentation states:

1. **Collapsed Home state** — header/helper visible, rows hidden.
2. **Expanded state** — header/helper visible, seven forecast rows visible.

### 6.1 Collapsed state

Collapsed visible content:

```text
NEXT 7 MORNINGS
View and plan your next seven mornings
[expansion affordance]
```

Rules:

- The header and helper copy remain visible.
- The seven rows are hidden.
- Do not show row dividers while collapsed unless a header divider is visually required by the glass system.
- Do not show a dense preview that competes with the Home hero.
- Collapsing does not change wake state, scheduling, intention, or persistence.

### 6.2 Expanded state

Expanded visible structure:

```text
┌──────────────────────────────────────────────┐
│ NEXT 7 MORNINGS                              │
│ View and plan your next seven mornings        │
├──────────────────────────────────────────────┤
│ Tomorrow          [White Days]        5:40 AM │
├──────────────────────────────────────────────┤
│ Sat, May 2        [Ashura]            5:39 AM │
├──────────────────────────────────────────────┤
│ Sun, May 3                            Quiet   │
└──────────────────────────────────────────────┘
```

The card should feel premium, calm, glassy, and spacious.

---

## 7. Visual shell and dividers

Use the existing app glass system.

Recommended implementation:

```swift
AppGlassSurface(
    variant: .grouped,
    contentPadding: 0
) { ... }
```

The visual direction should remain:

- dark glass;
- subtle translucency;
- rounded continuous corners;
- low-opacity border;
- no opaque table background;
- no heavy dashboard chrome;
- no bright card-level accent color.

Divider requirements:

- Use the same subtle divider treatment as the Weekly Fajrcast and other glass cards.
- Do not use default iOS `List` separators.
- One divider appears after the header in expanded state.
- Dividers appear between expanded rows.
- Row dividers must not dominate the card.

---

## 8. Row anatomy

Each expanded row contains exactly three visible lanes:

```text
date lane | opportunity/context tag lane | trailing wake/status lane
```

### 8.1 Date lane

The date lane identifies the morning.

Preferred visible formats:

```text
Today
Tomorrow
Sat, May 2
Sun, May 3
```

Rules:

- The first row should use the resolved forecast-start label, usually `Today` if the relevant wake/alarm moment is still upcoming, otherwise normally `Tomorrow`.
- Subsequent rows should use Gregorian date labels like `Sat, May 2`.
- Do not replace the Gregorian date label with Ramadan or other observance text.
- Islamic calendar context belongs in the middle context tag lane, detail views, accessibility, or month-planning surfaces.

### 8.2 Middle lane: opportunity/context tags only

The middle lane is no longer a general wake-state tag lane.

It shows only meaningful opportunity or calendar-context tags.

Allowed examples:

```text
[Ramadan]
[Eid]
[Fasting unavailable]
[No fast]
[Ashura]
[Arafah]
[Dhul Hijjah]
[White Days]
[Shawwal 6]
```

Rules:

- Ordinary mornings may have an empty middle lane.
- Do not show `[Fajr]` as a routine fallback tag.
- Do not show `[Fasting]` to indicate intended fasting.
- Do not show `[Suhoor]` as a row tag.
- Do not show `[Tahajjud]` as a row tag.
- Do not show `[Quiet mode]` in the middle lane.
- Do not show Monday/Thursday as a compact tag.
- Tags are not tappable in this compact card.
- Tags should not wrap.
- If no meaningful opportunity/context exists, leave the middle lane empty rather than filling it with a routine state label.

### 8.3 Trailing wake/status lane

The trailing lane remains the dominant visible execution information.

Preferred wake-time format:

```text
5:40 AM
```

Quiet mode behavior:

```text
Quiet
```

Rules:

- Normal wake-enabled rows show the resolved wake time.
- Quiet rows show `Quiet` in the trailing lane instead of the wake time/status.
- Quiet must not appear as a middle-lane tag.
- If the resolver provides a wake anchor hidden beneath Quiet, that hidden meaning may appear in accessibility or detail, not in the compact trailing lane.
- Use right-aligned, stable trailing layout.
- Use monospaced digits where possible for times.
- Do not add explanatory row subtitles.

---

## 9. Shared row grid and alignment

Rows must use a shared three-lane grid.

Do **not** use a natural row-level `HStack` where the tag cluster is placed immediately after the date and then followed by a spacer. That causes row-by-row drift.

Required grid:

```text
date lane | centered opportunity/context tag lane | trailing wake/status lane
```

Required behavior:

- The date label is leading-aligned inside the shared date lane.
- The trailing wake/status is trailing-aligned inside the shared trailing lane.
- The full tag cluster is centered inside the shared middle lane.
- The middle lane centerline aligns across all seven rows.
- Short labels like `Tomorrow` must not pull tags left.
- Long labels like `Wednesday, May 6` must not push tags right.
- Quiet’s shorter trailing text must not collapse the trailing lane or alter the row grid.

Recommended SwiftUI shape:

```swift
HStack(alignment: .center, spacing: 0) {
    Text(display.dateLabel)
        .frame(width: metrics.dateLaneWidth, alignment: .leading)

    tagCluster
        .frame(width: metrics.tagLaneWidth, alignment: .center)

    trailingTimeOrStatus
        .frame(width: metrics.timeLaneWidth, alignment: .trailing)
}
.frame(height: metrics.rowHeight, alignment: .center)
.frame(maxWidth: .infinity, alignment: .leading)
```

A custom `Layout`, `Grid`, measured `PreferenceKey`, or `ZStack`-based layout is acceptable if the visual result satisfies the shared-lane requirements.

---

## 10. Row height, spacing, and vertical centering

### 10.1 State-invariant row height

Each expanded row must preserve the same height for a given device width and Dynamic Type profile.

Required behavior:

- Ordinary rows, opportunity rows, Ramadan rows, Eid rows, fasting-unavailable rows, Suhoor-resolved rows, and Quiet rows use the same resolved row height.
- Quiet mode must not make the row shorter.
- Rows may grow for Dynamic Type, but they must grow consistently as a list.
- Do not derive row height from only the natural height of each row’s current contents.
- Use shared row metrics for the expanded snapshot.

### 10.2 Vertical centering

A row is the vertical cell between its upper divider and lower divider.

Required geometry:

```text
rowTopY = lower edge of divider above row
rowBottomY = upper edge of divider below row
rowCenterY = rowTopY + ((rowBottomY - rowTopY) / 2)
```

Required behavior:

- Date label frame center aligns to `rowCenterY`.
- Tag cluster frame center aligns to `rowCenterY`.
- Trailing wake/status lockup frame center aligns to `rowCenterY`.
- Do not use row-level `.firstTextBaseline` alignment for the three outer row elements.
- Do not add row-state-specific top/bottom offsets.
- Any vertical padding must be symmetric around the row center.

---

## 11. Opportunity/context tag doctrine

Tags are compact context markers.

A tag should answer:

```text
What is specially meaningful about this morning?
```

not:

```text
What routine wake state is this morning in?
```

### 11.1 Allowed middle-lane categories

The middle lane may show:

1. **Ramadan context**
   - `Ramadan`
2. **Eid / no-fasting context**
   - `Eid`
   - `Fasting unavailable`, or compact `No fast` if width requires
3. **Sunnah fasting opportunities / observances**
   - `Ashura`
   - `Arafah`
   - `Dhul Hijjah`
   - `White Days`
   - `Shawwal 6`
4. **Other approved observance/context tags** supplied by the existing domain layer.

### 11.2 Disallowed middle-lane tags

Do not show these as compact middle-lane tags:

```text
Fajr
Fasting
Suhoor
Tahajjud
Quiet mode
Mon/Thu
Qada
Kaffarah
Vow
```

Rationale:

- `Fajr` is the ordinary baseline and should not be repeated on most rows.
- `Fasting`, `Suhoor`, `Qada`, `Kaffarah`, and `Vow` are intention/plan meanings that belong in detail, accessibility, or planning surfaces rather than this compact lane.
- `Quiet` belongs in the trailing status lane.
- Monday/Thursday is intentionally suppressed to avoid over-tagging routine weekly opportunities.

### 11.3 Intended fasting behavior

If the user has intended/planned a fast, do **not** show `[Fasting]` in this compact row.

If the intended fast is associated with a visible observance/context tag, show only that context tag.

Examples:

```text
Ashura intended fast      -> [Ashura]
White Days intended fast  -> [White Days]
Arafah intended fast      -> [Arafah]
Generic intended fast     -> no middle-lane tag unless another context applies
Qada intended fast        -> no middle-lane tag unless another context applies
```

The intended status may still appear in:

- Day Detail;
- accessibility text;
- future planning surfaces;
- hidden row display model fields;
- analytics/diagnostics.

### 11.4 Ramadan behavior

Ramadan remains visible as a context tag:

```text
[Ramadan]
```

Rules:

- Ramadan may visually own the middle lane when applicable.
- Do not show `[Fasting] [Ramadan]`.
- Do not show `[Fajr] [Ramadan]`.
- Ramadan wake/default behavior remains resolved upstream by the canonical morning resolver.

### 11.5 Eid and fasting-unavailable behavior

Eid and fasting-unavailable states should appear in the middle lane.

Preferred visible tags:

```text
[Eid]
[Fasting unavailable]
```

Compact fallback if width is constrained:

```text
[No fast]
```

Rules:

- Use the existing domain/context engine to determine when fasting is unavailable or prohibited.
- Do not infer no-fasting state from strings or UI labels.
- Do not use `[Fasting]` with these tags.
- These tags may suppress ordinary opportunity tags when the engine says fasting is unavailable.

### 11.6 Monday/Thursday suppression

Do not show a Monday/Thursday tag in the compact Next 7 Mornings card.

This includes:

- Monday/Thursday as an opportunity-only tag;
- Monday/Thursday as an intended-fast tag.

If the user intended a Monday/Thursday fast, the intention remains available in Day Detail and accessibility, but the compact middle lane should not display `Mon/Thu`.

### 11.7 Shawwal 6 completion-aware suppression

Show `Shawwal 6` only if all of the following are true:

1. the date is eligible for Shawwal 6;
2. the existing fasting engine says the tag is applicable/compatible;
3. the user has not already completed six intended Shawwal 6 fasts;
4. the completed count includes only fasts explicitly intended/tracked as Shawwal 6.

Qada, Kaffarah, Vow, Ramadan, generic voluntary fasts, or other fasts completed during Shawwal do not count toward Shawwal 6 unless they were explicitly intended/tracked as Shawwal 6.

---

## 12. Tag priority and maximum tags

Default maximum visible tags per row:

```text
3
```

Priority order:

1. Fasting unavailable / no-fast context
2. Eid
3. Ramadan
4. Arafah
5. Ashura
6. Dhul Hijjah
7. White Days
8. Shawwal 6
9. Other approved contextual tags from the domain layer

Rules:

- Tags must not wrap.
- Do not show `+2` overflow in this compact row unless a future design review approves it.
- If tags do not fit, cap by priority and preserve the full meaning in accessibility/detail.
- Apply compact tag-chip metrics before dropping a valid two-tag pair.
- A row with no valid context tags should show an empty middle lane.

---

## 13. Tag visual treatment

Tags should look like small, premium, restrained capsules.

Recommended base style:

- capsule shape;
- compact badge typography;
- low-opacity fill;
- subtle stroke;
- no heavy saturated pills;
- no icon by default;
- compact internal padding designed for two-tag and three-tag rows.

Recommended starting metrics at default text size:

```text
tagHorizontalPadding = 5–6 pt per side
tagVerticalPadding = 2–3 pt per side
interTagSpacing = 4 pt
strokeWidth = 0.75–1 pt
```

Rules:

- Do not use icon-leading chips in this compact row unless future design explicitly approves it.
- Preserve text readability.
- Use accessibility text for full meanings when compact labels are shortened.

---

## 14. Example row states

### Ordinary Fajr-anchored morning

```text
Tomorrow                              5:40 AM
```

### White Days opportunity

```text
Wed, May 6      [White Days]          5:33 AM
```

### White Days intended fast

```text
Wed, May 6      [White Days]          5:33 AM
```

Visible compact row is the same as opportunity-only; intention is available in detail/accessibility.

### Ashura

```text
Sat, May 2      [Ashura]              5:39 AM
```

### Arafah and Dhul Hijjah

```text
Thu, May 7      [Arafah] [Dhul Hijjah] 5:32 AM
```

### Ramadan

```text
Sun, Mar 8      [Ramadan]             5:11 AM
```

### Eid / fasting unavailable

```text
Fri, Mar 20     [Eid]                 5:09 AM
```

```text
Fri, Mar 20     [Fasting unavailable] 5:09 AM
```

### Quiet mode

```text
Tue, May 5                            Quiet
```

### Monday/Thursday opportunity

```text
Thu, May 7                            5:32 AM
```

Do not show `Mon/Thu` in this compact surface.

---

## 15. Forbidden visible row patterns

Do not show visible rows like:

```text
Tomorrow        [Fajr]                  5:40 AM
Sat, May 2      [Fajr] [Ashura]         5:39 AM
Sun, May 3      [Fasting] [Ashura]      5:37 AM
Mon, May 4      [Tahajjud]              5:36 AM
Tue, May 5      [Quiet mode]            5:35 AM
Thu, May 7      [Fasting] [Mon/Thu]     5:32 AM
```

Do not show explanatory row text such as:

```text
Regular Fajr morning • 30 min before Fajr ends
Fasting day • Changed • 45 min before Fajr begins
Moved earlier by latest wake
Skipped for this date
Fixed wake for this date
After Fajr
```

These meanings may still exist in the data model, accessibility label, detail screen, or diagnostics.

---

## 16. Data ownership

The renderer must not invent tags.

The renderer must not parse visible row text into tags.

The renderer must not infer observance compatibility on its own.

Recommended ownership:

```text
Schedule/domain layer
    resolves dates, wake times, contexts, intentions, quiet mode, completion progress

Context/opportunity domain layer
    determines Ramadan, Eid, fasting unavailable, observance opportunities, and compatibility

NextSevenMorningsPresentation
    converts resolved inputs into compact date label, context tags, trailing status, and accessibility text

NextSevenMorningsRowView
    renders only the prepared display model
```

Do not duplicate:

- Fajr calculation;
- wake-time resolution;
- Hijri date calculation;
- Ramadan detection;
- fasting observance compatibility;
- Shawwal 6 completion logic;
- Quiet mode semantics.

---

## 17. Recommended data contract

Names are illustrative. Use existing project conventions where available.

```swift
struct NextSevenMorningsSnapshot: Equatable {
    let title: String                    // "NEXT 7 MORNINGS"
    let subtitle: String                 // "View and plan your next seven mornings"
    let rows: [NextSevenMorningsRowDisplay] // exactly 7 when ready
    let loadingState: LoadingState
    let generatedAt: Date
}
```

```swift
struct NextSevenMorningsRowDisplay: Equatable, Identifiable {
    let id: String                       // canonical morning/date key
    let dateKey: String
    let date: Date
    let dateLabel: String                // Today, Tomorrow, Sat, May 2
    let contextTags: [MorningContextTagDisplay]
    let trailingTime: Date?
    let trailingStatusText: String?      // e.g. Quiet
    let isQuiet: Bool
    let isInactive: Bool
    let accessibilityLabel: String
}
```

```swift
struct MorningContextTagDisplay: Equatable, Identifiable {
    let id: String
    let title: String                    // Ramadan, Eid, Ashura, etc.
    let semantic: MorningContextTagSemantic
    let priority: Int
    let accessibilityText: String
}
```

```swift
enum MorningContextTagSemantic: Equatable {
    case ramadan
    case eid
    case fastingUnavailable
    case observanceOpportunity(FastSecondaryVirtueTag)
    case observanceContext(String)
}
```

Important: this compact display model may hide user intention states visually while preserving them for accessibility/detail.

---

## 18. Context tag resolver algorithm

Pseudo-logic:

```text
1. If fasting is unavailable/prohibited for the morning:
   return [Fasting unavailable] or [Eid] when Eid is the governing context.

2. If Eid applies:
   return [Eid].

3. If Ramadan applies:
   return [Ramadan].

4. Get compatible visible observance/context tags from the existing domain engine:
   - Arafah
   - Ashura
   - Dhul Hijjah
   - White Days
   - Shawwal 6
   - other approved context tags

5. Remove Monday/Thursday in all compact cases.

6. Suppress Shawwal 6 if completion-aware rules say it is complete.

7. Cap by priority and fit.

8. Return an empty tag list if no meaningful context remains.
```

Important:

- Do not add `[Fajr]` as fallback.
- Do not add `[Fasting]` for intended fasts.
- Do not add `[Quiet mode]`; Quiet is a trailing status.
- Do not parse UI strings to determine context.

---

## 19. Date range rules

When expanded and ready, the card shows exactly seven upcoming Fajr-centered mornings.

Default behavior:

- Row 1 is the next immediate alarm or next relevant morning supplied by the canonical resolver.
- If today’s relevant wake/alarm moment is still upcoming, Row 1 may be `Today`.
- If today’s relevant wake/alarm moment has passed, Row 1 is normally `Tomorrow`.
- Rows 2–7 are the following six calendar mornings.

Weekly Fajrcast alignment:

- `visibleDateKeys` for Next 7 Mornings should equal the Weekly Fajrcast `visibleDateKeys` in the same order.
- Neither surface should include previous mornings in this aligned MVP behavior.
- Neither surface should silently skip a Quiet/no-alarm morning merely to find an active marker.

Rules:

- The expanded card should not silently show fewer than seven rows in the ready state unless data is unavailable.
- If prayer-time data is partial, show truthful rows only and use a loading/partial state.
- Do not include past mornings.
- Completion history may affect context tags, especially Shawwal 6 suppression.

---

## 20. Interaction rules

### 20.1 Expand / collapse

The card appears collapsed by default on Home.

Collapsed state:

- `NEXT 7 MORNINGS` remains visible.
- `View and plan your next seven mornings` remains visible.
- Rows are hidden.
- The user can tap the header, expansion affordance, or approved card control to expand.

Expanded state:

- All seven rows are visible when data is ready.
- The user can collapse the card back to the header/helper-visible state.

Expansion/collapse is UI-only:

- no wake mode changes;
- no intention changes;
- no date-specific override changes;
- no scheduling changes;
- no alarm creation/cancellation.

### 20.2 Row tap

Tapping a row opens that morning’s existing detail view.

Rules:

- The full row is the tap target.
- Tags are not individually tappable.
- No inline editing appears in this card.
- Adjustments belong in detail or planning surfaces.

---

## 21. Accessibility requirements

Each row should expose one coherent accessibility label.

Recommended structure:

```text
{Date}. {Context summary if any}. {Wake or quiet status}. {Hidden intention detail if useful}. Double tap for details.
```

Examples:

```text
Tomorrow. Wake at 5:40 AM. Double tap for details.
Wednesday, May 6. White Days. Wake at 5:33 AM. Double tap for details.
Saturday, May 2. Ashura. Fast intended. Wake at 5:39 AM. Double tap for details.
Sunday, March 8. Ramadan morning. Wake at 5:11 AM. Double tap for details.
Tuesday, May 5. Quiet mode. Double tap for details.
```

Accessibility may include information not visible in the compact row, such as:

- Fajr or Suhoor mode;
- fasting intention;
- Qada/Kaffarah/Vow intention;
- hidden wake anchor under Quiet;
- adjusted time;
- latest wake cap;
- full observance list when visual tags are capped.

Visible rows must remain simple.

---

## 22. Dynamic Type and responsive behavior

All visible text must scale:

- header;
- helper copy;
- date label;
- context tags;
- wake time/status.

When layout is constrained:

1. preserve trailing wake/status readability;
2. preserve date label readability;
3. apply compact tag-chip padding and compact inter-tag spacing;
4. reduce visible tag count from three to two when needed;
5. preserve at least one meaningful context tag only after compact two-tag fitting has failed;
6. allow card height and row height to grow consistently;
7. do not wrap tags;
8. do not shrink wake time/status into illegibility;
9. do not reintroduce subtitle/explanatory row text.

Quiet rows must remain the same height as other rows for the same Dynamic Type profile.

---

## 23. Loading, partial, and empty states

### 23.1 Loading

Use a calm skeleton with seven row placeholders or a preserved card height.

Do not show fake tags.

### 23.2 Partial data

If some future mornings cannot be resolved:

- show resolved rows truthfully;
- show unavailable rows with calm status only if necessary;
- do not invent wake times;
- do not invent tags.

### 23.3 Empty/error

If no forecast can be resolved:

```text
NEXT 7 MORNINGS
View and plan your next seven mornings
Wake forecast will appear once times are available.
```

This is exceptional, not a normal row pattern.

---

## 24. Current codebase migration guidance

Existing source areas likely relevant:

```text
Subh/Features/Home/MorningHomeSnapshot.swift
Subh/Features/Home/SubhHomeView.swift
Subh/Features/Wake/WakePagePresentation.swift
Subh/Features/Wake/WakeRowComponents.swift
Subh/Core/ProductSurfacePresentation.swift
Subh/Core/Morning/Context/MorningFastDomain.swift
Subh/Core/Morning/Context/MorningTagComputationDomain.swift
Subh/Core/Morning/Context/ResolvedDayContextResolver.swift
Subh/Core/Morning/Models/MorningContextModels.swift
Subh/Features/Wake/FajrWindowCompactCard.swift
Subh/UI/Components/AppGlassSystem.swift
Subh/Core/Utilities/DesignTokens.swift
```

Do not reuse visible `subtitle` text or bullet-separated prose as the source of tags.

Do not parse existing visible strings.

Do not reuse a general-purpose chip list if it forces state tags like `Fajr`, `Fasting`, or `Quiet mode` into this compact middle lane.

Recommended implementation direction:

```text
Resolved morning/day snapshot
  -> context/opportunity resolver
  -> NextSevenMorningsPresentation.row(...)
  -> NextSevenMorningsRowDisplay
  -> NextSevenMorningsRowView
```

Reuse:

- `AppGlassSurface`;
- `WakeGlassTheme`;
- `DesignTokens`;
- existing time lockup visual language;
- existing fasting/observance domain types;
- existing tag compatibility logic;
- existing row tap-to-detail navigation.

---

## 25. Testing requirements

### 25.1 Header and collapsed-state tests

- Collapsed Home state shows `NEXT 7 MORNINGS`.
- Collapsed Home state shows `View and plan your next seven mornings`.
- Collapsed Home state hides the seven rows.
- Expanding reveals exactly seven rows when ready.
- Collapsing hides rows without mutating wake state.
- Old visible copy `NEXT 7 DAYS` is not shown.
- Old visible copy `7-DAY WAKE FORECAST` is not shown.

### 25.2 Home placement tests

- The card appears inside the **Plan ahead** section.
- The card appears above Calendar Months and Hijri Months.
- The Plan ahead heading uses high-contrast/white styling.

### 25.3 Row layout tests

- Row display has date label, context tag lane, and trailing wake/status lane.
- Tag cluster horizontal centerline aligns across all seven rows.
- Short date labels do not pull tags left.
- Long date labels do not push tags right.
- Quiet’s trailing `Quiet` status does not change grid width or row height.
- Date label, context tag cluster, and wake/status are vertically centered between row dividers.
- Row height remains consistent across ordinary, opportunity, Ramadan, Eid, fasting-unavailable, Suhoor-resolved, and Quiet rows for a given text-size profile.
- Quiet mode does not shrink the row height.
- Row display has no visible subtitle.
- Relation/provenance text is not visible.

### 25.4 Context tag tests

- Ordinary morning returns no visible context tags.
- Fajr fallback is not rendered as `[Fajr]`.
- Intended fasting does not render `[Fasting]`.
- Suhoor does not render `[Suhoor]`.
- Quiet mode does not render `[Quiet mode]` in the middle lane.
- Quiet mode renders `Quiet` in the trailing lane.
- Ramadan renders `[Ramadan]`.
- Eid renders `[Eid]`.
- Fasting unavailable renders `[Fasting unavailable]` or approved compact `[No fast]`.
- Ashura context renders `[Ashura]`.
- Arafah context renders `[Arafah]`.
- Dhul Hijjah context renders `[Dhul Hijjah]`.
- White Days context renders `[White Days]`.
- Shawwal 6 context renders `[Shawwal 6]` when remaining.
- Shawwal 6 suppresses after six intended Shawwal 6 fasts are completed.
- Monday/Thursday does not render as a compact tag, even when the fast is intended.
- Full hidden meaning remains available in accessibility/detail.

### 25.5 Accessibility tests

- Accessibility label includes date.
- Accessibility label includes visible context meanings.
- Accessibility label includes wake time or Quiet status.
- Accessibility may include hidden intention details where useful.
- Accessibility includes full tag detail if visual tags are capped.

---

## 26. Locked requirements

These should not change without design review:

1. Visible header is `NEXT 7 MORNINGS`.
2. Visible helper copy is `View and plan your next seven mornings`.
3. Do not show `NEXT 7 DAYS` as visible copy.
4. Do not show `7-DAY WAKE FORECAST`.
5. The card is collapsed by default on Home with header/helper visible.
6. The expanded card shows seven upcoming Fajr-centered mornings in the ready state.
7. Home placement is inside **Plan ahead**, above Calendar Months and Hijri Months.
8. Each row has only date, opportunity/context tags, and wake time/status.
9. Rows do not show visible subtitles.
10. Rows do not show bullet-separated explanatory text.
11. Tags are not individually tappable.
12. The row remains the tap target for detail navigation.
13. Tags are centered in a shared middle lane that aligns across all seven rows.
14. Expanded rows use consistent state-invariant row height for the same Dynamic Type profile.
15. Quiet mode rows do not become shorter than non-Quiet rows.
16. Quiet mode appears as trailing `Quiet`, not as a middle-lane tag.
17. Routine `[Fajr]` tags are not shown.
18. `[Fasting]` is not shown in the compact middle lane.
19. `[Suhoor]` is not shown in the compact middle lane.
20. `[Tahajjud]` is not shown in the compact middle lane.
21. `[Ramadan]` remains visible as context.
22. `[Eid]` remains visible where applicable.
23. Fasting-unavailable/no-fast context remains visible where applicable.
24. Monday/Thursday tags are suppressed in this compact surface.
25. Shawwal 6 is completion-aware.
26. Compatible opportunity/context overlaps may show together.
27. The row renderer must not recreate observance compatibility logic.
28. The row renderer must not invent tags.
29. Tags are capped and do not wrap.
30. Accessibility preserves the full meaning hidden from the compact row.

---

## 27. Recreation checklist

### Card shell

- [ ] Uses dark grouped glass card.
- [ ] Rounded continuous corners match current visual direction.
- [ ] Content padding is handled internally, not by a default `List`.
- [ ] Header and row dividers use the same subtle line style.

### Header

- [ ] Header reads `NEXT 7 MORNINGS`.
- [ ] Helper reads `View and plan your next seven mornings`.
- [ ] Old `NEXT 7 DAYS` copy is removed from the visible surface.
- [ ] Header uses eyebrow styling.
- [ ] Helper copy is subordinate but legible.

### Rows

- [ ] Card is collapsed by default with rows hidden.
- [ ] Expanded card renders exactly seven rows in ready state.
- [ ] Date labels are Gregorian-first.
- [ ] No visible subtitle appears.
- [ ] Time/status lockup remains large and right-aligned.
- [ ] Quiet renders as trailing `Quiet`.
- [ ] Tags sit centered between the shared date lane and shared trailing lane.
- [ ] Tag centerline aligns across all seven rows.
- [ ] Date label, tag cluster, and wake/status are vertically centered.
- [ ] Row height is consistent across all row states.
- [ ] Quiet does not shrink the row.

### Context tags

- [ ] Ordinary morning shows no middle-lane tag.
- [ ] Ramadan shows `[Ramadan]`.
- [ ] Eid shows `[Eid]`.
- [ ] Fasting unavailable/no-fast context appears.
- [ ] Opportunity/context tags appear for Ashura, Arafah, Dhul Hijjah, White Days, and Shawwal 6 where applicable.
- [ ] Monday/Thursday does not appear.
- [ ] Fajr/Fasting/Suhoor/Tahajjud/Quiet mode do not appear as middle-lane tags.
- [ ] Shawwal 6 is suppressed after six intended Shawwal 6 fasts are completed.
- [ ] Full meaning remains in accessibility/detail.

---

## 28. Remaining open items

### 28.1 Full intent visibility

This compact card intentionally hides some intention states, such as generic intended fasting or Qada. Day Detail and accessibility must preserve the meaning so the compact visual simplification does not erase user understanding.

### 28.2 Fasting-unavailable label length

Preferred visible label is `Fasting unavailable`. If this does not fit in the compact lane at common sizes, `No fast` may be used as a compact visual label with accessibility text of `Fasting unavailable`.

### 28.3 Extreme Dynamic Type

At very large accessibility sizes, the card may reduce visible tags, but must not reintroduce row subtitles or allow row-by-row height variance.

---

## 29. Final design intent

The Next 7 Mornings card should feel like a calm, premium preview of the user’s near-term Fajr-centered life.

At a glance, the user should understand:

- what morning is coming;
- whether anything special applies;
- whether they will wake or be quiet.

The strongest version of the card is restrained:

```text
Tomorrow                              5:40 AM
Sat, May 2      [Ashura]              5:39 AM
Sun, May 3                            Quiet
Mon, May 4                            5:36 AM
Tue, May 5      [White Days]          5:35 AM
Wed, May 6      [Ramadan]             5:33 AM
Thu, May 7      [Eid]                 5:32 AM
```

This gives the user the essence of the next seven mornings without clutter: date, meaningful context, wake status.
