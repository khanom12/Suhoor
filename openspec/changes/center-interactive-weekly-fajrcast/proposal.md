# Center Interactive Weekly Fajrcast

## Summary

Realign the Weekly Fajrcast card with the revised platform-agnostic recreation spec: the selected morning is always centered in a seven-day context window, chart selection is interactive, the footer leads with exact Fajr begin/end times, inline chart boundary labels are removed, and compact chart text becomes more readable while remaining dark, restrained, and glass-based.

## Problem

The current compact Fajrcast implementation still behaves like a future rolling week in important places. It also treats the compact card mostly as a tap target, with selection happening in the detail view rather than on the card. The latest product spec changes the card's mental model:

- the card shows `selected - 3` through `selected + 3`, not the next seven future days
- the selected day is the center column
- selecting a visible day recenters the chart around that day
- the footer must state exact Fajr begin/end times for the selected day before any wake summary
- inline `FAJR BEGINS` / `FAJR ENDS` chart labels should be removed
- compact chart text should scale and read slightly larger than the previous smallest treatment

If this remains partially aligned, the card can drift away from the core product job: explaining the selected morning inside its surrounding Fajr context.

## Scope

In scope:

- Build compact Weekly Fajrcast snapshots from a centered seven-day day set.
- Preserve next-relevant-morning default selection.
- Allow compact chart tap/drag selection and recentering.
- Keep detail navigation using the currently selected date.
- Update the footer to show mandatory Fajr begin/end text and optional selected wake relation text.
- Remove compact inline boundary labels.
- Increase compact chart/footer base text sizes and Dynamic Type behavior.
- Preserve active/off marker distinction and selected callout/guide/marker/weekday alignment.
- Update focused tests and OpenSpec requirements.

Out of scope:

- Reintroducing a tab-first Wake IA. The current app OpenSpec has moved the signature card onto the single Subh home surface; this change aligns the card behavior wherever it is rendered.
- Adding chips for adjusted/special/fasting contexts to the compact card.
- Adding new analytics, telemetry, or external data flows.
- Redesigning the full Fajrcast detail screen beyond receiving the current selected date.

## User Impact

Users will see the selected morning in the center of the Weekly Fajrcast, with three surrounding mornings on each side. The card will state exact selected-day Fajr begin/end times, make the selected wake/off state clearer, and let users scrub the week without accidentally treating the card as a static preview.

## Risks

- Centered generation requires resolved schedule data for recent past mornings, not only future mornings.
- The card is still embedded in the single-screen home architecture, while the product spec uses Wake-surface language.
- Interactive gestures must avoid accidental detail navigation.

## Validation

- OpenSpec strict validation for this change.
- Focused snapshot tests for centered seven-day windows, footer text, off-state footer behavior, adjusted-week insight preservation, and compact tick count.
- Focused Xcode test run for `ScheduleServiceExtractionTests`.
- `git diff --check`.
