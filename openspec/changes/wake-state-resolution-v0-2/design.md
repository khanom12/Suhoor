## Context

Subh already resolves prayer windows, selected plans, wake anchors, wake times, schedules, quick wake modes, early-worship boundaries, and hero presentation. The remaining v0.2 gap is composition: the same morning can still be interpreted through separate fragments such as `QuickWakeMode`, `ResolvedWakeState`, `fajrWindowVisualMode`, `skipDay`, and schedule events.

The affected implementation areas are:

- `Subh/Core/Morning/Models/*` for canonical wake-state models.
- `Subh/Core/Morning/WakeStateSelectionResolver.swift` for quick state and context mapping.
- `Subh/Core/Scheduling/MorningResolver.swift` and `RuleDecisionLog` consumers for resolver-owned wake timing.
- `Subh/Features/Home/MorningHomePresentation.swift` and `Subh/Core/Services/ScheduleService.swift` for hero snapshot and adjustment-window consumers.
- `SubhTests/ScheduleServiceExtractionTests.swift` and focused morning-domain tests for behavior coverage.

## Goals / Non-Goals

**Goals:**

- Produce one `ResolvedMorningWakeState` payload for a visible morning.
- Keep Fajr, Fast, and Quiet states layered over one Fajr-centered morning engine.
- Represent Quiet as an activation overlay, preserving the underlying Fajr or early-worship boundary.
- Track wake-time origin and activation separately from schedule status.
- Let presentation and adjustment logic consume the resolved wake state rather than duplicating boundary decisions.

**Non-Goals:**

- Redesign the Morning Hero layout.
- Add full Ramadan, Qada, Sunnah fast, or Tahajjud planning surfaces.
- Add a new platform scheduler or replace existing AlarmKit/notification scheduling.
- Migrate persisted storage to a new schema in this change.
- Support custom out-of-range wake visuals beyond hiding the adjuster truthfully.

## Decisions

1. Add a derived domain model before persisted schema changes.

   `ResolvedMorningWakeState` is derived from `ActiveAlarmDay`, `RuleDecisionLog`, `DailyPrayerWindow`, and existing override/config state. This avoids a risky storage migration while giving all consumers a single structure to depend on.

2. Keep quick selection mutation in `WakeStateSelectionResolver`.

   The existing resolver already owns `Fast | Fajr | Quiet` write behavior. This change extends it with read-side resolution and helper values instead of moving quick selection into SwiftUI or `ScheduleService`.

3. Map current schedule evidence to schedule status conservatively.

   The current app can prove scheduled, quiet, no-anchor, and unavailable states from active-day data. Permission-blocked and failed schedule statuses are modeled now and can be supplied by the scheduler reconciliation path later without changing the surface contract.

4. Reuse `EarlyWorshipBoundaryResolver`.

   The final-third calculation remains centralized. The new resolver calls it and surfaces missing Maghrib/final-third as an unavailable early-worship boundary rather than inventing a value.

## Risks / Trade-offs

- [Risk] The first implementation derives per-mode restoration from existing overrides, but the current persisted override model has one fixed wake override per date. → Mitigation: keep the canonical model and tests explicit, preserve existing behavior, and avoid claiming independent per-mode persistence until storage is expanded.
- [Risk] Schedule failure and permission-blocked states may not be fully wired from platform callbacks yet. → Mitigation: model them as first-class statuses and add pure resolver tests so future scheduler reconciliation can set them without changing UI contracts.
- [Risk] Adding a new payload without replacing every consumer could leave duplicate logic alive. → Mitigation: update the hero and adjustment-window consumers in this change, and document any remaining compatibility paths as non-authoritative.
