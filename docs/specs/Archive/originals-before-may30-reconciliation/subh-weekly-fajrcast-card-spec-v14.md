# Weekly Fajrcast Card Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-weekly-fajrcast-card-spec-v14.md` |
| Version | 14 |
| Spec status | Product / implementation direction; canonical Desktop working spec |
| Supersedes | `subh-weekly-fajrcast-card-spec-v13.md` |
| Related specs | `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-fajr-time-calculation-determination-selection-spec-v1.md`, `subh-morning-hero-item-spec-v15.md`, `subh-next-7-mornings-wake-forecast-spec-v2.md` |
| Owning domain / surface | Home / Weekly Fajrcast card |
| Implementation audit status | Needs implementation audit |

## Purpose
Define the weekly Fajrcast card as a compact, truthful supporting view of resolved Fajr-window movement and wake context across the same upcoming seven days shown by Next 7 Mornings.

## What This Spec Owns
- Weekly chart geometry, interaction, labels, and accessibility.
- Selected-day, forecast-start-day, and snap-back behavior.
- Visual/copy rules for compact Fajr-window trend support.

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


## May 29 Weekly Fajrcast Quiet / Pause Alignment Addendum

This May 29 alignment is normative for MVP and supersedes conflicting lower/historical wording in this file.

- `Fajr` and `Suhoor` are the only exposed MVP wake purposes.
- `Quiet` is a one-morning alarm/sound override, not a wake purpose.
- `Pause` is an indefinite app-wide wake-alarm policy, not a wake purpose.
- User-facing MVP copy must not expose `Pre-Fajr`, `Early`, `Fast mode`, `Fasting mode`, `Quiet mode`, or `Pause mode` as visible wake purposes.
- Internal/code terms may remain where required for compatibility, but visible surfaces must use `Fajr`, `Suhoor`, `Quiet`, `Alarms paused`, `Time to wake`, `I’m awake`, `I’m fasting today`, and `I prayed Fajr` according to `subh-quiet-pause-hero-wake-flow-alignment-spec-v1.md`.

Weekly Fajrcast must consume resolved snapshots and must not infer, schedule, cancel, or mutate Quiet/Pause state.

If alarm state appears on the chart/card, use the same status vocabulary as Next 7:

```text
Quiet
Paused
Rings once
Turn on alarms
Alarm issue
```

Do not show `Quiet mode`, `Pause mode`, `Pre-Fajr`, `Early`, or `Fast mode` in visible chart copy.

## MVP Suhoor Alignment Addendum
This addendum is normative for MVP and supersedes conflicting lower sections in this file.

- Weekly Fajrcast consumes the resolved morning state; it does not create a separate before-Fajr interpretation.
- The MVP before-Fajr wake state is `Suhoor`.
- `Tahajjud only`, `Other early worship`, and generic `Pre-Fajr` states are deferred and must not appear as active MVP chart context labels.
- Opportunity-only fasting dates may be surfaced as supporting context when this card's tag doctrine allows it, but they must not imply a planned Suhoor wake unless the resolved morning has Suhoor/fasting intent.

## v14 Next 7 Mornings Alignment Addendum

This addendum is normative for v14 and supersedes any lower v13 language that centers the chart around a mixed prior/current/future window.

- Weekly Fajrcast now shows the same seven upcoming dates as the `Next 7 Mornings` forecast card.
- The first visible column is the next immediate alarm or next relevant morning supplied by the canonical resolver.
- The remaining six columns are the six following calendar mornings.
- The chart must not include previous mornings in this aligned MVP behavior.
- `visibleDateKeys` must match the `Next 7 Mornings` card exactly and in the same order.
- The resting focus and snap-back target normally equal the first visible day.
- User touch interaction remains temporary inspection within the seven visible days; it does not mutate wake state and does not load an eighth day.
- The chart remains a fixed seven-column view during interaction. The user's phrase “scroll the upcoming week” is implemented as scrubbing/inspecting across the visible upcoming week unless a later spec deliberately introduces horizontal week paging.

## 1. Scope

This specification defines the **Weekly Fajrcast card** as a standalone product, UX, visual, data, interaction, and accessibility component.

It intentionally does **not** depend on any legacy navigation model, host screen, adjacent card, analytics view, or app structure. A designer or engineer should be able to recreate the card from this document alone.

## 2. One-sentence definition

**Weekly Fajrcast is a dark, glass-style seven-day card that starts with the next immediate alarm or next relevant morning, then shows the following six mornings, with a fixed Gregorian week pill, top weekday labels, a plotted Fajr window, and a bottom callout that lets the user temporarily inspect the upcoming week without moving the chart; when touch inspection ends, the card snaps back to the first visible next-alarm / next-relevant focus.**

The card helps the user understand:

- when Fajr begins for each visible morning
- when Fajr ends for each visible morning
- whether an alarm, off-state, quiet state, or no-alarm state exists for a visible morning
- how the inspected morning relates to Fajr while the user is touching or scrubbing
- what the next-alarm/resting morning is when the user is not interacting
- how Fajr begins shifts across the visible week in plain language
- whether the visible week has a qualifying special non-Ramadan Sunnah fasting opportunity worth surfacing

## 3. Naming

Visible card title:

```text
WEEKLY FAJRCAST
```

User-facing card name:

```text
Weekly Fajrcast
```

The title must not be replaced by generic labels such as `Forecast`, `Weekly Chart`, or `Fajr Times` unless the product naming system changes deliberately.

## 4. Core mental model

> **The band is the Fajr window. Markers are alarms or planned wake states. The chart window is the upcoming week. Touch temporarily inspects a visible day. Release returns the card to the first visible next alarm / next relevant morning.**

This creates three separate concepts:

- **Forecast start day:** the first visible date. It is the next immediate alarm or next relevant morning supplied by the data layer.
- **Resting focus / snap-back target:** the date shown when no chart gesture is active. This is normally the first visible next active alarm or next relevant morning supplied by the data layer.
- **Inspection focus:** the visible date currently under the user’s finger, tap, drag, scrub, or accessible inspection action.

At rest, the focused day equals the resting focus, normally the first visible day. During an active touch/scrub, the focused day temporarily becomes the inspection focus. When the touch ends, the guide, emphasized marker, bottom callout, header date pill, and accessibility value return to the resting focus / snap-back target.

The chart does not move, pan, scroll, or recenter during this process. The visible date columns, Fajr band, y-axis scale, top x-axis labels, and optional elapsed overlay remain fixed while only the temporary focus presentation changes.

The header pill has one intentional exception: at rest it shows the visible seven-day Gregorian range, but during active touch/scrub it temporarily shows the currently inspected day’s single Gregorian date. When the gesture ends and focus snaps back, the pill returns to the visible seven-day Gregorian range.

The footer is no longer a focused-day Fajr-time readout. In v14 it is a visible-week-level trend and context summary. It explains how Fajr begins shifts across the visible week and, only when applicable, surfaces qualifying special non-Ramadan Sunnah fasting opportunities. It must not summarize the weekly alarm plan or repeat the focused-day alarm relation.

## 5. Seven-day window rules

The chart always renders exactly seven day columns:

1. forecast start day
2. forecast start day plus 1
3. forecast start day plus 2
4. forecast start day plus 3
5. forecast start day plus 4
6. forecast start day plus 5
7. forecast start day plus 6

The forecast start day is always the first column. The chart must not center the next alarm by including previous mornings.

### Default forecast start day and snap-back target

On first load, choose the next immediate alarm or next relevant morning:

- If today’s relevant wake/alarm moment is still upcoming, the forecast start day may be today.
- If today’s relevant wake/alarm moment has passed, the forecast start day is normally tomorrow.
- If the next relevant morning has no active alarm, it may still be the forecast start day; the card must show the correct no-alarm/off/quiet state rather than skipping the date.

The resting focus and snap-back target should normally be the same as the forecast start day. If the data layer intentionally supplies a different `snapBackTargetDateKey`, it must still be one of the seven visible dates and must represent the next alarm or next relevant morning. The renderer must not search outside the supplied snapshot to choose a different snap-back date.

### Alignment with Next 7 Mornings

Weekly Fajrcast and Next 7 Mornings must use the same visible date set:

```text
visibleDateKeys = forecastStartDateKey through forecastStartDateKey + 6 days
```

Rules:

- The two surfaces must agree on the first visible date.
- The two surfaces must agree on all six following dates.
- The two surfaces must keep the same order.
- A date shown in the forecast list should be inspectable in the chart.
- A date shown in the chart should have a corresponding forecast row when the Next 7 Mornings card is expanded.

### Visible-window immutability during card interaction

A tap, press, drag, or scrub inside the card may temporarily change the inspection focus, but it must not change the seven visible dates.

The visible dates change only when the card receives a new resolved snapshot, such as after a day rollover, a location/settings recalculation, or an explicit external request to rebuild the upcoming week around a different forecast start day.

## 6. Scrubbing and selection behavior

### What the user can do

The user can inspect any of the seven visible mornings by:

- tapping a day column
- pressing a day column
- dragging left or right across the chart
- scrubbing continuously across the chart
- using accessible increment/decrement actions where supported

### What scrubbing means

Scrubbing is **temporary focus movement inside the existing seven-day chart**. It is not horizontal chart scrolling and it is not persistent date selection.

During active scrub:

- the chart remains fixed to the same seven upcoming dates
- the header pill temporarily changes from the seven-day Gregorian range to the touched/focused day’s single Gregorian date
- the top x-axis weekday labels remain unchanged
- the Fajr band remains unchanged
- the y-axis scale remains unchanged
- the static past/elapsed overlay remains unchanged
- the focused guide moves to the touched day column
- the emphasized marker updates to the touched/focused day when that day has a marker
- the bottom callout updates to the touched/focused day
- the footer remains the visible-week-level context summary and does not chase the user’s finger
- the screen reader value updates to the touched/focused day and must use correct tense for in-progress and future Fajr windows, and any elapsed same-day state

The visible footer no longer needs past-tense rewrites during scrub because it no longer displays focused-day Fajr begin/end sentences. Past/future tense is still required for accessibility summaries, detail payloads, and any non-visible focused-day strings supplied by the data layer.

### Release / snap-back behavior

When the user lifts their finger or otherwise ends the chart gesture, the card must snap back to the next-alarm/resting focus.

On release:

- `focusedDateKey` returns to `snapBackTargetDateKey`
- the focused guide returns to the snap-back target column, normally the first column
- the bottom callout returns to the snap-back target
- marker emphasis returns to the snap-back target, if that target has a marker
- the header pill returns from focused single-date text to the visible seven-day range text
- the static past/elapsed overlay, if supplied, does not change
- the footer remains the same visible-week-level context summary unless the underlying snapshot changes
- the chart still does not pan, scroll, recenter, or load more dates

The snap-back should feel calm and intentional. Use a subtle ease or fade/position transition. It should not feel like the chart is being horizontally scrolled back; only the focus presentation returns.

If the snap-back target has no active alarm, no planned wake anchor, or a quiet/no-alarm state, the card still snaps back to that date and displays the truthful no-alarm/off/quiet state. The renderer must not choose another date just to find a marker.

### Tap behavior

A chart tap is treated as a short inspection gesture. It may briefly show the tapped day’s guide, marker emphasis, bottom callout, header pill date text, and accessibility value, but after the touch ends it returns to the snap-back target. A tap on a day column should not permanently move the resting focus.

### Edge limits

The user can scrub only within the seven visible columns. If the touch moves beyond the left or right chart edge, inspection focus clamps to the first or last visible day. The card must not advance to an eighth day, load another week, or animate the chart sideways.

### Tap versus detail opening

A chart tap inspects the tapped day. It should not immediately open a detail screen.

If the card later supports opening a detailed experience, that action must be separate from active chart inspection. Any gesture that begins as a chart scrub must suppress accidental navigation.

The exact detail destination and route/event name remain an open item for the next iteration.

## 7. Card anatomy

The card contains five primary regions:

1. Liquid Glass outer shell
2. header row
3. top divider
4. chart region
5. bottom divider and footer region

The header contains:

- fixed title: `WEEKLY FAJRCAST`
- dynamic Gregorian date pill that shows the visible seven-day range at rest and the inspected single date during active scrub

The chart region contains, from top to bottom:

- top x-axis weekday labels
- seven day columns
- Fajr interval band
- Fajr begin boundary line
- Fajr end boundary line
- in-chart `Fajr begins` and `Fajr ends` labels near the left/start side of the plot
- focused-day vertical guide
- alarm/off/no-marker states
- right-side y-axis labels
- bottom focused-day callout

The footer contains:

- a compact week-level Fajr trend line when available
- an optional qualifying special non-Ramadan Sunnah fasting opportunity line when useful

The footer must not duplicate the focused-day alarm time, focused-day alarm offset, weekly alarm-plan summary, or exact focused-day Fajr begin/end sentence in v14.

## 8. Visual shell and dynamic sizing

### Liquid Glass direction

The card should feel dark, premium, calm, translucent, and restrained.

Recommended direction:

- dark neutral glass base
- subtle translucency or material blur where supported
- low-opacity edge highlight or border
- rounded corners, visually around 20–28 px/pt
- mostly monochrome foreground elements
- no heavy opaque black panel
- no loud analytics-dashboard styling

### Contrast hierarchy

High contrast is reserved for:

- focused alarm/off marker when present
- focused-day callout
- header date pill text
- all visible footer text

Quiet elements include:

- grid lines
- dividers
- Fajr band fill
- Fajr boundary lines
- non-focused markers
- static past/elapsed overlay

The in-chart `Fajr begins` and `Fajr ends` labels should be readable but still quieter than the focused marker and callout.

### Dynamic sizing decision

Use a **dynamic measured layout**, not a fully hardcoded layout for every text-size stop.

The renderer should derive typography from platform-native dynamic text metrics, then measure the resulting header, fixed-width Gregorian pill, chart labels, bottom callout, in-chart Fajr labels, and footer. The seven-stop table below is a set of minimum layout guardrails, not a maximum and not a substitute for measuring real text.

In practical terms:

- font sizes scale from the base tokens in this spec
- line heights come from the actual scaled font metrics
- the card height is `max(stopMinimumHeight, measuredContentHeight)`
- the chart region height is `max(stopMinimumChartRegionHeight, measuredChartRegionHeight)`
- the plot scale height is a stable minimum defined below, not a tiny height that changes from stop to stop
- the y-axis rail width is `max(stopMinimumRailWidth, measuredWidestTickLabel + railPadding)`
- the header pill width is measured from the maximum possible Gregorian range/date string for the current locale and text size, not from the current week’s shorter text
- the footer may wrap; wrapping increases card height
- no essential text may be clipped to preserve a compact height

### Tuned chart plot-height rule

Use the current tuned target. Do not change it as part of this footer/content refinement.

Use this locked plot-height model:

```text
staticPlotScaleHeight = 128 px/pt minimum
```

Meaning:

- `staticPlotScaleHeight` is the vertical distance used by the plotted y-axis scale between the top and bottom plot boundaries.
- It is the same minimum at all seven standard iPhone text-size stops.
- It is sized so the largest standard text-size stop can still make the y-axis labels feel comfortable without making the graph feel oversized.
- Text-size changes should alter measured text, rail width, footer wrapping, top x-axis label spacing, bottom callout spacing, footer breathing room, and overall card height; they should not make the plotted y-axis scale line shrink or jump between stops.
- For accessibility sizes beyond the standard seven stops, preserve at least this height and grow only if required for legibility. Never reduce it to regain compactness.

### Seven-stop iPhone text-size guardrails

Map the device/app text setting to seven non-accessibility stops. The exact native scaling curve may differ by platform; these values define the intended layout behavior.

| Text stop | Typical meaning | Approx text scale from base | Min card height | Min chart region height | Static plot scale height | Min y-axis rail width |
|---:|---|---:|---:|---:|---:|---:|
| 1 | smallest | 0.88× | 266 | 184 | 128 | 40 |
| 2 | small | 0.94× | 268 | 184 | 128 | 42 |
| 3 | medium | 0.98× | 270 | 186 | 128 | 44 |
| 4 | default | 1.00× | 272 | 188 | 128 | 46 |
| 5 | large | 1.08× | 284 | 194 | 128 | 52 |
| 6 | extra large | 1.17× | 296 | 202 | 128 | 58 |
| 7 | largest | 1.28× | 310 | 210 | 128 | 64 |

Rules for this table:

- Stop 4 is the design baseline for the typography sizes listed elsewhere in this document.
- Lower stops may reduce text slightly through native scaling, but the card should not look cramped or miniature.
- Higher stops must increase layout space, especially the footer, bottom callout, top x-axis labels, chart region, and y-axis rail.
- The plotted y-axis scale height remains at least 128 at every stop.
- If the platform exposes accessibility text sizes beyond these seven stops, continue the same measured-growth model beyond Stop 7.
- If measured content exceeds the table minimum, measured content wins.

### Base typography tokens at Stop 4

Use these base sizes before platform scaling:

| Element | Base size | Weight / behavior |
|---|---:|---|
| Header title | 12 | regular, uppercase |
| Gregorian date pill | 12 | regular, full month names, single line if possible |
| X-axis weekday labels | 13 | medium |
| Y-axis time labels | 13 | medium, monospaced digits where possible |
| In-chart Fajr boundary labels | 13 minimum | medium or regular; never smaller than x-axis/y-axis labels |
| Focused callout label | 13 | medium |
| Focused callout time | 18 | bold, monospaced digits where possible |
| Focused callout suffix | 11 | regular, monospaced digits where possible |
| Footer primary | 13 | regular, 100% opacity |
| Footer secondary | 13 | regular, 100% opacity; same size and opacity as primary |

### Layout measurement rules

The card is a vertical stack:

1. outer padding
2. header row
3. top divider
4. chart region
5. bottom divider
6. footer region
7. outer padding

Required behavior:

- Header height is at least the scaled Gregorian pill height.
- The Gregorian pill height is at least `scaledLineHeight + 8`.
- The chart region includes the top x-axis label row, the x-axis-to-plot gap, the static plot scale area, the plot-to-bottom-callout gap, the focused callout block, and the breathing space above the footer divider.
- The plot scale area must remain visually meaningful and must not be compressed to absorb larger text.
- The y-axis rail expands leftward as labels grow while the label right edge stays aligned to the chart/content boundary.
- Footer primary may wrap at natural word boundaries.
- Footer secondary is optional; if present, it may wrap or shorten before the primary line truncates. Do not reserve a blank second-line row when no secondary text is shown.
- The footer must not truncate the weekly Fajr trend delta, annual-extreme wording, or qualifying special fasting observance name/date phrase if avoidable.

### Top x-axis label spacing rule

The x-axis weekday labels now sit **above** the plot. They replace the old top callout position.

Required behavior:

- The x-axis labels sit below the top divider and above the top plot boundary.
- At Stop 4, keep about **8 px/pt** between the top divider and the x-axis label line box.
- At smaller stops, keep at least **6 px/pt** between the top divider and the x-axis label line box.
- At Stops 5–7, keep at least **9 px/pt**, or more only if scaled font metrics require it.
- For accessibility sizes beyond the seven standard stops, use `max(9 px/pt, 0.45 × scaledXAxisLineHeight)`.
- This spacing should feel balanced with the bottom callout-to-divider spacing.
- The labels must not appear glued to the top divider, but this should remain a compact chart label row, not a large blank header-like section.

### X-axis-to-plot spacing rule

The top x-axis weekday labels must not sit directly against the upper plot boundary.

Required behavior:

- At Stop 4, keep about **4 px/pt** between the bottom of the x-axis label line box and the top plot boundary.
- At smaller stops, keep at least **3 px/pt**.
- At Stops 5–7, keep at least **5 px/pt**, or more only if scaled font metrics require it.
- For accessibility sizes beyond the seven standard stops, use `max(5 px/pt, 0.25 × scaledXAxisLineHeight)`.
- This is a minimal separation, not a large new section.
- If labels are positioned by baseline rather than line box, ensure the visible glyphs do not touch or visually merge with the upper plot boundary.

### Plot-to-bottom-callout spacing rule

The focused-day callout now sits **below** the plot. Its contents and typography stay the same as before; only the vertical position changes.

Required behavior:

- Treat the callout as a measured block containing the relative label and wake/status time.
- At Stop 4, keep about **5 px/pt** between the bottom plot boundary and the top of the callout block.
- At smaller stops, keep at least **4 px/pt**.
- At Stops 5–7, keep at least **6 px/pt**, or more only if scaled font metrics require it.
- For accessibility sizes beyond the seven standard stops, use `max(6 px/pt, 0.28 × scaledCalloutLineHeight)`.
- The callout must not look glued to the plot, but it should remain visually connected to the focused guide and marker.
- The callout must align horizontally to the focused day column, just as it did before the vertical swap.

### Bottom callout-to-footer-divider spacing rule

The bottom focused-day callout must sit geometrically centered between the lower plot boundary and the bottom divider/footer boundary. This is an implementation rule, not only visual guidance: the gap above the callout and the gap below the callout should be equal after measuring the actual scaled callout block.

Required behavior:

- Treat the full callout as one measured block, including the relative label, wake/status time, meridiem suffix, internal line gap, and scaled font line boxes.
- Compute the callout position from both boundaries rather than using only a fixed offset below the plot.
- At Stop 4, the target top gap and bottom gap are both about **5 px/pt**.
- At smaller stops, each gap should be at least **4 px/pt**.
- At Stops 5–7, each gap should be at least **6 px/pt**, or more only if scaled font metrics require it.
- For accessibility sizes beyond the seven standard stops, use `max(6 px/pt, 0.28 × scaledCalloutLineHeight)` for each side.
- The footer divider may shift upward by a few pixels to close an oversized lower gap; do not compensate by adding unused blank space back into the chart region.
- If more space is needed, grow the card height before compressing the plot or overlapping the callout.

Implementation geometry:

```text
plotBottomY = rendered lower boundary of the plot scale area
footerDividerY = rendered top boundary line of the footer
calloutBlockHeight = measured height of the full focused-day callout block
interstitialHeight = footerDividerY - plotBottomY

calloutTopY = plotBottomY + ((interstitialHeight - calloutBlockHeight) / 2)
calloutBottomY = calloutTopY + calloutBlockHeight

topGap = calloutTopY - plotBottomY
bottomGap = footerDividerY - calloutBottomY
```

Acceptance target:

- `topGap` and `bottomGap` should match within **1 px/pt** at Stop 4 after pixel snapping.
- At larger text sizes, they should match within **2 px/pt** if native font metrics or pixel rounding make exact equality impossible.
- If the calculated gaps fall below the minimums above, increase the interstitial space or card height; do not push the callout upward and leave a large lower pocket.
- The callout must not appear visually biased toward the chart or toward the footer divider.

### Footer bottom breathing-space rule

Add a deliberately larger amount of intentional space below the final visible footer line so the last line does not feel tight against the card's lower inner edge.

Required behavior:

- The final visible footer line is the primary trend line when no secondary line is present, and the secondary fasting-opportunity line when an optional secondary line is present.
- At Stop 4, keep about **20 px/pt** between the final footer line box and the card's lower inner padding edge.
- At smaller stops, keep at least **16 px/pt**.
- At Stops 5–7, keep at least **22 px/pt**, or more if scaled font metrics require it.
- For accessibility sizes beyond the seven standard stops, use `max(22 px/pt, 0.75 × scaledFooterLineHeight)`.
- This bottom breathing space is separate from the bottom callout-to-footer-divider spacing above the footer. Do not steal space from the chart-to-footer gap to create it.
- If the optional secondary line is absent, do not leave a blank second-line slot; apply the bottom breathing space directly below the primary trend line.
- This larger lower inset is intentional and may make the card slightly taller; do not remove it by compressing the chart or reducing text size.

### Preferred overflow handling

When space is tight, adapt in this order:

1. grow card height
2. widen the y-axis rail leftward while keeping its right edge fixed
3. preserve the static plot scale height
4. preserve top divider-to-x-axis spacing
5. preserve the small x-axis-to-plot gap
6. preserve the plot-to-bottom-callout gap
7. preserve the geometric bottom callout-to-footer-divider centering
8. preserve the enlarged footer-bottom breathing space below the final visible footer line
9. allow footer primary to wrap
10. allow footer secondary to wrap or shorten
11. omit footer secondary if it cannot fit without harming the primary line
12. if the fixed-width full-month Gregorian pill cannot fit on a narrow device, use a deliberate global compact fallback for the pill rather than resizing it per week
13. truncate only non-essential decorative or secondary wording

Do not solve layout pressure by freezing text at a small size, shrinking the chart plot into a cramped strip, placing the top x-axis labels against the upper plot boundary, placing the bottom callout against the lower plot boundary, or creating an unbalanced gap between the bottom callout and footer divider.

## 9. Header requirements

### Title

The header title is fixed:

```text
WEEKLY FAJRCAST
```

Recommended default style:

- all caps
- 12 pt/sp/px equivalent base size
- regular weight
- white at approximately 50% opacity
- single line

The title must scale with user text-size settings. It should remain recognizable but visually secondary to the header date pill and chart content.

### Header date pill

The header date pill is now **Gregorian-only**. Do not display lunar or secondary-calendar text in this compact pill.

The pill has two modes:

1. **Resting range mode** — when no chart gesture is active, the pill describes the anchored seven visible Gregorian dates.
2. **Active inspection date mode** — while the user is touching, pressing, dragging, or scrubbing on the chart, the pill describes the currently inspected/focused Gregorian date only.

The pill container remains in the same top-right position in both modes. The content changes; the chart does not move.

### Resting range mode

Preferred format:

```text
FullMonth startDay–endDay
FullMonth startDay–FullMonth endDay
```

Examples:

```text
April 26–30
April 26–May 2
September 30–October 6
```

Gregorian range formatting:

- same month: `April 26–30`
- crossing months: `April 26–May 2`
- crossing years: still omit the year in the compact pill unless the wider product explicitly introduces year display
- use full English month names in English locales: January, February, March, April, May, June, July, August, September, October, November, December
- in localized builds, use the locale’s full month names unless a deliberate global compact fallback is required for narrow width

### Active inspection date mode

While an active chart touch/scrub is in progress, replace the range text with the inspected day’s single Gregorian date.

Format:

```text
FullMonth day
```

Examples:

```text
April 29
May 2
September 30
```

Rules:

- The displayed date must be the currently inspected/focused day, not the forecast start day unless the forecast start day is also under inspection.
- Scrubbing forward updates the pill to the forward inspected day.
- Scrubbing backward updates the pill to the previous inspected day.
- Holding on a day keeps that day’s single-date text visible.
- The pill should update responsively with the same focus changes that update the guide, marker emphasis, bottom callout, and accessibility value.
- On gesture release, after the focus snaps back to the snap-back target, the pill returns to resting range mode.

### Fixed-width pill rule

The pill should not visibly resize when the week changes or when the user scrubs from range mode into single-date mode.

Required behavior:

- Measure the maximum possible Gregorian pill string for the active locale, current font, and current text-size stop.
- Set the pill width from that maximum measurement plus horizontal capsule padding.
- Use that width for both resting range mode and active inspection date mode.
- Do not resize the pill per current week, per current month, or per scrubbed day.
- The pill may still grow when the user changes text size, locale, or typography metrics, because the maximum measurement changes.

For English, no-year, seven-day Gregorian ranges, the current longest practical range string is:

```text
September 30–October 6
```

Use this as the English design-width reference, but implementations should measure all possible localized full-month seven-day range strings rather than hardcoding this exact string globally.

If the measured maximum width cannot fit on a very narrow device:

1. first allow the card/header layout to use the measured width if the surrounding layout permits it
2. then use a deliberate global compact fallback, such as short month names, for all pill states on that size class
3. do not switch between full and short month names based on the current week’s content
4. do not add secondary-calendar text back into the pill

### Pill animation and layout stability

The pill text may crossfade or update instantly. Avoid horizontal layout jumps during scrub.

Recommended behavior:

- keep the pill capsule width stable during the gesture
- use the same capsule style, height, text style, and alignment in both modes
- do not animate the pill in a way that suggests the chart is paging to another week
- do not recompute the seven visible dates just because the pill is showing a single date
- center the shorter single-date text inside the fixed-width capsule unless the platform text system has a stronger native alignment convention

If the focused single-date text is still too wide at large text sizes, allow the pill/card to expand according to the dynamic sizing rules or apply the deliberate global compact fallback for that size class.

## 10. Divider requirements

Use two subtle horizontal dividers:

- one between the header and chart
- one between the chart and footer

Recommended style:

- 1 px/pt stroke
- white at approximately 5% opacity
- horizontally aligned with the card content grid

Dividers should organize the card without making it feel segmented or heavy.

The top divider must not feel glued to the top x-axis weekday labels. The bottom divider must not feel glued to the bottom focused-day callout, and the focused-day callout must be geometrically centered between the lower plot boundary and the divider. Use the spacing rules in Section 8.

## 11. Chart layout

### Column structure

The chart always has seven evenly spaced columns. Column 1 is the forecast start day and normally the resting next-alarm / next-relevant focus. During active inspection, the focused day may be any visible column; after release, focus returns to the snap-back target.

Weekday labels show the initials for the seven visible dates and now sit at the **top** of the chart region, above the plot. The focused weekday label is white. Other weekday labels are white at approximately 70% opacity.

### Vertical order inside the chart region

From top to bottom, the chart region is:

1. top x-axis weekday label row
2. small x-axis-to-plot gap
3. plotted Fajr band / grid / markers / y-axis area
4. small plot-to-callout gap
5. focused-day callout block
6. bottom callout-to-divider breathing space

This is a deliberate current-layout switch from the earlier layout where the callout sat above the plot and the x-axis labels sat below it. The callout contents, typography, and horizontal alignment rules stay the same; only its vertical position changes.

### Vertical sizing

The plotted y-axis scale uses the tuned plot-height rule from Section 8.

Required behavior:

- The plot scale height is at least 128 px/pt.
- The plot scale height should remain visually stable across the seven standard text-size stops.
- Larger text should grow the surrounding chart region and card height, not compress the plotted scale.
- Four y-axis tick labels must fit comfortably inside the plot scale without crowding the top or bottom boundary.

### Layer order

Render from back to front:

1. shell background
2. subtle chart backdrop/frame
3. static past/elapsed overlay, if enabled
4. horizontal grid
5. vertical day grid
6. Fajr interval band
7. Fajr begin/end boundary strokes
8. in-chart `Fajr begins` and `Fajr ends` labels
9. focused-day vertical guide
10. non-focused markers
11. focused marker, if one exists
12. y-axis labels
13. top x-axis weekday labels
14. bottom focused-day callout

The focused guide, focused marker when present, bottom callout, and focused weekday label must align to the same column. The static past/elapsed overlay is not a focus layer and must not align itself to the scrubbed day unless the scrubbed day is also the snap-back target.

### Grid

Horizontal grid lines align to y-axis ticks. Vertical grid lines align to day columns.

Recommended style:

- 1 px/pt stroke
- white at approximately 5% opacity

The grid is structural and must never compete with the focused marker, Fajr band, in-chart Fajr labels, or footer.

### Static past/elapsed overlay

The chart may include a subtle translucent overlay that indicates the elapsed/past portion of the visible week up to the next alarm or snap-back target.

This overlay is **static during scrubbing**.

Rules:

- The overlay is fixed to the resolved next-alarm/resting boundary, not to the user’s finger.
- It must not move, stretch, or re-anchor when the user scrubs across visible days.
- During scrub, only the guide, bottom callout, header pill text, accessibility value, and marker emphasis change.
- The overlay should remain over the past/elapsed portion of the chart and must not extend into future columns merely because the user is touching those columns.
- By default, the overlay covers visible columns earlier than the snap-back target. If the design/data layer provides an explicit next-alarm boundary geometry, it may extend up to that boundary, but never beyond it.
- If no reliable next-alarm/resting boundary is supplied, do not render this overlay.

Recommended visual treatment:

- very subtle veil, approximately 6–10% opacity depending on material
- quiet enough that grid, band, labels, and past markers remain readable
- no animation during scrub
- optional fade only when the underlying snapshot or next-alarm boundary changes

### Fajr interval band

The band connects the visible days’ Fajr begin and Fajr end values.

- upper boundary: Fajr begins
- lower boundary: Fajr ends
- fill: subtle white or dawn-tinted translucent fill, approximately 5% opacity
- boundary lines: white at approximately 10–12% opacity
- stroke: thin, solid, not dashed

The band remains the core chart metaphor. The in-chart boundary labels identify which boundary is which without requiring the footer to repeat exact Fajr begin/end sentences.

### In-chart Fajr boundary labels

The compact chart must show two readable labels inside or directly on the plot area:

```text
Fajr begins
Fajr ends
```

Placement:

- `Fajr begins` and `Fajr ends` are boundary annotations, not strokes on the boundary lines themselves. Their rotated bounding boxes must never sit directly on top of the corresponding line.
- Default placement: `Fajr begins` sits comfortably above the Fajr begin boundary line, and `Fajr ends` sits comfortably below the Fajr end boundary line.
- The default placement applies when the visible week has quiet/silent/no-alarm states, or when the relevant wake/alarm markers sit inside the Fajr window between Fajr begins and Fajr ends.
- Pre-Fajr wake placement: if the resolved weekly/resting alarm pattern places the relevant wake markers before Fajr begins, place the `Fajr begins` label comfortably below the Fajr begin boundary line instead of above it. This keeps the label close to the boundary while avoiding the before-Fajr marker area above the line.
- `Fajr ends` remains below the Fajr end boundary line in all normal states unless an extreme collision fallback is explicitly required.
- Both labels are anchored near the left side of the plot, visually associated with the left/start side of the seven-day window.
- The labels should begin close to the plot’s leading edge, but not touch the left plot boundary. Use a leading clearance such as 6 px/pt after rotation, not merely an unrotated text-origin inset.
- The labels must also avoid the topmost and bottommost plot boundary lines. Their rotated bounding boxes must remain comfortably inside the plot area with at least 4–6 px/pt of clearance from the top, bottom, and left plot boundaries wherever possible.
- The labels do not move with scrubbing and do not align to the focused day.
- Use the boundary position at the label’s left-side anchor point to determine vertical placement, rather than using the focused day’s boundary.

Angle and boundary-alignment rule:

The `Fajr begins` and `Fajr ends` labels must be angled to match the rendered line they identify. The label baseline should be parallel to the corresponding Fajr boundary at the label’s anchor position. Do not use a hardcoded decorative angle.

Calculate the angle after the chart has resolved its actual plot geometry, y-axis scale, text size, and visible day x-positions:

```text
plotContentLeft = left edge of the plotted graph area
plotContentRight = right edge of the plotted graph area, before the y-axis label rail
boundaryPath = rendered Fajr begin or Fajr end path in screen coordinates

labelAnchorX = plotContentLeft + leadingLabelInset + measuredLabelWidth / 2
labelAnchorX = clamp(
  labelAnchorX,
  plotContentLeft + leadingLabelInset + measuredLabelWidth / 2,
  plotContentRight - leadingLabelInset - measuredLabelWidth / 2
)
sampleRadius = min(max(12 px/pt, 0.35 × dayColumnWidth), 28 px/pt)

x0 = clamp(labelAnchorX - sampleRadius, plotContentLeft, plotContentRight)
x1 = clamp(labelAnchorX + sampleRadius, plotContentLeft, plotContentRight)
y0 = boundaryPath.y(at: x0)
y1 = boundaryPath.y(at: x1)

labelAngleRadians = atan2(y1 - y0, x1 - x0)
labelAngleDegrees = labelAngleRadians × 180 / π
```

Application rules:

- Rotate each label by its own calculated `labelAngleRadians` in rendered screen coordinates.
- For a piecewise-linear boundary path, this sample method may resolve to the local segment angle or a short averaged tangent across adjacent day points.
- If a label is nudged horizontally to avoid a collision, recompute the angle from the new `labelAnchorX`.
- If a label is nudged only along the normal direction, keep the same tangent angle.
- The rotated text remains straight text; the label does not need to curve glyph-by-glyph along the path.
- Pixel snapping may round the final transform, but the intended angle source is always the rendered boundary tangent.

Position offset from the boundary:

The label position is computed from the rendered boundary tangent and then offset along that boundary’s normal. The offset must create visible separation from the boundary line while keeping the label close enough to clearly identify the boundary.

Recommended offset:

```text
minimumBoundaryClearance = max(5 px/pt, 0.30 × scaledBoundaryLabelLineHeight)
preferredBoundaryClearance = max(6 px/pt, 0.35 × scaledBoundaryLabelLineHeight)
```

Apply the clearance from the boundary line to the nearest edge of the rotated label bounding box, not from the text baseline alone.

Default normal direction rules:

- When the week is quiet/silent/no-alarm, or when relevant wake markers sit between Fajr begins and Fajr ends, place `Fajr begins` above its boundary line. In screen coordinates where y increases downward, use the normal with negative y direction.
- Place `Fajr ends` below its boundary line. In screen coordinates where y increases downward, use the normal with positive y direction.

Pre-Fajr wake normal direction rule:

- When the relevant wake/alarm pattern is before Fajr begins, place `Fajr begins` below the Fajr begin boundary line using the positive-y normal.
- This is the only normal state where `Fajr begins` moves below its boundary. It should remain close to the line and must not drift toward the Fajr end label or become centered inside the band.

Boundary and plot-edge clearance rules:

- The rotated label bounding box must clear its corresponding Fajr boundary line by at least `minimumBoundaryClearance`.
- The rotated label bounding box must clear the top plot boundary, bottom plot boundary, and left plot boundary by at least 4 px/pt, with 6 px/pt preferred at default text size.
- If the preferred boundary clearance would push a label into the top/bottom/left plot boundary, reduce toward the minimum clearance before changing the label’s side.
- Do not allow either label to physically touch or visually merge with the Fajr boundary stroke, gridline, top plot line, bottom plot line, or left plot line.
- The label should read as attached to its boundary line, not floating independently inside the band and not printed on the line itself.

Typography:

- font size must be at least the x-axis/y-axis label size at the same text-size stop
- Stop 4 minimum: 13 px/pt equivalent
- medium or regular weight is acceptable, but it must remain legible
- recommended opacity: approximately 70% white on dark glass, adjusted only if needed for contrast
- do not shrink these labels below axis-label size to solve collision problems

Collision rules:

- Measure collision using the rotated label bounding box, not the unrotated text rectangle.
- Markers, focused guide clarity, y-axis readability, and plot-edge clarity have priority over the labels.
- The labels must not cover the selected marker, non-selected markers, or the selected-guide break around the marker.
- The labels must not sit directly on the Fajr begin/end strokes; line-label separation is a collision requirement, not a decorative preference.
- If a marker overlaps a label, first apply the state-aware side rule: for a before-Fajr wake pattern, move `Fajr begins` below its boundary; otherwise keep the default above/below placement.
- If overlap remains, nudge the label within a small leading label lane while keeping it near the left/start side; then recompute the boundary angle if the horizontal anchor changed.
- If vertical adjustment is needed, nudge each label farther along its chosen normal direction while preserving boundary clearance and plot-edge clearance.
- Maintain at least 6 px/pt of visual clearance between a rotated label and any marker glyph whenever possible.
- Do not solve collisions by flattening the label back to 0°, by placing it directly on the boundary line, or by using an unrelated fixed angle.
- If an extreme text-size or data collision makes both labels impossible without covering markers or touching chart boundaries, prefer a measured card-height increase or wider label lane before hiding either label.

### Focused-day guide

The focused day receives a vertical guide.

Recommended style:

- thin white dashed line
- stronger than the grid
- dash pattern near 5 on / 4 off
- broken around the focused marker when a marker exists

When the focused day has no plotted marker, the guide may remain continuous through the plot area. On release, this guide returns to the snap-back target column.

## 12. Fajr begin/end data rules

### Fajr begin

Fajr begin is resolved by the app’s prayer-time calculation method for the selected location and date.

### Fajr end

Fajr end is not calculated by inventing a card-specific offset from Fajr begin. The card must receive a **location-resolved Fajr end boundary** for each visible day.

Implementation rule:

- Fajr begin comes from the app’s calculation method.
- Fajr end comes from the selected location’s resolved prayer-time/solar boundary data.
- The renderer must not derive Fajr end on its own.
- If the selected location changes, all visible Fajr begin/end values must be re-resolved.

The chart band, boundary strokes, in-chart labels, accessibility summary, and detail payload must use the same Fajr begin/end values. The v14 footer is a week-level trend/context summary and is not the authoritative location for exact focused-day Fajr begin/end times.

## 13. Y-axis and chart scale

### Y-axis labels

The compact card shows exactly four visible y-axis labels.

Recommended default style:

- 13 pt/sp/px equivalent base size
- medium weight
- monospaced digits where possible
- white at approximately 70% opacity
- placed in a dedicated right-side rail

The y-axis rail expands as text size increases. The plot area may shrink horizontally only after label readability and right alignment are preserved. The plot scale height must remain at least the static 128 px/pt minimum from Section 8.

### Right-alignment rule

Y-axis time labels must be visually right-aligned to the chart/content boundary.

Required behavior:

- All four y-axis labels are trailing/right aligned within the rail.
- The right edge of the y-axis label text aligns to the same internal content boundary as the header and footer divider endpoints.
- As dynamic text grows, the rail expands leftward; the label right edge must stay fixed against the right boundary.
- Labels must not appear centered in the rail, left-aligned inside the rail, or offset inconsistently because one time string is wider than another.
- Use a small consistent right inset only if the design system requires it; that inset must remain constant across text sizes.

This alignment is especially important at larger text sizes. A wider label such as `12:00 AM` should take more room to the left, not push its right edge away from the boundary.

### Time formatting

Use the user’s locale and platform time preference where possible.

Valid examples include:

- `5:00`
- `5 AM`
- `05:00`
- `5:00 AM`

Do not force a single global time format unless required by the localization system.

### Scale calculation

The y-axis scale is calculated from the current visible seven-day window.

Include:

- all visible Fajr begin times
- all visible Fajr end times
- active alarm/wake marker times
- off-state marker times only when a planned wake anchor exists

Exclude:

- no-alarm days with no planned wake anchor
- quiet/no-status days with no planned wake anchor
- unavailable marker values

Use padding so markers and boundary lines do not sit on the top or bottom edge. Recommended minimum padding: 10 minutes above and below the plotted min/max range.

### Tick interval preference

Use human-friendly intervals. Preferred ladder:

1. 15 minutes
2. 30 minutes
3. 45 minutes
4. 60 minutes
5. 75 minutes
6. 90 minutes
7. 105 minutes
8. 120 minutes

A 10-minute interval is acceptable only when the visible data range is unusually tight and four readable ticks remain clearer than coarser alternatives.

## 14. Alarm and marker states

The renderer must not invent marker positions. A marker appears only when the day data provides a real active wake time or a real planned wake anchor.

### Active alarm

Meaning: the day has an active wake cue.

Display:

- focused day: strong alarm marker aligned to wake time
- non-focused day: subdued dot or simplified alarm marker aligned to wake time
- callout: wake time
- footer: visible-week-level context summary only; no redundant visible alarm-relation line

Recommended focused marker style:

- alarm or alarm-filled symbol
- white
- strongest marker in the chart

Recommended non-focused style:

- approximately 9 px/pt dot or simplified marker
- white at approximately 50% opacity

### Off with planned wake anchor

Meaning: the day has a known planned wake anchor, but the alarm is disabled, skipped, or off.

Display:

- focused day: strong off-state marker aligned to the planned wake anchor
- non-focused day: subdued off-state marker aligned to the planned wake anchor
- callout: `Off`
- footer: visible-week-level context summary only

Recommended icon: alarm-off, bell-slash, or equivalent.

### No alarm / no planned wake anchor

Meaning: no active alarm exists and no planned wake anchor exists for that day.

Display:

- no dot
- no circle
- no alarm icon
- no off icon
- no plotted placeholder marker
- the day column remains empty except for the Fajr band, grid, guide if focused, in-chart labels, and x-axis label

If this day is focused, the callout should show `No alarm` or a similarly concise no-alarm label, and accessibility text must state that no alarm is set for that specific date. The visible footer must not add a day-specific no-alarm line; it may only summarize week-level no-alarm context when that is true for the visible week.

### Quiet hours / no status indicator

Meaning: the day intentionally has no alarm/status indicator because a quiet or paused state applies.

Display:

- no plotted marker unless a planned wake anchor is explicitly provided
- callout and accessibility text explain the quiet/no-alarm state when focused
- visible footer remains the visible-week-level context summary

### Unavailable marker data

Meaning: the card lacks enough data to truthfully plot a marker.

Display:

- do not guess a marker location
- do not include the missing marker in the y-axis scale
- use missing-data messaging if the focused day depends on that missing data

## 15. Focused-day callout

The focused-day callout now sits **below the plot** and aligns horizontally with the currently focused day column.

This is a vertical layout change only. The callout’s contents, hierarchy, typography, snap-back behavior, and horizontal alignment remain the same as before.

At rest, the callout aligns with the snap-back target, normally the first visible next-alarm / next-relevant column. During active scrub or press, it temporarily aligns with the inspected column. On release, it returns to the snap-back target with the guide, marker emphasis, header pill, and accessibility value.

Contents:

1. relative label
2. focused wake time, `Off`, or `No alarm`
3. optional meridiem suffix when applicable

Relative label examples:

- `TODAY`
- `TOMORROW`
- `MONDAY`
- `TUESDAY`

Time/status examples:

- `5:12 AM`
- `Off`
- `No alarm`

Recommended default typography:

- relative label: 13, medium
- time main: 18, bold, monospaced digits where possible
- suffix: 11, regular, monospaced digits where possible

The callout scales with user text-size settings. At larger sizes, increase callout width, chart region height, and card height before allowing overlap or truncation.

The callout must feel connected to the focused vertical guide and marker even though it is now below the plot. It must not drift into a generic footer-like caption.

## 16. Footer rules

The v14 footer is a compact **week-level Fajr trend and context summary**, not a focused-day Fajr-time readout and not a weekly alarm-plan summary.

Its job is to help the user understand the visible seven-day Fajrcast in plain language without repeating information already shown by:

- the Fajr band
- the in-chart `Fajr begins` and `Fajr ends` labels
- the y-axis timing scale
- the focused-day callout
- marker states
- accessibility summaries and detail payloads

At rest and during chart scrubbing, the footer describes the visible upcoming week. It does not chase the user’s finger. When the user releases a scrub, the footer normally remains unchanged unless the entire snapshot changes.

### Footer typography and opacity

All visible footer text uses the same visual treatment.

Required behavior:

- Footer primary and footer secondary, when secondary is present, use the same base size: 13 at Stop 4 before scaling.
- Footer primary and footer secondary, when secondary is present, use the same opacity: 100% white on the dark glass surface.
- Footer primary and footer secondary, when secondary is present, use the same regular weight unless a platform’s native font rendering requires minor optical correction.
- The second footer line must not be dimmed, faded, smaller, or lower-opacity than the first line.
- Footer hierarchy comes from line order and wording, not from opacity or type-size differences.

### Footer content model

The footer may contain one or two lines.

- **Line 1:** weekly Fajr trend line for the visible seven-day window.
- **Line 2:** optional qualifying special non-Ramadan Sunnah fasting opportunity line.

No blank second-line slot is reserved when line 2 is absent.

### Line 1: weekly Fajr trend

Line 1 should explain how **Fajr begins** changes across the visible week. It should use easy language, not technical chart language.

Preferred sentence patterns:

```text
Fajr begins {n} minutes earlier by week’s end.
Fajr begins {n} minutes later by week’s end.
Fajr begins around the same time this week.
This is the earliest Fajr begins this year.
This is the latest Fajr begins this year.
```

Examples:

```text
Fajr begins 6 minutes earlier by week’s end.
Fajr begins 4 minutes later by week’s end.
Fajr begins around the same time this week.
This is the earliest Fajr begins this year.
```

Rules:

- Use the first visible day and last visible day in the visible seven-day window to describe the weekly change.
- The default trend boundary is `fajrBeginTime`, not the user’s alarm time.
- Compute the minute delta from resolved local times after location, calculation method, date, time zone, and daylight-saving adjustments are already applied.
- If the last visible day’s Fajr begin time is earlier than the first visible day’s Fajr begin time, say Fajr begins `{n} minutes earlier`.
- If the last visible day’s Fajr begin time is later than the first visible day’s Fajr begin time, say Fajr begins `{n} minutes later`.
- If the absolute change is less than about 2 minutes, use the “around the same time” pattern instead of a tiny delta.
- Use singular `1 minute` when the delta is exactly one minute.
- Prefer full `minutes` wording. A compact `min` fallback is allowed only when the full word would create wrapping or truncation at the current text size.
- If the data layer marks the visible week as containing the selected location’s annual earliest or latest Fajr-begin moment, the annual-extreme sentence may take priority over the ordinary minute-delta sentence.
- Do not use wording like `trend is up`, `trend is down`, `rising`, or `falling` in the visible footer.
- Do not mention the exact focused wake time here; the callout already owns that.
- Do not mention exact Fajr begin/end clock times here; the chart and accessibility own those.
- Do not summarize default alarm offsets, no-alarm weeks, quiet days, adjusted mornings, or off states in this footer line.

If the weekly Fajr trend cannot be resolved in a ready state, the data layer should either omit the footer line for the missing-data state or provide a calm fallback string such as:

```text
Fajr trend will appear once times are available.
```

The renderer must not guess the trend.

### Line 2: qualifying special non-Ramadan Sunnah fasting opportunity

Line 2 is optional. It should appear only when the data layer supplies a qualifying **special non-Ramadan Sunnah fasting** context for the visible upcoming week.

Allowed patterns:

```text
Fasting opportunity: {observanceName} on {dayName}.
Fasting opportunity: {observanceName} this week.
Fasting planned: {observanceName} on {dayName}.
Fasting planned on {count} special days this week.
```

Examples:

```text
Fasting opportunity: Ashura on Friday.
Fasting opportunity: Dhul-Hijjah days this week.
Fasting planned: Arafah on Thursday.
```

Rules:

- Show line 2 only for qualifying special non-Ramadan fasting observances or opportunities that the product deliberately wants to surface.
- Examples of qualifying contexts include Ashura, Tasu’a, Arafah, the first nine days of Dhul-Hijjah, notable Muharram fasting opportunities, or another named Sunnah fasting observance supplied by the data layer.
- Do **not** show line 2 merely because the week contains ordinary Monday/Thursday fasting days.
- Do **not** show line 2 merely because the week contains White Days.
- Do **not** show line 2 merely because the visible week is Ramadan, and do not say or imply that every Ramadan day is a fasting day.
- Do **not** show generic negative copy such as `No fasting days are planned this week.`
- If the user has an explicit fasting intention for a qualifying special observance, prefer `Fasting planned...` wording.
- If the app is surfacing an observance opportunity without an explicit user intention, prefer `Fasting opportunity...` wording.
- If the qualifying fasting copy becomes too verbose, shorten or omit line 2 before harming line 1 or the footer-bottom breathing space.

### Forbidden visible footer patterns in v14

Do not show focused-day Fajr-time sentences in the compact footer:

```text
Fajr begins at 5:21 AM • Fajr ends at 6:43 AM
Fajr began at 5:21 AM • Fajr ended at 6:43 AM
```

Do not show redundant focused-day alarm summaries in the compact footer:

```text
Tomorrow’s alarm is 30 min before Fajr begins.
Friday’s alarm is set for 5:10 AM.
Yesterday’s alarm was off for this date.
```

Do not show weekly alarm-plan summaries in the compact footer:

```text
Default alarm: 30 min before Fajr ends.
No wake alarms are set for this week.
Quiet days: Monday and Tuesday.
This week includes 2 adjusted wake mornings.
```

Do not show routine or generic fasting copy:

```text
No fasting days are planned this week.
Fasting planned on Monday and Thursday.
White Days this week.
Ramadan fasting this week.
Tomorrow is a fasting day.
Yesterday was a fasting day.
```

### Footer priority

If space is constrained, preserve content in this order:

1. line 1 weekly Fajr trend
2. line 2 qualifying special non-Ramadan Sunnah fasting opportunity, when present
3. enlarged footer-bottom breathing space below the final visible line

At large text sizes, wrap the footer and grow the card rather than truncating the line 1 trend. Omit line 2 before truncating line 1.

## 17. Gregorian date display rules

The compact card header date pill is Gregorian-only in v14.

Required behavior:

- Do not display lunar or secondary-calendar text in the compact header pill.
- Use full Gregorian month names where the locale supports them and the measured fixed-width pill can fit.
- Use the same Gregorian date source for the week range and active scrub single-date text.
- No previous-day history is required for the v14 chart because it shows the upcoming week. If the first visible day is today and partly elapsed, use resolved same-day state rather than completion history to explain it.
- If the user or system has a date override that affects the resolved app date, the data layer should reflect that before building the snapshot.

Ramadan and other special contexts may still be resolved upstream by the app, but the compact pill itself stays Gregorian-only.

## 18. Special context priority

The compact card may support several contextual day meanings, but it should not become chip-heavy or visually crowded. In v14, special context primarily affects:

- marker/callout state where relevant
- accessibility summary
- detail-event payload
- optional week-level footer context, but only for the weekly Fajr trend and qualifying special non-Ramadan fasting opportunities

When multiple special contexts exist, use this priority for modeling and detail payloads:

1. **Ramadan**
2. **Fasting**
3. **Tahajjud**
4. **Adjusted**
5. ordinary day / no special context

Rules:

- Ramadan remains the top priority for context modeling and accessibility/detail payloads.
- Ramadan and fasting are expected not to occur together, but if both are present in data, Ramadan wins.
- The footer must not say or imply that each Ramadan day is a fasting day.
- Explicit fasting intentions outside Ramadan may be summarized in the footer only when they correspond to a qualifying special Sunnah fasting observance; ordinary Monday/Thursday fasts and White Days are suppressed in the compact footer.
- Fasting wins over Tahajjud for context modeling when the day is not Ramadan.
- Tahajjud wins over adjusted for context modeling.
- Adjusted appears only when no stronger special context applies.
- Alarm/off/no-alarm/quiet status still matters, but it should be communicated through marker, callout, accessibility, and detail payloads rather than the compact footer.

Allowed visible footer copy for qualifying special non-Ramadan fasting:

```text
Fasting opportunity: Ashura on Friday.
Fasting opportunity: Dhul-Hijjah days this week.
Fasting planned: Arafah on Thursday.
```

Do not show these in the compact visible footer:

```text
Ramadan: Tomorrow is a fasting day.
Fasting planned on Monday and Thursday.
White Days this week.
No fasting days are planned this week.
Fasting day: Friday’s alarm is set for 5:10 AM.
Tahajjud: Thursday’s alarm is 45 min before Fajr begins.
Adjusted: Monday’s alarm is off for this date.
Quiet day: no alarm is set for tomorrow.
```

## 19. Accessibility requirements

Accessibility is a core requirement.

### Dynamic text

All readable text must scale with user text-size settings:

- header title
- Gregorian header date pill
- top x-axis labels
- y-axis labels
- in-chart `Fajr begins` and `Fajr ends` labels
- focused-day callout label
- focused-day callout time/status
- footer primary line
- footer secondary line when present

Use the dynamic sizing model in Section 8. No chart text may remain fixed and tiny while the rest of the interface scales.

### Layout adaptation

When text scales up, adapt in this order:

1. increase card height
2. widen the y-axis rail
3. preserve or increase chart height
4. increase callout width
5. preserve top divider-to-x-axis spacing
6. preserve the x-axis-to-plot gap
7. preserve the plot-to-bottom-callout gap
8. preserve geometric bottom callout-to-footer-divider centering
9. preserve enlarged footer-bottom breathing space
10. allow footer primary wrapping
11. allow footer secondary wrapping or shortening
12. omit footer secondary before harming the primary line
13. apply the deliberate global compact fallback for the fixed-width Gregorian pill only if full month names cannot fit on the size class

Do not hide essential Fajr context, make axis labels unreadable, or shrink in-chart Fajr labels below axis-label size.

### Screen reader summary

Expose one coherent summary for the focused day.

Recommended structure:

```text
Weekly Fajrcast. {Relative day} focused. {Alarm/status sentence}. {Fajr begin/end sentence}. {Week-context sentence optional}. Double tap for details.
```

Examples:

```text
Weekly Fajrcast. Tomorrow focused. Alarm at 5:10 AM. Fajr begins at 5:40 AM. Fajr ends at 6:43 AM. Fajr begins 6 minutes earlier by week’s end. Double tap for details.
Weekly Fajrcast. Yesterday focused. Alarm was at 5:10 AM. Fajr began at 5:40 AM. Fajr ended at 6:43 AM. Double tap for details.
Weekly Fajrcast. Thursday focused. No alarm was set for Thursday. Fajr began at 5:37 AM. Fajr ended at 6:41 AM.
```

The accessibility summary must still use correct focused-day tense for past, in-progress, and upcoming Fajr windows even though the visible footer is now a week-level summary.

### Accessible day navigation

Where supported, expose adjustable actions:

- increment: inspect the next visible day
- decrement: inspect the previous visible day
- reset/default action, if available: return to the snap-back target / next-alarm focus

These actions are limited to the same seven visible days. They do not pan or recenter the chart. At the left or right edge, the action should clamp or report that no further visible day is available.

Because assistive technologies do not always have the same “finger release” moment as touch scrubbing, accessible inspection may remain on the inspected day long enough for the user to hear the updated summary. During that accessible inspection state, the header pill should use the inspected day’s single Gregorian date just as it does during touch scrub. When accessibility focus leaves the card, or when the user invokes the default/reset action, the visual focus and header pill should return to the snap-back target / resting range mode.

The footer remains week-level during accessible inspection unless the entire snapshot changes.

### Reduced motion and non-color dependency

Respect reduced-motion settings. Use minimal fade or emphasis changes instead of animated scrubbing effects when reduced motion is enabled.

Active, off, no-alarm, quiet, selected/focused, adjusted, and special states must not rely on color alone. Use icon, shape, text, weight, opacity, and accessibility labels as appropriate.

## 20. Responsive behavior

### Narrow widths

On narrow devices:

- preserve exactly seven visible days
- keep the forecast start day first
- keep y-axis labels readable
- keep the header date pill fixed-width for the measured maximum Gregorian string when possible
- if full month names cannot fit, use one deliberate global compact pill fallback for that size class rather than resizing per week
- allow footer wrapping
- allow card height growth

### Wider layouts

On wider layouts:

- do not stretch the chart until it loses compact-card identity
- preserve the upcoming-week rhythm
- cap maximum width through the containing layout if needed
- keep the in-chart Fajr labels near the left/start side instead of letting them drift toward the center of a very wide chart

### Localization

The card must handle longer localized labels by expanding, compacting, or wrapping according to the priority rules above. It should not assume English month names, English weekday initials, or a fixed AM/PM format.

For the header date pill, measure the maximum possible localized Gregorian range/date string for the current locale and text-size stop. If a fallback is required, it must be applied consistently for that size class, not only to particular weeks.

## 21. Data contract

The card should receive a resolved snapshot. The renderer should not infer prayer times, calendar display text, context priority, alarm relation text, snap-back target, past-overlay boundary, marker times, weekly Fajr trend, or footer summary content. The renderer may derive purely geometric presentation values, such as rotated Fajr-boundary label angles, from the rendered chart paths because those values depend on final layout geometry.

```text
WeeklyFajrcastSnapshot
- forecastStartDateKey
- restingFocusDateKey
- snapBackTargetDateKey
- focusedDateKey
- visibleDays[7]
- nextSevenDaysVisibleDateKeys[7] optional, for cross-surface assertion
- weekPillText
- pillWidthReferenceText optional
- yAxisTicks[4]
- weekFooterPrimaryText
- weekFooterSecondaryText optional
- weeklyFajrTrendSummary optional
- specialFastingSummary optional
- accessibilitySummary
- focusedFajrWindowState upcoming | inProgress | completed | unavailable
- pastOverlayBoundary optional
- loadingState ready | loading | partial | missingData | error
```

At rest, `focusedDateKey` should equal `snapBackTargetDateKey`. During active inspection, the renderer may temporarily set `focusedDateKey` to the inspected visible day. On release, it must set `focusedDateKey` back to `snapBackTargetDateKey`.

`weekPillText` is the resting range-mode pill text for the visible seven-day Gregorian window. During active inspection, the renderer should display the focused day’s Gregorian `datePillText` in the same pill instead. On release, the renderer must return the pill display to `weekPillText`.

`pillWidthReferenceText` may be supplied by the data/design layer to support fixed-width measurement. In English no-year formatting, this is normally equivalent to `September 30–October 6`. If not supplied, the renderer should measure the maximum localized Gregorian range/date candidates itself.

`weekFooterPrimaryText` is the visible weekly Fajr trend line. `weekFooterSecondaryText`, when present, is the qualifying special non-Ramadan Sunnah fasting opportunity line. These are not focused-day strings and should not change merely because the user scrubs within the seven visible days.

The snap-back target must be supplied by the data layer. It is normally the same as `forecastStartDateKey` and represents the first visible next alarm or next relevant morning. The renderer must not infer a different target by scanning for the nearest marker.

### Past overlay boundary

If the chart uses the static past/elapsed overlay, the snapshot should provide a boundary.

```text
PastOverlayBoundary
- enabled true | false
- boundaryDateKey
- boundaryTime optional
- source nextAlarm | resolvedElapsedBoundary | explicit
```

Rules:

- `boundaryDateKey` must be one of the seven visible days.
- The overlay is anchored to this boundary and must not use `focusedDateKey` during scrub.
- If `enabled` is false or the boundary is unavailable, do not render the overlay.
- If `boundaryTime` is supplied, it may be used to refine the overlay to the next-alarm marker or resolved boundary; if not supplied, use the default column-based overlay rule from Section 11.

### Optional week footer summary payload

The data layer may provide structured context in addition to precomposed footer strings.

```text
WeekFajrTrendSummary
- trendSummaryType earlier | later | sameTime | annualEarliest | annualLatest | unavailable
- trendBoundary fajrBegins
- deltaMinutes optional
- firstVisibleDateKey
- lastVisibleDateKey
- annualExtremeDateKeys optional
```

```text
SpecialFastingSummary
- fastingSummaryType none | specialOpportunity | specialPlanned | ramadanSuppressed | routineSuppressed | omitted | unavailable
- qualifyingObservances optional
  - observanceName
  - dateKeys
  - userIntendsToFast true | false | unknown
- suppressedRoutineTypes optional mondayThursday | whiteDays | ramadan
```

Rules:

- Prefer precomposed `weekFooterPrimaryText` and `weekFooterSecondaryText` for display.
- Structured fields are for tests, fallback composition, diagnostics, and detail payloads.
- The primary footer string must come from `WeekFajrTrendSummary` or an equivalent precomposed data-layer trend string.
- The secondary footer string must come from `SpecialFastingSummary` and must be omitted unless a qualifying special non-Ramadan fasting observance is supplied.
- The renderer must not infer special non-Ramadan fasting opportunities from Ramadan, ordinary Monday/Thursday fast days, White Days, or generic day-level `isFasting` values.
- The renderer must not compose a line that says all Ramadan days are fasting, must not show a fasting-summary line solely because the week is Ramadan, and must not show `No fasting days are planned this week.` in the compact footer.
- Alarm-plan fields such as default offsets, quiet days, no-alarm weeks, adjusted mornings, and off states may exist elsewhere in the app, but they are not footer content in this v14 card.

### Visible day payload

Each visible day should provide:

```text
FajrcastDay
- dateKey
- gregorianDate
- datePillText
- weekdayInitial
- relativeLabel
- temporalRelation past | today | future
- fajrBeginTime
- fajrEndTime
- fajrEndSource locationResolved
- fajrWindowState upcoming | inProgress | completed | unavailable
- alarmState active | offWithAnchor | noAlarm | quietHours | unavailable
- alarmMomentState upcoming | elapsed | none | unavailable
- wakeTime optional
- plannedWakeAnchorTime optional
- wakeDisplayText
- markerPolicy plottedActive | plottedOff | none | unavailable
- relationText optional
- isForecastStartDay
- isRestingFocus
- isFocused
- specialContext none | ramadan | fasting | tahajjud | adjusted
- specialContextSource optional
- accessibilityText
```

Rules:

- `visibleDays` always equals forecastStartDateKey through forecastStartDateKey plus 6 calendar days.
- `focusedDateKey` must be one of the seven visible days.
- `restingFocusDateKey` and `snapBackTargetDateKey` must be one of the seven visible days.
- `weekFooterPrimaryText`, optional `weekFooterSecondaryText`, and `accessibilitySummary` must match the visible week and current focused-day accessibility state.
- `weekFooterPrimaryText` must describe the weekly Fajr begin trend, not the alarm plan.
- `weekFooterSecondaryText` must be omitted unless there is a qualifying special non-Ramadan Sunnah fasting opportunity or plan.
- `datePillText` must be preformatted for active inspection using the selected Gregorian date only, for example `April 29`.
- `weekPillText` must be preformatted for resting mode using the visible seven-day Gregorian range only, for example `April 26–May 2`.
- `markerPolicy = none` means no marker is rendered and no marker time is included in scale calculation.
- `fajrEndSource` must be `locationResolved` unless the data layer explicitly adds another supported source in the future.
- The renderer may use `focusedFajrWindowState`, `fajrWindowState`, and `alarmMomentState` for tests, animations, and accessibility.
- The static past/elapsed overlay must be driven by `pastOverlayBoundary`, not by the currently inspected day.
- The compact card does not need day-level visible footer strings; focused-day exact Fajr wording belongs to accessibility, detail, diagnostics, or future expanded presentations.

## 22. Loading, partial, and missing-data states

### Loading

Use a calm skeleton or placeholder that preserves the card’s measured height for the current text-size stop. Avoid layout jumps when data resolves.

### Missing Fajr data

If Fajr begin/end data cannot be resolved for the focused day:

- do not show guessed times
- do not render a misleading Fajr band for that day
- show a calm fallback message
- expose a clear accessibility label

Example:

```text
Weekly Fajrcast will appear once Fajr times are available.
```

### Partial visible-day data

If some non-focused days are missing but the focused day is available, render only if the chart can remain truthful. Missing days should be visibly unavailable rather than connected with fake Fajr-band continuity.

## 23. Locked requirements

These rules should not change without deliberate design review:

1. The visible title is `WEEKLY FAJRCAST`.
2. The card shows exactly seven day columns.
3. The forecast start day is always the first column.
4. The visible window is forecastStartDateKey through forecastStartDateKey plus 6 calendar days.
5. Tapping, pressing, or scrubbing changes the inspection focus only while the interaction is active.
6. When touch inspection ends, the card snaps back to the snap-back target / next alarm.
7. The chart does not move, pan, scroll, or recenter during scrub or snap-back.
8. The user can inspect only the seven visible days.
9. Edge panning beyond seven days is not supported.
10. The header pill is Gregorian-only.
11. The header pill uses full month names by default.
12. The header pill is fixed-width from the maximum possible Gregorian range/date text for the current locale/text size, not resized per current content.
13. The header pill describes the visible upcoming Gregorian window at rest, temporarily shows the inspected day’s single Gregorian date during active scrub, and returns to the visible range on release.
14. The x-axis weekday labels sit above the plot.
15. The focused-day callout sits below the plot.
16. The focused-day callout contents and typography remain unchanged from the prior callout model.
17. The footer is a week-level Fajr trend/context summary and does not chase the user’s scrub focus.
18. The compact footer must not show focused-day exact Fajr begin/end sentences.
19. The compact footer must not repeat focused-day alarm time, alarm offset, off-state, or quiet-state copy.
20. Footer line 1 summarizes how Fajr begins changes across the visible upcoming week.
21. Footer line 1 uses plain language such as `Fajr begins 6 minutes earlier by week’s end`, not technical trend wording.
22. Footer line 1 may use annual-extreme wording when the data layer marks the week as containing the year’s earliest or latest Fajr begin.
23. Footer line 2 appears only for qualifying special non-Ramadan Sunnah fasting opportunities or plans.
24. Ordinary Monday/Thursday fasts, White Days, Ramadan, generic no-fasting text, adjusted mornings, quiet days, no-alarm weeks, and alarm-plan summaries are suppressed in the compact footer.
25. Ramadan must not create repetitive footer copy saying every day is a fasting day.
26. Fajr end comes from selected-location resolved data, not a renderer-invented offset.
27. The Fajr interval band is the core chart metaphor.
28. In-chart `Fajr begins` and `Fajr ends` labels are shown.
29. The in-chart Fajr labels sit near the left/start side of the plot and do not move with scrubbing.
30. The in-chart Fajr labels must be at least as large as the axis labels.
31. The in-chart Fajr labels are angled from the rendered tangent of their corresponding boundary line, not from a fixed decorative angle.
32. The in-chart Fajr labels must sit near, not on, their corresponding boundary lines, with visible clearance from the boundary stroke.
33. `Fajr begins` uses default above-line placement except when the relevant wake pattern is before Fajr begins, where it moves below the begin line.
34. In-chart Fajr labels must not cover alarm markers, selected-guide clarity, Fajr boundary strokes, or plot boundary lines.
35. Active, off-with-anchor, no-alarm, quiet, and unavailable states are visually distinct.
36. No-alarm/no-planned-anchor days have no dot, circle, icon, or placeholder marker.
37. The renderer never invents marker times.
38. The focused guide, marker when present, bottom callout, and focused weekday label align to the same inspected/resting column.
39. The static past/elapsed overlay, if supplied for same-day elapsed state, is anchored to the data-layer boundary and does not move with scrubbing.
40. Y-axis labels are trailing/right aligned to the chart/content boundary; the rail expands leftward as text grows.
41. The plotted y-axis scale height is at least 128 px/pt and remains visually stable across the seven standard text-size stops.
42. The top x-axis labels keep defined spacing from the top divider and top plot boundary.
43. The bottom focused-day callout is geometrically centered between the lower plot boundary and footer divider using the measured callout block.
44. The footer keeps enlarged breathing space below the final visible footer line.
45. Footer primary and secondary text use the same size, weight, and 100% opacity when the secondary line is present.
46. Header title, header date pill, callout, axes, in-chart labels, and footer all scale with text-size settings.
47. The card uses dynamic measured sizing with seven-stop guardrails; it is not a fixed-height card.
48. The card may grow taller for readability and accessibility.
49. Context priority for modeling and detail payloads is Ramadan, then fasting, then Tahajjud, then adjusted.
50. The visual treatment remains dark, glassy, restrained, and premium.

## 24. Recreation checklist

### Product behavior

- [ ] Seven visible days are rendered.
- [ ] Forecast start day is the first visible column.
- [ ] Window is forecast start day D through D+6.
- [ ] Initial forecast start day follows next-immediate-alarm / next-relevant-morning logic.
- [ ] Snap-back target is supplied and normally equals the first visible next alarm / next relevant morning.
- [ ] User can tap or press a visible day to temporarily inspect it.
- [ ] User can scrub left/right across visible days.
- [ ] Active scrub updates guide, marker emphasis, bottom callout, header pill date text, and accessibility summary.
- [ ] Active scrub does not change the visible-week-level footer.
- [ ] Same-day elapsed states use accurate accessibility wording.
- [ ] Releasing the scrub snaps focus back to the snap-back target / next alarm.
- [ ] Scrub and snap-back do not move, pan, scroll, or recenter the chart.
- [ ] Scrub clamps at the first and seventh visible days.
- [ ] Detail opening is suppressed during chart interaction.

### Header

- [ ] Title reads `WEEKLY FAJRCAST`.
- [ ] Header pill is Gregorian-only.
- [ ] Header pill uses full month names by default.
- [ ] Header pill reflects the visible upcoming seven-day Gregorian range at rest.
- [ ] Header pill switches to the inspected day’s single Gregorian date during active scrub.
- [ ] Header pill returns to the visible seven-day range on release.
- [ ] Header pill width is measured from the maximum possible Gregorian range/date string for the locale/text size.
- [ ] Header pill does not resize per current week or scrubbed day.
- [ ] Missing history does not create blank date text.
- [ ] Header scales and compacts gracefully.

### Chart

- [ ] X-axis weekday labels are positioned above the plot.
- [ ] Focused callout is positioned below the plot.
- [ ] Focused callout contents, typography, and horizontal alignment match the defined callout model.
- [ ] Fajr interval band connects begin/end values across the visible week.
- [ ] Fajr boundary lines are subtle.
- [ ] In-chart `Fajr begins` and `Fajr ends` labels are shown.
- [ ] Fajr labels are near the left/start side of the plot.
- [ ] Fajr labels are at least as large as x-axis/y-axis labels.
- [ ] Fajr labels do not move with scrubbing.
- [ ] Fajr labels rotate to match the rendered tangent angle of their corresponding boundary line.
- [ ] Fajr label normal offsets place `Fajr begins` above its line by default, but below its line for before-Fajr wake patterns.
- [ ] `Fajr ends` remains below its line in normal states.
- [ ] Fajr labels clear their boundary strokes and do not sit directly on the lines they identify.
- [ ] Fajr labels avoid plot-edge, marker, and guide collisions using rotated bounding boxes.
- [ ] Four y-axis labels are shown.
- [ ] Y-axis labels are right/trailing aligned to the content boundary.
- [ ] Y-axis rail expands leftward for larger text.
- [ ] Plot scale height is at least 128 px/pt.
- [ ] Plot scale height remains visually stable across the seven standard text-size stops.
- [ ] Top x-axis labels keep the required spacing from the top divider and top plot boundary.
- [ ] Bottom callout is geometrically centered between the lower plot boundary and footer divider using the measured callout block.
- [ ] Focused guide aligns with the inspected/resting day column.
- [ ] Guide, callout, marker emphasis, and header pill snap back to the next-alarm target on release.
- [ ] Static past/elapsed overlay, if supplied, is anchored to the data-layer boundary.
- [ ] Static past/elapsed overlay does not move with the scrubbed day.
- [ ] Active and off-with-anchor markers are visually distinct.
- [ ] No-alarm/no-planned-anchor days render no marker.
- [ ] Renderer does not invent unavailable marker times.
- [ ] No-marker days are excluded from y-axis marker scale inputs.

### Dynamic sizing

- [ ] Text sizes derive from platform-native dynamic text metrics.
- [ ] Stop 4 uses the base typography tokens in this spec.
- [ ] Seven text-size stops use the minimum card/chart/rail guardrails from Section 8.
- [ ] The static plot scale height remains at least 128 px/pt at each standard stop.
- [ ] The layout swap does not collapse x-axis, plot, callout, geometric callout centering, or footer breathing space.
- [ ] Actual measured text can grow the card beyond the stop minimum.
- [ ] Footer wrapping increases card height instead of clipping text.
- [ ] Footer has enlarged breathing space below the final visible footer line.
- [ ] Y-axis rail width is measured from the widest scaled tick label.
- [ ] Y-axis label right edge remains fixed to the content boundary as the rail expands.
- [ ] Fixed-width pill measurement is recalculated when text size or locale changes.

### Footer

- [ ] Footer is a week-level Fajr trend/context summary.
- [ ] Footer does not update merely because the user scrubs to another day.
- [ ] Line 1 explains how Fajr begins changes across the visible upcoming week.
- [ ] Line 1 uses easy language such as `Fajr begins 6 minutes earlier by week’s end.`
- [ ] Line 1 can use annual-extreme wording when the data layer marks the week as containing the year’s earliest/latest Fajr begin.
- [ ] Line 1 does not summarize default alarm offsets, quiet days, no-alarm weeks, adjusted mornings, or focused-day status.
- [ ] Line 2 appears only for qualifying special non-Ramadan Sunnah fasting opportunities or plans.
- [ ] Routine Monday/Thursday fasts, White Days, and Ramadan do not create footer line 2.
- [ ] Generic negative copy such as `No fasting days are planned this week.` is not shown.
- [ ] Ramadan does not generate repetitive daily fasting copy.
- [ ] Footer does not show `Fajr begins at... • Fajr ends at...` sentences.
- [ ] Footer does not repeat focused-day alarm time or alarm offset.
- [ ] Footer primary and secondary use the same base size, weight, and 100% opacity when secondary is present.
- [ ] Footer secondary is not dimmed, faded, smaller, or lower-opacity than footer primary.
- [ ] Footer has enlarged bottom breathing space below the final visible line.
- [ ] Footer wraps or card grows at larger text sizes.

### Accessibility

- [ ] All text scales, including in-chart Fajr labels.
- [ ] Screen reader summary includes card name, focused day, alarm/status, Fajr begin, Fajr end, weekly Fajr trend, and any qualifying special fasting context.
- [ ] Screen reader wording uses correct past/in-progress/future tense for the focused day.
- [ ] Accessible increment/decrement stays within the seven visible days.
- [ ] Accessible reset/default action returns to the snap-back target when available.
- [ ] Reduced motion is respected.
- [ ] State is not communicated by color alone.

## 25. Remaining open ambiguity for next iteration

### Detail destination

The compact card may emit an intent to open a more detailed Fajrcast experience, but the exact destination, route name, event name, and payload contract are not finalized in this spec.

Minimum likely payload, if implemented:

```text
OpenWeeklyFajrcastDetailIntent
- forecastStartDateKey
- focusedDateKey
- sourceCardId optional
```

Until this is decided, the card should still support day focusing and scrubbing independently of navigation.

## 26. Final design intent

The Weekly Fajrcast card should feel like a premium morning forecast for Fajr-centered life: minimal, readable, calm, precise, grounded, and interaction-aware.

At a glance, the user should understand the upcoming week’s Fajr window and the first visible next-alarm/resting morning. With one touch, they should inspect any of the seven upcoming days without the chart moving away or loading another week. While they scrub, the header pill should show the inspected day’s Gregorian date only, and the bottom callout should show the inspected day’s alarm or wake state. When they release, the card should calmly return to the first visible next alarm / next relevant morning and the pill should return to the full Gregorian week range. The bottom callout should feel precisely centered in its chart-to-footer pocket, and the `Fajr begins` / `Fajr ends` labels should read as native annotations attached near the sloped boundary lines, angled with them, but never printed directly on top of them.

The v14 visual direction keeps the secondary-calendar text removed from the pill, keeps weekday labels at the top of the plot, keeps the focused-day callout below the plot, and keeps readable in-chart `Fajr begins` and `Fajr ends` labels near the left/start side of the chart. The footer becomes a concise week-level Fajr trend/context summary: line 1 explains how Fajr begins changes across the week, and line 2 appears only for qualifying special non-Ramadan Sunnah fasting opportunities.

The chart should remain proportionate: tall enough for legible y-axis labels and Fajr boundary labels, but compact enough that the graph does not dominate the card. The bottom callout should sit evenly between the lower plot boundary and the footer divider, while the final footer line should have generous lower breathing room. The y-axis labels should sit cleanly against the right content boundary, the static past/elapsed overlay should indicate past context without chasing the user’s finger, and the new Fajr labels must not interfere with markers, Fajr boundary strokes, or chart boundary lines. The final experience should remain exact and calm even when there is no alarm, quiet time, Ramadan, fasting, Tahajjud, or an adjusted wake state.
