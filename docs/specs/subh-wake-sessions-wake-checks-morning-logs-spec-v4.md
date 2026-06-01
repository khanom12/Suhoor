# Subh Wake Sessions, Wake Checks, and Morning Logs Specification v4 — June 1 CTA, Early-Awake, Wake-Check Display, and Logging Reconciliation

| Field | Value |
| --- | --- |
| Canonical filename | `subh-wake-sessions-wake-checks-morning-logs-spec-v4.md` |
| Version | 4 |
| Spec status | Active wake execution and logging contract |
| Date | 2026-06-01 |
| Related specs | Index, May 31 Scenario Walkthrough, Alignment, Morning Resolution, Hero, Quiet/Pause, Alarm Delivery, Testing Harness |
| Owning domain / surface | Alarm execution, follow-up alarms, acknowledgement, and morning logs |

## May 31, 2026 update status

Version 3 adds the 5-minute wake-check algorithm, the relevant-boundary minus 5/6 minute rules, the single-shot Fajr-start event after Suhoor, slider-activated Fajr wake checks after Suhoor, and separate Fajr wake vs prayer completion logging.

Canonical MVP doctrine:

```text
Wake purpose values: Fajr, Suhoor
Visible planning selector order: Suhoor | Fajr
Alarm state: active | quiet | paused | rings-once | blocked | issue
Execution state: not started | ringing | follow-up pending | awake acknowledged | fasting logged | Fajr logged | ended/no response | issue
```

## June 1, 2026 CTA/logging reconciliation

This version is reconciled with `subh-cta-logging-and-wake-action-spec-v2.md`. If earlier text in this file conflicts with the CTA spec, use the June 1 rules below:

- Active wake CTAs live in the Hero: **I’m Awake for Suhoor** and **I’m Awake for Fajr**.
- Logging and early-awake actions live in the context-card action area, not in the Hero and not as a separate standalone CTA card.
- Ordinary system/AlarmKit dismissal does not by itself mean the user is awake. It dismisses the current alarm attempt and the Hero must advance to the next pending wake-check time when one exists.
- Only explicit awake confirmation, confirmed early-awake action, or an explicitly supported platform action mapped to awake confirmation cancels remaining wake checks as wake success.
- **I’m Awake for Fajr** and **I Prayed Fajr** must not appear simultaneously.
- Late Fajr and fast completion use compact check/X prompt rows and must distinguish ✓, ✕, and unrecorded.
- Silence/unanswered is never treated as no.

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

- Slot 6 primary action is `I’m Awake`.
- Fajr/Suhoor switching is hidden or locked for that executing wake.
- Pause changes should not retroactively cancel the current executing wake unless a later safety spec explicitly allows it.
- The app must not show `Stop checks`.
- Quiet is not shown as a competing Slot 6 action. If an approved alarm-state control exposes active-session Quiet cancellation, it requires explicit confirmation and logs a distinct cancellation reason.

## 4. Primary wake acknowledgement

Active alarm and follow-up states show purpose-specific user-facing CTAs:

```text
I’m Awake for Suhoor
I’m Awake for Fajr
```

Explicit wake acknowledgement must:

- stop the current alarm sound;
- cancel remaining follow-up alarms for that purpose-scoped session;
- record wake acknowledgement;
- preserve acknowledgement source;
- advance the Hero to the appropriate post-acknowledgement state.

Ordinary system/AlarmKit dismissal without explicit awake confirmation is not wake acknowledgement. It must:

- stop/dismiss the current attempt;
- keep the wake session unresolved;
- leave later valid checks scheduled;
- update the Hero to the next pending wake-check time;
- preserve dismissal source for analytics/debugging.

Allowed explicit acknowledgement sources:

```text
inAppAwakeButton
supportedAwakeNotificationAction
earlyAwakeConfirmation
reconciliationFallbackOnlyWhenPlatformProvesAwake
```

Dismissal-only sources:

```text
systemAlarmDismiss
systemNotificationDismiss
timeout
unknownDismissal
```

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
Fajr alarm/check fires
→ user may dismiss current attempt without confirming awake
→ if dismissed without awake confirmation, next valid check remains scheduled and Hero advances to its time
→ user taps I’m Awake for Fajr
→ remaining Fajr follow-ups cancelled
→ Fajr wake acknowledgement logged
→ short anti-double-tap cooldown, starting target 1.5 seconds
→ if Fajr has begun and not ended, show I Prayed Fajr in the context-card action area
→ user taps I Prayed Fajr
→ Fajr prayer completion logged
→ at Fajr end, Home switches to next morning
```

`I’m Awake for Fajr` does not log Fajr prayer completion. `I Prayed Fajr` logs prayer completion separately. Do not show them simultaneously.

## 7. Suhoor wake flow

```text
Suhoor alarm/check fires
→ user may dismiss current attempt without confirming awake
→ if dismissed without awake confirmation, next valid check remains scheduled and Hero advances to its time
→ user taps I’m Awake for Suhoor
→ remaining Suhoor follow-ups cancelled
→ Suhoor wake acknowledgement logged
→ Hero transitions to same-morning Fajr
→ default Fajr delivery target is Fajr beginning / adhan-event
→ no Fajr wake checks are created by default
→ if user commits a later Fajr slider value, create/activate a normal Fajr wake session with checks
→ if Fajr wake session runs, show I’m Awake for Fajr
→ Fajr wake acknowledgement remains separate from Suhoor wake acknowledgement
```

There is no active Suhoor-flow CTA called `I’m fasting today`. Fast completion is logged after Maghrib through context-card check/X prompts when Suhoor was selected or when the date is Ramadan.

## 8. Fajr-start event after Suhoor

A Fajr-start event after Suhoor is distinct from a Fajr wake session.

| Behaviour | Wake checks? | Notes |
| --- | --- | --- |
| Suhoor wake session | Yes | Uses Suhoor boundary = Fajr begins. |
| Fajr-start event after Suhoor | No | Single AlarmKit event at Fajr begins. |
| User-selected post-Suhoor Fajr slider activation | Yes | User intentionally configures Fajr wake session. |

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

- `I’m Awake` is the normal way to stop the session and cancel checks.
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

If Fajr prayer is not logged before Fajr ends, the Hero still rolls to the next relevant morning. A compact prompt inside the context-card action area may log the previous relevant morning.

CTA copy:

```text
I prayed Fajr earlier today? ✓ ✕
I prayed Fajr yesterday morning? ✓ ✕
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

1. Active wake states show `I’m Awake` as primary Slot 6 action.
2. `Stop checks` is not visible copy.
3. Active-session Quiet cancellation, if exposed, requires confirmation and is not wake acknowledgement.
4. System dismissal without explicit awake confirmation does not count as wake acknowledgement; it advances to the next pending wake check when one exists, with source preserved.
5. `I’m Awake` cancels remaining follow-up alarms.
6. Follow-ups use 5-minute intervals and respect Fajr/Suhoor boundaries.
7. Latest wake time is relevant boundary minus 5 minutes.
8. Latest new session creation is relevant boundary minus 6 minutes.
9. No wake check is scheduled at the exact relevant boundary.
10. Suhoor acknowledgement and Fajr wake acknowledgement are separate outcome facts.
11. Suhoor acknowledgement does not automatically create a Fajr wake-check session.
12. Fajr-start event after Suhoor is single-shot and has no wake checks by default.
13. Slider-activated Fajr wake checks after Suhoor is user-initiated and then uses normal Fajr wake-check rules.
14. `I’m Awake for Fajr` does not log Fajr prayer completion.
15. `I Prayed Fajr` appears only after Fajr wake acknowledgement, after the anti-double-tap delay, and before Fajr ends.
16. Late Fajr logging appears inside the context-card action area after Hero rollover if completion was not logged.
17. No response is logged as no response, not missed Fajr/fast by default.

---

## June 1 Addendum: Wake Execution and Log Reconciliation

### A. Wake attempt dismissal

A wake attempt can be dismissed without the user explicitly confirming awake. In that case:

- the current alarm/check stops;
- the wake session remains unresolved;
- any later valid wake checks remain scheduled;
- the Hero displays the next pending wake-check time;
- no wake success is logged.

Only **I’m Awake for Suhoor**, **I’m Awake for Fajr**, confirmed early-awake, or an explicitly supported platform action mapped to awake confirmation resolves wake success.

### B. Fajr prayer sequence

Fajr wake and prayer completion are sequential:

```text
I’m Awake for Fajr
→ short anti-double-tap cooldown, starting target 1.5 seconds
→ I Prayed Fajr in the context-card action area
```

Do not show both actions at the same time.

### C. Fast completion replaces the old fasting-today log

There is no active wake-session CTA called **I’m fasting today** in this reconciled model. Fast completion is logged after Maghrib through compact check/X prompts when Suhoor was selected or the date is Ramadan.

### D. Qada candidate foundations

- Fajr ✕ creates future Qada Fajr relevance.
- Ramadan fast ✕ creates future Qada fast relevance.
- Optional fast ✕ supports statistics and encouragement but does not create the same Qada fast requirement.
- Expired unresolved prompts do not create Qada candidates.

