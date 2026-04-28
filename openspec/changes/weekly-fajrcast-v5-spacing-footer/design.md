## Overview

This change applies the v5 Weekly Fajrcast card sizing and footer refinements without changing the data contract, centered seven-day window, snap-back interaction model, or alarm scheduling behavior.

## Layout Guardrails

The compact card and chart keep the seven-stop Dynamic Type profile introduced for the Weekly Fajrcast, but update the minimum sizes to the v5 values:

| Stop | Card min | Chart min | Static plot | Rail min |
|---|---:|---:|---:|---:|
| xSmall | 282 | 206 | 150 | 40 |
| small | 284 | 206 | 150 | 42 |
| medium | 286 | 208 | 150 | 44 |
| large/default | 288 | 210 | 150 | 46 |
| xLarge | 302 | 216 | 150 | 52 |
| xxLarge | 314 | 224 | 150 | 58 |
| xxxLarge | 328 | 232 | 150 | 64 |

Accessibility sizes remain taller than the standard stops so scaled text can grow without clipping. The chart is still allowed to exceed the minimum height if measured text, footer wrapping, or the surrounding layout requires more room.

## Chart Breathing Space

The compact chart layout should reserve explicit space between the x-axis weekday label line box and the bottom edge of the chart frame, which sits above the card's bottom divider.

The implementation will:

- Lower the compact plot top enough to support the 150 pt plot scale within the v5 chart height.
- Treat x-axis labels as a real line box rather than a loose point offset.
- Reserve stop-specific bottom breathing space:
  - 8 pt for smaller standard stops.
  - 10 pt for the default stop.
  - 12 pt for larger standard stops.
  - Accessibility sizes use at least 12 pt and grow with scaled axis text.

If a future measured layout needs more room, the card should grow before the x-axis-to-divider spacing is compressed.

## Footer Treatment

Footer hierarchy comes from line order and wording, not type weight, size, or opacity. The primary and secondary footer lines should both use:

- base 13 pt scaled text
- regular weight
- full-opacity white

Context prefixes such as Ramadan, fasting, Tahajjud, and adjusted text inherit the same full-opacity style.

## Non-Goals

- Do not change the Weekly Fajrcast data model or snapshot generation.
- Do not change centered seven-day anchoring, temporary inspection, or snap-back behavior.
- Do not add inline `FAJR BEGINS` / `FAJR ENDS` labels.
- Do not change alarm scheduling, persistence, or notification reliability behavior.
