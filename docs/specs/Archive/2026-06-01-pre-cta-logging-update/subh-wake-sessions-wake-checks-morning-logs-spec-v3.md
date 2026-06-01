# Subh Wake Sessions, Wake Checks, and Morning Logs Specification v3 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-wake-sessions-wake-checks-morning-logs-spec-v3.md` |
| Version | 3 |
| Spec status | Active wake execution and logging contract |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Alignment, Morning Resolution, Hero, Quiet/Pause, Alarm Delivery, Testing Harness |
| Owning domain / surface | Alarm execution, follow-up alarms, acknowledgement, and morning logs |

## May 31, 2026 update status

Version 3 adds the 5-minute wake-check algorithm, the relevant-boundary minus 5/6 minute rules, the single-shot Fajr-start event after Suhoor, optional Fajr follow-up, and separate Fajr wake vs prayer completion logging.

Canonical MVP doctrine:

```text
Wake purpose values: Fajr, Suhoor
Visible planning selector order: Suhoor | Fajr
Alarm state: active | quiet | paused | rings-once | blocked | issue
Execution state: not started | ringing | follow-up pending | awake acknowledged | fasting logged | Fajr logged | ended/no response | issue
```

## 1. Purpose

This spec defines what happens after a scheduled Subh wake alarm begins and how wake acknowledgement, wake checks, and morning logs are recorded.

Wake Sessions and Wake Checks are execution-layer behavior. They do not choose Fajr/Suhoor purpose and they do not determine whether a future date is Quiet or Paused.

## 2. Core lifecycle

```text
scheduled
→ primary alarm ringing
→ follow-up pending / follow-up ringing as needed
→ awake acknowledged OR quiet-cancelled OR ended/no response OR issue
→ optional current-morning logging CTAs
→ handoff to next morning at Fajr end
```

## 3. Execution boundary

Once the first alarm begins:

- Slot 6 primary action is `I’m awake`.
- Fajr/Suhoor switching is hidden or locked for that executing wake.
- Pause changes should not retroactively cancel the current executing wake unless a later safety spec explicitly allows it.
- The app must not show `Stop checks`.
- Quiet is not shown as a competing Slot 6 action. If an approved alarm-state control exposes active-session Quiet cancellation, it requires explicit confirmation and logs a distinct cancellation reason.

## 4. Primary wake acknowledgement

Active alarm and follow-up states show:

```text
I’m awake
```

`I’m awake` must:

- stop the current alarm sound;
- cancel remaining follow-up alarms for that purpose-scoped session;
- record wake acknowledgement;
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

## 5. Relevant boundaries and wake-check generation

Follow-up alarms exist only inside the selected purpose’s relevant boundary:

```text
Suhoor relevant window end = Fajr begins
Fajr relevant window end = Fajr ends
```

Wake-check rules:

```text
Wake-check interval = 5 minutes
Earliest newly scheduled wake time = current time + 1 minute
Latest wake time = relevant window end - 5 minutes
Latest new session creation time = relevant window end - 6 minutes
No wake check at the exact end boundary
```

Generate attempts as follows:

1. initial alarm at selected wake time;
2. follow-up checks every 5 minutes;
3. stop once the next check would be later than `relevant window end - 5 minutes`;
4. never schedule a check at the exact relevant boundary.

Default 30-minute wake session:

| Attempt | Timing |
| --- | --- |
| Initial alarm | 30 minutes before relevant boundary |
| Wake check 1 | 25 minutes before relevant boundary |
| Wake check 2 | 20 minutes before relevant boundary |
| Wake check 3 | 15 minutes before relevant boundary |
| Wake check 4 | 10 minutes before relevant boundary |
| Final wake check | 5 minutes before relevant boundary |

If the selected wake time is 10 minutes before the boundary, schedule two attempts: initial alarm at 10 minutes before and final check at 5 minutes before. If selected wake time is 5 minutes before, schedule one attempt and no follow-up.

If there is not enough time for a follow-up, Slot 5 says:

```text
Final alarm this morning
```

Wake Checks/follow-ups stop immediately after acknowledgement or confirmed quiet cancellation.

## 6. Fajr wake flow

```text
Fajr alarm rings
→ Time to wake
→ user taps I’m awake or dismisses system alarm
→ remaining Fajr follow-ups cancelled
→ Fajr wake acknowledgement logged
→ after at least 60 seconds, if Fajr has begun and not ended, show I prayed Fajr
→ user taps I prayed Fajr
→ Fajr prayer completion logged
→ at Fajr end, Home switches to next morning
```

`I’m awake` / `I’m Awake for Fajr` does not log Fajr prayer completion. `I prayed Fajr` logs prayer completion separately.

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
→ at Fajr begins, issue a single Fajr-start event if configured/eligible
→ do not automatically create Fajr wake checks
→ user may intentionally opt into Fajr follow-up from the Hero
→ if Fajr follow-up is configured, create a normal Fajr wake session
→ if that Fajr wake session runs, show I’m awake for Fajr
→ user taps I’m awake for Fajr
→ Fajr wake acknowledgement logged separately from Suhoor wake acknowledgement
→ after anti-double-tap delay, show I prayed Fajr while Fajr is still open
→ at Fajr end, Home switches to next morning
```

`I’m fasting today` is not fast completion. It records current-day fasting intention/status.

If the user does not tap `I’m fasting today` before Fajr begins, fasting may be logged elsewhere if supported. The default Fajr-start event after Suhoor remains single-shot unless the user opts into Fajr follow-up.

## 8. Fajr-start event after Suhoor

A Fajr-start event after Suhoor is distinct from a Fajr wake session.

| Behaviour | Wake checks? | Notes |
| --- | --- | --- |
| Suhoor wake session | Yes | Uses Suhoor boundary = Fajr begins. |
| Fajr-start event after Suhoor | No | Single AlarmKit event at Fajr begins. |
| User-selected Fajr follow-up | Yes | User intentionally configures Fajr wake session. |

The Fajr-start event may continue according to AlarmKit/system alarm behaviour until dismissed, but it does not spawn 5-minute wake checks.

## 9. No-response handling

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

## 10. Quiet and Pause interaction

Before execution begins:

- Quiet prevents the session from starting.
- Pause prevents the session from being scheduled unless ring-once applies.

After execution begins:

- `I’m awake` is the normal way to stop the session and cancel checks.
- Approved active-session Quiet cancellation, if exposed, requires confirmation and is logged separately from wake acknowledgement.
- Pause remains a future scheduling policy and should not retroactively rewrite the active wake session unless a later safety spec explicitly allows it.

## 11. Morning logs

The system may write separate log records for:

```text
wakeAcknowledged
suhoorWakeAcknowledged
fajrWakeAcknowledged
wakeEndedNoResponse
quietDuringExecution
fastingTodayLogged
fajrPrayerLogged
lateFajrPrayerLogged
alarmIssue
quietMorning
pausePolicyChanged
ringOnceExceptionUsed
```

These records must remain analytically distinct. Do not infer one from another unless explicitly defined.

## 12. Late Fajr logging

If Fajr prayer is not logged before Fajr ends, the Hero still rolls to the next relevant morning. A separate prompt below the context card may log the previous relevant morning.

CTA copy:

```text
I Prayed Fajr Earlier Today
I Prayed Fajr Yesterday Morning
```

The prompt disappears when tapped, when logged elsewhere, or when the next relevant wake window begins.

Expiry boundary:

| Next selected purpose | Prompt expires when |
| --- | --- |
| Fajr | next Fajr window begins |
| Suhoor | next Suhoor window begins |

## 13. Analytics and behavior shaping

Free/core logging should capture enough metadata to support user benefit and future insight without storing noisy micro-interactions.

Recommended metadata:

- target morning date;
- wake purpose;
- resolved alarm state at execution start;
- scheduled primary alarm time;
- relevant boundary used: Fajr begins or Fajr ends;
- follow-up schedule generated;
- acknowledgement time;
- acknowledgement source;
- number of follow-ups scheduled/fired/cancelled;
- whether Quiet/Pause/ring-once affected the morning;
- whether Fajr wake acknowledgement and Fajr prayer completion were logged separately;
- whether late logging was shown/tapped/expired.

Do not log every slider micro-movement. Persist final committed values and meaningful interactions.

## 14. Acceptance criteria

1. Active wake states show `I’m awake` as primary Slot 6 action.
2. `Stop checks` is not visible copy.
3. Active-session Quiet cancellation, if exposed, requires confirmation and is not wake acknowledgement.
4. System dismissal counts as wake acknowledgement for MVP with source preserved.
5. `I’m awake` cancels remaining follow-up alarms.
6. Follow-ups use 5-minute intervals and respect Fajr/Suhoor boundaries.
7. Latest wake time is relevant boundary minus 5 minutes.
8. Latest new session creation is relevant boundary minus 6 minutes.
9. No wake check is scheduled at the exact relevant boundary.
10. Suhoor acknowledgement and Fajr wake acknowledgement are separate outcome facts.
11. Suhoor acknowledgement does not automatically create a Fajr wake-check session.
12. Fajr-start event after Suhoor is single-shot and has no wake checks by default.
13. Optional Fajr follow-up is user-initiated and then uses normal Fajr wake-check rules.
14. `I’m Awake for Fajr` does not log Fajr prayer completion.
15. `I prayed Fajr` appears only after Fajr wake acknowledgement, after the anti-double-tap delay, and before Fajr ends.
16. Late Fajr logging appears below the context card after Hero rollover if completion was not logged.
17. No response is logged as no response, not missed Fajr/fast by default.
