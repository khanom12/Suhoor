## Why

The v0.7 Morning Hero keeps the compact v0.6 Fajr-end relation for ordinary wake positions, but calls out exact Fajr-window endpoints with clearer copy and red text. This makes endpoint scrubs feel intentional instead of showing `0 min before Fajr ends` or a large minute count at Fajr begin.

## What Changes

- Use `Wake up as Fajr begins` when the active or tentative wake time is exactly at Fajr begin.
- Use `Wake up as Fajr ends` when the active or tentative wake time is exactly at Fajr end.
- Keep `Wake up {X} min before Fajr ends` for non-endpoint active wake positions.
- Render endpoint relation text in red while keeping non-endpoint relation text in the existing secondary treatment.
- Preserve off, no-alarm, missing-Fajr, quiet, and unavailable state copy.

## Capabilities

### Modified Capabilities

- `single-screen-morning-home`: The Morning Hero renders v0.7 endpoint-aware relation copy and endpoint red tone while preserving the existing location-first layout and Fajr adjuster behavior.

## Impact

- Affected code:
  - `Subh/Features/Home/MorningHomePresentation.swift`
  - `Subh/Features/Home/SubhHomeView.swift`
  - Focused presentation and UI tests
- No prayer-time calculation behavior changes.
- No persistence or override policy changes.
- No new production dependency.
