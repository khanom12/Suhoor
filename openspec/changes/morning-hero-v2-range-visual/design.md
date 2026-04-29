## Context

The home hero currently consumes `MorningHomeHeroDisplay` from `MorningHomePresentation` and renders the v0.1 five-row layout. It already avoids prayer-time calculation in SwiftUI and has focused tests in `SubhTests/ScheduleServiceExtractionTests.swift`.

This change affects:

- `Subh/Features/Home/MorningHomePresentation.swift`
- `Subh/Features/Home/SubhHomeView.swift`
- `SubhTests/ScheduleServiceExtractionTests.swift`

No services, stores, scheduling adapters, prayer-time calculators, or persistence models need to change.

## Goals / Non-Goals

**Goals:**

- Update the hero presentation model with weekday-free date text, compact Hijri token, Fajr begin/end display text, optional marker ratio, indicator state, and accessibility text.
- Render the v0.2 order: date, relative day, primary wake row, secondary relation line, and compact Fajr range visual.
- Make the Fajr range visual feel native and restrained: time labels flank a subtle track, with a wake/off-anchor marker positioned from resolved times.
- Preserve missing-data honesty by hiding the range visual when Fajr begin/end data is unavailable.
- Add focused tests for date formatting, marker ratio, missing data, and inactive state behavior.

**Non-Goals:**

- Do not change Fajr calculation, Fajr-end source, wake scheduling, alarm delivery, or user settings.
- Do not add a chart, card, badge, or decorative weather-style surface inside the hero.
- Do not introduce a new dependency or animation system.

## Decisions

1. **Derive marker ratio only from resolved dates in presentation.**
   `MorningHomePresentation` will compute `(wake - fajrStart) / (fajrEnd - fajrStart)` only when wake/planned-anchor, Fajr begin, and Fajr end are all present. Ratios below `0` or above `1` are preserved so the renderer can show an overflow marker instead of lying by clamping silently.

2. **Use a bespoke SwiftUI range row rather than a chart component.**
   The range visual is a small semantic control, not a forecast chart. A local view can keep it centered, compact, and accessible while avoiding the visual and architectural weight of reusing Weekly Fajrcast chart pieces.

3. **Use state-specific marker treatment.**
   Active alarms use a filled marker. Off-with-anchor uses a hollow marker. No-alarm/unavailable states show no marker. Overflow wakes use a distinct edge treatment outside the track bounds when space allows.

4. **Keep accessibility textual and complete.**
   The visible visual row omits `Fajr begins`/`Fajr ends` labels, so `MorningHomeHeroDisplay` continues to expose full Fajr-window accessibility text in the coherent hero summary.

## Risks / Trade-offs

- **Risk: A tiny visual marker could feel decorative instead of informative.** → Mitigation: keep the marker high-contrast, close to the relation text, and pair it with exact begin/end time labels.
- **Risk: Overflow wake times can be hard to represent in compact width.** → Mitigation: preserve unclamped ratios in data and render an edge marker with distinct placement/treatment when the ratio falls outside `0...1`.
- **Risk: Long localized time/date strings may crowd the one-line visual.** → Mitigation: use flexible track width, multiline-safe hero growth, and keep the full meaning in accessibility.
