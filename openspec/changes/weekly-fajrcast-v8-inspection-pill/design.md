## Overview

The existing Weekly Fajrcast card already receives temporary chart inspection callbacks and snap-back callbacks. This change uses that existing interaction state locally in the card to switch the header pill content without changing the chart data model or moving the anchored seven-day window.

## Pill Modes

The header date pill has two rendering modes:

- **Resting range mode:** default mode; text is the existing anchored seven-day Gregorian + Hijri range.
- **Active inspection date mode:** enabled while a chart selection/drag/scrub is active, or after an accessible day adjustment; text is the currently focused selected day's Gregorian + Hijri single-date string.

The capsule position, width, height, typography, color, and background remain unchanged in both modes to avoid layout jumps.

## Data Source

The current Swift model does not yet expose a dedicated `datePillText` field per day. To keep the pass scoped, the card derives the single-date pill from the selected `FajrWindowPoint.date` using the same Gregorian and adjusted Hijri helpers already used by the range pill.

Fallback behavior:

- If Hijri text is available and fits, render `Gregorian | Hijri`.
- If preferred Hijri text does not fit, use the compact Hijri token.
- If Hijri text is unavailable, render the Gregorian date only.

## Interaction

The card sets local pill inspection state when existing chart callbacks select or move focus. Touch release clears that local state before forwarding the existing snap-back callback. Accessibility increment/decrement leaves the pill in date mode so the inspected day can remain audible/visible, matching the v8 accessibility note.

## Non-Goals

- Do not alter chart geometry, v7 spacing, y-axis labels, marker behavior, footer copy, snapshot generation, or alarm scheduling.
- Do not add a new persistent selected date.
- Do not recompute or recenter the visible seven-day window from pill changes.
