## Why

Subh now depends on one consistent answer to “when is the wake?” across Tomorrow Morning, Morningcast, Fajrcast, scheduling, detail views, and cached data. Legacy Suhoor-era code still contains isolated Fajr-start offset calculations, which can create visual drift, stale rows, and harder-to-debug performance work.

## What Changes

- Make `MorningScheduleResolver` the singular authority for resolving wake anchors, wake times, and resolved wake state.
- Convert compatibility builders and presentation fallbacks so they consume resolver output or already-resolved schedule snapshots instead of recomputing independent Fajr-start offsets.
- Preserve caching, but require schedule caches to be treated as resolver output snapshots that are invalidated when wake-rule inputs change.
- Keep first-wave MVP UX focused on the current Subh default rather than exposing legacy pre-Fajr wake customization as a competing primary path.
- Document the remaining legacy areas that are allowed to exist temporarily only as compatibility/persistence surfaces, not as wake-time authorities.

## Capabilities

### New Capabilities
- `single-source-wake-resolution`: Ensures all app surfaces and scheduling paths derive wake timing from one resolver-owned pathway.

### Modified Capabilities
- `morning-resolution`: Clarifies that morning resolution is the only source of truth for wake timing.
- `fajr-end-mvp-wake`: Clarifies that Fajr-end minus 30 must propagate through all display, schedule, and cache consumers.

## Impact

- Affected code: `MorningScheduleResolver`, `DayScheduleBuilder`, schedule cache loading/saving, Morningcast/Tomorrow detail presentation, and tests around alarm configuration and home snapshots.
- Existing cached schedules are safe to discard and rebuild when their wake-rule signature does not match current defaults.
- Persisted user settings and the preserved `Suhoor.*` storage namespace are not wiped by this change.
