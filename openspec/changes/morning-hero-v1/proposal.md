## Why

The home hero is the first answer to "what does tomorrow morning look like?", but it currently reads more like a compact alarm preview. The v0.1 Morning Hero should make the resolved Fajr-centered morning explicit by showing the target day, Gregorian and Hijri date, wake state, relation to the exact Fajr boundary, and the Fajr begin/end window.

## What Changes

- Add a Morning Hero presentation contract for the home snapshot with preformatted date, wake, relation, Fajr-window, icon, and accessibility text.
- Render the home hero as a centered five-row summary: relative day, Gregorian/Hijri date line, primary wake time or state, wake relation/status line, and Fajr begin/end line.
- Show Hijri date when available using the `•` delimiter, with a Gregorian-only fallback.
- Ensure active, off, no-alarm, quiet, and unavailable wake states are visibly and accessibly distinct.
- Keep Fajr begin/end values sourced from the resolved home snapshot/data layer; SwiftUI must not invent Fajr end times or relation offsets.
- Scale all readable hero text with the seven standard iPhone text-size stops and allow measured content to grow the hero region and push the Weekly Fajrcast card down.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `single-screen-morning-home`: The Tomorrow Morning hero requirements change from a compact alarm preview to the v0.1 Morning Hero summary.

## Impact

- Affected code:
  - `Subh/Features/Home/MorningHomeSnapshot.swift`
  - `Subh/Features/Home/MorningHomePresentation.swift`
  - `Subh/Features/Home/SubhHomeView.swift`
  - Focused home/presentation tests under `SubhTests/`
- No persisted settings, cached schedules, scheduled alarms, notification identifiers, storage namespaces, calculation methods, or alarm delivery behavior are changed.
- This is a presentation/data-contract refinement for the existing single-screen home surface.
