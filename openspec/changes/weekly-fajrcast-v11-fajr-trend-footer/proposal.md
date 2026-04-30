## Why

The Weekly Fajrcast v10 footer still explained alarm-plan and generic fasting context, which made the compact card feel too much like a schedule summary and not enough like a Fajr-window forecast. The v11 spec narrows the footer to the weekly Fajr-begin trend plus only deliberately surfaced special non-Ramadan fasting opportunities.

## What Changes

- Replace the compact footer primary line with a plain-language Fajr-begin trend across the anchored seven visible days.
- Suppress default-alarm, adjusted, quiet, no-alarm, routine fasting, White Days, Ramadan, and generic negative fasting copy from the compact visible footer.
- Keep optional footer secondary text only for qualifying special non-Ramadan Sunnah fasting observances such as Arafah, Ashura, or Dhul Hijjah opportunities.
- Increase the default card minimum-height guardrails and footer bottom breathing space from the v11 spec.
- Balance the bottom focused-day callout closer to the footer divider by reducing the chart bottom-callout spacing.
- Preserve focused-day Fajr begin/end detail in accessibility and keep scrubbing/snap-back behavior unchanged.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Weekly Fajrcast compact footer content and spacing requirements change from v10 alarm/fasting summary behavior to v11 Fajr-trend/special-opportunity behavior.

## Impact

- Affected SwiftUI presentation: `Subh/Features/Wake/FajrWindowCompactCard.swift`, `Subh/Features/Wake/FajrWindowChartView.swift`.
- Affected snapshot generation: `Subh/Core/Services/FajrWindowSurfaceProvider.swift`.
- Affected tests: `SubhTests/ScheduleServiceExtractionTests.swift`.
- No persistence, alarm scheduling, cached schedule, or migration behavior is changed.
