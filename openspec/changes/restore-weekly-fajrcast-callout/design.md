## Context

The compact Weekly Fajrcast home card is a supporting surface for tomorrow morning. Its chart already uses weekday initials on the x-axis, while the selected-day overlay is the card's immediate-answer layer. A recent Cloud pass changed that overlay label to the weekday name, which makes the selected callout less direct when tomorrow is selected.

## Goals / Non-Goals

**Goals:**
- Keep the compact Fajrcast axis as weekday initials.
- Keep the selected callout focused on the selected morning's relation to now: `TODAY`, `TOMORROW`, or a weekday fallback for non-immediate selections.
- Preserve accessibility wording that can include fuller date context.
- Add focused coverage in `ScheduleServiceExtractionTests`.

**Non-Goals:**
- No redesign of `WeeklyFajrcastCard`, `FajrWindowChartView`, or the detail Fajr-window surface.
- No changes to Fajr start/end calculation, wake resolution, alarm scheduling, persistence, or Hijri date-range rendering.
- No new dependencies or migration behavior.

## Decisions

- Keep relative-label calculation in `FajrWindowSurfaceProvider`, where compact snapshot copy is already prepared. This avoids adding business-copy branching to SwiftUI.
- Reuse `compactSubject(for:now:timeZone:)` for the visible compact label. This preserves the existing today/tomorrow behavior and falls back to a weekday/date-derived label for other selected days.
- Update the existing tomorrow-selection test to assert `TOMORROW`, because that is the behavioral contract the home card needs to protect.

## Risks / Trade-offs

- [Risk] A non-immediate selected day still needs a legible label. -> Mitigation: `compactSubject` already falls back to the point's long weekday label.
- [Risk] This can be confused with x-axis labeling. -> Mitigation: tests distinguish the selected callout label from the x-axis initials.
