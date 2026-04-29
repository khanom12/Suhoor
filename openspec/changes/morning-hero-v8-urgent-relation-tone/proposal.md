## Why

The v0.8 Morning Hero keeps endpoint-specific relation copy, but changes the red treatment. Red is no longer an endpoint marker; it is an urgency warning only when the wake time leaves 10 minutes or less before Fajr ends.

## What Changes

- Keep `Wake up as Fajr begins` and `Wake up as Fajr ends` endpoint copy.
- Use normal relation styling for Fajr-begin endpoint wakes unless the whole Fajr window is 10 minutes or less.
- Use urgent red styling for active wake relations when the rounded whole-minute difference to Fajr end is 10 minutes or less.
- Use the app's semantic danger/critical color instead of arbitrary red.
- Preserve state copy for off, no-alarm, quiet, missing-Fajr, and unavailable hero states.

## Capabilities

### Modified Capabilities

- `single-screen-morning-home`: The Morning Hero relation line uses v0.8 urgent-red semantics while preserving endpoint-aware relation copy and final-row placement.

## Impact

- Affected code:
  - `Subh/Features/Home/MorningHomePresentation.swift`
  - `Subh/Features/Home/SubhHomeView.swift`
  - Focused presentation, schedule-manager, and UI assertions
- No prayer-time calculation behavior changes.
- No persistence or override policy changes.
- No new production dependency.
