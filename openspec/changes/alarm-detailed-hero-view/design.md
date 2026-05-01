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
6. One liquid-glass context card below the hero for day significance and any mode-specific controls.
7. A compact purpose control in the context card only when Early needs purpose, limited to Fast or Tahajjud.
8. A compact fast-purpose control in the context card only for Early + Fast, locked to Ramadan fast during Ramadan.
9. A single Fajr-adhan-after-wake toggle only for non-Ramadan Early + Fast.

The screen keeps the same app background and liquid-glass treatment as the home screen so it reads as one product surface.

## State Flow
- Build presentation from the selected day snapshot and existing active-day resolver helpers.
- Preview slider movement locally for immediate time/relative-text updates.
- Commit drag release through the existing day-specific wake adjustment path.
- Commit mode changes through `ScheduleManager` quick-mode selection so downstream snapshots and scheduling reconcile normally.
- Re-resolve after persistence rather than keeping a separate detail-screen source of truth.

## Purpose Handling
`Early` replaces the older user-facing `Fast` label in this detail surface because the state may represent fasting or Tahajjud. The selectable purpose set is intentionally small: Fast and Tahajjud. Legacy combined purpose data may still decode, but the UI must not present Fast + Tahajjud as an option.

## Fast Purpose Handling
When Early is for Fast, the screen presents all applicable fasting opportunities for the selected date as the default fast purpose. If there are no opportunities, the default is Voluntary fast. Ramadan is locked to Ramadan fast. Non-Ramadan dates can choose a date-specific override such as Qada fast, Voluntary fast, or Other fast without changing global observance settings.

## Audio Handling
The detail screen does not expose broad audio choice UI in v3. The only user-editable audio-related control is a date-specific `Fajr adhan at Fajr begins` toggle for non-Ramadan Early + Fast. It maps onto the existing per-day Fajr boundary event field and lets the existing resolver/scheduler regenerate events. Selecting Fajr adhan as the Fajr-mode wake sound must still leave the wake alarm enabled; Quiet is the only mode that turns the wake alarm off.

## Quiet and Ramadan
Quiet mode uses `Quiet Mode` as the primary display and keeps the hero layout stable by reserving the slider region. Outside Ramadan, Quiet suppresses wake and Fajr audio for the date. During Ramadan, Quiet suppresses the pre-Fajr wake alarm while preserving the Fajr adhan.

## Accessibility
The hero exposes a concise accessibility summary. The date line includes both calendars, the slider supports standard adjustment actions, the mode selector exposes selected state, and Quiet mode clearly announces that no wake alarm will ring for the date.
