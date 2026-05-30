# Subh Wake Purpose and Alarm-State Mutation Contract v3 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-quick-wake-mode-intent-mutation-contract-v3.md` |
| Version | 3 |
| Spec status | Active shared mutation contract |
| Date | 2026-05-30 |
| Supersedes / overrides | Historical quick-mode model that treated Quiet as a third wake purpose or exposed Pre-Fajr/Early/Fast as active MVP purposes |
| Related specs | Index, Morning Resolution, Hero, Day Detail, Quiet/Pause, Alarm Delivery, Wake Sessions, Next 7, Month |
| Owning domain / surface | Shared user-intent mutation behavior |

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

This contract defines how Subh mutates target-morning intent from Home, Day Detail, Settings, and downstream planning surfaces.

It exists so that Home Hero, Day Detail, Next 7, Month, Alarm Delivery, and Morning Resolution do not invent separate behavior for the same user action.

## 2. Core separation

The app must preserve these concepts separately:

```text
WakePurpose              = Fajr | Suhoor
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
| `selectWakePurpose(targetMorning, .fajr)` | Home Slot 6, Day Detail | Sets selected wake purpose to Fajr. Preserves Suhoor alarm config. Clears no Quiet/Pause state by itself. |
| `selectWakePurpose(targetMorning, .suhoor)` | Home Slot 6, Day Detail | Sets selected wake purpose to Suhoor. Preserves Fajr alarm config. Defaults fasting purpose according to Section 5. |
| `setQuiet(targetMorning)` | Home Slot 3 action sheet, Day Detail | Sets `DateAlarmOverride.quiet`. Cancels stale scheduled delivery for target morning. Preserves purpose and alarm configs. |
| `clearQuiet(targetMorning)` | Home Slot 3 action sheet, Day Detail | Clears `DateAlarmOverride.quiet`. Re-resolves against global Pause and setup state. |
| `pauseWakeAlarmsIndefinitely()` | Settings / Wake Alarms; Home paused-state affordance if present | Sets `GlobalWakeAlarmPolicy.pausedIndefinitely`. Does not create date-specific Quiet records. |
| `resumeWakeAlarms()` | Settings / Wake Alarms; Home paused-state affordance | Sets global policy to active. Manual Quiet dates remain Quiet. |
| `ringTargetMorningDespitePause(targetMorning)` | Home/Detail while globally paused | Sets `DateAlarmOverride.ringDespitePause` for exactly one target morning. Pause remains active after that morning. |
| `clearRingDespitePause(targetMorning)` | Home/Detail while globally paused | Clears the one-morning exception and returns the date to inherited Pause unless another override applies. |
| `adjustAlarmTime(targetMorning, purpose, alarmConfig)` | Home slider, Detail slider | Updates only the currently selected purpose-specific alarm config. |
| `resetMorningToDefaults(targetMorning)` | Day Detail | Clears date-specific purpose, alarm-time, fasting-purpose override, Quiet, and ring-once exception unless a later spec narrows reset scope. Does not change global Pause. |
| `setFastingPurpose(targetMorning, fastingPurpose)` | Day Detail under Suhoor / fasting controls | Updates fasting-purpose metadata. Does not create a new wake purpose. |
| `acknowledgeAwake(targetMorning, purposeContext, source)` | Home active wake flow, Fajr-phase check after Suhoor, AlarmKit/system dismissal | Moves the purpose-scoped wake check to acknowledged and cancels remaining follow-up alarms for that phase. `purposeContext` is `fajr` or `suhoor`. |
| `logFastingToday(targetMorning)` | Home after Suhoor acknowledgement, Detail/log surface | Records current-day fasting intention/status, not fast completion. |
| `logPrayedFajr(targetMorning)` | Home after Fajr begins, Detail/log surface | Records Fajr prayer completion for the morning. |

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

## 6. Quiet behavior

Quiet is a date-level alarm override. It must not erase purpose or fasting metadata.

Setting Quiet must:

- cancel pending scheduled delivery for the target morning;
- prevent primary and follow-up wake alarms for that target morning;
- preserve selected Fajr/Suhoor purpose;
- preserve Fajr and Suhoor alarm settings;
- preserve opportunity context, Ramadan context, and existing logs;
- not create missed Fajr, missed fast, delivery-failure, or permission-failure records.

Quiet is available only before the first alarm begins. After wake execution starts, the only user-facing active action is `I’m awake`.

## 7. Pause and ring-once behavior

Pause is app-wide and indefinite for MVP.

While global Pause is active:

- all upcoming Subh wake alarms are suppressed unless a date has `ringDespitePause`;
- existing manual Quiet overrides remain manual Quiet, not inherited Pause;
- the user can create `Ring tomorrow only` or `Ring this morning only` for one target morning;
- after the ring-once morning completes or expires, Pause remains active;
- resuming alarms clears inherited Pause but does not clear manual Quiet dates.

## 8. Compatibility migration

Legacy persisted values may be decoded for data safety, but they must not be re-exposed as active MVP UI.

| Legacy value / wording | MVP normalized meaning |
| --- | --- |
| `Pre-Fajr`, `Early`, `Fast`, `Fasting mode` as top-level mode | `WakePurpose.suhoor` with fasting/suhoor intent |
| `Quiet` as quick mode / selector segment | `DateAlarmOverride.quiet` |
| `Pause mode` | `GlobalWakeAlarmPolicy.pausedIndefinitely` |
| `Tahajjud only`, `Other early worship` as before-Fajr reasons | Deferred legacy metadata; not active MVP selection or resolver output |
| `Stop checks` | Not user-facing; use `I’m awake` to stop current alarm flow |

## 9. Save behavior

Home and Day Detail mutations save immediately unless a specific later editor spec introduces an explicit draft editor.

`Done` in Day Detail is an exit/navigation action, not the persistence boundary for MVP wake-purpose, Quiet, alarm-time, or reset changes.

Rapid repeated taps must be idempotent:

- repeated selection of the already-selected purpose creates no duplicate record;
- repeated Quiet action creates one Quiet override;
- repeated ring-once action creates one ring-once exception;
- scheduler refresh should be idempotent and reconcile by canonical target-morning identifiers.

## 10. Acceptance criteria

1. Home and Day Detail use the same purpose selector: `Fajr | Suhoor`.
2. Quiet never appears as a third selector segment.
3. Selecting Fajr/Suhoor does not clear Quiet, Pause, or the other purpose’s saved alarm config.
4. Setting Quiet cancels stale delivery and preserves the underlying selected purpose.
5. Clearing Quiet restores active or paused behavior according to global policy and setup state.
6. Pause is global and indefinite only.
7. Ring-once exception while paused does not resume all alarms.
8. Active wake execution exposes `I’m awake`, not Quiet or Stop checks.
9. System dismissal maps to `acknowledgeAwake(targetMorning, purposeContext, source: systemAlarmDismiss)` for MVP.
10. Legacy values decode safely but do not reappear in visible MVP controls.
