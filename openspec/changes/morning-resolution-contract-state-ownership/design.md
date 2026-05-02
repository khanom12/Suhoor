## Context

Subh is a SwiftUI iOS app whose product unit is the next Fajr-centered morning. Existing architecture already includes the right anchors: `MorningScheduleResolver`, `ResolvedDaySnapshot`, `MorningWakeResolutionService`, `ResolvedMorningWakeState`, `WakeStateSelectionResolver`, `EarlyWorshipBoundaryResolver`, `ResolvedDayPurpose`, materialized events, completion models, and delivery diagnostics. This change tightens the ownership boundaries between those anchors.

Current overlapping OpenSpec changes for wake resolution, day purpose, alarm pipeline diagnostics, Home Hero, Alarm Detail, Weekly Fajrcast, and Next 10 are marked complete. This change therefore modifies the existing `morning-resolution` capability instead of creating a duplicate capability. It is a system-layer contract, not a visual redesign.

Affected implementation anchors include:

- `Subh/Core/Scheduling/MorningResolver.swift`
- `Subh/Core/Morning/MorningWakeResolutionService.swift`
- `Subh/Core/Morning/WakeStateSelectionResolver.swift`
- `Subh/Core/Morning/EarlyWorshipBoundaryResolver.swift`
- `Subh/Core/Morning/Models/ResolvedDaySnapshot.swift`
- `Subh/Core/Morning/Models/DayPurposeModels.swift`
- `Subh/Core/Morning/DayPurposeResolver.swift`
- `Subh/Core/Morning/Models/MorningContextModels.swift`
- `Subh/Core/Morning/Context/MorningFastDomain.swift`
- `Subh/Core/Morning/Context/MorningTagComputationDomain.swift`
- `Subh/Core/Morning/Context/ResolvedDayContextResolver.swift`
- `Subh/Core/Morning/Planning/MorningPlanResolver.swift`
- `Subh/Core/Morning/Models/MorningPlanModels.swift`
- `Subh/Core/Scheduling/ScheduledDateSourceModels.swift`
- `Subh/Core/Morning/State/MorningStateSnapshot.swift`
- `Subh/Core/Morning/Models/CompletionModels.swift`
- `Subh/Core/Morning/Completion/DailyCompletionResolver.swift`
- alarm scheduling, notification, and AlarmKit coordinators
- Home Hero, Alarm Detail, Weekly Fajrcast, and Next 10/Morningcast providers and views
- XCTest coverage for scheduling, wake-state resolution, day-purpose resolution, completion, alarm delivery, and static architecture guardrails

## Goals / Non-Goals

**Goals:**

- Preserve one canonical pipeline from prayer-window inputs to `ResolvedDaySnapshot` and `ResolvedMorningWakeState`.
- Keep day meaning, user intention, wake boundary, wake time, alarm activation, delivery status, and completion credit as separate modeled concepts.
- Route SwiftUI interactions through domain intents rather than direct override writes, direct scheduling, or local prayer-boundary math.
- Make date-specific overrides preserve global defaults and keep Quiet Mode as an overlay with underlying-mode restoration.
- Make scheduler handoff consume resolved materialized events and return delivery diagnostics without redefining intent.
- Add tests for default Fajr, Fast, opportunity-only, Quiet restoration, Ramadan, Qada, Tahajjud, manual drag, endpoint copy, urgent tone, Fajr adhan audio, later Fajr toggle, permission-blocked delivery, missing boundaries, DST/timezone, preview behavior, date-specific detail edits, and static view guardrails.

**Non-Goals:**

- No visual redesign or new primary surface.
- No separate Ramadan, Qada, fasting, Tahajjud, or Quiet engine.
- No new prayer-time provider policy beyond preserving canonical ownership.
- No new remote telemetry or production dependency.
- No broad rewrite of completed surface work when adapter-level fixes are enough.

## Decisions

### Decision: Extend the existing `morning-resolution` capability

Use `openspec/changes/morning-resolution-contract-state-ownership/specs/morning-resolution/spec.md` because `openspec/specs/morning-resolution/spec.md` already owns the resolved morning contract.

Alternative considered: create a new `morning-resolution-contract` capability. That would document the contract but risk creating two sources of truth for the same morning aggregate.

### Decision: Preserve the current resolver spine

The implementation will keep the dependency direction:

```text
Location + timezone + prayer settings
  -> Prayer-time resolver
  -> DailyPrayerWindow
  -> Hijri / observance / date-source / fast-domain resolvers
  -> ResolvedDayPurpose
  -> Plan resolver + date-specific override resolver
  -> MorningScheduleResolver
  -> ResolvedDaySnapshot
  -> ActiveDayResolver / ActiveAlarmDay builder
  -> MorningWakeResolutionService
  -> ResolvedMorningWakeState
  -> Surface snapshots + scheduler commands
  -> SwiftUI views + AlarmCoordinator / notification layer
```

Alternative considered: let each surface normalize the state it needs. That is simpler locally but recreates the exact drift this contract prevents.

### Decision: Add or adapt a domain intent-handling service

Prefer adapting existing services/stores over a parallel API. The intent path must cover:

- `selectWakeMode(dateKey, mode)`
- `previewWakeAdjustment(dateKey, proposedWakeTime)`
- `commitWakeAdjustment(dateKey, finalWakeTime)`
- `selectEarlyPurpose(dateKey, purpose)`
- `selectFastPurpose(dateKey, purpose)`
- `toggleFajrAdhanAtFajrBegins(dateKey, enabled)`
- `restoreDefaultWake(dateKey)`

SwiftUI views will call this path through providers/view models. The intent handler may update `DailyAlarmOverride` or an existing equivalent model, invalidate affected resolved snapshots, and request scheduler reconciliation.

Alternative considered: allow views to keep writing overrides directly. That preserves less code, but it keeps persistence and scheduling decisions inside presentation.

### Decision: Adapt date-specific override semantics before adding a new store

If `DailyAlarmOverride` can represent the required semantics, it will be extended/adapted for:

- quick wake mode override
- underlying wake mode before Quiet
- wake rule and wake-time override/origin
- early wake purpose override
- fast purpose override
- selected opportunity IDs
- Fajr adhan at Fajr begins override
- Quiet overlay
- created/updated/source metadata where consistent with existing storage

Migration/defaulting must treat missing new fields as compatibility defaults and must not mutate global defaults.

Alternative considered: introduce a new date-intention store immediately. That may be cleaner eventually, but it risks duplicate persistence during this contract hardening.

### Decision: Treat Quiet as an overlay

Quiet suppresses delivery for a date while preserving the underlying resolved meaning and the last non-quiet mode where available. Reselecting Fajr or Fast restores the preserved state before defaulting.

Alternative considered: encode Quiet as the only selected mode. That loses the reasoned morning underneath and makes restoration and explanation less trustworthy.

### Decision: Separate activation, delivery status, and audio role

`alarmActivation` remains the user/app intent to wake. `scheduleStatus`/delivery diagnostics describe platform delivery. Sound or adhan role describes audio content/event type. A permission-blocked active wake remains active with blocked delivery; Fajr adhan wake audio remains an active alarm.

Alternative considered: collapse blocked delivery or adhan audio into a quiet/off visual state. That is easier to display but misrepresents reliability and user intention.

### Decision: Surface snapshots stay adapters

Home Hero, Alarm Detail, Weekly Fajrcast, and Next 10 will consume `ResolvedDaySnapshot`, `ResolvedMorningWakeState`, and layout-ready snapshots. They may format labels and emit intents, but must not compute Fajr end, final-third start, fasting intention, alarm activation, or schedule status locally.

Alternative considered: leave currently duplicated calculations in views and cover them with UI tests. That would still leave calculation rules less auditable and harder to synchronize.

### Decision: Scheduler handoff is event-based

The scheduling layer consumes resolved materialized events and the active wake state, then reports schedule/delivery results back. It must not infer day purpose, quick mode, or completion credit.

Alternative considered: let scheduler map quick mode to events directly. That creates another wake engine and bypasses day-purpose resolution.

## Persistence / Migration Approach

- Read existing `DailyAlarmOverride` records using compatibility defaults for missing fields.
- Preserve global settings unless an explicit global-settings flow is used.
- Store one-date edits under the target date key in the resolved location timezone.
- Preserve underlying mode and purpose data when Quiet is applied.
- Reconcile scheduled events after committed date-specific mutations, using resolved event identifiers and avoiding unrelated alarm cancellations.
- Avoid remote migration or telemetry; this is local state only.

Rollback is straightforward at the app-code level because added fields/defaults should be optional or compatibility-backed. Persisted new fields must be ignored safely by older code only if the storage format already tolerates unknown fields; if it does not, implementation must avoid incompatible schema writes or document the risk.

## Scheduler Handoff Approach

- `MorningScheduleResolver` remains responsible for materialized event intent.
- `MorningWakeResolutionService` remains responsible for canonical wake-state activation, boundary, copy, visual mode, and delivery-status interpretation.
- The alarm coordinator consumes materialized events plus activation state and reports delivery diagnostics.
- Permission loss, AlarmKit unavailability, notification fallback, or missing pending deliveries update delivery status, not quick wake mode or Quiet overlay.
- Later Fajr-boundary audio toggles only affect that boundary event, never the pre-Fajr wake event.

## Testing Strategy

- Domain tests for resolver ownership: default Fajr, Fast quick selection, opportunity-only White Days, Ramadan, Qada, Tahajjud, missing Fajr end, missing final-third data, DST/timezone, endpoint copy, urgent relation tone, and Fajr adhan audio.
- Persistence/intent tests for date-specific edits, manual drag, Quiet over Fajr, Quiet over Fast, Fajr adhan boundary toggle, and Alarm Detail selected-date behavior.
- Scheduler tests for materialized event handoff, permission-blocked status, and active intent preservation.
- Surface/provider tests for Hero preview + Fajrcast live marker without persistence until commit.
- Static architecture tests scanning SwiftUI view files for direct schedule/create/cancel calls, direct `DailyAlarmOverride` writes, and final-third/Fajr-end calculations.

## Risks / Trade-offs

- [Risk] Existing tests may encode UI-local shortcuts. -> Mitigation: update tests to assert the new ownership boundary rather than remove coverage.
- [Risk] The override model may not cleanly hold every required concept. -> Mitigation: adapt the existing model only as far as compatible, and leave a documented follow-up if a proper store migration is needed.
- [Risk] Alarm delivery code may currently infer activation from pending-delivery state. -> Mitigation: add focused tests for `active + permissionBlocked` and adjust only the handoff/status mapping.
- [Risk] Static scans can be noisy. -> Mitigation: scope scans to SwiftUI view files and a short list of forbidden patterns that indicate real ownership violations.
- [Risk] Full simulator/Xcode tests may be slow or unavailable locally. -> Mitigation: run the narrowest relevant XCTest commands first and document any environment limitations honestly.

## Rollout Order

1. Create and validate the OpenSpec delta under `morning-resolution`.
2. Audit current models, resolvers, stores, scheduler handoff, surfaces, and tests.
3. Implement domain/override/intent semantics with compatibility defaults.
4. Tighten resolver and scheduler separation.
5. Adapt surface providers/views to consume resolved state and emit intents only.
6. Add acceptance and static architecture tests.
7. Run OpenSpec validation, targeted XCTest, broader build/tests where available, lint/format if configured.
8. Update `tasks.md`, commit, and push through the normal repository workflow.

## Implementation Notes

- `DailyAlarmOverride` was compatible enough for this change after adding optional fields with nil/false compatibility defaults. A separate store migration is not needed for the contract hardening implemented here.
- Qada remains resolved through the existing day-purpose/tag pipeline and now uses the early-worship wake plan without granting overlapping Sunnah opportunity credit.
- Existing delivery-status modeling already preserves active wake intent while reporting permission-blocked delivery, so the implementation tightened tests and resolver handoff without adding a new delivery-status enum.
