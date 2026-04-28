## Overview

This change applies the v7 Weekly Fajrcast spacing model without changing the data contract, centered seven-day anchoring, temporary inspection, snap-back behavior, static past overlay, y-axis right alignment, or footer-context generation.

## Standard Guardrails

The seven standard text-size stops use the v7 card/chart/profile values:

| Stop | Card min | Chart min | Static plot | Rail min |
|---|---:|---:|---:|---:|
| xSmall | 260 | 184 | 128 | 40 |
| small | 262 | 184 | 128 | 42 |
| medium | 264 | 186 | 128 | 44 |
| large/default | 266 | 188 | 128 | 46 |
| xLarge | 278 | 194 | 128 | 52 |
| xxLarge | 290 | 202 | 128 | 58 |
| xxxLarge | 304 | 210 | 128 | 64 |

Accessibility sizes continue to use measured growth. They preserve at least the v7 plot height and grow only when scaled labels need the room.

## Spacing Model

The compact chart height remains measured as the maximum of the stop minimum and the required content stack:

`calloutBand + staticPlotScaleHeight + plotToXAxisGap + xAxisLineHeight + xAxisBottomSpacing`

Where:

- `staticPlotScaleHeight` is 128 pt for the seven standard stops.
- `calloutBand` uses the measured callout block plus compact equal breathing:
  - 4 pt per side for smaller stops.
  - 5 pt per side at the default stop.
  - 6 pt per side for larger standard stops.
  - accessibility uses `max(6, 0.28 * scaledCalloutLineHeight)`.
- `plotToXAxisGap` is separate from footer breathing:
  - 3 pt for smaller stops.
  - 4 pt at the default stop.
  - 5 pt for larger standard stops.
  - accessibility uses `max(5, 0.25 * scaledXAxisLineHeight)`.
- `xAxisBottomSpacing` keeps the v5/v6 divider breathing rule.

The removed v6 graph and callout height must not return as unrelated blank padding.

## Non-Goals

- Do not change snapshot generation or footer-context copy.
- Do not alter marker, band, guide, y-axis, snap-back, or navigation behavior.
- Do not touch alarm scheduling, persistence, notifications, or reliability diagnostics.
