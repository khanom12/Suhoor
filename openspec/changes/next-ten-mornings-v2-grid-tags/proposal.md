## Why

The v2 forecast specification tightens the Next 10 Mornings contract after the first implementation pass. The card now needs stable row-grid alignment and an explicit Fajr anchor on opportunity-only mornings so the forecast reads as a calm Fajr-centered system rather than a row-by-row tag list.

## What Changes

- Update opportunity-only tag resolution so non-intended Sunnah opportunities render as `[Fajr]` plus compatible opportunity tags.
- Add a shared three-lane row grid for date, centered tags, and trailing wake time/status so tag clusters align across all visible forecast rows.
- Preserve the compact no-subtitle row contract, existing glass shell, row tap navigation, and full accessibility meaning.
- Add focused tests for the v2 tag doctrine and shared row layout metrics.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: Refine the Next 10 Mornings card requirements for opportunity-only Fajr anchoring and shared centered tag-lane alignment.

## Impact

- Affects `Subh/Features/Home/MorningHomePresentation.swift`, `Subh/Features/Home/SubhHomeView.swift`, focused presentation tests, and OpenSpec artifacts.
- No changes to persisted settings, cached schedules, alarm delivery semantics, prayer-time calculation, or scheduled alarm identifiers.
