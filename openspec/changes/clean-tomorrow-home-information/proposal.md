## Why

The weather-style home hero looked visually calmer, but it still spent prime space repeating labels, ordinary/default context, and provider diagnostics. The primary home should answer "what do I need to know for tomorrow morning?" immediately, with deeper trust details available in supporting surfaces.

## What Changes

- Simplify the home hero to show tomorrow identity, compact date, wake time, meaningful status, and the shortest useful wake relationship.
- Suppress ordinary/default context and provider diagnostic copy from the hero unless it represents actionable degraded state.
- Keep context chips only when they add meaningful, non-redundant context.
- Default Weekly Fajrcast selection to tomorrow and avoid repeating the selected wake relationship in its footer copy.
- Make Morningcast forward-looking by excluding today and tomorrow from the home list and using compact rows with exception-only subtitles.
- Preserve existing schedule, alarm, permission, and morning-resolution behavior.

## Capabilities

### New Capabilities

### Modified Capabilities
- `single-screen-morning-home`: Refine the primary home information hierarchy so tomorrow is clear, non-redundant, and supported by non-repeating forecast surfaces.

## Impact

- Affects SwiftUI home presentation, home presentation models, Morningcast snapshot filtering, compact Fajrcast summary selection, and focused presentation tests.
- Does not change prayer-time calculation, wake-resolution logic, scheduling, alarm delivery, persisted settings, or existing scheduled alarms.
