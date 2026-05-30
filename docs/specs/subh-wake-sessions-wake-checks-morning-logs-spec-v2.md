# Subh Wake Sessions, Wake Checks, and Morning Logs Specification v2 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-wake-sessions-wake-checks-morning-logs-spec-v2.md` |
| Version | 2 |
| Spec status | Active wake execution and logging contract |
| Date | 2026-05-30 |
| Related specs | Index, Alignment, Morning Resolution, Hero, Quiet/Pause, Alarm Delivery, Testing Harness |
| Owning domain / surface | Alarm execution, follow-up alarms, acknowledgement, and morning logs |

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

This spec defines what happens after a scheduled Subh wake alarm begins.

Wake Sessions and Wake Checks are execution-layer behavior. They do not choose Fajr/Suhoor purpose and they do not determine whether a future date is Quiet or Paused.

## 2. Core lifecycle

```text
scheduled
→ primary alarm ringing
→ follow-up pending / follow-up ringing as needed
→ awake acknowledged OR ended/no response OR issue
→ optional current-morning logging CTAs
→ handoff to next morning at Fajr end
```

## 3. Execution boundary

Once the first alarm begins:

- Quiet is unavailable for that executing wake.
- Fajr/Suhoor switching is hidden or locked for that executing wake.
- Pause changes should not retroactively cancel the current executing wake unless a later safety spec explicitly allows it.
- The user-facing action is `I’m awake`.
- The app must not show `Stop checks`.

## 4. Primary action

Active alarm and follow-up states show:

```text
I’m awake
```

`I’m awake` must:

- stop the current alarm sound;
- cancel remaining follow-up alarms for that target morning;
- record awake acknowledgement;
- preserve acknowledgement source;
- advance the Hero to post-acknowledgement state.

Allowed acknowledgement sources:

```text
inAppButton
systemAlarmDismiss
systemNotificationAction
reconciliationFallback
```

For MVP, explicit AlarmKit/system dismissal is equivalent to `I’m awake` for wake-flow completion. The source remains available for analytics/debugging.

## 5. Follow-up alarm rules

Follow-up alarms exist only inside the selected purpose’s relevant boundary.

```text
Fajr purpose boundary: Fajr ends
Suhoor purpose boundary: Fajr begins
```

Rules:

- Do not schedule follow-ups beyond the boundary.
- If there is not enough time for a follow-up, Slot 5 says `Final alarm this morning`.
- The primary alarm may still ring close to the boundary if the selected plan is valid and platform constraints allow it.
- Wake Checks/follow-ups stop immediately after acknowledgement.

## 6. Fajr wake flow

```text
Fajr alarm rings
→ Time to wake
→ user taps I’m awake or dismisses system alarm
→ remaining follow-ups cancelled
→ awake acknowledgement logged
→ after at least 60 seconds, if Fajr has begun and not ended, show I prayed Fajr
→ user taps I prayed Fajr
→ Fajr completion logged
→ at Fajr end, Home switches to next morning
```

Do not show `I prayed Fajr` immediately after `I’m awake`; use the anti-double-tap delay.

## 7. Suhoor wake flow

```text
Suhoor alarm rings
→ Time to wake
→ user taps I’m awake or dismisses system alarm
→ remaining Suhoor follow-ups cancelled
→ Suhoor wake acknowledgement logged
→ before Fajr begins and after delay, show I’m fasting today when eligible
→ user taps I’m fasting today
→ fasting intention/status logged for the day
→ at Fajr begins, run the Fajr-phase wake check if Fajr wake is unconfirmed
→ show I’m awake for Fajr
→ user taps I’m awake for Fajr
→ Fajr wake acknowledgement logged separately from Suhoor wake acknowledgement
→ after the anti-double-tap delay, show I prayed Fajr while Fajr is still open
→ at Fajr end, Home switches to next morning
```

`I’m fasting today` is not fast completion. It records current-day fasting intention/status.

If the user does not tap `I’m fasting today` before Fajr begins, the Hero prioritizes the Fajr-specific wake check first, then Fajr prayer logging. Fasting may be logged elsewhere if supported.

## 8. No-response handling

If the wake session reaches its end without acknowledgement:

```text
executionState = endedNoResponse
Hero primary = Alarm ended
Supporting copy = No response recorded
```

No response is not automatically:

- missed Fajr;
- missed fast;
- Quiet;
- delivery failure.

Later analytics may analyze no-response behavior, but the wake-session log must remain specific.

## 9. Quiet and Pause interaction

Before execution begins:

- Quiet prevents the session from starting.
- Pause prevents the session from being scheduled unless ring-once applies.

After execution begins:

- Quiet is no longer available for that wake.
- The active wake can be acknowledged with `I’m awake`.
- Follow-up cancellation happens through acknowledgement, not through Quiet.

## 10. Morning logs

The system may write separate log records for:

```text
wakeAcknowledged
wakeEndedNoResponse
fastingTodayLogged
fajrPrayerLogged
alarmIssue
quietMorning
pausePolicyChanged
ringOnceExceptionUsed
```

These records must remain analytically distinct. Do not infer one from another unless explicitly defined.

## 11. Analytics and behavior shaping

Free/core logging should capture enough metadata to support user benefit and future insight without storing noisy micro-interactions.

Recommended metadata:

- target morning date;
- wake purpose;
- resolved alarm state at execution start;
- scheduled primary alarm time;
- acknowledgement time;
- acknowledgement source;
- number of follow-ups scheduled/fired/cancelled;
- boundary used: Fajr begins or Fajr ends;
- whether Quiet/Pause/ring-once affected the morning;
- whether Fajr and fasting CTAs were shown/tapped.

Do not log every slider micro-movement. Persist final committed values and meaningful interactions.

## 12. Acceptance criteria

1. Active wake states show only `I’m awake` as primary action.
2. `Stop checks` is not visible copy.
3. Quiet cannot be selected once the first alarm starts.
4. System dismissal counts as awake acknowledgement for MVP with source preserved.
5. `I’m awake` cancels remaining follow-up alarms.
6. Follow-ups respect Fajr/Suhoor boundaries.
7. Suhoor acknowledgement and Fajr wake acknowledgement are separate outcome facts.
8. Suhoor acknowledged before Fajr creates `I’m awake for Fajr` at/after Fajr begins when `fajrWakeStatus` is unconfirmed.
9. `I’m fasting today` is available only before Fajr begins and after Suhoor acknowledgement/delay.
10. `I prayed Fajr` appears only after Fajr wake acknowledgement, after the anti-double-tap delay, and before Fajr ends.
11. No response is logged as no response, not missed Fajr/fast by default.
