# Subh Morning Hero Item Specification v16 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-morning-hero-item-spec-v16.md` |
| Version | 16 |
| Spec status | Active Home Hero product and implementation direction |
| Date | 2026-05-30 |
| Related specs | Index, Alignment, Morning Resolution, Quick Mutation, Quiet/Pause, Wake Sessions, Alarm Delivery, Next 7, Month, Shared Tags |
| Owning domain / surface | Home / Morning Hero |

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

The Home Hero answers one question:

```text
What does this morning / tomorrow morning look like, and what should I do now?
```

It must remain a fixed-height state machine. The user should not experience layout jumping when switching between active, Quiet, Paused, ring-once, setup, or wake-execution states.

## 2. Hero slot model

The Home Hero has six fixed slots:

```text
Slot 1 — Location
Slot 2 — Morning label
Slot 3 — Primary alarm-state button / status
Slot 4 — Alarm slider / timeline surface
Slot 5 — One-line supporting copy
Slot 6 — Primary action row
```

Required layout rules:

- The hero frame height, baselines, major text sizes, slot heights, and vertical spacing remain stable across states.
- State changes use opacity, crossfade, symbol change, glass treatment, or controlled time rolling; they do not recompose the hero vertically.
- Slot 6 occupies the same physical row for `Fajr | Suhoor`, `I’m awake`, `I’m awake for Fajr`, `I’m fasting today`, `I prayed Fajr`, and checked status pills.
- The hero may grow only for accessibility/Dynamic Type in a controlled way that pushes lower cards down rather than clipping text.

## 3. Slot 1 — Location

Slot 1 displays the resolved location for the target morning.

Rules:

- Use the same location source as prayer-time resolution.
- Do not replace location with special context labels such as Ramadan, Quiet, or Paused.
- Missing location surfaces through Slot 3/5 setup copy, not by hiding Slot 1 unexpectedly.

## 4. Slot 2 — Morning label

Use morning-centered labels:

```text
Tomorrow morning
This morning
Now
Later this morning
```

Rules:

- `Tomorrow morning`: next-morning planning.
- `This morning`: same-morning planning or Fajr-prayer period after wake execution.
- `Now`: alarm ringing or follow-up pending/ringing.
- `Later this morning`: after Suhoor acknowledgement and before Fajr begins.
- At Fajr end, the Home Hero switches to the next morning.

Avoid `Today`, `Tomorrow`, and `Morning complete` as primary Hero labels unless a later spec explicitly reintroduces them.

## 5. Slot 3 — Primary alarm-state button / status

Slot 3 displays the most important alarm state. In planning/silent/paused/setup states it is also the primary action-sheet entry point.

Examples:

```text
5:42 AM
Quiet
Alarms paused
Turn on alarms
Set location
Time to wake
Next alarm soon
You’re awake
Fasting today
Fajr has begun
Fajr complete
Alarm ended
Alarm issue
```

Slot 3 must not show deprecated system-oriented copy such as `Wake confirmed`, `Saved wake`, `Delivery suppressed`, `Permission blocked`, or `Quiet mode`.

## 6. Slot 4 — Alarm slider / timeline surface

Slot 4 remains physically present in every Hero state.

| State family | Slot 4 behavior |
| --- | --- |
| Active Fajr/Suhoor planning | Active draggable marker / slider within the relevant boundary. |
| Quiet | Ghosted saved marker; not draggable. |
| Paused | Ghosted saved marker; not draggable unless ring-once is active. |
| Rings once despite Pause | Active draggable marker. |
| Setup/blocked/issue | Disabled marker/timeline with warning treatment if truthful. |
| Alarm execution | Locked alarm timeline. |
| Logged/ended states | Locked completed or ended marker. |

The slider changes only the currently selected purpose-specific alarm config.

## 7. Slot 5 — Supporting copy

Slot 5 is one line and explains the current state in plain language.

Examples:

```text
30 min before Fajr ends
30 min before Fajr begins
Alarm saved for 5:42 AM
Rings tomorrow only
Rings this morning only
Tap when you’re awake
Next alarm in 4 min
Final alarm this morning
Fajr begins at 5:21 AM
Fajr ends at 6:31 AM
Logged for this morning
No response recorded
Subh couldn’t confirm the alarm
```

Slot 5 should truncate gracefully. It must not become a multi-row explanation that pushes Slot 6 down in normal text sizes.

## 8. Slot 6 — Primary action row

Planning states show exactly this purpose selector:

```text
[ Fajr | Suhoor ]
```

The selector changes `WakePurpose` only. It does not Quiet the day, pause alarms, log completion, or schedule locally.

Active wake-execution states show exactly:

```text
[ I’m awake ]
```

Do not show `Stop checks`. Do not show Quiet. Do not show the Fajr/Suhoor selector while the executing wake is active.

Post-action states use one CTA or checked status pill:

```text
✓ I’m awake
[I’m awake for Fajr]
✓ I’m awake for Fajr
[I’m fasting today]
✓ I’m fasting today
[I prayed Fajr]
✓ I prayed Fajr
```

Do not use a generic `Done` button for Fajr/fasting logged states.

## 9. State table

Slot 1 is always location. Slot 4 remains present in every state.

| Phase / state | Slot 2 | Slot 3 primary | Slot 4 behavior | Slot 5 supporting copy | Slot 6 action row |
| --- | --- | --- | --- | --- | --- |
| Active Fajr | Tomorrow morning / This morning | `5:42 AM` | active draggable marker | `30 min before Fajr ends` | `[ Fajr | Suhoor ]` |
| Active Suhoor | Tomorrow morning / This morning | `4:51 AM` | active draggable marker | `30 min before Fajr begins` | `[ Fajr | Suhoor ]` |
| Quiet Fajr | Tomorrow morning / This morning | `Quiet` | ghosted saved marker | `Alarm saved for 5:42 AM` | `[ Fajr | Suhoor ]` |
| Quiet Suhoor | Tomorrow morning / This morning | `Quiet` | ghosted saved marker | `Alarm saved for 4:51 AM` | `[ Fajr | Suhoor ]` |
| Paused Fajr | Tomorrow morning / This morning | `Alarms paused` | ghosted saved marker | `Alarm saved for 5:42 AM` | `[ Fajr | Suhoor ]` |
| Paused Suhoor | Tomorrow morning / This morning | `Alarms paused` | ghosted saved marker | `Alarm saved for 4:51 AM` | `[ Fajr | Suhoor ]` |
| Rings once while paused | Tomorrow morning / This morning | `5:42 AM` | active draggable marker | `Rings tomorrow only` / `Rings this morning only` | `[ Fajr | Suhoor ]` |
| Alarms not allowed | Tomorrow morning / This morning | `Turn on alarms` | saved marker with warning treatment | `Alarm saved for 5:42 AM` | setup action or `[ Fajr | Suhoor ]` if safe |
| Location missing | Tomorrow morning / This morning | `Set location` | disabled timeline | `Set location to calculate Fajr` | setup action |
| First alarm ringing | Now | `Time to wake` | locked alarm timeline | `Tap when you’re awake` | `[ I’m awake ]` |
| Follow-up pending | Now | `Next alarm soon` | locked alarm timeline | `Next alarm in 4 min` | `[ I’m awake ]` |
| Follow-up ringing | Now | `Time to wake` | locked alarm timeline | `Tap when you’re awake` | `[ I’m awake ]` |
| Final alarm/no follow-ups | Now | `Time to wake` | locked alarm timeline | `Final alarm this morning` | `[ I’m awake ]` |
| Fajr acknowledged | This morning | `You’re awake` | locked completed marker | `Fajr ends at 6:31 AM` | `✓ I’m awake`, then `[ I prayed Fajr ]` when eligible |
| Suhoor acknowledged before Fajr | Later this morning | `You’re awake` | locked completed marker | `Fajr begins at 5:21 AM` | `✓ I’m awake`, then `[ I’m fasting today ]` when eligible |
| Fasting logged before Fajr | Later this morning | `Fasting today` | locked completed marker | `Logged for today` | `✓ I’m fasting today` |
| Fajr begins after Suhoor, Fajr wake unconfirmed | This morning | `Fajr has begun` | locked/current marker | `Fajr ends at 6:31 AM` | `[ I’m awake for Fajr ]` |
| Fajr wake confirmed after Suhoor | This morning | `You’re awake for Fajr` | locked/current marker | `Fajr ends at 6:31 AM` | `✓ I’m awake for Fajr`, then `[ I prayed Fajr ]` when eligible |
| Fajr logged | This morning | `Fajr complete` | locked completed marker | `Logged for this morning` | `✓ I prayed Fajr` |
| Alarm ended/no response | This morning | `Alarm ended` | locked ended marker | `No response recorded` | passive status / review if needed |
| Alarm issue | This morning | `Alarm issue` | locked planned marker | `Subh couldn’t confirm the alarm` | `[ Review ]` |

## 10. Action sheets from Slot 3

Slot 3 opens action sheets only in planning/silent/paused/setup states. During active wake execution, Slot 6 owns the action.

### Active alarm

```text
Title: 5:42 AM alarm is on
Body: Subh will ring tomorrow morning.
Actions: Quiet tomorrow / Change time / Cancel
```

Use `this morning` instead of `tomorrow morning` for same-morning targets.

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

## 11. Wake-flow CTA rules

### Fajr flow

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

### Suhoor flow

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
→ if Fajr wake is unconfirmed, show I’m awake for Fajr
→ user taps I’m awake for Fajr
→ Fajr wake acknowledgement is logged separately
→ after the anti-double-tap delay, show I prayed Fajr while Fajr is still open
→ at Fajr end, hero switches to the next morning
```

`I’m fasting today` records fasting intention/status, not fast completion.

If the user does not tap `I’m fasting today` before Fajr begins, the Hero prioritizes the Fajr-specific wake check first and then Fajr prayer logging. Fasting may be logged through Detail/log surfaces if supported.

## 12. Active wake execution rules

Once the first alarm begins:

- Quiet is unavailable for that wake.
- Fajr/Suhoor switching is hidden or locked.
- Slot 6 shows only `I’m awake`.
- `I’m awake` stops the current alarm flow and cancels remaining follow-up alarms.
- Explicit system/AlarmKit dismissal is equivalent to `I’m awake` for MVP, with source stored internally.

## 13. Visual treatment

Preserve the premium translucent/liquid-glass surface language used by the app’s cards and planning surfaces.

Requirements:

- The purpose selector is a single translucent segmented pill with two states: `Fajr | Suhoor`.
- Preserve controlled highlight glide between Fajr and Suhoor.
- The primary wake time may rapidly roll between active wake times during Fajr/Suhoor transitions.
- The timeline marker may animate between within-Fajr and before-Fajr positions when the wake boundary changes.
- Quiet, Paused, and blocked states change treatment without adding/removing structural rows.

## 14. Accessibility

- Slot order must be logical: location, morning label, alarm state, timeline, supporting copy, action.
- The selector exposes selected/unselected state for Fajr and Suhoor only.
- Quiet and Paused states announce saved alarm time separately when useful.
- Active alarm announces `Time to wake` and the `I’m awake` action.
- Dynamic Type must not clip primary state, action labels, or essential supporting copy.

## 15. Acceptance criteria

1. The Hero never displays a three-segment `Fajr | Suhoor | Quiet` selector.
2. The planning selector is exactly `Fajr | Suhoor`.
3. Quiet and Pause are reached through Slot 3/action sheet or Settings, not the selector.
4. The Hero height and major slot positions are stable across active, Quiet, Paused, ring-once, setup, execution, and logged states.
5. Separate Fajr and Suhoor alarm settings are preserved through Quiet/Pause and purpose switching.
6. Active alarm states expose only `I’m awake`.
7. System dismissal is handled as an awake acknowledgement for MVP.
8. Suhoor acknowledged before Fajr can show `I’m fasting today`; after Fajr begins the next wake CTA is `I’m awake for Fajr`, then the next eligible completion CTA is `I prayed Fajr`.
9. At Fajr end, Home switches to the next morning.
10. Deprecated user-facing terms do not appear in the Hero.
