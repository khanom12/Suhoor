# Subh MVP Interaction Inventory v5 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-mvp-interaction-inventory-v5.md` |
| Version | 5 |
| Spec status | Active interaction inventory summary and scenario-group contract |
| Date | 2026-05-30 |
| Related specs | Index, Quick Mutation, Hero, Detail, Quiet/Pause, Wake Sessions, Pricing, Testing Harness |
| Owning domain / surface | MVP interaction coverage and scenario grouping |

## May 30, 2026 reconciliation status

This active spec has been reconciled against the finalized Quiet / Pause / Hero / Wake Flow direction. It is implementation-facing. Older wording preserved in `Archive/originals-before-may30-reconciliation/` is historical only and must not be implemented when it conflicts with this active file.

Canonical MVP doctrine used across the active spec set:

```text
Wake purpose: Fajr | Suhoor
Alarm state: active | quiet | paused | rings-once | blocked | issue
Execution state: not started | ringing | follow-up pending | awake acknowledged | fasting logged | Fajr logged | ended/no response | issue
```

Quiet and Pause are not wake purposes. `Suhoor` is the only exposed MVP before-Fajr wake purpose and is fasting/suhoor-oriented. Generic non-fasting `Pre-Fajr`, `Early`, `Tahajjud only`, and `Other early worship` flows are deferred unless a later approved spec explicitly reintroduces them.


## 1. Purpose

This inventory identifies the MVP interaction groups that must be covered by implementation and testing after the Quiet/Pause/Hero reconciliation.

The archived original contains detailed historical scenario IDs. This active inventory keeps the scenario coverage but removes stale requirements that exposed Quiet as a wake purpose or exposed non-fasting before-Fajr choices.

## 2. Active interaction groups

| Group | Interaction family | Required outcome |
| --- | --- | --- |
| A | Home Hero Fajr planning | User can view/adjust Fajr alarm and keep purpose Fajr. |
| B | Home Hero Suhoor planning | User can select Suhoor, use Suhoor alarm config, and default fasting-purpose logic applies. |
| C | Home Hero Quiet | User can set/clear Quiet from alarm-state action sheet before execution. |
| D | Home Hero Pause display | Paused state displays without changing hero height. |
| E | Ring once while paused | User can ring one target morning while Pause remains active. |
| F | Day Detail editing | User can edit selected date purpose, alarm time, Quiet, ring-once, fasting purpose, reset. |
| G | Next 7 Mornings | Rows display seven mornings and navigate to Detail. |
| H | Month planning | Dates/rows display context/status and navigate to Detail. |
| I | Weekly Fajrcast | Inspection-only seven-morning summary. |
| J | Wake Session Fajr | Alarm rings, `I’m awake`, follow-ups cancel, `I prayed Fajr` eligibility works. |
| K | Wake Session Suhoor | Alarm rings, `I’m awake`, `I’m fasting today` before Fajr, then `I’m awake for Fajr`, then `I prayed Fajr`. |
| L | System dismissal | Explicit system/AlarmKit dismissal records awake acknowledgement source. |
| M | No response | Session ends with `No response recorded`, not missed by default. |
| N | Delivery issues | Permission/setup/delivery failures show issue/setup states, not Quiet. |
| O | Pricing exposure | Core interactions remain Free; Plus reserved for insights/history/etc. |
| P | Testing harness | Simulation can exercise all states without waiting for real mornings. |

## 3. Deferred scenario families

These historical scenario families are explicitly deferred from active MVP:

```text
Tahajjud-only before-Fajr selection
Other early worship before-Fajr selection
Fasting + Tahajjud combined selection
Generic Pre-Fajr / Early / Fast mode selector states
Quiet as a third purpose segment
Active wake-session Quiet cancellation
Date-range Pause / recurring Pause / pause reason picker
```

## 4. Compatibility scenario families

Legacy values must be decoded safely:

| Legacy scenario | Active expected behavior |
| --- | --- |
| Existing Pre-Fajr/Early/Fast saved value | Normalize to Suhoor-compatible behavior. |
| Existing Quiet quick-mode record | Normalize to DateAlarmOverride.quiet. |
| Existing non-fasting before-Fajr metadata | Preserve for migration/debug if needed, but do not surface as active MVP. |
| Existing wake-stop/dismiss behavior | Treat explicit dismissal as awake acknowledgement for MVP. |

## 5. Required test scenarios

Minimum scenario coverage:

1. Active Fajr planning → set Quiet → clear Quiet → Fajr plan restored.
2. Active Suhoor planning → set Quiet → switch Fajr/Suhoor while Quiet → saved times preserved.
3. Pause globally → row shows Paused → ring tomorrow only → Pause remains after target morning.
4. Manual Quiet during Pause → resume alarms → manual Quiet remains.
5. Alarm starts → Quiet unavailable → `I’m awake` cancels follow-ups.
6. System dismissal → acknowledgement source recorded → follow-ups cancelled.
7. Suhoor acknowledged → `I’m fasting today` before Fajr → `I’m awake for Fajr` after Fajr begins → `I prayed Fajr`.
8. Suhoor acknowledged but fasting CTA not tapped → after Fajr begins, prioritize `I’m awake for Fajr`, then `I prayed Fajr`.
9. Fajr alarm no response → `Alarm ended` / `No response recorded`.
10. Missing permission → `Turn on alarms`, not Quiet.
11. Next 7 row Quiet/Paused status → tapping opens Day Detail.
12. Month row opportunity tags only; trailing status shows Quiet/Paused.
13. Weekly Fajrcast shows summary and mutates nothing.
14. Pricing gate check: no core wake action requires Plus.
15. Legacy Pre-Fajr/Fast/Quiet-as-mode values migrate/normalize without visible stale copy.

## 6. Acceptance criteria

1. The inventory no longer treats Quiet as a wake purpose.
2. Non-fasting before-Fajr flows are marked deferred.
3. Every core Quiet/Pause/Hero/Wake Session behavior has a testable scenario.
4. Scenario coverage includes system dismissal acknowledgement.
5. Pricing coverage confirms Free/core access for safety and basic wake utility.
