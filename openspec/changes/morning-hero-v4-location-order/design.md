## Context

The v0.3 hero already receives resolved wake, relation, Fajr begin/end, and adjuster eligibility from `MorningHomePresentation`. The schedule rows also carry a `locationDescription`, but the home hero did not surface it and still used the visible date row as the first row.

## Decisions

1. **Keep date data resolved but hide it in SwiftUI.**
   `MorningHomeHeroDisplay.dateLine` remains available for future reactivation and tests, but `TomorrowMorningHero` no longer renders that field in the visible stack.

2. **Pass location as display data, not as UI inference.**
   `MorningHomeHeroDisplay` exposes `locationText` and an optional `locationIconName`. `ScheduleManager` provides the current prayer-time location label and whether it is automatic/current-location mode.

3. **Keep the Fajr adjuster behavior unchanged.**
   The visual moves above the relation line, but drag mapping, live primary-time updates, relation updates, clamping, accessibility adjustment, and commit-on-release stay on the existing v0.3 path.

4. **Use calm fallbacks.**
   If a human-readable location is not available, the display falls back to `Current location`, `Location unavailable`, or `Choose location` rather than showing coordinates.

## Risks / Trade-offs

- The schedule model currently stores a single human-readable location description for all days in the active window. That is appropriate for the current single-location settings model.
- If reverse geocoding is delayed in automatic mode, the hero may briefly show `Current location` until the service supplies a neighborhood or city name.
