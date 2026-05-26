# Next 10 Mornings Wake Forecast Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-next-10-mornings-wake-forecast-spec-v4.md` |
| Version | 4 |
| Spec status | Product / implementation direction; canonical Desktop working spec |
| Supersedes | None recorded in the active Desktop set |
| Related specs | `00-subh-spec-index-v1.md`, `subh-morning-resolution-contract-state-ownership-spec-v2.md`, `subh-quick-wake-mode-intent-mutation-contract-v1.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v2.md`, `subh-alarm-detail-view-screen-spec-v7.md` |
| Owning domain / surface | Home / Next 10 Mornings forecast surface |
| Implementation audit status | Needs implementation audit |

## Purpose
Define the compact and expanded forecast that previews the next 10 resolved mornings without becoming a second wake engine.

## What This Spec Owns
- Forecast row content, grouping, collapsed/expanded behavior, and routing.
- Tag and wake-state display rules for upcoming mornings.
- Home integration boundaries for future-day hydration.

## Normative Requirements
The normative requirements in this spec are the explicit MUST, SHALL, required, acceptance, and scenario statements below. Recommendations, implementation guidance, examples, and future-direction notes are advisory unless this spec or a later canonical spec promotes them to requirements.

## Out of Scope / Deferred
- Code/spec divergence classification is deferred to a later implementation audit.
- App code, tests, and OpenSpec library artifacts are out of scope for this docs-only cleanup.
- Historical archive filenames are kept only as historical references and are not promoted back into the active spec set.

## Open Questions and Deferred Work
Open questions, TODO-style notes, future ideas, and implementation audit prompts below are retained as the working queue for later spec improvement. This cleanup standardizes them as deferred work rather than claiming they are resolved.

## Cleanup Notes
- This file was renamed and header-normalized in the Desktop working-spec cleanup pass.
- The Desktop folder remains the canonical working-spec location.
- Implementation completeness claims in older prose should be treated as historical context until the later audit updates this field.

## MVP Suhoor Alignment Addendum
This addendum is normative for MVP and supersedes conflicting lower sections in this file.

- Forecast rows should reflect `Suhoor`, `Fajr`, and `Quiet` as the active MVP wake-mode vocabulary.
- `Suhoor` is the only exposed before-Fajr wake state in MVP.
- Rows must not surface `Tahajjud only`, `Other early worship`, or generic `Pre-Fajr` as active user-selectable states.
- Suhoor rows may show fasting-opportunity or fasting-purpose tags according to the tag doctrine, but opportunity-only dates must remain informational and must not become intended Suhoor.
- Quiet rows preserve underlying Suhoor/Fajr meaning for restoration while showing delivery suppression.

## 1. Scope

This specification defines the **Next 10 Mornings Wake Forecast** card as a standalone product, UX, visual, data, tagging, interaction, collapsed/expanded, and accessibility component.

It replaces the current visible “10-Day Wake Forecast / Next 10 mornings” presentation with a cleaner, single-header, tag-driven forecast list.

This revision also locks the Home behavior:

```text
Next 10 Mornings is collapsed by default on Home.
The header remains visible.
The user can expand it to reveal the ten-row list.
```

The component must preserve the current premium glass visual direction while simplifying the information architecture of each row.

This spec covers:

- visible card naming
- collapsed and expanded Home behavior
- row anatomy
- row-height invariance across states, including Quiet mode
- tag doctrine
- tag priority and suppression rules
- Fajr fallback behavior
- Ramadan behavior
- fasting intention vs fasting opportunity
- Tahajjud interaction
- quiet mode future behavior
- Shawwal 6 completion-aware suppression
- divider styling
- row layout
- data contract
- accessibility
- Codex implementation guidance
- acceptance checklist

This spec does **not** define:

- the full day detail screen
- the full Plans tab behavior
- the full fasting intention editor
- the quiet mode pipeline implementation
- the completion/progress history architecture beyond the inputs needed for tag suppression
- alarm delivery semantics
- prayer-time calculation logic
- Weekly Fajrcast behavior

Weekly Fajrcast remains as currently designed and is not collapsed by this specification.

## 2. One-sentence definition

**Next 10 Mornings is a dark, glass-style wake forecast that appears collapsed by default on Home with its header visible, and expands into a ten-row list showing only three visible row concepts: the date, compact state tags, and the resolved wake time/status.**

The card helps the user understand:

- which upcoming mornings are coming next
- when the user is expected to wake
- whether the morning is ordinary Fajr, Ramadan, fasting-intended, Tahajjud-intended, a Sunnah opportunity, quiet mode, or another meaningful state
- what changed from ordinary without displaying explanatory prose in every row

---

## 3. Product mental model

Subh is a **Fajr-centered morning system**.

Every morning is resolved around a default Fajr-based wake rhythm unless a stronger state modifies it.

The forecast card should express that model with minimal visible content:

```text
ordinary Fajr rhythm -> meaningful day state -> wake execution
```

The row should not explain the entire decision tree. It should only show the resolved result.

Detailed explanations belong in:

- day detail
- settings
- Plans
- Progress
- accessibility text
- diagnostics/tests

They do not belong as visible row subtitles in this card.

---

## 4. Naming

### Visible card header

The card header is exactly:

```text
NEXT 10 MORNINGS
```

### Removed visible text

Do not show:

```text
10-DAY WAKE FORECAST
Next 10 mornings
```

as a two-line header.

The old title/subtitle structure should be removed from the visible component.

### User-facing name

Use this name in product writing and accessibility when needed:

```text
Next 10 Mornings
```

### Internal component name

Recommended new naming:

```swift
NextTenMorningsCard
NextTenMorningsRowView
NextTenMorningsPresentation
NextTenMorningsTagResolver
NextTenMorningsSnapshot
```

Avoid continuing to use `Morningcast` in new public-facing naming. It may remain as a compatibility alias only if needed during migration.

---

## 5. Core design principle

The visible row has only three concepts:

```text
Date label | Tag cluster | Wake time/status
```

Do not show any visible subtitle line.

Do not show visible explanatory prose in the row.

Do not show bullet-separated row text.

Do not show adjustment, relation, provenance, latest-wake cap, or schedule-rule language in the visible row.

### Forbidden visible row patterns

Do not show:

```text
Regular Fajr morning • 30 min before Fajr ends
Fasting day • Changed • 45 min before Fajr begins
Moved earlier by latest wake
Skipped for this date
No wake set
Fixed wake for this date
After Fajr
Available for this date only
```

These meanings may still exist in the data model and accessibility labels.

---

## 6. Card anatomy

The card has two presentation states:

1. **Collapsed Home state** — header visible, rows hidden.
2. **Expanded state** — header visible, ten forecast rows visible.

### Collapsed Home state

The collapsed state contains:

1. Liquid Glass outer shell
2. single header row
3. expansion affordance
4. optional header divider, if visually needed by the glass system

Collapsed visible header:

```text
NEXT 10 MORNINGS
```

Rules:

- The header remains visible so the user knows what can be expanded.
- Do not show the ten rows while collapsed.
- Do not show row dividers while collapsed unless a visual affordance requires one header divider.
- Do not show a preview dense enough to compete with the Home hero.
- Collapsing does not change wake state, scheduling, intention, or persistence.

### Expanded state

The expanded state contains:

1. Liquid Glass outer shell
2. single header row
3. header divider
4. ten forecast rows
5. row dividers
6. optional bottom divider after the final row

Recommended expanded structure:

```text
┌──────────────────────────────────────────────┐
│ NEXT 10 MORNINGS                             │
├──────────────────────────────────────────────┤
│ Tomorrow        [Fajr]                5:40 AM│
├──────────────────────────────────────────────┤
│ Sat, May 2      [Fajr] [Ashura]       5:39 AM│
├──────────────────────────────────────────────┤
│ Sun, May 3      [Fasting] [Ashura]    5:37 AM│
├──────────────────────────────────────────────┤
│ ...                                          │
└──────────────────────────────────────────────┘
```

The card should feel like the current screenshot when expanded: premium, calm, glassy, and spacious.

## 7. Visual shell

Use the existing app glass system.

Recommended implementation:

```swift
AppGlassSurface(
    variant: .grouped,
    contentPadding: 0
) { ... }
```

The visual direction should remain:

- dark glass
- subtle translucency
- rounded continuous corners
- low-opacity border
- no opaque table background
- no heavy dashboard chrome
- no bright card-level accent color

The card should visually harmonize with the Weekly Fajrcast card.

---

## 8. Divider requirements

Use the same divider treatment as the Weekly Fajrcast card header/footer boundaries.

Recommended implementation:

```swift
Rectangle()
    .fill(WakeGlassTheme.divider)
    .frame(height: 1)
```

Required behavior:

- header divider uses the same style as row dividers
- row dividers are subtle and do not dominate the card
- divider opacity should remain approximately white at 5% opacity
- dividers align to the same internal content grid as the Weekly Fajrcast card
- do not use default iOS List separators
- do not use row-specific colored separators
- do not remove row separation entirely; ten large time rows need structure

Divider placement:

- one divider after the header
- one divider between each row
- optional final divider after row 10 if visually needed

---

## 9. Header requirements

### Header text

Visible text:

```text
NEXT 10 MORNINGS
```

Style direction:

- uppercase
- small eyebrow style
- 50–60% white opacity
- tracking consistent with existing app eyebrow styling
- vertically aligned with the row content grid

Recommended base style:

```swift
Text("NEXT 10 MORNINGS")
    .appTextRole(.eyebrow)
    .foregroundStyle(WakeGlassTheme.tertiaryText)
```

### Header padding

Header should feel similar to the current card, but slightly cleaner because there is only one line.

Recommended starting point:

- horizontal inset: match Weekly Fajrcast compact card / current card grid
- top padding: 16–18 pt
- bottom padding: 10–12 pt

The header must not look like a separate card title plus subtitle block.

---

## 10. Row anatomy

Each row contains exactly:

1. date label
2. centered tag cluster
3. trailing wake time/status

The tag cluster must sit in a **stable center lane** between the date label lane and the alarm time lane. It must not drift left or right from row to row merely because one date label is shorter, one alarm time is wider, or one tag cluster has fewer tags.

This section locks two fixes from implementation testing:

1. the tag cluster must be centered from a shared row grid, not from row-specific `HStack` spacing; and
2. the date label, tag cluster, and wake time/status must all be vertically centered between the row's upper and lower horizontal dividers.

### Required row grid

Do **not** use a natural `HStack` where the tags are placed immediately after the date text and then followed by a spacer. That creates row-by-row tag-position deviations because `Tomorrow`, `Sat, May 2`, and `Wednesday, May 6` have different measured widths.

Use a measured three-lane row grid instead:

```text
date lane | centered tag lane | time/status lane
```

Recommended geometry:

```text
contentWidth = full internal row content width
contentLeadingX = 0
contentTrailingX = contentWidth

dateLaneWidth = max(
    minimumDateLaneWidth,
    widest measured date label across the 10 visible rows
)

timeLaneWidth = max(
    minimumTimeLaneWidth,
    widest measured trailing time/status lockup across the 10 visible rows
)

middleLaneLeadingX = contentLeadingX + dateLaneWidth + minimumDateToTagGap
middleLaneTrailingX = contentTrailingX - timeLaneWidth - minimumTagToTimeGap

tagLaneWidth = middleLaneTrailingX - middleLaneLeadingX
tagLaneCenterX = middleLaneLeadingX + (tagLaneWidth / 2)
```

All ten rows must use the same `dateLaneWidth`, `tagLaneWidth`, `timeLaneWidth`, `middleLaneLeadingX`, `middleLaneTrailingX`, and `tagLaneCenterX` for a given resolved snapshot and text-size environment.

The visual midpoint of the full tag cluster must sit on `tagLaneCenterX`. This is the center of the shared space between the measured date lane and measured time lane, not the center produced by a row-specific spacer after the date text renders.

### Required alignment behavior

- The date label is leading-aligned inside the shared date lane.
- The wake time/status is trailing-aligned inside the shared time lane.
- The full tag cluster is centered inside the shared tag lane.
- The tag cluster horizontal centerline must align across all ten rows.
- The tag lane center must be computed from the shared row grid, not from each row’s actual date-label text width.
- Short date labels like `Tomorrow` must not pull tags left.
- Longer date labels like `Wednesday, May 6` must not push tags right.
- Wider times or status labels must be accounted for by the shared time lane, not by row-specific spacing.
- Do not use a natural row-level `HStack(alignment: .firstTextBaseline)` plus `Spacer()` to position the tags; that pattern is prone to both horizontal drift and vertical mis-centering.
- Prefer a custom `Layout`, `Grid`, measured `PreferenceKey` pass, or a `ZStack`-based row that places the date lane, tag lane, and time lane from shared metrics.

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

A `ZStack` or custom `Layout` is also acceptable, and may be preferable if it gives stricter control over `tagLaneCenterX`.

The exact implementation may use `Grid`, a measured layout helper, a custom `Layout`, or a `PreferenceKey` measurement pass. The requirement is the alignment result: **tags are perfectly centered in the same middle lane across all ten rows.**

### Date label

The date label identifies the morning.

Preferred visible formats:

```text
Tomorrow
Sat, May 2
Sun, May 3
Mon, May 4
```

Rules:

- The first row should usually say `Tomorrow`.
- Subsequent rows should use Gregorian date labels like `Sat, May 2`.
- Do not replace the Gregorian row date with Ramadan date text.
- Ramadan should be communicated by the `[Ramadan]` tag, not by changing the date label.
- Hijri/Islamic context belongs in tags, detail views, accessibility, or future expanded displays.

This is a deliberate surface-specific departure from any existing generic row date label that may show Ramadan-specific date text.

### Tag cluster

Tags sit in the centered tag lane between the date label lane and the trailing time lane.

Rules:

- Tags are visible chips/capsules.
- Tags must never wrap to a second line in the standard row layout.
- Tags must not push the wake time off-screen.
- Tags must not replace the wake time.
- Tags must be text-readable and not icon-only.
- Tags are not tappable in this compact card.
- Tags must be horizontally centered as a group inside the shared tag lane.
- A row with one tag and a row with three tags still share the same tag-lane centerline.
- Tag chip padding must be compact enough that normal two-tag combinations such as `[Fajr] [White Days]` do not collapse solely because the capsules are over-padded.

### Trailing wake time/status

The trailing time remains the dominant visual information in the row.

Preferred format:

```text
5:40 AM
```

Rules:

- Use large, right-aligned, monospaced digits where possible.
- Keep the same visual feeling as the current screenshot.
- The time should be visually stronger than the tags.
- The meridiem suffix should be smaller than the main time.
- If a wake anchor exists but alarm delivery is quiet/paused, the row may still show the wake time while the tag communicates quiet mode.
- If no wake anchor exists, the trailing area may show a concise status, but this should be rare and separately reviewed because the preferred card model is date + tags + time.

## 11. Row height, spacing, and vertical centering

Rows should preserve the current spacious rhythm, but the content inside each row must be geometrically centered between the row boundary dividers.

### State-invariant row height

The row height must remain consistent for every row in the expanded card for the current device width and Dynamic Type profile.

In particular, Quiet mode must not make a row shorter.

Required behavior:

- Fajr rows, Ramadan rows, fasting-intended rows, Tahajjud rows, custom rows, and Quiet mode rows use the same resolved row height for the same text-size environment.
- Row height may grow for Dynamic Type or measured content, but it must grow consistently across the list.
- Quiet mode must keep the same vertical row footprint even if it has fewer visible tags or a shorter trailing status.
- Do not derive row height from only the natural height of each row’s current contents.
- Use shared row metrics for the expanded snapshot.


A row is the vertical cell between its upper horizontal divider and lower horizontal divider. The date label, tag cluster, and wake time/status lockup all share the same row center.

Required geometry:

```text
rowTopY = lower edge of the divider above the row
rowBottomY = upper edge of the divider below the row
rowHeight = rowBottomY - rowTopY
rowCenterY = rowTopY + (rowHeight / 2)

dateLabelFrame.centerY == rowCenterY
tagClusterFrame.centerY == rowCenterY
timeLockupFrame.centerY == rowCenterY
```

Required behavior:

- The date label must be vertically centered between the row dividers.
- The full tag cluster must be vertically centered between the row dividers.
- The full wake time/status lockup must be vertically centered between the row dividers.
- The meridiem suffix may baseline-align internally with the main time, but the **whole time lockup frame** must be center-aligned in the row.
- Do not use row-level `.firstTextBaseline` alignment to align the three outer row elements.
- Do not add element-specific top/bottom offsets to manually nudge only the date, only the tags, or only the time.
- Any vertical padding must be symmetric around the row center.

Recommended direction:

- default row vertical padding: approximately 18–20 pt
- compact/smaller text sizes: never below 14 pt vertical breathing
- accessibility sizes: grow row height rather than clipping tags or wake time

The list should remain calm and scan-friendly.

Do not compress rows to fit more content above the fold.

---

## 12. Tag doctrine

Tags are not explanations. Tags are compact state markers.

A tag should answer:

```text
What kind of morning is this?
```

not:

```text
Why did the scheduling engine choose this wake time?
```

### Key doctrine

`[Fajr]` is **not** a universal base tag, but it is still the visible anchor tag for Fajr-based ordinary and opportunity-only mornings.

`[Fajr]` appears when the morning remains Fajr-anchored and no intentional or overriding state owns the row.

The row may show `[Fajr]` beside non-intended Sunnah opportunity tags such as `[Ashura]`, `[Arafah]`, `[White Days]`, `[Dhul Hijjah]`, or `[Shawwal 6]`.

The row must not show `[Fajr]` beside stronger intentional or overriding tags like `[Fasting]`, `[Tahajjud]`, `[Ramadan]`, or `[Quiet mode]`.

---

## 13. Tag categories

### 13.1 Fajr anchor/fallback tag

Visible tag:

```text
[Fajr]
```

Meaning:

- ordinary Fajr-based wake morning
- no intended fast
- no intended Tahajjud
- no Ramadan state
- no quiet mode
- the wake is still fundamentally anchored to Fajr

Use `[Fajr]` when the day is normal **or** when a Sunnah fasting opportunity exists but the user has not intended/planned that fast.

Opportunity-only examples:

```text
[Fajr] [Ashura]
[Fajr] [Arafah]
[Fajr] [White Days]
[Fajr] [Shawwal 6]
[Fajr] [Arafah] [Dhul Hijjah]
```

Do not show `[Fajr]` when:

- Ramadan applies
- quiet mode applies
- fasting is intended
- Tahajjud is intended
- a stronger intentional or overriding special context owns the row

### 13.2 Ramadan tag

Visible tag:

```text
[Ramadan]
```

Rules:

- Ramadan shows only `[Ramadan]`.
- Do not show `[Fajr] [Ramadan]`.
- Do not show `[Fasting] [Ramadan]` in this compact forecast.
- Ramadan visually owns the row.
- Ramadan may still affect wake rules upstream.
- Ramadan detail text belongs in the detail view or accessibility, not in the row.

### 13.3 Fasting-intended tag

Visible base tag:

```text
[Fasting]
```

Show `[Fasting]` only when the user has actually intended/planned a fast.

Do not show `[Fasting]` for mere opportunities.

If the intended fast has a specific type or observance, show `[Fasting]` plus the specific tag.

Examples:

```text
[Fasting] [Ashura]
[Fasting] [Arafah]
[Fasting] [White Days]
[Fasting] [Shawwal 6]
[Fasting] [Qada]
[Fasting] [Kaffarah]
[Fasting] [Vow]
[Fasting] [Dhul Hijjah]
```

If the user intends a generic voluntary fast with no recognized specific observance:

```text
[Fasting]
```

Rules:

- Do not show `[Fajr]` with `[Fasting]`.
- `[Fasting]` indicates intention, not opportunity.
- `[Fasting]` may appear with multiple compatible observance/type tags if the engine says they make sense.

### 13.4 Tahajjud-intended tag

Visible tag:

```text
[Tahajjud]
```

Rules:

- Show `[Tahajjud]` when Tahajjud is intended/planned or the day uses Tahajjud refinement.
- Do not show `[Fajr]` with `[Tahajjud]`.
- If a fast is also intended, fasting normally appears before Tahajjud only if both are allowed to surface.
- If no fast is intended but the date has a visible fasting opportunity, Tahajjud may coexist with the opportunity tag.

Examples:

```text
[Tahajjud]
[Tahajjud] [Ashura]
[Tahajjud] [White Days]
```

If row space is constrained, `[Tahajjud]` normally outranks opportunity tags but does not outrank `[Fasting]` or `[Ramadan]`.

### 13.5 Quiet mode tag

Visible tag:

```text
[Quiet mode]
```

Rules:

- Quiet mode shows `[Quiet mode]` only.
- Do not show any other tag with quiet mode.
- Do not show `[Fajr] [Quiet mode]`.
- Do not show `[Fasting] [Quiet mode]`.
- Do not show `[Tahajjud] [Quiet mode]`.
- Do not show opportunity tags with quiet mode.

Quiet mode is not fully implemented yet. This spec defines the future visual contract so the eventual pipeline has a target.

Open implementation question:

- If quiet mode preserves a wake anchor but suppresses notification behavior, the row should likely still show the wake time.
- If quiet mode means no wake cue or planned wake anchor, the trailing area may need a concise status instead of a time.

Do not solve this by adding explanatory row text.

### 13.6 Opportunity tags

Opportunity tags mean the date has a meaningful Sunnah fasting opportunity, but the user has not yet intended/planned the fast.

In this compact forecast, an opportunity-only morning still displays the Fajr anchor because the morning remains an ordinary Fajr-based wake unless the user commits to fasting or Tahajjud.

Examples:

```text
[Fajr] [Ashura]
[Fajr] [Arafah]
[Fajr] [Dhul Hijjah]
[Fajr] [White Days]
[Fajr] [Shawwal 6]
```

Rules:

- Do not show `[Fasting]` unless the user intended the fast.
- Show `[Fajr]` alongside qualifying non-intended opportunity tags.
- Opportunity tags may coexist when the engine determines the overlap is valid.
- `[Fajr]` should remain first in opportunity-only rows.

Examples:

```text
[Fajr] [Arafah] [Dhul Hijjah]
[Fajr] [White Days] [Shawwal 6]
```

### 13.7 Monday/Thursday rule

Do not show `[Mon/Thu]` as a mere opportunity in this compact forecast.

Show it only when the user has actually intended/planned that fast.

Examples:

```text
[Fasting] [Mon/Thu]
```

Without intention, a Monday or Thursday should show another applicable tag if one exists; otherwise it falls back to:

```text
[Fajr]
```

### 13.8 White Days rule

White Days can appear as an opportunity.

Examples:

```text
[Fajr] [White Days]
[Fasting] [White Days]
```

Rules:

- If not intended, show `[Fajr] [White Days]`.
- If intended, show `[Fasting] [White Days]`.
- White Days may coexist with Shawwal 6 when the engine marks the overlap as compatible.

### 13.9 Shawwal 6 rule

Shawwal 6 can appear as an opportunity or intended fast tag only while it remains relevant.

Examples:

```text
[Fajr] [Shawwal 6]
[Fasting] [Shawwal 6]
[Fajr] [White Days] [Shawwal 6]
[Fasting] [White Days] [Shawwal 6]
```

Suppression rule:

Show `[Shawwal 6]` only if all of the following are true:

1. the date is eligible for Shawwal 6
2. the existing fasting engine says the tag is applicable/compatible for that date
3. the user has not already completed six Shawwal fasts
4. the completed count includes only fasts that were intended as Shawwal 6
5. Qada, Kaffarah, Vow, Ramadan, generic voluntary fasts, or other fasts completed during Shawwal do **not** count toward the six unless they were explicitly intended/tracked as Shawwal 6

Do not infer Shawwal completion from “fasted during Shawwal” alone.

The resolver should receive a completion-aware input such as:

```swift
ShawwalSixProgressSummary
- completedIntendedShawwalSixCount
- remainingCount
- completedDateKeys
- isComplete
```

If `isComplete == true`, suppress `[Shawwal 6]` in this compact forecast.

---

## 14. Overlapping opportunity rules

The tag resolver must not recreate complex fiqh/observance compatibility logic manually.

It should reference the existing fasting domain and compatibility engine.

Current overlap patterns already supported by the fasting domain include examples such as:

- Monday/Thursday coexisting broadly
- White Days coexisting with Shawwal 6
- Arafah coexisting with first nine of Dhul Hijjah
- compatible observance filtering by priority

The forecast tag resolver should consume already-normalized or date-derived compatible observance tags.

Rules:

- Tags can appear together when the engine says they make sense.
- Do not duplicate compatibility logic inside SwiftUI row rendering.
- Do not parse visible strings to determine overlap.
- Do not show suppressed tags.
- Do not show Monday/Thursday unless intended even if it is technically date-derived.
- Do not show Shawwal 6 when completion-aware suppression applies.

---

## 15. Tag priority

Apply this priority for visible tags:

1. Quiet mode
2. Ramadan
3. Fasting intention
4. Specific intended obligatory fast: Qada, Kaffarah, Vow
5. Specific intended Sunnah/observance tags: Arafah, Ashura, Dhul Hijjah, White Days, Shawwal 6, Mon/Thu
6. Tahajjud intention
7. Fajr anchor with opportunity-only tags: Fajr + Arafah, Ashura, Dhul Hijjah, White Days, Shawwal 6
8. Fajr fallback

### Practical display rules

- Quiet mode replaces all tags.
- Ramadan replaces all tags.
- Fasting intention removes `[Fajr]`.
- Tahajjud intention removes `[Fajr]`.
- Opportunity-only tags do **not** remove `[Fajr]`; they appear beside it.
- `[Fajr]` appears when no intentional or overriding state applies, including when a non-intended opportunity is being surfaced.

---

## 16. Maximum visible tags

Default maximum visible tags per row:

```text
3
```

Do not wrap tags.

Before dropping a valid second tag, the implementation must first use the compact tag-chip metrics in Section 17. A normal two-tag opportunity pair such as `[Fajr] [White Days]` is a protected fit target at standard row width and standard dynamic type sizes. It must not collapse to `[Fajr]` or `[White Days]` merely because chip padding, inter-chip spacing, or row layout is too generous.

Do not show `+2` overflow in the compact row unless a future design review approves it.

If more than three tags are valid:

- show the highest-priority three
- include the full tag list in accessibility
- preserve full details in the day detail view

Examples of acceptable visible maximums:

```text
[Fasting] [White Days] [Shawwal 6]
[Fasting] [Arafah] [Dhul Hijjah]
[Tahajjud] [White Days] [Shawwal 6]
```

---

## 17. Tag visual treatment

Tags should look like small, premium, restrained capsules.

Recommended base style:

- capsule shape
- small badge typography
- short readable label
- low-opacity fill
- subtle stroke
- no heavy saturated pill
- no bouncing badges
- no icon by default
- compact internal padding designed for two-tag and three-tag rows

### Compact tag-chip metrics

Implementation testing showed that overly generous capsule padding can cause valid secondary tags to disappear, such as an intended visible pair of `[Fajr] [White Days]`. This card needs its own compact chip metrics rather than blindly reusing a larger general-purpose chip.

Recommended starting metrics at default text size:

```text
tagHorizontalPadding = 5–6 pt per side
tagVerticalPadding = 2–3 pt per side
interTagSpacing = 4 pt
strokeWidth = 0.75–1 pt
minimumTagHeight = measuredTextHeight + verticalPadding * 2
```

Rules:

- Do not use heavy 8–10 pt horizontal padding if it causes valid two-tag rows to collapse.
- Do not use icon-leading chips in this compact row unless a future design review explicitly approves it; icons consume the width needed for text tags.
- The fit target at default text size is that `[Fajr] [White Days]` renders together in the shared tag lane on standard supported iPhone widths.
- The fit target for three-tag rows is best effort, but `[Fajr]` plus one opportunity tag should remain more protected than a third overlapping opportunity tag.
- If a row still cannot fit after compact metrics, reduce from three tags to two before reducing from two tags to one.

### Text-only rule

For this forecast card, tags should be text-first and preferably text-only.

Do not rely on icons.

Do not make icons the dominant marker.

Existing `FastTagStyle.systemImage` may be useful elsewhere, but the compact forecast row should not become icon-heavy.

### Suggested visual prominence

Use two prominence levels:

#### Strong state tags

Used for:

- `[Quiet mode]`
- `[Ramadan]`
- `[Fasting]`
- `[Tahajjud]`

Treatment:

- slightly stronger fill
- slightly stronger stroke
- readable text
- still restrained

#### Opportunity tags

Used for:

- `[Ashura]`
- `[Arafah]`
- `[Dhul Hijjah]`
- `[White Days]`
- `[Shawwal 6]`

Treatment:

- quieter fill
- subtle stroke
- text remains readable

#### Fajr fallback tag

Used for:

- `[Fajr]`

Treatment:

- monochrome or near-monochrome
- visually calm
- not colored as if it were a special event

---

## 18. Tag text labels

Preferred visible labels:

| Meaning | Visible tag |
|---|---|
| ordinary Fajr fallback | `Fajr` |
| quiet mode | `Quiet mode` |
| Ramadan | `Ramadan` |
| fasting intended | `Fasting` |
| Tahajjud intended | `Tahajjud` |
| Qada makeup fast | `Qada` |
| Kaffarah expiation fast | `Kaffarah` |
| Vow / Nadhr fast | `Vow` |
| Arafah | `Arafah` |
| Ashura | `Ashura` |
| White Days | `White Days` |
| Monday/Thursday intended fast | `Mon/Thu` |
| First nine of Dhul Hijjah | `Dhul Hijjah` |
| Six of Shawwal | `Shawwal 6` |

Do not use long labels such as:

```text
Fasting opportunity
Voluntary Sunnah
First 9 of Dhul Hijjah
Monday/Thursday Fast
Qada Makeup Fast
```

in the compact row.

Longer labels belong in accessibility and detail.

---

## 19. Example row states

### Ordinary day

```text
Tomorrow        [Fajr]                  5:40 AM
```

### Ashura opportunity, not intended

```text
Sat, May 2      [Fajr] [Ashura]         5:39 AM
```

### Ashura fast intended

```text
Sat, May 2      [Fasting] [Ashura]      5:39 AM
```

### Arafah and Dhul Hijjah opportunity

```text
Thu, May 7      [Fajr] [Arafah] [Dhul Hijjah]  5:32 AM
```

### Arafah fast intended

```text
Thu, May 7      [Fasting] [Arafah] [Dhul Hijjah]  5:32 AM
```

### White Days opportunity

```text
Wed, May 6      [Fajr] [White Days]     5:33 AM
```

### White Days intended

```text
Wed, May 6      [Fasting] [White Days]  5:33 AM
```

### Monday/Thursday not intended

```text
Thu, May 7      [Fajr]                  5:32 AM
```

### Monday/Thursday intended

```text
Thu, May 7      [Fasting] [Mon/Thu]     5:32 AM
```

### Tahajjud intended

```text
Fri, May 8      [Tahajjud]              5:31 AM
```

### Tahajjud intended on Ashura opportunity, fast not intended

```text
Fri, May 8      [Tahajjud] [Ashura]     5:31 AM
```

### Qada intended

```text
Sun, May 10     [Fasting] [Qada]        5:28 AM
```

### Ramadan

```text
Sun, Mar 8      [Ramadan]               5:11 AM
```

### Quiet mode

```text
Tue, May 5      [Quiet mode]            5:35 AM
```

---

## 20. Row content forbidden combinations

Do not show:

```text
[Fajr] [Fasting]
[Fajr] [Tahajjud]
[Fajr] [Ramadan]
[Fajr] [Quiet mode]
[Fasting] [Ramadan]
[Quiet mode] [Fasting]
[Quiet mode] [Tahajjud]
[Quiet mode] [Ashura]
[Mon/Thu]
```

Exception for `[Mon/Thu]`:

```text
[Fasting] [Mon/Thu]
```

is allowed when the user intended the Monday/Thursday fast.

---

## 21. Data ownership

The renderer must not invent tags.

The renderer must not parse existing visible row text into tags.

The renderer must not infer observance compatibility on its own.

The renderer receives a resolved row display model from the presentation layer.

Recommended ownership:

```text
Schedule/domain layer
    resolves dates, wake times, contexts, intentions, quiet mode, completion progress

NextTenMorningsTagResolver
    converts resolved day state into compact forecast tags

NextTenMorningsPresentation
    prepares date label, tags, trailing time/status, accessibility text

NextTenMorningsRowView
    renders only the prepared display model
```

---

## 22. Recommended data contract

```swift
struct NextTenMorningsSnapshot: Equatable {
    let title: String                 // "NEXT 10 MORNINGS"
    let rows: [NextTenMorningsRowDisplay] // exactly 10 when ready
    let loadingState: LoadingState
    let generatedAt: Date
}
```

```swift
struct NextTenMorningsRowDisplay: Equatable, Identifiable {
    let id: String                    // dateKey
    let dateKey: String
    let date: Date
    let dateLabel: String             // Tomorrow, Sat, May 2
    let tags: [NextTenMorningsTagDisplay]
    let trailingTime: Date?
    let trailingStatusText: String?
    let isInactive: Bool
    let accessibilityLabel: String
}
```

```swift
struct NextTenMorningsTagDisplay: Equatable, Identifiable {
    let id: String
    let title: String                 // Fajr, Fasting, Ashura, etc.
    let semantic: NextTenMorningsTagSemantic
    let prominence: NextTenMorningsTagProminence
    let priority: Int
    let accessibilityText: String
}
```

```swift
enum NextTenMorningsTagSemantic: Equatable {
    case fajrFallback
    case quietMode
    case ramadan
    case fastingIntent
    case tahajjudIntent
    case qada
    case kaffarah
    case vow
    case observanceOpportunity(FastSecondaryVirtueTag)
    case observanceIntended(FastSecondaryVirtueTag)
}
```

```swift
enum NextTenMorningsTagProminence: Equatable {
    case strong
    case opportunity
    case fallback
}
```

---

## 23. Tag resolver input contract

Recommended resolver signature:

```swift
struct NextTenMorningsTagResolverInput {
    let date: Date
    let dateKey: String
    let activeDay: ActiveAlarmDay
    let resolvedContext: ResolvedDayContext
    let tagResult: TagComputationResult
    let fastIntentSelection: FastIntentSelection?
    let fastSuggestions: FastIntentSuggestions?
    let compatibleOpportunityTags: [FastSecondaryVirtueTag]
    let quietModeState: QuietModeState?
    let shawwalSixProgress: ShawwalSixProgressSummary?
    let hasDayOverride: Bool
}
```

The exact type names may differ, but these concepts must be available.

### Required inputs

- date
- date key
- wake time or wake state
- resolved day context
- primary fasting intent
- secondary observance tags
- whether the fast is intended vs merely suggested
- compatible date-derived opportunity tags
- quiet mode status
- Shawwal 6 completion progress
- day override flag

---

## 24. Tag resolver algorithm

Pseudo-logic:

```text
1. If quiet mode is active:
   return [Quiet mode]

2. If Ramadan applies:
   return [Ramadan]

3. Build intended fast tags:
   - If user has intended/planned a fast:
       start with [Fasting]
       add specific primary fast type when applicable:
           Qada, Kaffarah, Vow
       add compatible intended observance tags:
           Arafah, Ashura, Dhul Hijjah, White Days, Shawwal 6, Mon/Thu
       suppress Shawwal 6 if completed
       return capped tags

4. Build Tahajjud tags:
   - If Tahajjud is intended/planned:
       start with [Tahajjud]
       add compatible visible opportunity tags if any:
           Arafah, Ashura, Dhul Hijjah, White Days, Shawwal 6
       do not add Mon/Thu unless fast intended
       suppress Shawwal 6 if completed
       return capped tags

5. Build opportunity-only tags:
   - Get compatible opportunity tags from the fasting engine.
   - Remove Mon/Thu unless fast intended.
   - Remove Shawwal 6 if completed.
   - If any remain, return [Fajr] plus the opportunity tags, capped by priority.

6. Return [Fajr].
```

Important:

- `[Fajr]` is a fallback for ordinary days and an anchor for opportunity-only days.
- `[Fajr]` should not be manually added before evaluating quiet mode, Ramadan, fasting intention, or Tahajjud intention.
- Quiet mode and Ramadan short-circuit the resolver.

---

## 25. Date range rules

When expanded and ready, the card shows exactly ten upcoming mornings.

Default behavior:

- first row: next future morning, normally tomorrow
- rows 2–10: subsequent calendar mornings

The current home hero owns the immediate next wake / tomorrow detail emphasis. The 10-row forecast provides the upcoming run of mornings beneath it.

Rules:

- The expanded card should not silently show fewer than ten rows in the ready state unless data is unavailable.
- If prayer-time data is partial, show truthful rows only and use a loading/partial state.
- Do not include past mornings.
- Do not include completion history as visible row content.
- Completion history may affect tags, especially Shawwal 6 suppression.

---

## 26. Interaction rules

### Expand / collapse

The Home card appears collapsed by default.

Collapsed state:

- The `NEXT 10 MORNINGS` header remains visible.
- The rows are hidden.
- The user can tap the header, expansion affordance, or approved card control to expand.

Expanded state:

- All ten rows are visible when data is ready.
- The user can collapse the card back to the header-visible state.

Expansion/collapse is UI-only:

- no wake mode changes
- no intention changes
- no date-specific override changes
- no scheduling changes
- no alarm creation/cancellation

### Row tap

Tapping a row opens that morning’s detail view.

The tap target is the full row.

Tags are not individually tappable.

### No inline editing

Do not add inline controls to this card.

Do not add toggles, menus, drag handles, plus buttons, disclosure chips, or edit affordances inside rows.

Adjustments belong in the detail view or relevant planning surfaces.

### No horizontal scroll

The card is a simple vertical forecast list when expanded.

Do not introduce horizontal scrolling for tags.

If tags cannot fit, cap the visible tags and preserve the full set in accessibility/detail.

## 27. Accessibility requirements

Each row should expose one coherent accessibility label.

Recommended structure:

```text
{Date}. {Tag summary}. Wake at {time}. {Optional hidden explanation}. Double tap for details.
```

Examples:

```text
Tomorrow. Fajr morning. Wake at 5:40 AM. Double tap for details.
Saturday, May 2. Ashura fasting opportunity. Wake at 5:39 AM. Double tap for details.
Sunday, May 3. Fasting intended for Ashura. Wake at 5:37 AM. Double tap for details.
Monday, May 4. Tahajjud intended. Wake at 5:36 AM. Double tap for details.
Tuesday, May 5. Fasting intended as Qada. Wake at 5:35 AM. Double tap for details.
Wednesday, May 6. Ramadan morning. Wake at 5:33 AM. Double tap for details.
Thursday, May 7. Quiet mode. Wake time 5:32 AM. Double tap for details.
```

Accessibility may include information not visible in the row, such as:

- adjusted for this date
- latest wake cap applied
- fixed wake
- no wake anchor
- Fajr relation
- full observance list when visual tags are capped
- Shawwal 6 progress context

Visible rows must remain simple.

---

## 28. Dynamic type and responsive behavior

All visible text must scale:

- header
- date label
- tags
- wake time
- status text if present

When layout is constrained:

1. preserve wake time readability
2. preserve date label readability
3. apply compact tag-chip padding and compact inter-tag spacing
4. preserve protected two-tag opportunity pairs such as `[Fajr] [White Days]` at standard widths
5. reduce visible tag count from three to two when needed
6. preserve at least one meaningful tag only after compact two-tag fitting has failed
7. allow card height/row height to grow
8. do not wrap tags
9. do not shrink wake time into illegibility
10. do not reintroduce subtitle text

### Narrow width behavior

On narrow screens:

- show fewer tags before reducing time legibility
- cap tags at one or two when needed
- preserve `[Fasting]` over specific observance only if the intention itself is the most important message
- preserve `[Ramadan]`, `[Quiet mode]`, and `[Tahajjud]` as single-tag states

Potential narrow examples:

```text
[Fasting] [Ashura]       -> if possible
[Fasting]                -> if constrained
[Fajr] [Arafah] [Dhul Hijjah]   -> if possible
[Arafah]                 -> if constrained
```

---

## 29. Loading, partial, and empty states

### Loading

Use a calm skeleton with ten row placeholders or a preserved card height.

Do not show fake tags.

### Partial data

If some future mornings cannot be resolved:

- show resolved rows truthfully
- show unavailable rows with calm status only if necessary
- do not invent wake times
- do not invent tags

### Empty/error

If no forecast can be resolved:

```text
NEXT 10 MORNINGS
Wake forecast will appear once times are available.
```

This is an exceptional state, not a normal row pattern.

---

## 30. Current codebase migration guidance

### Existing areas likely involved

Current source areas likely relevant:

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

### Do not do this

Do not reuse the current visible `WakePagePresentation.row(...).subtitle` as the source of row meaning.

Do not split the subtitle string on `•` to create tags.

Do not use `scheduleChipTitles(...)` directly as the forecast tag model because it includes operational labels that are not appropriate for this surface.

### Recommended implementation direction

Create a dedicated display pipeline:

```text
WakeRowEntry
  -> NextTenMorningsPresentation.row(...)
  -> NextTenMorningsRowDisplay
  -> NextTenMorningsRowView
```

Create a dedicated tag resolver:

```text
ActiveAlarmDay + ResolvedDayContext + TagComputationResult + completion/quiet state
  -> NextTenMorningsTagResolver
  -> [NextTenMorningsTagDisplay]
```

### Reuse allowed

Reuse:

- `AppGlassSurface`
- `WakeGlassTheme`
- `DesignTokens`
- existing time lockup visual language
- existing fasting domain types
- existing tag compatibility logic
- existing row tap-to-detail navigation

Refactor private pieces only if needed to avoid duplication, for example extracting a reusable wake time lockup from `WakeRowComponents` if the existing lockup is private.

---

## 31. Testing requirements

Add or update tests for the display resolver.

### Header and collapsed-state tests

- collapsed Home state shows the `NEXT 10 MORNINGS` header
- collapsed Home state hides the ten rows
- expanding the card reveals exactly ten rows when ready
- collapsing the card hides rows without mutating wake state
- header title is `NEXT 10 MORNINGS`
- old title `10-Day Wake Forecast` is not visible
- subtitle `Next 10 mornings` is not visible as separate text

### Row content tests

- row display has date label
- row display has tags
- row display has trailing time/status
- tag cluster horizontal centerline aligns across all ten rows
- tag cluster is centered from shared lane geometry, not row-specific spacers
- `[Fajr] [White Days]` fits at default text size without collapsing because of excessive chip padding
- short date labels do not pull tags left
- long date labels do not push tags right
- wider trailing times/statuses are handled by shared time lane measurement
- date label, tag cluster, and wake time/status are vertically centered between row dividers
- row height remains consistent across Fajr, Pre-Fajr, Ramadan, fasting, Tahajjud, and Quiet rows for a given text-size profile
- Quiet mode does not shrink the row height
- row display has no visible subtitle
- relation text is not visible
- adjustment text is not visible

### Tag tests

- ordinary day returns `[Fajr]`
- Ramadan returns `[Ramadan]` only
- quiet mode returns `[Quiet mode]` only
- intended Ashura fast returns `[Fasting] [Ashura]`
- Ashura opportunity without intention returns `[Fajr] [Ashura]`
- intended Qada returns `[Fasting] [Qada]`
- intended Tahajjud returns `[Tahajjud]`
- intended Tahajjud on Ashura opportunity can return `[Tahajjud] [Ashura]`
- Monday/Thursday opportunity without intention returns `[Fajr]` unless another visible opportunity applies
- intended Monday/Thursday fast returns `[Fasting] [Mon/Thu]`
- White Days opportunity returns `[Fajr] [White Days]`
- intended White Days returns `[Fasting] [White Days]`
- Shawwal 6 opportunity returns `[Fajr] [Shawwal 6]` when remaining
- Shawwal 6 is suppressed after six intended Shawwal fasts are completed
- Shawwal 6 completion count ignores Qada/Kaffarah/Vow/Ramadan/generic fasts unless explicitly intended as Shawwal 6
- compatible overlaps can produce multiple tags
- incompatible/suppressed tags are not shown
- tag cap is respected
- full tag list remains available for accessibility/detail when capped

### Accessibility tests

- accessibility label includes date
- accessibility label includes tag meanings
- accessibility label includes wake time/status
- accessibility label includes full tag detail if visual tags are capped
- accessibility includes hidden adjustment/relation information where useful

### Visual snapshot tests, if available

- default ten-row card
- card with mixed opportunity/intended tags
- `[Fajr] [White Days]` visible together in the centered tag lane
- row with one tag, two tags, and three tags all sharing the same tag-lane centerline
- row date, tags, and wake time/status vertically centered between dividers
- Ramadan row
- quiet mode row
- accessibility dynamic type size
- narrow width tag capping

---

## 32. Locked requirements

These should not change without design review:

1. Visible header is `NEXT 10 MORNINGS`.
2. Do not show `10-DAY WAKE FORECAST`.
3. Do not show a second header subtitle.
4. The card is collapsed by default on Home with the `NEXT 10 MORNINGS` header visible.
5. The expanded card shows ten upcoming mornings in the ready state.
6. Each row has only date, tags, and wake time/status.
7. Rows do not show visible subtitles.
8. Rows do not show bullet-separated explanatory text.
9. Tags are not individually tappable.
10. The row remains the tap target for detail navigation.
11. Divider styling matches the Weekly Fajrcast subtle divider line.
12. Tags are centered in a shared middle lane that aligns across all ten rows.
13. Expanded rows use a consistent state-invariant row height for the same Dynamic Type profile.
14. Quiet mode rows do not become shorter than non-Quiet rows.
15. `[Fajr]` is an anchor/fallback tag for ordinary and opportunity-only Fajr-based mornings.
16. `[Fajr]` does not appear with `[Fasting]`.
17. `[Fajr]` does not appear with `[Tahajjud]`.
18. `[Fajr]` does not appear with `[Ramadan]`.
19. `[Fajr]` does not appear with `[Quiet mode]`.
20. Ramadan shows `[Ramadan]` only.
21. Quiet mode shows `[Quiet mode]` only.
22. `[Fasting]` appears only when the user intended/planned a fast.
23. Opportunity-only days show `[Fajr]` plus the observance tag without `[Fasting]`.
24. Monday/Thursday does not show as an opportunity-only tag.
25. Monday/Thursday can show only as `[Fasting] [Mon/Thu]` when intended.
26. White Days can show as an opportunity.
27. Shawwal 6 is completion-aware.
28. Shawwal 6 completion counts only intended Shawwal 6 fasts.
29. Compatible opportunity overlaps may show together.
30. The row renderer must not recreate fiqh compatibility logic.
31. The row renderer must not invent tags.
32. The tag resolver must not parse visible strings to infer tags.
33. Tags are capped and do not wrap.
34. Tag chips use compact padding; excessive capsule padding must not cause valid two-tag rows to collapse.
35. `[Fajr] [White Days]` and other `[Fajr]` plus single-opportunity pairs are protected fit targets at standard row width and standard dynamic type sizes.
36. Date label, tag cluster, and wake time/status are vertically centered between each row's upper and lower dividers.
37. The row’s outer layout must not rely on first-baseline alignment for the three main row elements.
38. Accessibility preserves the full meaning hidden from the compact row.

---

## 33. Recreation checklist

### Card shell

- [ ] Uses dark grouped glass card.
- [ ] Rounded continuous corners match current visual direction.
- [ ] Content padding is handled internally, not by a List.
- [ ] Header and row dividers use the same subtle line style.

### Header

- [ ] Header reads `NEXT 10 MORNINGS`.
- [ ] Old title is removed.
- [ ] Old subtitle is removed.
- [ ] Header uses eyebrow styling.

### Rows

- [ ] Card is collapsed by default on Home with the header visible.
- [ ] Expanded card renders exactly ten rows in ready state.
- [ ] First row normally starts with `Tomorrow`.
- [ ] Date labels are Gregorian-first.
- [ ] Ramadan appears as a tag, not as a date-label replacement.
- [ ] No visible subtitle appears.
- [ ] No timing relation prose appears.
- [ ] No adjustment/provenance prose appears.
- [ ] Time lockup remains large and right-aligned.
- [ ] Tags sit centered between the shared date lane and shared time lane.
- [ ] Tag cluster horizontal centerline aligns across all ten rows.
- [ ] Tags are centered from shared lane geometry, not row-specific spacers.
- [ ] Shorter or longer date labels do not create row-specific tag drift.
- [ ] Date label, tag cluster, and wake time/status are vertically centered between row dividers.
- [ ] Row height is consistent across all row states at the same Dynamic Type profile.
- [ ] Quiet mode rows do not become shorter than non-Quiet rows.
- [ ] Tags use compact chip padding.
- [ ] `[Fajr] [White Days]` remains visible together at default size.
- [ ] Tags do not wrap.

### Tags

- [ ] Ordinary day shows `[Fajr]`.
- [ ] Ramadan shows `[Ramadan]` only.
- [ ] Quiet mode shows `[Quiet mode]` only.
- [ ] Intended fast shows `[Fasting]`.
- [ ] Intended specific fast shows `[Fasting]` plus specific tag.
- [ ] Opportunity-only day shows `[Fajr]` plus the observance tag.
- [ ] Monday/Thursday opportunity is suppressed unless intended.
- [ ] White Days opportunity is allowed.
- [ ] Shawwal 6 is suppressed after six intended Shawwal fasts are completed.
- [ ] Compatible overlaps are respected.
- [ ] Tag cap is respected.
- [ ] Full meaning remains in accessibility/detail.

### Accessibility

- [ ] Row accessibility label includes date.
- [ ] Row accessibility label includes tag summary.
- [ ] Row accessibility label includes wake time/status.
- [ ] Row accessibility label includes hidden details where useful.
- [ ] Dynamic type does not clip date, tags, or time.

---

## 34. Remaining open items

### Quiet mode pipeline

Quiet mode is not yet fully implemented. This spec locks the visual behavior:

```text
[Quiet mode]
```

as the only visible tag.

The implementation still needs to decide whether quiet mode preserves a displayed wake time or replaces it with a concise trailing status when no wake anchor exists.

### Shawwal 6 completion source

The completion/progress layer must provide a reliable count of completed **intended Shawwal 6** fasts.

This should not be approximated by counting any fast completed during Shawwal.

### Tag capping at extreme dynamic type sizes

At accessibility sizes, the exact cap may need to reduce from three visible tags to two or one depending on device width. The priority order in this spec should determine which tags remain visible.

However, at standard dynamic type sizes and standard supported widths, the implementation should first use compact chip padding and the shared centered tag lane before dropping a valid two-tag pair such as `[Fajr] [White Days]`.

---

## 35. Final design intent

The Next 10 Mornings card should feel like a calm, premium wake forecast for Fajr-centered life.

It should not feel like a dense schedule table, an analytics list, or a debugging readout.

At a glance, the user should understand:

- what morning is coming
- when they will wake
- what kind of morning it is

The row should never try to explain every rule in the scheduling engine.

The strongest version of the card is restrained:

```text
Tomorrow        [Fajr]                  5:40 AM
Sat, May 2      [Fajr] [Ashura]         5:39 AM
Sun, May 3      [Fasting] [Ashura]      5:37 AM
Mon, May 4      [Tahajjud]              5:36 AM
Tue, May 5      [Fajr] [White Days]     5:35 AM
Wed, May 6      [Fasting] [Qada]        5:33 AM
Thu, May 7      [Ramadan]               5:32 AM
```

This gives the user the essence of the next ten mornings without clutter: date, meaning, wake time.
