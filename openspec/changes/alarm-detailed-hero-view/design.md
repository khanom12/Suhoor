# Design

## Existing Boundary
The Home hero already owns the product pattern for wake-time presentation, boundary-relative copy, quick wake mode selection, and one-day wake-time adjustment. The detailed screen should consume the same resolved display state and mutate the same daily override fields rather than introducing screen-local scheduling behavior.

## User Experience
The detail screen is a single hero-like surface:

1. Gregorian and Hijri date line.
2. Primary wake time or quiet state.
3. Relative wake description.
4. Wake adjustment slider for active wake modes.
5. `Fajr | Early | Quiet` mode selector using the Home hero visual language.
6. A compact purpose control only when Early needs purpose, limited to Fast or Tahajjud.
7. A compact fast-type control only for Early + Fast, locked to Ramadan fast during Ramadan.
8. A compact audio control for active modes, distinguishing wake alarm and Fajr adhan without exposing delivery plumbing.

The screen keeps the same app background and liquid-glass treatment as the home screen so it reads as one product surface.

## State Flow
- Build presentation from the selected day snapshot and existing active-day resolver helpers.
- Preview slider movement locally for immediate time/relative-text updates.
- Commit drag release through the existing day-specific wake adjustment path.
- Commit mode changes through `ScheduleManager` quick-mode selection so downstream snapshots and scheduling reconcile normally.
- Re-resolve after persistence rather than keeping a separate detail-screen source of truth.

## Purpose Handling
`Early` replaces the older user-facing `Fast` label in this detail surface because the state may represent fasting or Tahajjud. The selectable purpose set is intentionally small: Fast and Tahajjud. Legacy combined purpose data may still decode, but the UI must not present Fast + Tahajjud as an option.

## Fast Type Handling
When Early is for Fast, the screen presents the date's strongest fasting opportunity as the default fast type. Ramadan is locked. Non-Ramadan dates can choose a date-specific override such as Qada fast, Voluntary fast, or Other fast without changing global observance settings.

## Audio Handling
The detail screen edits only date-specific wake alarm and Fajr adhan behavior. It maps compact UI choices onto the existing per-day `suhoorEnabled` and `fajrEnabled` override fields, then lets the existing resolver/scheduler regenerate events. It does not introduce a parallel audio delivery pipeline and it does not surface AlarmKit or notification fallback details.

## Quiet and Ramadan
Quiet mode uses `Quiet Mode` as the primary display and keeps the hero layout stable by reserving the slider region. Outside Ramadan, Quiet suppresses wake and Fajr audio for the date. During Ramadan, Quiet suppresses the pre-Fajr wake alarm while preserving the Fajr adhan.

## Accessibility
The hero exposes a concise accessibility summary. The date line includes both calendars, the slider supports standard adjustment actions, the mode selector exposes selected state, and Quiet mode clearly announces that no wake alarm will ring for the date.
