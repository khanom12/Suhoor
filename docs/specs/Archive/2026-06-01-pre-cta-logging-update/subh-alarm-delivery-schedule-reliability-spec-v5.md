# Subh Alarm Delivery, Schedule Reliability, and Reconciliation Specification v5 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-alarm-delivery-schedule-reliability-spec-v5.md` |
| Version | 5 |
| Spec status | Active delivery and scheduling reliability spec |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Morning Resolution, Quiet/Pause, Wake Sessions, Hero, Quick Mutation, Testing Harness |
| Owning domain / surface | Alarm scheduling, cancellation, delivery ledger, and reliability states |

## May 31, 2026 update status

Version 5 aligns delivery with the May 31 wake-session algorithm: 5-minute checks, final attempt at relevant boundary minus 5 minutes, latest new session at boundary minus 6 minutes, and a single-shot Fajr-start event after Suhoor unless the user opts into Fajr follow-up.

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
single Fajr-start event after Suhoor
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

| ResolvedAlarmState | Schedule primary alarm/event? | Schedule follow-ups? | Ledger/reconciliation meaning |
| --- | --- | --- | --- |
| active | Yes | Yes, if boundary allows | Expected to ring |
| quiet | No | No | Intentionally quiet for date |
| pausedInherited | No | No | Suppressed by global Pause |
| ringsOnceDespitePause | Yes | Yes, if boundary allows | Date exception while Pause remains active |
| blocked | No | No | Cannot schedule until setup/permission fixed |
| issue | Attempt/reconcile as appropriate | No until resolved | Delivery issue/failure state |
| unavailable | No | No | Missing required timing/context |
| fajrStartEventOnly | Yes, single Fajr-start event | No | Suhoor completed; no Fajr wake session unless user opts in |

## 4. Quiet scheduling

When `DateAlarmOverride.quiet` is set before execution:

- cancel any pending primary alarm for that target morning;
- cancel pending follow-up alarms for that target morning;
- prevent wake-session creation for that target morning;
- mark ledger/reconciliation as intentionally quiet, not failed;
- preserve the saved Fajr/Suhoor alarm config for restoration.

When approved active-session Quiet cancellation is confirmed:

- cancel remaining alarms/checks for the active session;
- record cancellation reason as `quietDuringExecution` or equivalent;
- do not mark the wake as acknowledged;
- do not mark Fajr prayer as completed.

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

## 7. Follow-up boundaries and generation

Follow-up alarms may be scheduled only within the selected purpose boundary:

```text
Fajr purpose: no follow-ups after Fajr ends
Suhoor purpose: no follow-ups after Fajr begins
```

Scheduling algorithm:

```text
Wake-check interval = 5 minutes
Earliest newly scheduled wake time = current time + 1 minute
Latest wake time = relevant boundary - 5 minutes
Latest new session creation time = relevant boundary - 6 minutes
No wake check at the exact relevant boundary
```

If not enough time remains for a follow-up, Delivery should mark the active session as final-alarm/no-follow-up rather than scheduling beyond the boundary.

A default 30-minute wake session produces attempts at 30, 25, 20, 15, 10, and 5 minutes before the relevant boundary.

## 8. Suhoor completion and Fajr-start event

After Suhoor wake acknowledgement:

- cancel remaining Suhoor follow-ups;
- do not automatically schedule a full Fajr wake-check session;
- schedule only a single Fajr-start event at Fajr begins if configured/eligible;
- do not schedule follow-ups for that Fajr-start event;
- if the user explicitly opts into Fajr follow-up, schedule a normal Fajr wake session using the Fajr boundary rules.

Delivery must keep these types distinct:

```text
suhoorWakeSession
fajrStartEventOnly
fajrWakeSession
```

## 9. Delivery capability and issue states

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

## 10. Ledger requirements

Recommended delivery ledger fields:

```text
targetMorningDate
wakePurpose
selectedAlarmTime
resolvedAlarmState
sessionOrEventType
relevantBoundary
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
quietDuringExecution
pauseSet
ringOnceCleared
purposeChanged
timeChanged
boundaryExpired
permissionLost
manualCleanup
awakeAcknowledged
```

## 11. Active execution handoff

When a scheduled alarm fires:

- create or update Wake Session execution state;
- hide/lock purpose switching for the executing wake;
- surface `I’m awake` as the active user action;
- treat explicit system dismissal as awake acknowledgement for MVP;
- cancel remaining follow-ups on acknowledgement;
- if approved active-session Quiet is confirmed, cancel remaining checks as quiet cancellation, not as acknowledgement.

## 12. Acceptance criteria

1. Delivery schedules only active, ring-once, or explicit Fajr-start event states.
2. Quiet cancels stale scheduled delivery and is not marked as failure.
3. Active-session Quiet cancellation, if exposed, cancels remaining checks without logging wake acknowledgement.
4. Pause suppresses future wake alarms without creating date Quiet records.
5. Ring-once schedules one paused target morning and does not resume all alarms.
6. Permission/setup/delivery issues do not display as Quiet/Pause.
7. Follow-ups never exceed the Fajr/Suhoor boundary.
8. Follow-ups use 5-minute intervals and stop no later than relevant boundary minus 5 minutes.
9. New session creation is blocked after relevant boundary minus 6 minutes.
10. Suhoor acknowledgement does not automatically schedule a Fajr wake-check session.
11. Fajr-start event after Suhoor has no follow-ups by default.
12. Delivery ledger preserves why alarms were scheduled/cancelled.
