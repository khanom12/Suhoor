# Subh Wake Purpose and Alarm-State Mutation Contract v5 — June 1 CTA, Early-Awake, and Post-Suhoor Fajr Mutation Reconciliation

| Field | Value |
| --- | --- |
| Canonical filename | `subh-quick-wake-mode-intent-mutation-contract-v5.md` |
| Version | 5 |
| Spec status | Active shared mutation contract |
| Date | 2026-06-01 |
| Related specs | Index, May 31 Scenario Walkthrough, Hero, Detail, Quiet/Pause, Alarm Delivery, Wake Sessions, Next 7 |
| Owning domain / surface | Shared intent/state mutation semantics |

## May 31, 2026 update status

Version 4 adds May 31 purpose selector order, sensitive Suhoor/Fajr switching rules, Next 7 row Quiet toggle mutations, slider-activated Fajr wake checks after Suhoor after Suhoor, and late Fajr logging.

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

This contract defines how Subh mutates target-morning intent from Home, Day Detail, Settings, Next 7, and downstream planning surfaces.

It exists so that Home Hero, Day Detail, Next 7, Month, Alarm Delivery, and Morning Resolution do not invent separate behavior for the same user action.

## 2. Core separation

The app must preserve these concepts separately:

```text
WakePurpose              = Fajr | Suhoor
Visible selector order   = Suhoor | Fajr
FastingPurpose           = Ramadan | Sunnah opportunity default | Voluntary | Qada | Vow/Nadhr | Kaffarah | Other fast | none
PurposeSpecificAlarmTime = saved Fajr alarm config + saved Suhoor alarm config
DateAlarmOverride        = none | quiet | ringDespitePause
GlobalWakeAlarmPolicy    = active | pausedIndefinitely
WakeExecutionState       = notStarted | ringing | followUpPending | awakeAcknowledged | fastingLogged | fajrLogged | endedNoResponse | issue
```

The selector mutates `WakePurpose` only. It must not turn alarms off, pause all alarms, log completion, or rewrite delivery state.

## 3. Active commands

All surfaces must emit one of these shared commands or an implementation-equivalent command with the same semantics.

| Command | Source surfaces | Mutation |
| --- | --- | --- |
| `selectWakePurpose(targetMorning, .suhoor)` | Home Slot 6, Day Detail | Sets selected wake purpose to Suhoor. Preserves Fajr alarm config. Obeys cutoff rules during/after Suhoor window. |
| `selectWakePurpose(targetMorning, .fajr)` | Home Slot 6, Day Detail | Sets selected wake purpose to Fajr. Preserves Suhoor alarm config. May require confirmation during active Suhoor window if it cancels an active/pending Suhoor session. |
| `setQuiet(targetMorning)` | Home alarm icon/wake-time confirmation, Day Detail, Next 7 row toggle | Sets `DateAlarmOverride.quiet`. Cancels stale scheduled delivery for target morning. Preserves purpose and alarm configs. |
| `clearQuiet(targetMorning)` | Home Quiet sheet, Day Detail, Next 7 row toggle | Clears `DateAlarmOverride.quiet`. Re-resolves against global Pause and setup state. |
| `quietActiveWakeSession(targetMorning, purposeContext, source)` | Approved active alarm-state confirmation only | Cancels remaining alarms/checks for the active session without logging wake acknowledgement, Fajr prayer completion, or fast completion. |
| `pauseWakeAlarmsIndefinitely()` | Settings / Wake Alarms; Home paused-state affordance if present | Sets `GlobalWakeAlarmPolicy.pausedIndefinitely`. Does not create date-specific Quiet records. |
| `resumeWakeAlarms()` | Settings / Wake Alarms; Home paused-state affordance | Sets global policy to active. Manual Quiet dates remain Quiet. |
| `adjustAlarmTime(targetMorning, purpose, alarmConfig)` | Home slider, Detail slider | Updates only the currently selected purpose-specific alarm config. Must obey boundary and cutoff rules. After Suhoor resolution, committing a Fajr slider value creates/activates same-morning Fajr wake delivery. |
| `recordWakeAttemptDismissed(attemptId, source)` | AlarmKit/system dismissal, system notification dismissal | Stops only the current attempt, records dismissal source, keeps session unresolved, and advances to the next valid wake check when one exists. |
| `acknowledgeAwake(targetMorning, purposeContext, source)` | Home active wake CTA, supported explicit awake action, confirmed early-awake | Moves the purpose-scoped wake state to acknowledged and cancels remaining follow-up alarms for that phase. `purposeContext` is `fajr` or `suhoor`. |
| `confirmAlreadyAwakeForSuhoor(targetMorning)` | Context-card action after confirmation | Records early Suhoor wake, cancels/silences pending Suhoor attempts, preserves Fajr adhan/event. |
| `confirmAlreadyAwakeForFajr(targetMorning)` | Context-card action after confirmation | Records early Fajr wake and cancels/silences Fajr adhan/alarm/checks for that morning. |
| `logPrayedFajr(targetMorning)` | Context-card in-window action, late prompt, historical log | Records Fajr prayer completion for the morning. |
| `recordFajrNotPrayed(targetMorning)` | Late/historical check/X prompt | Records explicit Fajr non-completion and creates Qada Fajr relevance. |
| `logFastCompleted(fastDate)` | Context-card fast prompt, historical log | Records fast completion. |
| `recordFastNotCompleted(fastDate)` | Context-card fast prompt, historical log | Records explicit fast non-completion; creates Qada fast relevance only for Ramadan fasts. |
| `expireUnresolvedPrompt(target, promptType)` | Prompt expiry resolver | Marks prompt expired unresolved without creating missed/Qada records. |
| `resetMorningToDefaults(targetMorning)` | Day Detail | Clears date-specific purpose, alarm-time, fasting-purpose override, Quiet, and ring-once exception unless a later spec narrows reset scope. Does not change global Pause. |

## 4. Purpose-specific alarm memory

Each editable morning must retain separate alarm configuration for Fajr and Suhoor.

Example:

```text
Target morning: Monday
Fajr alarm: 30 min before Fajr ends
Suhoor alarm: 45 min before Fajr begins
Selected purpose: Fajr
Date override: Quiet
```

If the user switches to Suhoor while Quiet, the date remains Quiet but the displayed saved time becomes the saved Suhoor alarm. Switching back to Fajr restores the saved Fajr alarm.

Required behavior:

1. Fajr/Suhoor switching changes purpose only.
2. Quiet/Pause changes whether Subh rings.
3. Purpose switching does not destroy the other purpose’s saved/custom alarm setting.
4. Resetting an alarm time resets only the current purpose unless a broader reset action is explicitly invoked.
5. Delivery refresh occurs after resolution, not through local UI scheduling shortcuts.

## 5. Suhoor fasting-purpose defaults

Selecting Suhoor means the user is waking before Fajr for suhoor/fasting.

Default fasting-purpose resolution:

| Context | Default fasting purpose |
| --- | --- |
| Ramadan fasting day | Ramadan fast |
| One or more applicable Sunnah opportunities | All applicable selected/default Sunnah opportunities for that date |
| No applicable specific opportunity | Voluntary fast |
| Explicit Qada/Vow/Kaffarah/Other fast selected | The explicit selected fasting purpose |
| Eid/forbidden fast day | Suhoor is disabled or requires a product-approved warning path; fasting must not be silently allowed |

Do not expose `Tahajjud only`, `Other early worship`, or generic non-fasting before-Fajr planning in MVP.

## 6. Sensitive-window purpose switching

Before the Suhoor window begins, the user may switch between Suhoor and Fajr normally.

During the Suhoor window:

- switching from Suhoor to Fajr requires confirmation if it cancels an active/pending Suhoor wake session;
- switching into Suhoor is allowed only while `current time <= Fajr begins - 6 minutes`;
- after Fajr begins, Suhoor is no longer newly schedulable for Today Morning.

Suggested confirmation:

```text
Title: Switch to Fajr for Today Morning?
Body: This will cancel your Suhoor wake session for this morning.
Actions: Keep Suhoor / Switch to Fajr
```

If switching into Suhoor is too late:

```text
It’s too close to Fajr to schedule Suhoor for Today Morning.
You can still wake for Fajr.
```

## 7. Quiet behavior

Quiet is a date-level alarm override. It must not erase purpose or fasting metadata.

Setting Quiet must:

- cancel pending scheduled delivery for the target morning;
- prevent primary and follow-up wake alarms for that target morning;
- preserve selected Fajr/Suhoor purpose;
- preserve Fajr and Suhoor alarm settings;
- preserve opportunity context, Ramadan context, and existing logs;
- not create missed Fajr, missed fast, delivery-failure, permission-failure, wake-acknowledgement, or prayer-completion records.

Next 7 row toggles may emit `setQuiet` / `clearQuiet` only. They must not change purpose, Pause, alarm time, or fasting purpose.

## 8. Pause and ring-once behavior

Pause is app-wide and indefinite for MVP.

While global Pause is active:

- all upcoming Subh wake alarms are suppressed unless a date has `ringDespitePause`;
- existing manual Quiet overrides remain manual Quiet, not inherited Pause;
- the user can create `Ring tomorrow only` or `Ring this morning only` for one target morning;
- after the ring-once morning completes or expires, Pause remains active;
- resuming alarms clears inherited Pause but does not clear manual Quiet dates.

## 9. Fajr completion logging

`acknowledgeAwake(... .fajr ...)` logs wake success only. It does not call `logPrayedFajr`.

`logPrayedFajr(targetMorning)` records Fajr prayer completion. It may be invoked from:

- the in-window `I Prayed Fajr` CTA after the anti-double-tap delay;
- Detail/log surfaces;
- the late prompt inside the context-card action area after Fajr end.

Late prompt copy:

```text
I prayed Fajr earlier today? ✓ ✕
I prayed Fajr yesterday morning? ✓ ✕
```

## 10. Compatibility migration

Legacy persisted values may be decoded for data safety, but they must not be re-exposed as active MVP UI.

| Legacy value / wording | MVP normalized meaning |
| --- | --- |
| `Pre-Fajr`, `Early`, `Fast`, `Fasting mode` as top-level mode | `WakePurpose.suhoor` with fasting/suhoor intent |
| `Quiet` as quick mode / selector segment | `DateAlarmOverride.quiet` |
| `Pause mode` | `GlobalWakeAlarmPolicy.pausedIndefinitely` |
| `Tahajjud only`, `Other early worship` as before-Fajr reasons | Deferred legacy metadata; not active MVP selection or resolver output |
| `Stop checks` | Not user-facing; use `I’m Awake` to stop current alarm flow |

## 11. Save behavior

Home and Day Detail mutations save immediately unless a specific later editor spec introduces an explicit draft editor.

`Done` in Day Detail is an exit/navigation action, not the persistence boundary for MVP wake-purpose, Quiet, alarm-time, or reset changes.

Rapid repeated taps must be idempotent:

- repeated selection of the already-selected purpose creates no duplicate record;
- repeated Quiet action creates one Quiet override;
- repeated ring-once action creates one ring-once exception;
- scheduler refresh should be idempotent and reconcile by canonical target-morning identifiers.

## 12. Acceptance criteria

1. Home and Day Detail use the same visible purpose selector order: `Suhoor | Fajr`.
2. Quiet never appears as a third selector segment.
3. Selecting Fajr/Suhoor does not clear Quiet, Pause, or the other purpose’s saved alarm config.
4. Sensitive Suhoor-window switching uses confirmation/cutoff rules.
5. Setting Quiet cancels stale delivery and preserves the underlying selected purpose.
6. Clearing Quiet restores active or paused behavior according to global policy and setup state.
7. Next 7 row Quiet toggle mutates only one-morning Quiet.
8. Pause is global and indefinite only.
9. Ring-once exception while paused does not resume all alarms.
10. Active wake execution exposes `I’m Awake` as primary Slot 6 action, not Quiet or Stop checks.
11. System dismissal maps to `acknowledgeAwake(targetMorning, purposeContext, source: systemAlarmDismiss)` for MVP.
12. Slider-activated Fajr wake checks after Suhoor after Suhoor is user-initiated.
13. `I’m Awake for Fajr` does not log Fajr prayer completion.
14. Legacy values decode safely but do not reappear in visible MVP controls.

---

## June 1 Addendum: New Mutation Commands

### A. Early-awake confirmations

Add mutations for:

```text
confirmAlreadyAwakeForSuhoor(morningDate)
confirmAlreadyAwakeForFajr(morningDate)
```

Both mutations require a prior user confirmation sheet/modal.

`confirmAlreadyAwakeForSuhoor` must cancel/silence pending Suhoor attempts while preserving the default Fajr-beginning adhan/event.

`confirmAlreadyAwakeForFajr` must cancel/silence the Fajr adhan/alarm/wake session/checks for the current morning.

### B. Attempt dismissal mutation

Add or preserve a mutation that records current-attempt dismissal without wake acknowledgement:

```text
recordWakeAttemptDismissed(attemptId, source)
```

It must not cancel remaining checks unless the dismissal source is explicitly mapped to awake confirmation.

### C. Post-Suhoor Fajr slider mutation

After Suhoor wake is resolved, committing a Fajr slider value mutates Fajr wake delivery for the same morning. This replaces the earlier separate **Set Fajr Wake Alarm** CTA concept.

