## Why

The current home forecast still reads like a generic wake list: it uses the legacy two-line “10-Day Wake Forecast / Next 10 mornings” header and row subtitles that explain scheduling mechanics. The new Next 10 Mornings card should make the upcoming run of mornings easier to scan by showing only the date, compact state tags, and the resolved wake time.

## What Changes

- Replace the visible Morningcast card header with a single `NEXT 10 MORNINGS` eyebrow header.
- Replace visible row subtitles with a dedicated compact tag presentation that distinguishes Fajr fallback, Ramadan, intended fasting, Tahajjud, and fasting opportunities.
- Keep the forecast on the existing single Subh home surface and preserve row tap-to-detail navigation.
- Preserve the existing wake-resolution and prayer-time engines; this change consumes resolved day state and tag computation results without changing scheduling semantics.
- Add focused presentation tests for the tag resolver, header/title contract, Gregorian date labels, forbidden tag combinations, and accessibility meaning.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: The home forecast list changes from the legacy Morningcast presentation to the dedicated Next 10 Mornings card contract.

## Impact

- Affected SwiftUI presentation: `Subh/Features/Home/SubhHomeView.swift`.
- Affected presentation models: `Subh/Features/Home/MorningHomeSnapshot.swift`, `Subh/Features/Home/MorningHomePresentation.swift`.
- New focused tests: `SubhTests/NextTenMorningsPresentationTests.swift`.
- No new dependencies, persistence changes, alarm delivery changes, cached schedule changes, or prayer-time calculation changes.
