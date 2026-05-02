## 1. OpenSpec / Spec Work

- [x] 1.1 Review repo guidance, project OpenSpec config, existing active changes, and existing capability specs.
- [x] 1.2 Create the `morning-resolution-contract-state-ownership` change under the existing `morning-resolution` capability.
- [x] 1.3 Write proposal, design, and delta spec artifacts for the contract.
- [x] 1.4 Run `openspec validate morning-resolution-contract-state-ownership --strict` and fix validation issues.

## 2. Model And Resolver Audit

- [x] 2.1 Audit morning resolver, wake-state resolver, day-purpose, fast-domain, context, completion, and scheduled date-source models.
- [x] 2.2 Identify current ownership gaps where surfaces, scheduler, or completion logic rederive wake state, intention, boundaries, activation, or status.
- [x] 2.3 Document compatibility assumptions before editing models or persistence.

## 3. Intent-Handling Path

- [x] 3.1 Introduce or adapt one date-specific intent API for quick wake mode, wake preview, wake commit, early purpose, fast purpose, Fajr adhan boundary toggle, and default restore.
- [x] 3.2 Route Home Hero and Alarm Detail mutations through the intent path instead of direct override writes or scheduling.
- [x] 3.3 Ensure preview intents do not persist or schedule until commit.

## 4. Date-Specific Override Semantics

- [x] 4.1 Adapt `DailyAlarmOverride` or the existing equivalent to represent required date-specific wake, purpose, opportunity, Fajr adhan, Quiet, and metadata semantics with compatibility defaults.
- [x] 4.2 Ensure one-date edits do not mutate global defaults.
- [x] 4.3 Ensure manual drag commits wake-time override and origin without inferring fast or Tahajjud intention.

## 5. Quiet Restoration

- [x] 5.1 Preserve underlying Fajr mode when Quiet is applied and restore it when Fajr is reselected.
- [x] 5.2 Preserve underlying Fast mode and selected fast purpose when Quiet is applied and restore it when Fast is reselected.
- [x] 5.3 Keep Ramadan, Qada, Sunnah/custom opportunity, Tahajjud, and selected purpose context present under Quiet.

## 6. Activation Vs Schedule Status Separation

- [x] 6.1 Keep active alarm intent separate from permission-blocked, degraded, missing, or delivered schedule status.
- [x] 6.2 Ensure permission-blocked delivery does not become Quiet or no-alarm in domain/UI state.

## 7. Audio Role Vs Activation Separation

- [x] 7.1 Ensure Fajr adhan wake audio remains an active alarm role rather than off/no-alarm state.
- [x] 7.2 Ensure toggling the later Fajr adhan at Fajr begins affects only the later boundary event, not the pre-Fajr wake event.

## 8. Surface Snapshot Adapters

- [x] 8.1 Ensure Home Hero consumes `ResolvedMorningWakeState` and emits intents only.
- [x] 8.2 Ensure Alarm Detail consumes selected date resolved state and commits date-specific intents only.
- [x] 8.3 Ensure Weekly Fajrcast consumes resolved seven-day snapshots plus optional live preview and does not persist from chart scrubbing.
- [x] 8.4 Ensure Next 10 consumes resolved tags and wake time/status without inferring intention from tag text or adding explanatory row prose.

## 9. Scheduler Handoff

- [x] 9.1 Ensure scheduler handoff consumes resolved materialized events and activation state.
- [x] 9.2 Ensure scheduler/delivery reports status back without redefining quick mode, day meaning, intention, or completion credit.
- [x] 9.3 Ensure reconciliation avoids cancelling unrelated alarms.

## 10. Tests

- [x] 10.1 Add resolver tests for default Fajr, Fast quick selection, opportunity-only White Days, Ramadan, Qada, Tahajjud, endpoint copy, urgent tone, missing Fajr end, missing final-third data, and DST/timezone handling.
- [x] 10.2 Add intent/persistence tests for Quiet over Fajr, Quiet over Fast, manual drag, Alarm Detail selected-date edits, and Fajr adhan boundary toggle.
- [x] 10.3 Add scheduler/status tests for active intent with permission-blocked delivery and Fajr adhan audio active wake.
- [x] 10.4 Add Hero preview plus Weekly Fajrcast live marker test with no persistence or scheduling until commit.
- [x] 10.5 Add architecture/static scan tests for SwiftUI view ownership guardrails.

## 11. Validation / Build

- [x] 11.1 Run OpenSpec strict validation after implementation.
- [x] 11.2 Run the relevant XCTest suite and broader build/test command when available.
- [x] 11.3 Confirmed no repository-standard formatting or linting command/config is present; no lint/format command was run.
- [x] 11.4 Update this task list honestly with completed and deferred items.

## 12. Commit / Push

- [x] 12.1 Review changed files and ensure no unrelated/generated/user-specific files are included.
- [x] 12.2 Commit with `Implement morning resolution state ownership contract`.
- [x] 12.3 Push the feature branch if credentials and normal workflow permit.
