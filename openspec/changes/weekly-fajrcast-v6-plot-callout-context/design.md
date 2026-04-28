## Overview

This change applies the v6 Weekly Fajrcast refinements while keeping the centered seven-day window, snap-back interaction, static overlay, y-axis right alignment, and v5 footer visual treatment intact.

## Plot Height

The compact chart's standard plotted scale height changes from 150 pt to 144 pt. This height is still stable across the seven standard text-size stops. Accessibility stops keep a height at or above 144 pt and may grow for legibility.

The reduction must come from the plotted scale area itself. It must not collapse:

- the top focused-callout breathing space
- the x-axis-to-bottom-divider breathing space
- footer padding or footer text sizing

## Focused Callout Breathing

The v6 spec requires the focused callout to feel balanced between the top divider and the plot boundary. The SwiftUI implementation does not have direct font metric measurement at this layer, so it will use the same dynamic type scale profile to estimate the callout block height from its label and time/status fonts.

For each Dynamic Type stop, the chart reserves:

- a top gap before the callout block
- the estimated callout block height
- a bottom gap before the plot boundary

The gaps use v6's stop-specific targets:

- 8 pt for smaller standard stops
- 10 pt at the default stop
- 12 pt for larger standard stops
- accessibility stops use at least 12 pt and grow with the scaled callout line height

The compact chart height becomes `max(stopMinimumChartHeight, measuredCalloutBand + staticPlotScaleHeight + xAxisLineHeight + xAxisBottomSpacing)`. This follows the v6 rule that measured content wins over the minimum guardrail.

## Footer Context

The renderer should prefer precomposed footer strings. The data layer already produces a focused-day secondary footer line and applies context prefixes in priority order: Ramadan, fasting, Tahajjud, adjusted.

This change will add test coverage to lock the focused adjusted-day behavior so secondary footer context is not replaced by a generic global alarm sentence.

Quiet/no-alarm is not yet represented as a separate alarm state in the current model. Existing off/skipped days remain expressed as off for the focused date.

## Non-Goals

- Do not change centered seven-day anchoring, temporary inspection, or snap-back behavior.
- Do not add new alarm-state schema for quiet/no-alarm days in this pass.
- Do not change alarm scheduling, persistence, or notification reliability behavior.
- Do not add inline `FAJR BEGINS` / `FAJR ENDS` chart labels.
