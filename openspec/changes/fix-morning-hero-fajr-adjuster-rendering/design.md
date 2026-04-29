# Design

## Eligibility Correction

The Fajr row hide gate will distinguish true fasting mornings from ordinary early wake mornings:

- Hide for primary/secondary `.fasting`, `.qadaFast`, and `.sunnahFast`.
- Hide for fasting tags such as Ramadan, Qada, Kaffarah, Vow, and voluntary fasts.
- Do not hide for `.suhoor` alone.

The rest of the v0.3 eligibility remains unchanged: missing Fajr end hides the bar, and active wakes outside Fajr begin/end hide the within-Fajr adjuster.

## Testable Interaction Surface

The Fajr row will expose stable identifiers for UI automation and keep row semantics visible:

- `morningHero.primaryWakeTime`
- `morningHero.relation`
- `morningHero.fajrWindow`
- `morningHero.fajrWindow.beginTime`
- `morningHero.fajrWindow.track`
- `morningHero.fajrWindow.marker`
- `morningHero.fajrWindow.endTime`

The row should be accessible as meaningful hero content, while the adjustable action remains available only when `wakeAdjustmentEnabled` is true.

## Drag Mapping

Drag position will be mapped by a deterministic helper:

- Clamp the x-coordinate to `[0, trackWidth]`.
- Convert to a ratio over the resolved Fajr begin/end duration.
- Round to the configured minute step.
- Clamp the resulting date to Fajr begin/end.

This helper will be unit tested independently of SwiftUI gesture delivery.

## UI Test Fixture

In debug builds only, a launch argument will seed a deterministic configured home state:

- fixed Toronto location
- default active in-Fajr wake rule
- onboarding/configuration complete
- no fasting preset enabled

This fixture exists solely for UI automation and will not run in normal production launches.

