# Subh Quiet Morning and Pause Contract Specification v2 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-quiet-mode-quiet-morning-contract-spec-v2.md` |
| Version | 2 |
| Spec status | Active Quiet and Pause contract |
| Date | 2026-05-30 |
| Related specs | Index, Alignment, Morning Resolution, Quick Mutation, Hero, Detail, Alarm Delivery, Wake Sessions |
| Owning domain / surface | One-morning Quiet, app-wide Pause, and related restoration behavior |

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

This spec defines intentional silence for Subh wake alarms.

There are two MVP silence mechanisms:

```text
Quiet: one selected morning will not ring.
Pause: Subh wake alarms stay off until resumed.
```

Quiet and Pause are not wake purposes and must not erase the underlying Fajr/Suhoor plan.

## 2. Quiet definition

Quiet is a date-level alarm override:

```text
Quiet = Subh will not ring for this specific morning.
```

Quiet must:

- suppress the primary wake alarm for that target morning;
- suppress follow-up alarms for that target morning;
- cancel stale scheduled delivery for that target morning;
- prevent a Wake Session from starting for that target morning;
- preserve selected Fajr/Suhoor purpose;
- preserve saved Fajr and Suhoor alarm settings;
- preserve day meaning, opportunity context, Ramadan context, and existing logs;
- remain distinct from permission failure, delivery failure, missing location, missing prayer times, and missed-prayer assumptions.

Quiet must not:

- log missed Fajr;
- log missed fast;
- imply skipped worship;
- change the user’s fasting-purpose metadata;
- turn off all future alarms;
- mutate global Pause.

## 3. Pause definition

Pause is an app-wide policy for Subh wake alarms:

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
pause reason picker
quiet reason picker
```

Pause must:

- live primarily in Settings / Wake Alarms;
- suppress upcoming Subh wake alarms while active;
- preserve all saved Fajr/Suhoor plans;
- preserve all date-specific Quiet overrides;
- show a visible paused state on Home;
- allow `Ring tomorrow only` / `Ring this morning only` as a one-morning exception;
- allow global resume.

## 4. Entry points

| User entry point | Quiet | Pause |
| --- | --- | --- |
| Home Hero Slot 3 alarm-state button | Apply/clear Quiet for target morning before execution | Show paused state; allow ring-once/resume when paused |
| Home Hero Slot 6 purpose selector | No Quiet control | No Pause control |
| Day Detail | Apply/clear Quiet; ring-once if paused | Display inherited Pause; allow approved pause actions |
| Next 7 Mornings | No inline mutation; row navigates to Detail | No inline mutation; row navigates to Detail |
| Month/list view | No inline mutation; row navigates to Detail | No inline mutation; row navigates to Detail |
| Settings / Wake Alarms | May include global explanations | Primary Pause/resume location |
| Active wake session | Quiet unavailable | Pause unavailable for current executing wake |

## 5. Quiet action sheet

For a future or pre-execution target morning:

```text
Title: Quiet tomorrow
Body: Subh won’t ring. Your alarm is saved.
Actions: Turn alarm on / Keep quiet
```

For an active alarm state:

```text
Do not show Quiet.
Show I’m awake as the only primary action.
```

## 6. Pause action sheet / Settings behavior

Settings primary language:

```text
Pause Subh wake alarms
Subh won’t ring until you resume.
```

Home paused-state sheet:

```text
Title: Alarms paused
Body: Subh won’t ring until you resume.
Actions: Ring tomorrow only / Resume alarms / Keep paused
```

`Ring tomorrow only` creates `DateAlarmOverride.ringDespitePause`. It does not clear global Pause.

## 7. Precedence and restoration

Resolution order:

```text
1. Setup/capability issue, if required for truthful ringing.
2. Manual Quiet for target morning.
3. Global Pause, unless ringDespitePause is set.
4. Active Fajr/Suhoor alarm.
```

Restoration rules:

- Clearing Quiet returns the date to active or paused based on global policy.
- Resuming Pause returns inherited paused dates to their saved active plans.
- Resuming Pause does not clear manual Quiet dates.
- Clearing ring-once while Pause is active returns the date to inherited Pause.
- A ring-once exception expires after the target morning or is cleared during cleanup.

## 8. Logging and analytics

Quiet may create a user-intent/state record such as:

```text
quietMorning(targetMorning, selectedPurpose, savedAlarmTime, createdAt, sourceSurface)
```

It must not create:

```text
missedFajr
missedFast
deliveryFailure
permissionFailure
wakeSessionNoResponse
```

Pause may create policy-state metadata, but individual inherited paused days should not be logged as manually Quiet unless the user explicitly sets Quiet for that date.

## 9. Delivery requirements

When Quiet is set:

- cancel pending primary alarm for the target morning;
- cancel pending follow-up alarms for the target morning;
- invalidate stale scheduler identifiers for that morning;
- update delivery ledger/reconciliation as intentionally suppressed, not failed.

When Pause is set:

- suppress future wake scheduling while active;
- cancel upcoming scheduled wake alarms as required by platform constraints;
- preserve enough metadata to restore active scheduling on resume;
- continue allowing non-wake app notifications only if separately allowed by the notification spec.

## 10. Copy rules

Use:

```text
Quiet
Alarms paused
Alarm saved for 5:42 AM
Rings tomorrow only
Rings this morning only
Subh won’t ring until you resume.
```

Avoid visible copy:

```text
Quiet mode
Pause mode
Delivery suppressed
No wake confirmed
Saved wake
Permission blocked
```

`I’m awake` is valid active wake-flow CTA copy, but it should not appear as Quiet-state explanatory copy.

## 11. Acceptance criteria

1. Quiet is a one-morning alarm override, not a wake purpose.
2. Pause is app-wide and indefinite, not a wake purpose.
3. Quiet is available before first alarm begins and unavailable after execution starts.
4. Home Slot 6 never shows Quiet in the Fajr/Suhoor selector.
5. Quiet preserves Fajr/Suhoor purpose and purpose-specific alarm settings.
6. Pause preserves saved plans and manual Quiet dates.
7. Ring-once while paused does not resume all alarms.
8. Quiet and Pause do not create missed-prayer or missed-fast records.
9. Delivery failures, permission blocks, and missing setup do not display as Quiet.
10. Next 7/Month route to Detail for mutation rather than exposing inline toggles.
