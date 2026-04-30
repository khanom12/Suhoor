## Summary

Fix two regressions in the Next 10 Mornings card after the v2 tag/grid refinement:

- opportunity-only rows should reliably show `[Fajr]` with context-derived opportunity tags such as `[White Days]`
- tag clusters should read visually centered in the row on iPhone widths, without row-local drift or unnecessary lane padding

## Problem

The v2 implementation handles `[Fajr] + opportunity` when compatible opportunity tags are passed directly, but the live row path only builds `compatibleOpportunityTags` from the date-derived observance calculator. Rows that already have resolved day context carrying `.whiteDays` can therefore miss `[White Days]` in the forecast card.

The row layout also uses unequal leading/trailing lane widths and adds extra horizontal padding around the tag lane. On compact iPhone widths this makes the tag cluster appear slightly left of center and can cause `[Fajr] [White Days]` to collapse to only `[Fajr]` even when the two-chip state should fit.

## Scope

This change is limited to the Next 10 Mornings presentation and row layout.

## Non-Goals

- Do not change prayer-time calculation, Hijri date calculation, scheduling, persistence, or alarm delivery.
- Do not change tag colors, glass shell styling, row tap behavior, or visible copy.
- Do not introduce tag interactivity, subtitles, horizontal scrolling, or a new measurement system.
