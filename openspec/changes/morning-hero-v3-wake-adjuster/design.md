## Context

The current hero consumes `MorningHomeHeroDisplay` from `MorningHomePresentation` and renders a static v0.2 Fajr range row in `SubhHomeView`. Wake resolution and date-specific overrides already live outside SwiftUI in `DailyAlarmOverride`, `MorningWakeRule`, `ActiveDayResolver`, `DayScheduleBuilder`, and `ScheduleManager`.

The v0.3 change crosses presentation, interaction, and schedule persistence:

- `Subh/Features/Home/MorningHomePresentation.swift` owns hero display fields, date text, range eligibility, and relation copy.
- `Subh/Features/Home/SubhHomeView.swift` owns SwiftUI layout, drag state, local transient display, and accessible adjustment actions.
- `Subh/Core/Services/ScheduleService.swift` coordinates date-specific override persistence and rescheduling.
- `Subh/Core/Services/AlarmConfigStore.swift` already stores `DailyAlarmOverride` entries.
- Tests should cover presentation contract and engine-backed override persistence.

## Goals / Non-Goals

**Goals:**
- Use full Gregorian and full Hijri month names in the hero date row.
- Hide the Fajr window visual when the target day is fasting, missing Fajr end, or the wake anchor is outside the Fajr begin/end window.
- Render eligible within-Fajr rows with endpoint circles and an alarm/off-state icon marker.
- Enable drag and accessibility adjustment only for active within-Fajr wake alarms.
- Update the primary wake time and relation text locally while dragging.
- Persist the release value as a date-specific fixed wake override, then re-resolve through `ScheduleManager.rescheduleDay`.

**Non-Goals:**
- Do not change the default wake rule, calculation method, Fajr-end source, or scheduled-date source model.
- Do not define the future fasting-day alternative visual.
- Do not support alarm creation from no-alarm rows in this change.
- Do not make out-of-window wake times interactive until a future alternate treatment is specified.
- Do not add new dependencies or a new global editing engine.

## Decisions

1. **Represent hero range eligibility in presentation.**
   `MorningHomePresentation` will expose a small visual mode enum so SwiftUI can render or hide the row without recomputing product eligibility. The mode is derived from resolved day context, Fajr begin/end availability, wake state, and the marker ratio.

2. **Keep transient drag state in the hero view.**
   The SwiftUI hero can hold a temporary wake date while a drag is active. The presentation layer provides helpers for formatting a tentative wake and relation against the already-resolved Fajr window, avoiding prayer calculation inside the view.

3. **Persist release values as date-specific fixed wake overrides.**
   A drag result is an override for the most immediate morning, not a new default. `ScheduleManager` will expose a focused method that writes a `DailyAlarmOverride` with `wakeStateOverride = .fixedWake`, `fixedWakeTimeOverrideMinutesFromMidnight`, and `bypassLatestWakeCap = true`, then reschedules only that date.

4. **Clamp interaction to the resolved Fajr window.**
   Dragging and accessible increment/decrement clamp to Fajr begin/end and use minute steps. This keeps the v0.3 control inside the specified within-Fajr treatment and avoids inventing an out-of-window behavior.

5. **Do not let the hero button steal adjustment gestures.**
   The hero remains tappable for details, but the range adjuster owns its drag gesture and exposes its own accessibility adjustable control when enabled.

## Risks / Trade-offs

- **Risk: Saving a fixed wake override changes relation copy from relative-to-Fajr to custom wake.** -> Mitigation: live drag uses relation text for feedback; after persistence, the engine truthfully reports a date-specific fixed wake unless a later rule type preserves relative in-Fajr offsets.
- **Risk: Rebuilding only one date may miss a broader context change.** -> Mitigation: use the existing `rescheduleDay` path, which rebuilds the active day and schedules/cancels only if that date is in the scheduled window.
- **Risk: The draggable icon can be difficult to hit at small visual sizes.** -> Mitigation: render a small calm glyph but give it a minimum 44 pt hit target.
- **Risk: Fasting or out-of-window days could look like missing data if hidden without explanation.** -> Mitigation: keep the relation line visible and hide only the fifth-row visual, with accessibility summary still including Fajr begin/end when available.
