## Why

Subh already has the right domain pieces for Fajr windows, day purpose, quick wake modes, materialized events, completion, and alarm delivery, but the ownership contract across those pieces is still easy to drift. This change makes the system-layer path authoritative so surfaces, scheduler handoff, and completion logic all consume the same resolved morning instead of independently inferring intention, alarm state, prayer boundaries, or credit.

The user/system problem is trust: a White Days opportunity must not silently become a fast intention, Quiet Mode must not erase the underlying Fajr/Fast/Tahajjud state, permission-blocked delivery must not be represented as no alarm, and Fajr adhan audio must not imply the wake alarm is off.

## What Changes

- Establish one canonical morning-resolution path from prayer window and day purpose through date-specific override, wake boundary, wake time, alarm activation, materialized events, delivery status, copy state, and surface snapshots.
- Tighten state separation so day meaning, user intention, wake boundary, wake time, alarm activation, delivery status, and completion credit remain distinct.
- Route user edits through a domain intent-handling path for quick mode selection, wake preview/commit, early purpose, fast purpose, Fajr adhan boundary toggles, and restoring the default wake for one date.
- Preserve date-specific edits separately from global defaults, including underlying mode restoration under Quiet Mode.
- Keep Quiet Mode as a delivery-suppression overlay while retaining Fajr/Fast/Tahajjud/Ramadan/Qada/opportunity context.
- Keep alarm activation separate from schedule or delivery diagnostics, including permission-blocked or degraded platform states.
- Keep audio role separate from activation, so Fajr adhan wake audio remains an active alarm and later Fajr-boundary audio toggles do not disable a pre-Fajr wake event.
- Require surface snapshots for Home Hero, Alarm Detail, Weekly Fajrcast, and Next 10 to consume resolved state and emit intents only.
- Require scheduler handoff to consume resolved materialized events and report delivery status without redefining morning intent.

## Scope

In scope:

- Domain models and resolvers around `ResolvedDaySnapshot`, `ResolvedMorningWakeState`, `ResolvedDayPurpose`, date-specific overrides, materialized events, copy state, and completion requirements.
- Intent handling for one-date wake mode and purpose edits.
- Persistence semantics for date-specific overrides and Quiet restoration.
- Scheduler handoff and delivery-status feedback boundaries.
- Surface snapshot adapter boundaries and static guardrails for SwiftUI view ownership.
- Unit/integration coverage for the contract scenarios.

Out of scope:

- Visual redesign of Home Hero, Alarm Detail, Weekly Fajrcast, or Next 10.
- Adding a separate Ramadan, fasting, Tahajjud, or Qada engine.
- Changing the prayer-time provider catalog or religious ruling policy.
- Adding analytics, remote telemetry, social features, or engagement mechanics.
- Replacing AlarmKit/notification delivery infrastructure beyond the handoff contract required here.

## Capabilities

### New Capabilities

- None. This contract belongs in the existing morning-resolution capability.

### Modified Capabilities

- `morning-resolution`: Add the canonical state-ownership, intent, override, Quiet overlay, activation/status, audio-role, surface snapshot, scheduler handoff, and acceptance-test requirements for one resolved Subh morning.

## Risks

- Existing persisted `DailyAlarmOverride` values may be incomplete for the new semantics, so migration/defaulting must preserve behavior without silently upgrading opportunities into intentions.
- Existing scheduled alarms or cached schedule windows may need reconciliation when date-specific state changes, but unrelated alarms must not be cancelled.
- Existing visual code may already be close to the right behavior; the implementation should avoid broad churn while preventing UI-local calculation and persistence shortcuts.
- Ramadan, Qada, and Sunnah/custom fast semantics are religiously sensitive; implementation must expose calculation/configuration state and avoid hard-coded unsupported claims.

## Impact

- Affected code areas include `Subh/Core/Morning`, `Subh/Core/Scheduling`, alarm scheduling and delivery coordinators, Home Hero providers/views, Alarm Detail providers/views, Weekly Fajrcast providers/views, Next 10/Morningcast providers/views, and related XCTest targets.
- Existing global defaults should remain unchanged by one-date edits.
- Existing date-specific overrides should remain readable, with compatibility defaults for newly modeled fields.
- Existing scheduled alarms are affected only through resolver-driven materialized event changes and reconciliation; this change must not introduce broad cancellation of unrelated deliveries.
- No new production dependency is expected.
