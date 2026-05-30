# Subh Quiet, Pause, Hero, and Morning Wake Flow Alignment Specification v2

| Field | Value |
| --- | --- |
| Canonical filename | `subh-quiet-pause-hero-wake-flow-alignment-spec-v2.md` |
| Version | 2 |
| Spec status | Canonical cross-spec alignment source of truth for the May 29/30 Quiet/Pause/Hero pass |
| Date | 2026-05-30 |
| Supersedes / overrides | Conflicting lower sections in active specs that treat Quiet as a wake purpose, expose `Pre-Fajr`/`Early`/`Fast` as user-facing wake purposes, show two active wake buttons, or use older hero copy |
| Related specs | `00-subh-spec-index-v4.md`, Morning Resolution, Planning Horizon, Quick Wake Mutation, Quiet Morning, Wake Sessions, Alarm Delivery, Morning Hero, Alarm Detail, Next 7 Mornings, Month Planning, Pricing/Tier Matrix, Testing Harness |
| Owning domain / surface | Cross-spec doctrine for Quiet, indefinite Pause, fixed-height Home Hero, wake-session hero states, and user-facing copy |

## 1. Purpose

This specification consolidates the final May 29 decision pass and the May 30 spec-reconciliation pass for Quiet, indefinite Pause, the fixed-height Home Hero, and wake-session copy/behavior.

The May 30 pass makes this file a direct implementation source of truth, not merely a loose addendum. Active specs in the root of the reconciled package have been rewritten or amended to remove conflicting lower-body requirements. Archived originals are traceability records only.

This specification consolidates the final May 29 decision pass for Quiet, indefinite Pause, the fixed-height Home Hero, and wake-session copy/behavior.

It is intentionally cross-cutting. The detailed domain specs still own their implementation areas, but this alignment spec is normative where older active specs conflict with the decisions below.

## 2. Canonical doctrine

Subh is a Fajr-centered morning system.

Each editable morning has a **wake purpose**:

```text
Fajr
Suhoor
```

Each editable morning also has an **alarm / sound state**:

```text
active
quiet for this morning
paused by app-wide pause
rings once despite pause
blocked / setup needed
issue / failed delivery
```

Quiet and Pause must not be modeled as siblings of Fajr and Suhoor.

```text
Correct model:
Wake purpose: Fajr | Suhoor
Alarm state: active | quiet | paused | rings-once | blocked | issue

Incorrect model:
Fajr mode | Suhoor mode | Quiet mode | Pause mode
```

## 3. Terminology rules

### 3.1 User-facing terms

Use these in visible app copy:

```text
Fajr
Suhoor
Quiet
Alarms paused
Time to wake
Next alarm soon
I’m awake
I’m fasting today
I prayed Fajr
Fajr complete
Alarm saved for 5:42 AM
No response recorded
Alarm ended
Alarm issue
Turn on alarms
Set location
```

### 3.2 Deprecated user-facing terms

Do not expose these as MVP user-facing wake purposes or hero/status copy:

```text
Pre-Fajr
Early
Early worship
Fast mode
Fasting mode
Quiet mode
Pause mode
Wake checks active
Wake confirmed
Wake ended
Saved wake
Saved Fajr wake
Saved Suhoor wake
No wake confirmed
Stop checks
Delivery suppressed
Active despite pause
Permission blocked
```

Implementation and specs may still use internal terms such as `WakeSession`, `WakeCheck`, `deliveryState`, or legacy enum cases where the current code requires them, but user-facing copy must use the plain-language vocabulary above.

### 3.3 “Wake” copy rule

Use `wake up` as a verb when natural, but avoid `wake` as a noun in visible copy.

```text
Preferred: Alarm saved for 5:42 AM
Avoid: Saved wake: 5:42 AM

Preferred: No response recorded
Avoid: No wake confirmed

Preferred: Alarm ended
Avoid: Wake ended
```

## 4. Data model / resolution layers

The canonical resolved morning should preserve these layers separately:

```text
MorningContext
  date, location, prayer times, calendar context, opportunity context

WakePurpose
  Fajr | Suhoor

PurposeSpecificAlarmConfig
  fajrAlarmConfig
  suhoorAlarmConfig

DateAlarmOverride
  none | quiet | ringDespitePause

GlobalWakeAlarmPolicy
  active | pausedIndefinitely

ResolvedAlarmState
  active | quiet | pausedInherited | ringsOnceDespitePause | blocked | issue | unavailable

WakeExecutionState
  notStarted | scheduled | ringing | followUpPending | awakeAcknowledged | fastingLogged | fajrLogged | endedNoResponse | issue
```

Quiet and Pause must never erase the selected wake purpose or the purpose-specific alarm settings.

## 5. Fajr/Suhoor memory rules

Each editable morning must remember Fajr and Suhoor alarm settings separately.

Example:

```text
Tomorrow
Fajr alarm: 15 min before Fajr ends
Suhoor alarm: 45 min before Fajr begins
Selected purpose: Fajr
Alarm state: Quiet
```

If the user switches to Suhoor while Quiet, the date remains Quiet but the displayed saved time changes to the saved Suhoor alarm. If the user switches back to Fajr, the saved Fajr alarm returns.

Required rules:

1. Switching Fajr/Suhoor changes wake purpose only.
2. Quiet/Pause changes whether Subh rings.
3. Switching purpose must not destroy the other purpose’s saved alarm configuration.
4. Quiet/Pause must not reset purpose-specific custom alarm settings.
5. Resetting an alarm time should reset only the currently selected purpose unless the user explicitly chooses a broader “reset this morning” action.

## 6. Quiet

Quiet is a date-level alarm decision.

```text
Quiet = Subh will not ring for this specific morning.
```

Quiet must:

- suppress the primary alarm and follow-up alarms for the target morning;
- cancel stale scheduled delivery for the target morning;
- prevent a Wake Session from starting for that target morning;
- preserve Fajr/Suhoor purpose and saved alarm settings;
- preserve day meaning, opportunity context, Ramadan context, and logs;
- remain distinct from permission failure, delivery failure, missing location, missing prayer times, and missed-prayer assumptions.

Quiet is available before the alarm begins. Once the first alarm has begun, Quiet is no longer a user-facing action for that wake.

## 7. Indefinite Pause

Pause is an app-wide wake-alarm policy.

```text
Alarms paused = Subh wake alarms will stay off until the user resumes them.
```

MVP Pause is indefinite only.

Do not expose these in MVP:

```text
pause until date
pause for 3 mornings
date-range pause
recurring pause
reason picker for pause/quiet
```

Pause must:

- live primarily in Settings / Wake Alarms;
- suppress upcoming Subh wake alarms and follow-up alarms while active;
- preserve all saved Fajr/Suhoor plans and date-specific overrides;
- show a visible paused state on Home without changing hero height;
- allow `Ring tomorrow only` / `Ring this morning only` as a date-specific exception;
- allow global resume from the paused state;
- keep manual Quiet decisions intact after global resume.

Future date-range silence, if introduced later, should be modeled as `Quiet selected mornings`, not as MVP Pause.

## 8. Precedence rules

Resolve the final alarm state using this precedence:

```text
1. Missing setup / blocked / issue states where applicable.
2. Manual Quiet for the selected date.
3. Global Pause, unless the date has ringDespitePause.
4. Active alarm for the selected Fajr/Suhoor purpose.
```

Manual Quiet beats `ringDespitePause` if both somehow exist.

When global Pause is resumed:

- dates that inherited Pause return to their saved Fajr/Suhoor plans;
- dates manually set to Quiet remain Quiet;
- `ringDespitePause` exceptions expire after their target morning or are cleared when no longer relevant.

## 9. Home Hero fixed-height design

The Home Hero is a fixed-height state machine. Its frame height, baselines, text sizes, slot heights, and vertical spacing must not change between states.

The hero has six fixed slots:

```text
Slot 1 — Location
Slot 2 — Morning label
Slot 3 — Primary alarm-state button / status
Slot 4 — Alarm slider / timeline surface
Slot 5 — One-line supporting copy
Slot 6 — Primary action row
```

Required layout rules:

- No vertical expansion/collapse by state.
- No moving the selector up/down.
- No state-specific hero height.
- Slot 3 uses one primary text style across all states.
- Slot 5 is single-line and truncation-safe.
- Slot 6 uses the same physical row for `Fajr | Suhoor`, `I’m awake`, `I’m awake for Fajr`, `I’m fasting today`, `I prayed Fajr`, and checked status pills.
- State transitions should use opacity/crossfade/symbol change/glass treatment, not layout shifts.

## 10. Home Hero Slot 2 copy

Use morning-centered labels:

```text
Tomorrow morning
This morning
Now
Later this morning
```

Rules:

- `Tomorrow morning`: next-morning planning.
- `This morning`: same-morning planning or Fajr-prayer period after the alarm flow.
- `Now`: alarm ringing or follow-up alarm pending/ringing.
- `Later this morning`: after Suhoor alarm is acknowledged and before Fajr begins.
- At Fajr end, Home Hero switches to the next morning.

Avoid `Today`, `Tomorrow`, and `Morning complete` as primary Home Hero labels unless a later spec explicitly needs them.

## 11. Home Hero state table

Slot 1 is always the resolved location. Slot 4 remains present in every state.

| Phase / state | Slot 2 | Slot 3 primary | Slot 4 behavior | Slot 5 supporting copy | Slot 6 action row |
| --- | --- | --- | --- | --- | --- |
| Active Fajr | Tomorrow morning / This morning | `5:42 AM` | active draggable marker | `30 min before Fajr ends` | `[ Fajr | Suhoor ]` |
| Active Suhoor | Tomorrow morning / This morning | `4:51 AM` | active draggable marker | `30 min before Fajr begins` | `[ Fajr | Suhoor ]` |
| Quiet Fajr | Tomorrow morning / This morning | `Quiet` | ghosted saved marker, not draggable | `Alarm saved for 5:42 AM` | `[ Fajr | Suhoor ]` |
| Quiet Suhoor | Tomorrow morning / This morning | `Quiet` | ghosted saved marker, not draggable | `Alarm saved for 4:51 AM` | `[ Fajr | Suhoor ]` |
| Paused Fajr | Tomorrow morning / This morning | `Alarms paused` | ghosted saved marker, not draggable | `Alarm saved for 5:42 AM` | `[ Fajr | Suhoor ]` |
| Paused Suhoor | Tomorrow morning / This morning | `Alarms paused` | ghosted saved marker, not draggable | `Alarm saved for 4:51 AM` | `[ Fajr | Suhoor ]` |
| Rings once while paused | Tomorrow morning / This morning | `5:42 AM` | active draggable marker | `Rings tomorrow only` / `Rings this morning only` | `[ Fajr | Suhoor ]` |
| Alarms not allowed | Tomorrow morning / This morning | `Turn on alarms` | saved marker with warning treatment | `Alarm saved for 5:42 AM` | `[ Fajr | Suhoor ]` or setup action |
| Location/prayer time missing | Tomorrow morning / This morning | `Set location` | disabled timeline | `Set location to calculate Fajr` | setup action |
| First alarm ringing | Now | `Time to wake` | locked alarm timeline | `Tap when you’re awake` | `[ I’m awake ]` |
| Follow-up alarm pending | Now | `Next alarm soon` | locked alarm timeline | `Next alarm in 4 min` | `[ I’m awake ]` |
| Follow-up alarm ringing | Now | `Time to wake` | locked alarm timeline | `Tap when you’re awake` | `[ I’m awake ]` |
| Final alarm, no follow-ups possible | Now | `Time to wake` | locked alarm timeline | `Final alarm this morning` | `[ I’m awake ]` |
| Fajr awake acknowledged | This morning | `You’re awake` | locked completed marker | `Fajr ends at 6:31 AM` | `✓ I’m awake`, then `[ I prayed Fajr ]` when eligible |
| Suhoor awake acknowledged before Fajr | Later this morning | `You’re awake` | locked completed marker | `Fajr begins at 5:21 AM` | `✓ I’m awake`, then `[ I’m fasting today ]` when eligible |
| Fasting logged before Fajr | Later this morning | `Fasting today` | locked completed marker | `Logged for today` | `✓ I’m fasting today` |
| Fajr begins after Suhoor, Fajr wake unconfirmed | This morning | `Fajr has begun` | locked/current morning marker | `Fajr ends at 6:31 AM` | `[ I’m awake for Fajr ]` |
| Fajr wake confirmed after Suhoor | This morning | `You’re awake for Fajr` | locked/current morning marker | `Fajr ends at 6:31 AM` | `✓ I’m awake for Fajr`, then `[ I prayed Fajr ]` when eligible |
| Fajr logged | This morning | `Fajr complete` | locked completed marker | `Logged for this morning` | `✓ I prayed Fajr` |
| Alarm ended without acknowledgement | This morning | `Alarm ended` | locked ended marker | `No response recorded` | passive status / review if needed |
| Alarm issue | This morning | `Alarm issue` | locked planned marker | `Subh couldn’t confirm the alarm` | `[ Review ]` |

## 12. Slot 6 rules

Planning states:

```text
[ Fajr | Suhoor ]
```

The selector changes wake purpose only. It does not turn alarms on/off.

Active alarm states:

```text
[ I’m awake ]
```

Do not show a second `Stop checks` button. `I’m awake` stops the current alarm flow and cancels remaining follow-up alarms for that morning.

Post-action states use one CTA or one checked status pill:

```text
✓ I’m awake
[I’m awake for Fajr]
✓ I’m awake for Fajr
[I’m fasting today]
✓ I’m fasting today
[I prayed Fajr]
✓ I prayed Fajr
```

Do not use a generic `Done` button for logged Fajr/fasting states.

## 13. Action sheets from the alarm-state button

The Slot 3 alarm-state button opens action sheets only in planning/silent/paused/setup states. During active alarm execution, the primary action is Slot 6 `I’m awake`.

### Active alarm

```text
Title: 5:42 AM alarm is on
Body: Subh will ring tomorrow morning.
Actions: Quiet tomorrow / Change time / Cancel
```

Use `this morning` instead of `tomorrow morning` when the target date is same morning.

### Quiet

```text
Title: Quiet tomorrow
Body: Subh won’t ring. Your alarm is saved.
Actions: Turn alarm on / Keep quiet
```

### Alarms paused

```text
Title: Alarms paused
Body: Subh won’t ring until you resume.
Actions: Ring tomorrow only / Resume alarms / Keep paused
```

### Rings once while paused

```text
Title: Rings tomorrow only
Body: Pause stays on for future mornings.
Actions: Stay paused tomorrow / Resume all alarms / Keep alarm on
```

### Alarms not allowed

```text
Title: Turn on alarms
Body: Your alarm is saved, but Subh can’t ring yet.
Actions: Open Settings / Not now
```

## 14. Wake execution rules

Once the first alarm begins:

- Quiet is no longer available for that morning.
- Fajr/Suhoor switching is hidden/locked for that executing wake.
- Slot 6 shows only `[ I’m awake ]`.
- The user-facing app does not expose `Stop checks`.
- `I’m awake` cancels remaining follow-up alarms for that morning.

For MVP, explicit system alarm dismissal from AlarmKit/system UI is treated as equivalent to `I’m awake` for wake-flow completion. Internally, store the acknowledgement source separately:

```text
acknowledgedBy: inAppButton | systemAlarmDismiss
```

## 15. Fajr flow

Fajr purpose flow:

```text
Fajr alarm rings
→ Time to wake
→ user taps I’m awake or dismisses system alarm
→ all follow-up alarms for the morning are cancelled
→ hero shows You’re awake
→ after at least 60 seconds, if Fajr has begun and has not ended, show I prayed Fajr
→ user taps I prayed Fajr
→ hero shows Fajr complete / ✓ I prayed Fajr
→ at Fajr end, hero switches to the next morning
```

Do not show `I prayed Fajr` immediately after `I’m awake`; the delay prevents accidental double-tapping.

## 16. Suhoor flow

Suhoor purpose flow:

```text
Suhoor alarm rings
→ Time to wake
→ user taps I’m awake or dismisses system alarm
→ all follow-up alarms for that Suhoor alarm are cancelled
→ Suhoor wake acknowledgement is logged
→ hero shows You’re awake
→ after at least 60 seconds and before Fajr begins, show I’m fasting today when eligible
→ user taps I’m fasting today
→ hero shows Fasting today / ✓ I’m fasting today
→ at Fajr begins, the Fajr phase still occurs
→ if Fajr wake has not yet been acknowledged, show I’m awake for Fajr
→ user taps I’m awake for Fajr
→ Fajr wake acknowledgement is logged separately from Suhoor wake acknowledgement
→ after the anti-double-tap delay, show I prayed Fajr while Fajr is still open
→ user taps I prayed Fajr
→ hero shows Fajr complete / ✓ I prayed Fajr
→ at Fajr end, hero switches to the next morning
```

`I’m fasting today` records fasting intention/status for the day. It does not record fast completion.

If the user does not tap `I’m fasting today` before Fajr begins, the hero should prioritize the Fajr-specific wake check first and then Fajr prayer logging. Fasting can be logged through an appropriate log/detail surface later if supported.

The Suhoor `I’m awake` and the later `I’m awake for Fajr` are separate facts:

```text
suhoorWakeStatus = acknowledged | noResponse | notApplicable | issue
fajrWakeStatus   = acknowledged | noResponse | notApplicable | issue
```

The later Fajr check exists to confirm that the user remained or became awake for Fajr; it is not a second Suhoor acknowledgement.

## 17. CTA timing rules

After any major hero action, wait at least 60 seconds before showing the next completion CTA.

Fajr-specific wake CTA visibility after Suhoor:

```text
visible when:
  selected purpose for the morning was Suhoor, AND
  Suhoor wake was acknowledged or the Suhoor alarm flow has ended, AND
  Fajr has begun, AND
  Fajr has not ended, AND
  fajrWakeStatus is not acknowledged
```

Fajr prayer CTA visibility:

```text
visible when:
  Fajr wake for the morning has been acknowledged, AND
  at least 60 seconds have passed since the last major hero action, AND
  Fajr has begun, AND
  Fajr has not ended
```

For a normal Fajr-purpose wake, `I’m awake` acknowledges the Fajr wake. For a Suhoor-purpose wake, `I’m awake` acknowledges the Suhoor wake; `I’m awake for Fajr` later acknowledges the Fajr wake.

Suhoor fasting CTA visibility:

```text
visible when:
  selected purpose is Suhoor, AND
  user acknowledged the Suhoor alarm, AND
  at least 60 seconds have passed, AND
  Fajr has not begun
```

## 18. Follow-up alarm boundaries

Follow-up alarms are scheduled only while there is enough time before the relevant boundary.

```text
Fajr purpose boundary: Fajr ends
Suhoor purpose boundary: Fajr begins
```

If the alarm is too close to the relevant boundary, no follow-up alarms are scheduled and Slot 5 says:

```text
Final alarm this morning
```

The primary alarm may still ring even one minute before the boundary or at the boundary if that is the selected plan and valid under the wake-window rules.

## 19. Fajr end handoff

At Fajr end, the Home Hero switches to the next morning.

Completed/acknowledged/logged current-morning history remains available through the appropriate log/detail surfaces. The Home Hero is not a full-day prayer or fasting tracker.

## 20. Next 7 / Month planning implications

Forecast and month surfaces must inherit the same state vocabulary:

```text
5:42 AM
Quiet
Paused
Rings once
Turn on alarms
Alarm issue
```

Rows/dates should remain navigation surfaces into Day Detail. They should not expose all quiet/pause controls directly in MVP.

## 21. Pricing / entitlement rule

These are Free/core utility controls:

```text
Quiet tomorrow / this morning
Turn alarm on
Pause Subh wake alarms indefinitely
Resume alarms
Ring tomorrow only while paused
I’m awake
I’m fasting today
I prayed Fajr
```

Do not paywall basic safety, alarm acknowledgement, quieting, or pausing controls.

## 22. Acceptance checks

1. No active MVP surface exposes `Pre-Fajr`, `Early`, `Fast mode`, or `Quiet mode` as a wake-purpose selector.
2. Home Hero bottom selector contains only `Fajr | Suhoor` in planning states.
3. Quiet is controlled from the alarm-state button/action sheet, not as a third wake purpose.
4. Pause is indefinite only for MVP and is activated from Settings / Wake Alarms.
5. While paused, `Ring tomorrow only` activates exactly one target morning without resuming all alarms.
6. Returning a one-off ringing date to silence while Pause is active removes the exception and restores inherited Pause; it does not create manual Quiet.
7. Manual Quiet survives global resume.
8. Quiet/Pause preserve separate Fajr and Suhoor alarm settings.
9. Active alarm states show one Slot 6 button: `I’m awake`.
10. Quiet is unavailable after the first alarm begins.
11. System alarm dismissal is treated as wake acknowledgement for MVP, with source preserved internally.
12. `I prayed Fajr` appears only after Fajr begins and the anti-double-tap delay passes.
13. `I’m fasting today` appears after Suhoor acknowledgement and delay, before Fajr begins.
14. At Fajr end, Home Hero switches to the next morning.
15. Permission/setup/issue states do not masquerade as Quiet or Pause.
