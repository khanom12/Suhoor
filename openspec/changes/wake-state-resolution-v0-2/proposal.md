## Why

The v0.2 wake-state specification makes explicit that Subh needs one resolved wake-state structure, not separate interpretations for quick selection, hero visuals, alarm activation, copy, and scheduling. The app already has most of the underlying pieces, but they need to be composed into one auditable domain payload so future Fajr, Fast, Quiet, Ramadan, Qada, Sunnah, and Tahajjud work does not fork the wake engine.

## What Changes

- Add a canonical `ResolvedMorningWakeState` domain model that separates day context, boundary regime, wake-time origin, alarm activation, schedule status, visual mode, and copy state.
- Add a resolver/service that derives that payload from an `ActiveAlarmDay` and the existing resolver-owned schedule/decision log output.
- Keep `Fast | Fajr | Quiet` as the hero quick selector while representing Quiet as an activation overlay that preserves the underlying Fajr or early-worship mode.
- Route hero presentation and wake-adjustment window decisions through the resolved wake-state payload instead of re-deriving boundary and copy fragments independently.
- Add focused tests for the v0.2 cases that are most likely to regress: Fajr default, Fast default, Quiet preservation, opportunity-only behavior, Tahajjud/fasting early-worship boundaries, manual adjustment origin, and schedule/permission status separation.

## Capabilities

### New Capabilities

- `wake-state-selection-resolution`: Defines the canonical resolved morning wake-state payload and the domain resolver that owns quick selection, boundary regime, activation, schedule status, visual mode, and copy-state composition.

### Modified Capabilities

- `single-source-wake-resolution`: Clarifies that resolver output must include wake-state semantics, not only raw wake time and schedule projections.
- `morning-resolution`: Adds the resolved morning wake state as the domain handoff consumed by surface snapshots and scheduler handoff.
- `fajr-end-mvp-wake`: Preserves the Fajr-end minus 30 default while tracking origin and activation separately from schedule results.

## Impact

- Affected code: morning domain models, `WakeStateSelectionResolver`, home presentation mapping, hero wake adjustment commit/window logic, and focused domain/presentation tests.
- Existing scheduled alarms are regenerated through the current centralized reschedule path; this change does not add a new scheduler or cancel unrelated alarms.
- Existing persisted settings and the preserved `Suhoor.*` storage namespace remain compatible. The new model is derived from existing schedule/override state rather than requiring a destructive migration.
