# Subh Alarm Delivery, Schedule Reliability, and Reconciliation Specification v4 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-alarm-delivery-schedule-reliability-spec-v4.md` |
| Version | 4 |
| Spec status | Active delivery and scheduling reliability spec |
| Date | 2026-05-30 |
| Related specs | Index, Morning Resolution, Quiet/Pause, Wake Sessions, Hero, Quick Mutation, Testing Harness |
| Owning domain / surface | Alarm scheduling, cancellation, delivery ledger, and reliability states |

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

Alarm Delivery schedules only what Morning Resolution says should actually ring.

It must distinguish:

```text
intentional silence
inherited global Pause
one-morning ring exception
blocked permissions/setup
delivery/scheduling failure
executing wake session
```

## 2. Scheduling source of truth

Delivery must not infer schedule state directly from UI controls.

Required pipeline:

```text
User action
→ shared mutation contract
→ durable state update
→ Morning Resolution snapshot
→ Alarm Delivery schedule/cancel/reconcile
→ Wake Session execution if alarm fires
```

## 3. Schedulable states

| ResolvedAlarmState | Schedule primary alarm? | Schedule follow-ups? | Ledger/reconciliation meaning |
| --- | --- | --- | --- |
| active | Yes | Yes, if boundary allows | Expected to ring |
| quiet | No | No | Intentionally quiet for date |
| pausedInherited | No | No | Suppressed by global Pause |
| ringsOnceDespitePause | Yes | Yes, if boundary allows | Date exception while Pause remains active |
| blocked | No | No | Cannot schedule until setup/permission fixed |
| issue | Attempt/reconcile as appropriate | No until resolved | Delivery issue/failure state |
| unavailable | No | No | Missing required timing/context |

## 4. Quiet scheduling

When `DateAlarmOverride.quiet` is set:

- cancel any pending primary alarm for that target morning;
- cancel pending follow-up alarms for that target morning;
- prevent wake-session creation for that target morning;
- mark ledger/reconciliation as intentionally quiet, not failed;
- preserve the saved Fajr/Suhoor alarm config for restoration.

Quiet must not be offered or applied after the first alarm begins.

## 5. Pause scheduling

When `GlobalWakeAlarmPolicy.pausedIndefinitely` is active:

- suppress upcoming wake alarms unless the date has `ringDespitePause`;
- cancel or avoid scheduling future wake alarms according to platform constraints;
- preserve durable plans for resumption;
- do not create manual Quiet records for inherited paused dates.

When Pause is resumed:

- schedule eligible active future alarms again;
- leave manual Quiet dates unscheduled;
- remove expired ring-once exceptions.

## 6. Ring-once exception

`DateAlarmOverride.ringDespitePause` schedules the selected target morning while global Pause remains active.

Rules:

- It applies to one target morning only.
- It respects the selected Fajr/Suhoor purpose and saved alarm config.
- It expires or is cleaned up after the target morning.
- Clearing it returns the date to inherited Pause if global Pause is still active.

## 7. Follow-up boundaries

Follow-up alarms may be scheduled only within the selected purpose boundary:

```text
Fajr purpose: no follow-ups after Fajr ends
Suhoor purpose: no follow-ups after Fajr begins
```

If not enough time remains for a follow-up, Delivery should mark the active session as final-alarm/no-follow-up rather than scheduling beyond the boundary.

## 8. Delivery capability and issue states

Delivery must keep these distinct from Quiet/Pause:

```text
notifications disabled
AlarmKit unavailable
Focus/system suppression
missing location
missing prayer times
scheduling API failure
stale identifier mismatch
clock/time-zone reconciliation issue
```

User-facing states should use plain copy:

```text
Turn on alarms
Set location
Alarm issue
Subh couldn’t confirm the alarm
```

Do not show `Permission blocked`, `Delivery suppressed`, or `Quiet` for these reliability problems.

## 9. Ledger requirements

Recommended delivery ledger fields:

```text
targetMorningDate
wakePurpose
selectedAlarmTime
resolvedAlarmState
scheduleIdentifier
followUpIdentifiers
scheduledAt
cancelledAt
cancellationReason
reconciliationStatus
platformCapabilityState
sourceMutation
```

Cancellation reasons should distinguish:

```text
quietSet
pauseSet
ringOnceCleared
purposeChanged
timeChanged
boundaryExpired
permissionLost
manualCleanup
```

## 10. Active execution handoff

When a scheduled alarm fires:

- create or update Wake Session execution state;
- lock/hide Quiet and purpose switching for the executing wake;
- surface `I’m awake` as the active user action;
- treat explicit system dismissal as awake acknowledgement for MVP;
- cancel remaining follow-ups on acknowledgement.

## 11. Acceptance criteria

1. Delivery schedules only active or ring-once resolved states.
2. Quiet cancels stale scheduled delivery and is not marked as failure.
3. Pause suppresses future wake alarms without creating date Quiet records.
4. Ring-once schedules one paused target morning and does not resume all alarms.
5. Permission/setup/delivery issues do not display as Quiet/Pause.
6. Follow-ups never exceed the Fajr/Suhoor boundary.
7. Delivery ledger preserves why alarms were scheduled/cancelled.
8. Active wake execution routes to Wake Sessions and no longer exposes Quiet.
