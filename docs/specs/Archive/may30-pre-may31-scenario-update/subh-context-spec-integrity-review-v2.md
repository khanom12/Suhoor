# Subh Context Spec Integrity Review v2 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-context-spec-integrity-review-v2.md` |
| Version | 2 |
| Spec status | Active integrity-review checklist |
| Date | 2026-05-30 |
| Related specs | Entire active spec set |
| Owning domain / surface | Spec quality, drift control, and implementation audit support |

## 1. Purpose

This review file records the key integrity traps that the May 30 reconciliation resolved and should prevent from reappearing.

## 2. Resolved drift traps

| Trap | Correct active rule |
| --- | --- |
| Quiet as third wake-purpose segment | Quiet is `DateAlarmOverride.quiet`; selector is `Fajr | Suhoor`. |
| Pause as a mode | Pause is `GlobalWakeAlarmPolicy.pausedIndefinitely`. |
| Pre-Fajr/Early/Fast as visible purposes | Suhoor is the only MVP before-Fajr purpose. |
| Tahajjud-only / Other early worship in MVP | Deferred; not active MVP UI/resolution. |
| Active-session Quiet | Not available after first alarm begins. |
| Stop checks button | Not visible; use `I’m awake`. |
| System dismissal not acknowledged | For MVP, explicit system dismissal counts as awake acknowledgement with source preserved. |
| Tags mixing purpose/status/context | Middle lane = opportunity/context only; trailing status = alarm state. |
| Next 7 inline editing | Rows navigate to Detail; no inline Quiet/Pause/purpose controls. |
| Quiet/Pause as missed worship | Quiet/Pause do not imply missed Fajr/fast. |

## 3. Audit checklist for future changes

Before accepting a future spec or implementation change, verify:

1. Home and Detail selectors remain `Fajr | Suhoor`.
2. Quiet/Pause remain separate alarm-state/policy layers.
3. Suhoor remains fasting-oriented in MVP.
4. Non-fasting before-Fajr planning is not reintroduced accidentally.
5. Active wake flow exposes only `I’m awake`.
6. Follow-ups respect Fajr/Suhoor boundaries.
7. System dismissal acknowledgement behavior remains deliberate and tested.
8. Next 7/Month remain navigation surfaces for edits.
9. Pricing does not paywall safety/basic wake utility.
10. Original archived specs are not used as implementation source without reconciling conflicts.
