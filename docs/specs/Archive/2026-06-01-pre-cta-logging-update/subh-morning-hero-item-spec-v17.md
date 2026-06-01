# Subh Morning Hero Item Specification v17 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-morning-hero-item-spec-v17.md` |
| Version | 17 |
| Spec status | Active Home Hero product and implementation direction |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Alignment, Morning Resolution, Quick Mutation, Quiet/Pause, Wake Sessions, Alarm Delivery, Next 7, Month, Shared Tags |
| Owning domain / surface | Home / Morning Hero |

## May 30, 2026 reconciliation status

This active spec has been reconciled against the finalized Quiet / Pause / Hero / Wake Flow direction. It is implementation-facing. Older wording preserved in `Archive/originals-before-may30-reconciliation/` is historical only and must not be implemented when it conflicts with this active file.

## May 31, 2026 morning-state framework update

Version 17 incorporates the May 31 walkthrough that began from the live Toronto app state and simulated the hero through daytime, evening, midnight, Suhoor window, Fajr begins, Fajr window, Fajr end, and post-Fajr next-morning rollover.

This update supersedes only the conflicting May 30 details listed here:

- visible planning selector order is `[ Suhoor | Fajr ]`;
- Slot 2 uses title-case `Today Morning` and `Tomorrow Morning` labels;
- Slot 3 remains minimal, but the alarm icon / wake-time control must look tappable and opens the deliberate Quiet confirmation;
- Quiet confirmation copy uses `Make Tomorrow Morning Quiet?` / `Make Today Morning Quiet?` and explains that no alarm or wake checks will ring;
- Slot 4/5 slider feedback must update live while dragging;
- after Fajr end, the Hero rolls to the next morning and any unresolved Fajr prayer log appears below the context card, not inside the Hero;
- Suhoor acknowledgement does not automatically create a full Fajr wake-check session; only a single Fajr-start event occurs by default unless the user opts into Fajr follow-up.

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
- Slot 6 occupies the same physical row for `Suhoor | Fajr`, `I’m awake`, `I’m awake for Fajr`, `I’m fasting today`, `I prayed Fajr`, and checked status pills.
- The hero may grow only for accessibility/Dynamic Type in a controlled way that pushes lower cards down rather than clipping text.

## 3. Slot 1 — Location

Slot 1 displays the resolved location for the target morning.

Rules:

- Use the same location source as prayer-time resolution.
- Do not replace location with special context labels such as Ramadan, Quiet, or Paused.
- Missing location surfaces through Slot 3/5 setup copy, not by hiding Slot 1 unexpectedly.

## 4. Slot 2 — Morning label

Use title-case morning-centered labels:

```text
Tomorrow Morning
Today Morning
Now
Later This Morning
```

Rules:

- `Tomorrow Morning`: next-morning planning before midnight, and the next relevant morning after the current Fajr window ends.
- `Today Morning`: same target morning after midnight and before Fajr end.
- `Now`: alarm ringing or follow-up pending/ringing.
- `Later This Morning`: after Suhoor acknowledgement and before Fajr begins when the next relevant action belongs later in the same morning.
- At Fajr end, the Home Hero switches to the next relevant morning; unresolved Fajr prayer logging for the ended morning moves to a separate prompt below the context card.

Avoid `Today`, `Tomorrow`, `This morning`, and `Morning complete` as primary Hero labels unless a later spec explicitly reintroduces them. Title-case `Today Morning` / `Tomorrow Morning` is the approved Hero language.

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

Slot 3 visual/interaction requirements from the May 31 walkthrough:

- When Slot 3 is an active alarm time, it is visually composed as an alarm icon followed by the wake time.
- Do not add explanatory body copy under the wake time inside the Hero.
- The alarm icon must sit in a subtle glass / semi-transparent tappable container, similar in affordance to the settings icon treatment.
- The tap target may include both the alarm icon and the adjacent wake time.
- Tapping the alarm icon/wake-time control opens the Quiet confirmation/action sheet; it must not instantly silence the morning without confirmation.
- If the focused morning is Quiet, Slot 3 shows `Quiet` as the primary state rather than showing a normal wake time as though delivery will occur.

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

Slot 4/5 live-feedback requirement: while the user drags the slider, Slot 3 wake time, the slider/thumb position, and Slot 5 supporting offset copy must update together. The UI must not show a stale or hidden Slot 5 value while the Slot 3 time is already changing.

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
[ Suhoor | Fajr ]
```

The selector changes `WakePurpose` only. It does not Quiet the day, pause alarms, log completion, or schedule locally.

Active wake-execution states show exactly:

```text
[ I’m awake ]
```

Do not show `Stop checks`. Do not show Quiet as a competing Slot 6 action. Do not show the Suhoor/Fajr selector while the executing wake is active.

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
| Active Fajr | Tomorrow Morning / Today Morning | `5:42 AM` | active draggable marker | `30 min before Fajr ends` | `[ Suhoor | Fajr ]` |
| Active Suhoor | Tomorrow Morning / Today Morning | `4:51 AM` | active draggable marker | `30 min before Fajr begins` | `[ Suhoor | Fajr ]` |
| Quiet Fajr | Tomorrow Morning / Today Morning | `Quiet` | ghosted saved marker | `Alarm saved for 5:42 AM` | `[ Suhoor | Fajr ]` |
| Quiet Suhoor | Tomorrow Morning / Today Morning | `Quiet` | ghosted saved marker | `Alarm saved for 4:51 AM` | `[ Suhoor | Fajr ]` |
| Paused Fajr | Tomorrow Morning / Today Morning | `Alarms paused` | ghosted saved marker | `Alarm saved for 5:42 AM` | `[ Suhoor | Fajr ]` |
| Paused Suhoor | Tomorrow Morning / Today Morning | `Alarms paused` | ghosted saved marker | `Alarm saved for 4:51 AM` | `[ Suhoor | Fajr ]` |
| Rings once while paused | Tomorrow Morning / Today Morning | `5:42 AM` | active draggable marker | `Rings tomorrow only` / `Rings this morning only` | `[ Suhoor | Fajr ]` |
| Alarms not allowed | Tomorrow Morning / Today Morning | `Turn on alarms` | saved marker with warning treatment | `Alarm saved for 5:42 AM` | setup action or `[ Suhoor | Fajr ]` if safe |
| Location missing | Tomorrow Morning / Today Morning | `Set location` | disabled timeline | `Set location to calculate Fajr` | setup action |
| First alarm ringing | Now | `Time to wake` | locked alarm timeline | `Tap when you’re awake` | `[ I’m awake ]` |
| Follow-up pending | Now | `Next alarm soon` | locked alarm timeline | `Next alarm in 4 min` | `[ I’m awake ]` |
| Follow-up ringing | Now | `Time to wake` | locked alarm timeline | `Tap when you’re awake` | `[ I’m awake ]` |
| Final alarm/no follow-ups | Now | `Time to wake` | locked alarm timeline | `Final alarm this morning` | `[ I’m awake ]` |
| Fajr acknowledged | Today Morning | `You’re awake` | locked completed marker | `Fajr ends at 6:31 AM` | `✓ I’m awake`, then `[ I prayed Fajr ]` when eligible |
| Suhoor acknowledged before Fajr | Later This Morning | `You’re awake` | locked completed marker | `Fajr begins at 5:21 AM` | `✓ I’m awake`, then `[ I’m fasting today ]` when eligible |
| Fasting logged before Fajr | Later This Morning | `Fasting today` | locked completed marker | `Logged for today` | `✓ I’m fasting today` |
| Fajr begins after Suhoor, Fajr wake unconfirmed | Today Morning | `Fajr has begun` | locked/current marker | `Fajr ends at 6:31 AM` | `[ I’m awake for Fajr ]` |
| Fajr wake confirmed after Suhoor | Today Morning | `You’re awake for Fajr` | locked/current marker | `Fajr ends at 6:31 AM` | `✓ I’m awake for Fajr`, then `[ I prayed Fajr ]` when eligible |
| Fajr logged | Today Morning | `Fajr complete` | locked completed marker | `Logged for this morning` | `✓ I prayed Fajr` |
| Alarm ended/no response | Today Morning | `Alarm ended` | locked ended marker | `No response recorded` | passive status / review if needed |
| Alarm issue | Today Morning | `Alarm issue` | locked planned marker | `Subh couldn’t confirm the alarm` | `[ Review ]` |

## 10. Action sheets from Slot 3

Slot 3 opens action sheets only in planning/silent/paused/setup states. During active wake execution, Slot 6 owns the action.

### Active alarm

```text
Title: Make Tomorrow Morning Quiet?
Body: No alarm or wake checks will ring. Use this only if you do not need Subh to wake you.
Actions: Keep Alarm On / Make Quiet / Change Time
```

Use `Make Today Morning Quiet?` for same-morning targets. The action sheet/popover pointer should point to the alarm icon/wake-time control.

### Quiet

```text
Title: Tomorrow Morning is Quiet
Body: No alarm or wake checks will ring, but your Suhoor/Fajr plan is saved.
Actions: Turn Alarm On / Keep Quiet
```

Use `Today Morning is Quiet` for same-morning targets.

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
→ all follow-up alarms for the Fajr wake session are cancelled
→ Fajr wake acknowledgement is logged
→ hero shows You’re awake / ✓ I’m awake
→ after at least 60 seconds, if Fajr has begun and has not ended, show I prayed Fajr
→ user taps I prayed Fajr
→ Fajr prayer completion is logged separately
→ hero shows Fajr complete / ✓ I prayed Fajr
→ at Fajr end, hero switches to the next relevant morning
```

`I’m awake` or `I’m Awake for Fajr` confirms wake success only. It does not log Fajr prayer completion. `I prayed Fajr` is the separate prayer-completion CTA.

If Fajr ends before prayer completion is logged, the Hero still switches to the next relevant morning. A separate late-logging prompt appears below the context card with `I Prayed Fajr Earlier Today` or, after midnight, `I Prayed Fajr Yesterday Morning`.

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
→ at Fajr begins, Subh may issue a single Fajr-start AlarmKit event
→ no Fajr wake checks run by default after Suhoor acknowledgement
→ if the user intentionally chooses Fajr follow-up from the Hero, switch/configure a Fajr wake session
→ if Fajr follow-up is active, user may tap I’m awake for Fajr
→ Fajr wake acknowledgement is logged separately
→ after the anti-double-tap delay, show I prayed Fajr while Fajr is still open
→ at Fajr end, hero switches to the next relevant morning
```

`I’m fasting today` records fasting intention/status, not fast completion.

Suhoor acknowledgement and Fajr wake acknowledgement are separate facts. However, a full Fajr wake-check session is not created automatically after Suhoor acknowledgement; the default Fajr-start event is single-shot and has no wake checks.

## 12. Active wake execution rules

Once the first alarm begins:

- Fajr/Suhoor switching is hidden or locked for the executing wake.
- Slot 6 shows only `I’m awake` as the primary active wake action.
- `I’m awake` stops the current alarm flow and cancels remaining follow-up alarms.
- Explicit system/AlarmKit dismissal is equivalent to `I’m awake` for MVP, with source stored internally.
- Quiet is not shown as a competing Slot 6 action. If an approved alarm-state control allows Quiet during execution, it must require explicit confirmation and cancel remaining alarms/checks as a user-requested quiet cancellation; this is not the normal acknowledgement path.

## 13. Visual treatment

Preserve the premium translucent/liquid-glass surface language used by the app’s cards and planning surfaces.

Requirements:

- The purpose selector is a single translucent segmented pill with two visible states in this order: `Suhoor | Fajr`.
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

1. The Hero never displays a three-segment `Suhoor | Fajr | Quiet` selector.
2. The visible planning selector is exactly `Suhoor | Fajr`.
3. Quiet and Pause are reached through the alarm icon/wake-time control, Slot 3/action sheet, Detail, Settings, or approved row toggle; not through the purpose selector.
4. The Hero height and major slot positions are stable across active, Quiet, Paused, ring-once, setup, execution, and logged states.
5. Separate Fajr and Suhoor alarm settings are preserved through Quiet/Pause and purpose switching.
6. Active alarm states expose `I’m awake` as the only primary Slot 6 action.
7. System dismissal is handled as an awake acknowledgement for MVP.
8. Suhoor acknowledged before Fajr does not automatically create a full Fajr wake-check session; the Fajr-start event is single-shot unless the user opts into Fajr follow-up.
9. `I’m Awake for Fajr` / Fajr wake acknowledgement does not log Fajr prayer completion.
10. `I prayed Fajr` logs Fajr prayer completion separately after the anti-double-tap delay.
11. At Fajr end, Home switches to the next relevant morning.
12. If Fajr prayer was not logged before Fajr end, the late logging prompt appears below the context card, not in the Hero.
13. Deprecated user-facing terms do not appear in the Hero.
