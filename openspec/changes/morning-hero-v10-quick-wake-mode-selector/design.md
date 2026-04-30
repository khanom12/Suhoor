# Design

## Canonical State
Add a `QuickWakeMode` domain enum with three user-facing modes:

- `fast`: active wake 30 min before Fajr begins.
- `fajr`: active wake 30 min before Fajr ends.
- `quiet`: no wake alarm rings for the target morning.

Daily overrides store the explicit quick mode. `EffectiveDailyConfig` exposes that explicit selection so all presentation surfaces can resolve from the same state.

## Intent Flow
The hero emits a mode-selection intent to `ScheduleManager`:

```text
Hero segment tap
  -> ScheduleManager.selectHeroWakeMode(for:mode:)
  -> daily override mutation
  -> rescheduleDay(preferCached: false)
  -> activeWindowSnapshot didSet
  -> hero, Weekly Fajrcast, next 10 mornings refresh
```

The SwiftUI view never creates, cancels, or schedules alarms directly.

## Mode Mutations
`Fajr`:

- Clears quiet state.
- Sets wake rule to `.inFajr`, anchor `.fajrEnd`, delta `30`.
- Enables the wake alarm path for the target morning.

`Fast`:

- Clears quiet state.
- Sets wake rule to `.preFajr`, anchor `.fajrStart`, delta `30`.
- Enables the wake alarm path for the target morning.
- Marks the day as selected fast for wake-planning display; it does not create a recurring fasting rule.

`Quiet`:

- Persists `quickWakeModeOverride = .quiet`.
- Suppresses wake/reminder/Fajr-boundary alarms for the target morning.
- Keeps the day resolvable so the hero can display Fajr begin/end boundaries.

## Presentation
`MorningHomePresentation` resolves a selected quick segment from the active day:

1. explicit quick mode override;
2. intended fasting/Tahajjud contexts map to `Fast`;
3. fallback maps to `Fajr`.

Existing skipped/off-with-anchor days remain in the existing alarm-off taxonomy unless the target morning has an explicit `quickWakeModeOverride = .quiet`. This keeps the new selector from silently relabeling older off days as Quiet mode.

Quiet mode uses:

- primary text `Quiet mode on`;
- relation text `No alarm will ring for {relative day}`;
- static Fajr begin -> Fajr end range when Fajr data is available;
- no marker and no adjustable control.

Fast mode uses the early-worship window when final-third data is available. Fajr mode uses the default Fajr begin -> Fajr end window.

## Downstream Surfaces
Because selection rebuilds the active day and refreshes `activeWindowSnapshot`, Weekly Fajrcast and next-ten rows see the updated wake date, disabled state, and override marker. Next-ten rows use the same selected mode to show quiet/fast semantics instead of deriving a second state.
