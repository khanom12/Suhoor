# Subh Wake Sessions, Wake Checks, and Morning Logs Spec v1.0

**Status:** Ready for implementation planning
**Scope:** Core/free MVP behavior
**Product spine:** Fajr-centered morning system
**Canonical owner:** This spec owns wake execution, wake confirmation, wake checks, and immediate morning logs. Other specs should reference this spec rather than duplicate its rules.
**Related specs:** `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md`, `subh-morning-hero-item-spec-v15.md`, `subh-quiet-mode-quiet-morning-contract-spec-v1.md`, `subh-sound-alarm-settings-spec-v1.md`

---

## v1.1 Alignment Note

This bundle adds the missing companion specs referenced by this Wake Sessions spec:

- `subh-quiet-mode-quiet-morning-contract-spec-v1.md`
- `subh-sound-alarm-settings-spec-v1.md`
- `00-subh-spec-index-v3.md`

The Wake Sessions spec remains the canonical owner for wake execution, wake checks, awake confirmation, and immediate MorningLog behavior. The new Quiet Mode and Sound specs own their narrower domains and should be referenced rather than duplicating their rules here.


## 1. Purpose

Subh must not treat a dismissed alarm as proof that the user is awake. This spec defines a **Wake Session** model in which Subh continues wake support through scheduled wake checks until the user explicitly confirms they are awake or the relevant morning window closes.

The same morning can also contain separate records for Suhoor, fasting intention, Fajr waking, and Fajr prayer. These records are related but not interchangeable.

---

## 2. Core principles

1. **Alarm stopped ≠ user awake.**
2. **Awake confirmed ≠ Fajr prayed.**
3. **Suhoor confirmed ≠ Fajr prayed.**
4. **Suhoor mode implies a planned fasting day, but fasting completion remains a separate future record.**
5. **Quiet Mode cancels wake execution but does not mean the user missed Fajr.**
6. **Automatic logs must be factual, not judgmental.**
7. **The hero layout must remain vertically stable while its action content changes.**
8. **This version implements the core/free behavior only; adaptive and advanced analytics remain future/paid scope.**

---

## 3. Definitions

| Term | Definition |
|---|---|
| **Wake Session** | The resolved operational wake plan for one local morning. Includes primary alarm, wake checks, confirmation state, and cancellation/expiry state. |
| **Primary alarm** | The first scheduled AlarmKit alarm for the resolved wake time. |
| **Wake check** | A follow-up alarm scheduled after the primary alarm if the user has not confirmed awake. |
| **Awake confirmation** | Explicit in-app user action: `I’m awake for Fajr` or `I’m awake for Suhoor`. |
| **Prayer confirmation** | Explicit in-app user action: `I prayed Fajr`. |
| **Fasting day planned** | The day has been set to Suhoor mode and therefore carries intended fasting context. |
| **Fasting intention confirmed** | The user has confirmed Suhoor wake, or later explicitly confirms fasting intent where supported. |
| **Quiet Morning** | A deliberate one-morning alarm suppression state. It is not a missed-prayer label. |
| **Hard cutoff** | The latest time at which Subh may schedule a wake check for that mode. |

---

## 4. Morning records that must remain separate

| Record | Meaning | Primary user action | Automatic? |
|---|---|---|---|
| **Suhoor wake outcome** | User woke during the Suhoor/pre-Fajr window. | `I’m awake for Suhoor` | No |
| **Fasting day planned** | User selected Suhoor mode for the morning. | Select/toggle Suhoor | Yes, when Suhoor is selected |
| **Fasting intention confirmed** | User actively confirmed the Suhoor wake/fasting morning. | `I’m awake for Suhoor` | Yes, after Suhoor wake confirmation |
| **Fajr wake outcome** | User confirmed being awake during the Fajr prayer window. | `I’m awake for Fajr` | No |
| **Fajr prayer outcome** | User confirmed that Fajr was prayed. | `I prayed Fajr` | No |
| **Fast completion outcome** | User completed the fast. | Future: `I completed today’s fast` | Future only |

Subh must not infer `Fajr prayed` from `I’m awake for Fajr`, and must not infer `Fajr missed` from no confirmation.

---

## 5. Modes and windows

### 5.1 Fajr mode

Fajr mode is the default year-round wake mode.

| Item | Rule |
|---|---|
| Default wake anchor | 30 minutes before Fajr ends, unless changed elsewhere by existing wake-resolution rules |
| Awake confirmation window | `Fajr begins <= now < Fajr ends` |
| Primary CTA | `I’m awake for Fajr` |
| Prayer CTA | `I prayed Fajr`, after awake confirmation or where prior awake state is already valid |
| Wake-check hard cutoff | `Fajr ends - 5 minutes` |

### 5.2 Suhoor mode

Suhoor mode is the fasting-oriented pre-Fajr wake mode. It implies a planned fasting day.

| Item | Rule |
|---|---|
| Default wake anchor | 30 minutes before Fajr begins, unless changed elsewhere by existing wake-resolution rules |
| Suhoor awake confirmation window | `final third begins <= now < Fajr begins` |
| Suhoor CTA | `I’m awake for Suhoor` |
| Fasting day planned | Set when Suhoor mode is selected |
| Fasting intention confirmed | Set when user taps `I’m awake for Suhoor` |
| Wake-check hard cutoff | `Fajr begins - 5 minutes` |
| After Fajr begins, if Suhoor wake was confirmed | Primary CTA becomes `I prayed Fajr` |
| After Fajr begins, if Suhoor wake was not confirmed | Primary CTA becomes `I’m awake for Fajr`; after that, `I prayed Fajr` |

### 5.3 Quiet Morning

Quiet Morning suppresses wake execution for the current/resolved morning.

| Item | Rule |
|---|---|
| Meaning | Do not ring alarms/wake checks for this morning |
| Log outcome | `quietMorning` |
| Must not log | `Fajr missed`, `Fast missed`, or any prayer judgment |
| During active wake session | Requires confirmation sheet before cancelling alarms |

---

## 6. Wake-check scheduling rules

### 6.1 Default core/free behavior

```text
Primary alarm + up to 5 wake checks
Wake-check interval: 5 minutes
Maximum total wake attempts: 6
```

A wake check is scheduled only if all are true:

```text
wakeCheckTime > primaryAlarmTime
wakeCheckTime <= modeHardCutoff
wakeCheckIndex <= 5
wakeSession is not confirmedAwake
wakeSession is not quiet/cancelled
```

### 6.2 Fajr example

```text
Fajr ends: 6:25
Primary alarm: 5:55
Hard cutoff: 6:20

5:55 primary alarm
6:00 wake check 1
6:05 wake check 2
6:10 wake check 3
6:15 wake check 4
6:20 wake check 5
```

No wake check is scheduled at Fajr end.

### 6.3 Suhoor example

```text
Fajr begins: 5:10
Primary alarm: 4:40
Hard cutoff: 5:05

4:40 primary alarm
4:45 wake check 1
4:50 wake check 2
4:55 wake check 3
5:00 wake check 4
5:05 wake check 5
```

No wake check is scheduled at Fajr begins.

### 6.4 Close-to-cutoff case

If the primary alarm is too close to the cutoff, Subh schedules only the primary alarm and any wake checks that fit before the hard cutoff.

Example:

```text
Fajr ends: 6:25
Primary alarm: 6:18
Hard cutoff: 6:20

6:18 primary alarm
No 6:23 wake check because 6:23 is after the 6:20 hard cutoff.
```

The UI may explain this only where necessary, without adding hero clutter.

---

## 7. Wake Session lifecycle

### 7.1 Required states

| State | Meaning |
|---|---|
| `planned` | Morning has a resolved wake plan but is not yet in the active operational window. |
| `scheduled` | Primary alarm and eligible wake checks have been scheduled. |
| `activeWindowOpen` | User may confirm awake for the current mode/window. |
| `primaryAlarmFired` | Primary alarm time has arrived. |
| `unconfirmed` | The user has not confirmed awake. |
| `wakeChecksPending` | One or more wake checks remain scheduled. |
| `confirmedAwakeForSuhoor` | User tapped `I’m awake for Suhoor`. |
| `confirmedAwakeForFajr` | User tapped `I’m awake for Fajr`. |
| `fajrPrayerConfirmed` | User tapped `I prayed Fajr`. |
| `expiredUnconfirmed` | Relevant window closed without awake confirmation. |
| `quietMorning` | User deliberately suppressed alarms for this morning. |
| `cancelledForMorning` | Wake execution was cancelled due to a mode/time change or explicit stop-for-morning action. |

### 7.2 State transition rules

| Trigger | Required result |
|---|---|
| User changes wake time | Cancel old alarm IDs, recompute, and reschedule the Wake Session. |
| User switches Fajr ↔ Suhoor | Cancel old alarm IDs, recompute mode windows and wake checks, reschedule. |
| User taps `I’m awake for Suhoor` | Mark `confirmedAwakeForSuhoor`; mark/affirm `fastingIntentConfirmed`; cancel primary alarm if pending; cancel all remaining wake checks. |
| User taps `I’m awake for Fajr` | Mark `confirmedAwakeForFajr`; cancel primary alarm if pending; cancel all remaining wake checks. |
| User taps `I prayed Fajr` | Mark `fajrPrayerConfirmed`; do not mutate fasting or wake records except as explicitly defined by UI flow. |
| User stops an AlarmKit alarm | Stop only that alarm occurrence; do not mark awake; keep remaining wake checks unless already cancelled. |
| User selects Quiet during active session | Show confirmation sheet; if confirmed, cancel all alarms and log `quietMorning`. |
| Window closes without confirmation | Mark wake outcome `expiredUnconfirmed`; do not mark prayer/fast missed. |

---

## 8. Hero UI contract

### 8.1 Fixed Hero Action Slot

The hero must reserve a fixed-height **Hero Action Slot** so the layout does not jump when the morning state changes.

The slot changes content but not its vertical footprint.

```text
Location / context row
Today / tomorrow row
Primary wake time
Wake explanation line
Hero Action Slot
Fajr/Suhoor wake selector or related controls
```

Quiet Mode placement should follow the latest Quiet Mode contract: it is an alarm-suppression control, not the same kind of wake target as Fajr/Suhoor.

### 8.2 Normal planning state

Show the adjustment slider in the Hero Action Slot.

```text
[ adjustment slider ]
```

### 8.3 Active window before primary alarm fires

If the user is already inside the valid confirmation window but the primary alarm has not fired, keep the slider available and add a compact awake action in the same slot.

Fajr:

```text
[ adjustment slider ]
Already awake? [I’m awake]
```

Suhoor:

```text
[ adjustment slider ]
Already awake? [I’m awake]
```

The compact button resolves to the mode-specific action:

```text
Fajr mode   -> I’m awake for Fajr
Suhoor mode -> I’m awake for Suhoor
```

### 8.4 After primary alarm fires, before confirmation

Replace the slider with the prominent confirmation CTA.

Fajr:

```text
[I’m awake for Fajr]
Wake checks will continue until you confirm.
```

Suhoor:

```text
[I’m awake for Suhoor]
Wake checks will continue until you confirm.
```

### 8.5 After awake confirmation

Fajr mode:

```text
Awake confirmed at {time}
[I prayed Fajr]
```

Suhoor mode before Fajr begins:

```text
Awake for Suhoor confirmed
Fasting today
```

Suhoor mode after Fajr begins, if Suhoor wake was confirmed:

```text
Awake for Suhoor confirmed
[I prayed Fajr]
```

Suhoor mode after Fajr begins, if Suhoor wake was not confirmed:

```text
[I’m awake for Fajr]
Wake checks for Suhoor have ended.
```

After `I’m awake for Fajr`, the CTA may become:

```text
[I prayed Fajr]
```

### 8.6 After Fajr prayer confirmation

```text
Fajr confirmed at {time}
```

If the user also confirmed Suhoor:

```text
Suhoor confirmed · Fajr confirmed
```

The exact copy may be refined by the design/copy spec, but the state meanings must not change.

---

## 9. AlarmKit / Lock Screen behavior

### 9.1 No native snooze for MVP

Subh should not use a native snooze mechanic for the Wake Checks feature. Wake checks are separate scheduled alarms owned by the Wake Session.

### 9.2 Lock Screen actions

Primary alarm examples:

```text
Wake for Fajr
Stop
Open Subh
```

```text
Wake for Suhoor
Stop
Open Subh
```

Wake-check examples:

```text
Fajr wake check
Stop
Open Subh
```

```text
Suhoor wake check
Stop
Open Subh
```

`Open Subh` should bring the user to the relevant morning hero where the in-app confirmation CTA appears.

### 9.3 Stop behavior

Stopping/dismissing the alarm from the Lock Screen must not mark the user awake. It only stops the currently alerting alarm occurrence.

Remaining wake checks stay scheduled unless the user confirms awake, switches to Quiet, or changes/cancels the morning plan.

---

## 10. Audio ramping

Subh should support gentle wake behavior through the sound asset itself, not through runtime per-alarm volume control.

Required asset approach:

```text
The audio waveform starts quietly and gradually increases in perceived intensity.
```

Recommended future asset names:

```text
adhan_fajr_gentle_ramp
adhan_fajr_balanced_ramp
adhan_fajr_strong_ramp
subh_chime_gentle_ramp
```

This spec does not require code-level volume ramping. It requires the app to be able to reference the chosen bundled/custom alarm sound according to the existing AlarmKit sound implementation.

---

## 11. Logging model

### 11.1 Logs exist for all users

Subh may create local operational logs for all users because they are necessary for wake reliability and state reconciliation.

Free/core includes:

```text
current morning state
recent operational state needed for reliability
basic user confirmations
```

Future/paid may unlock:

```text
long-term history
analytics
streaks
adaptive recommendations
export/backup
advanced filtering
```

### 11.2 MorningLog fields

A MorningLog should support at least:

```text
morningId
localDate
timeZoneId
locationContextId
hijriDateContext
mode: fajr | suhoor | quiet
fajrBegins
fajrEnds
finalThirdBegins
resolvedWakeTime
primaryAlarmId
wakeCheckAlarmIds[]
wakeCheckIntervalMinutes = 5
maxWakeChecks = 5
wakeOutcome
suhoorWakeOutcome
fajrWakeOutcome
fastingDayPlanned
fastingIntentConfirmed
fastCompletionOutcome // future-ready
fajrPrayerOutcome
quietMorning
createdAt
updatedAt
```

### 11.3 Outcome values

Wake outcomes:

```text
notYetOpen
scheduled
primaryFired
confirmedAwake
expiredUnconfirmed
quietMorning
cancelledForMorning
```

Suhoor wake outcome:

```text
notApplicable
planned
confirmedAwakeForSuhoor
expiredUnconfirmed
```

Fajr wake outcome:

```text
notYetOpen
confirmedAwakeForFajr
expiredUnconfirmed
unconfirmed
```

Fajr prayer outcome:

```text
unconfirmed
confirmedPrayed
confirmedPrayedLater // future-ready
confirmedMissed // explicit user action only; not automatic
notRequiredOrExempt // future-ready/private-sensitive
```

Fasting outcomes:

```text
notPlanned
planned
intentionConfirmed
completionUnconfirmed
completed // future-ready
notCompleted // explicit user action only; not automatic
```

### 11.4 Event log examples

Subh may log factual events such as:

```text
wakeSessionCreated
primaryAlarmScheduled
wakeCheckScheduled
primaryAlarmFired
wakeCheckFired
alarmStopped
awakeForSuhoorConfirmed
fastingIntentConfirmed
awakeForFajrConfirmed
fajrPrayerConfirmed
wakeChecksCancelled
wakeSessionExpiredUnconfirmed
quietMorningSelected
quietMorningConfirmed
modeChanged
wakeTimeChanged
scheduleReconciled
```

Subh must not automatically log:

```text
Fajr missed
Fast missed
Prayer skipped
```

---

## 12. Quiet Mode confirmation sheet

If the user selects Quiet during an active wake session, show a confirmation sheet:

```text
Stop wake checks for this morning?

Subh will cancel the remaining alarms and mark this morning as quiet.

[Keep wake checks]
[Stop for this morning]
```

If confirmed:

```text
cancel primary alarm if pending
cancel all wake checks
log quietMorning
hide awake/prayer CTAs as appropriate
```

Do not mark Fajr or fasting as missed.

---

## 13. Future/paid scope placeholders

The following are intentionally not part of the current implementation pass:

| Future area | Description |
|---|---|
| Adaptive Wake Checks | Subh suggests increasing/decreasing wake checks based on recent behavior. |
| Advanced interval control | User can choose intervals such as 2, 3, 5, or 10 minutes. |
| Advanced wake-check count | User can set max wake checks beyond the default. |
| Heavy-sleeper profile | Stronger alarm sequence and escalation rules. |
| Long-term insights | Trends, streaks, consistency, and reflection views. |
| Fast completion logging | Evening/later-day confirmation that the fast was completed. |
| Prayer analytics | Long-term Fajr wake/prayer patterns. |

Do not implement paywalls, StoreKit, entitlement checks, or premium analytics as part of this spec unless a separate pricing/entitlement implementation pass explicitly requests them.

---

## 14. Reconciliation requirements

When the app opens, returns from background, crosses midnight, changes timezone/location context, or receives alarm state changes, Subh must reconcile:

```text
current local time
resolved morning boundaries
stored Wake Session
stored MorningLog
scheduled AlarmKit IDs
current mode
quiet state
awake/prayer/fasting confirmations
```

If stale alarms exist after a mode/time/boundary change, they must be cancelled and replaced with the corrected alarm set.

If the current time is past the relevant cutoff, Subh must not schedule new wake checks for that window.

---

## 15. Edge cases

| Case | Required behavior |
|---|---|
| User wakes before primary alarm and taps `I’m awake for Fajr` | Cancel primary alarm and wake checks; mark Fajr awake confirmed. |
| User wakes before primary alarm and moves slider later | Recompute and reschedule the primary alarm/wake checks if still within valid scheduling window. |
| User wakes for Suhoor and taps `I’m awake for Suhoor` | Cancel remaining Suhoor alarms; log Suhoor awake and fasting intention confirmed. |
| Suhoor user reaches Fajr begins after confirming Suhoor | Show `I prayed Fajr` as primary CTA. |
| Suhoor user reaches Fajr begins without confirming Suhoor | Suhoor wake expires unconfirmed; show `I’m awake for Fajr` first. |
| User stops every alarm but never opens app | Wake session expires unconfirmed; do not mark Fajr missed. |
| User switches to Quiet during active wake checks | Confirm first; then cancel alarms and log `quietMorning`. |
| Primary alarm is after hard cutoff | Schedule primary only if valid under existing alarm rules; no wake checks beyond cutoff. |
| Fajr prayer is confirmed without prior awake confirmation through a future surface | Allow data model to store prayer confirmation independently; do not require data falsification. |
| User changes time zone/location | Re-resolve boundaries and reschedule only if the morning remains operationally valid. |
| App is killed/reopened after confirmation | Reconstruct state from MorningLog and cancel/reconcile any stale alarms. |

---

## 16. Acceptance criteria

### 16.1 Fajr wake checks

Given a Fajr morning with wake time 30 minutes before Fajr ends, when the Wake Session is scheduled, then Subh schedules one primary alarm and up to five wake checks at five-minute intervals, with no wake check later than five minutes before Fajr ends.

### 16.2 Suhoor wake checks

Given a Suhoor morning with wake time 30 minutes before Fajr begins, when the Wake Session is scheduled, then Subh schedules one primary alarm and up to five wake checks at five-minute intervals, with no wake check later than five minutes before Fajr begins.

### 16.3 Alarm stop does not confirm awake

Given an alarm fires, when the user stops it from the Lock Screen, then the current alarm stops but the Wake Session remains unconfirmed and eligible remaining wake checks stay scheduled.

### 16.4 Awake confirmation cancels remaining alarms

Given a Wake Session has pending alarms, when the user taps `I’m awake for Fajr` or `I’m awake for Suhoor`, then Subh marks the relevant awake confirmation and cancels all remaining alarms for that morning.

### 16.5 Suhoor implies fasting context

Given the user selects Suhoor mode, then the MorningLog marks `fastingDayPlanned`. Given the user taps `I’m awake for Suhoor`, then the MorningLog marks `fastingIntentConfirmed`.

### 16.6 Prayer logging remains separate

Given the user taps `I’m awake for Fajr`, then Subh must not mark `fajrPrayerConfirmed` until the user taps `I prayed Fajr`.

### 16.7 No automatic missed labels

Given the user never confirms awake or prayer, then Subh may mark `expiredUnconfirmed` or `unconfirmed`, but must not automatically mark Fajr or fasting as missed.

### 16.8 Hero layout stability

Given the hero enters or exits active wake states, then the surrounding hero layout must not shift vertically; only the content inside the fixed Hero Action Slot changes.

### 16.9 Quiet Mode safety

Given the user selects Quiet during an active Wake Session, then Subh shows the confirmation sheet before cancelling alarms. If confirmed, Subh logs `quietMorning` and does not log Fajr missed.

### 16.10 Future paid scope not implemented

Given this implementation pass, then Subh must not add adaptive recommendations, long-term insights, advanced interval customization, StoreKit, paywalls, or entitlement checks unless required by a separate spec.

---

## 17. Documents to update by reference

After this spec is accepted, update these existing specs by reference only:

1. **Subh Morning Resolution Contract and State Ownership Spec**
   Add Wake Session ownership and separate wake/prayer/fasting outcomes.

2. **Subh Alarm Delivery and Schedule Reliability Spec**
   Add primary alarm + wake-check scheduling, alarm ID ownership, cancellation, and reconciliation rules.

3. **Subh Morning Hero Item Spec**
   Add fixed Hero Action Slot and state-based CTAs.

4. **Subh MVP Interaction Inventory**
   Add interactions for awake confirmation, prayer confirmation, Suhoor confirmation, Quiet during active session, alarm stop, and wake-check expiry.

5. **Subh Planning Horizon / Day Resolution / Intention Anchoring Spec**
   Add the distinction between Suhoor-selected fasting day, fasting intention confirmation, and future fast completion.

6. **Subh Pricing Entitlement Spec**
   Clarify that Wake Sessions, Wake Checks, and basic local morning logs are free/core; long-term insights and adaptive controls remain future/paid.

7. **Quiet Mode / Quiet Morning Contract**
   Align Quiet Mode as alarm suppression that logs `quietMorning`, not missed prayer.

8. **Sound / Alarm Settings Spec, if present**
   Add ramped sound asset expectations and avoid promising runtime volume control.

9. **OpenSpec index / source-of-truth map**
   Register this spec as the canonical owner for Wake Sessions, Wake Checks, and immediate Morning Logs.

---

## 18. Non-goals

This spec does not implement:

```text
StoreKit
paid tiers
adaptive wake logic
advanced wake-check interval controls
long-term analytics UI
fast completion UI
prayer streaks
social/accountability features
cloud sync
new religious-ruling logic
```

It only defines the core wake execution and immediate morning confirmation model.
