# Subh Quiet Morning and Pause Contract Specification v3 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-quiet-mode-quiet-morning-contract-spec-v3.md` |
| Version | 3 |
| Spec status | Active Quiet and Pause contract |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Alignment, Morning Resolution, Quick Mutation, Hero, Detail, Alarm Delivery, Wake Sessions, Next 7 |
| Owning domain / surface | One-morning Quiet, app-wide Pause, and related restoration behavior |

## May 31, 2026 update status

Version 3 updates Quiet entry/copy and Next 7 inline Quiet handling. It also clarifies that active-session Quiet cancellation may be exposed only as a deliberate confirmed alarm-state control, not as the primary active wake CTA.

Canonical MVP doctrine:

```text
Wake purpose values: Fajr, Suhoor
Visible planning selector order: Suhoor | Fajr
Alarm state: active | quiet | paused | rings-once | blocked | issue
Execution state: not started | ringing | follow-up pending | awake acknowledged | fasting logged | Fajr logged | ended/no response | issue
```

Quiet and Pause are not wake purposes and must not erase the underlying Fajr/Suhoor plan.

## 1. Purpose

This spec defines intentional silence for Subh wake alarms.

There are two MVP silence mechanisms:

```text
Quiet: one selected morning will not ring.
Pause: Subh wake alarms stay off until resumed.
```

## 2. Quiet definition

Quiet is a date-level alarm override:

```text
Quiet = Subh will not ring for this specific morning.
```

Quiet must:

- suppress the primary wake alarm for that target morning when set before execution;
- suppress follow-up alarms for that target morning;
- cancel stale scheduled delivery for that target morning;
- prevent a Wake Session from starting for that target morning when set before execution;
- cancel remaining alarms/checks if deliberately set during an active wake session through an approved confirmed alarm-state control;
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
- mutate global Pause;
- count as `I’m Awake` acknowledgement unless the user separately acknowledges wake.

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

The May 31 walkthrough did not fully redesign indefinite Pause. Maintain the May 30 model except where the new hero/context/Next 7 layout requires truthful display.

## 4. Entry points

| User entry point | Quiet | Pause |
| --- | --- | --- |
| Home Hero alarm icon / wake-time control | Apply/clear Quiet for target morning with confirmation | If paused, show paused state and approved paused actions |
| Home Hero Slot 6 purpose selector | No Quiet control | No Pause control |
| Day Detail | Apply/clear Quiet; ring-once if paused | Display inherited Pause; allow approved pause actions |
| Next 7 Mornings | Right-column per-row Quiet toggle | Show inherited Pause truthfully; do not globally pause inline |
| Month/list view | No inline mutation; row navigates to Detail | No inline mutation; row navigates to Detail |
| Settings / Wake Alarms | May include global explanations | Primary Pause/resume location |
| Active wake session | Primary action remains `I’m awake`; confirmed alarm-state Quiet may cancel remaining checks if exposed | Pause unavailable for current executing wake unless later safety spec approves |

## 5. Quiet confirmation copy

When alarm is currently on:

```text
Title: Make Tomorrow Morning Quiet?
Body: No alarm or wake checks will ring. Use this only if you do not need Subh to wake you.
Actions: Keep Alarm On / Make Quiet
```

Use `Make Today Morning Quiet?` for same-morning targets.

When Quiet is currently on:

```text
Title: Tomorrow Morning is Quiet
Body: No alarm or wake checks will ring, but your Suhoor/Fajr plan is saved.
Actions: Turn Alarm On / Keep Quiet
```

Use `Today Morning is Quiet` for same-morning targets.

The popover/action sheet pointer must point to the alarm icon/wake-time control when launched from the Hero.

## 6. Active-session Quiet cancellation

If active-session Quiet cancellation is exposed:

- it must not appear as the primary Slot 6 action;
- it must require explicit confirmation;
- it cancels remaining alarms/checks for the active purpose-scoped session;
- it writes a distinct cancellation reason, such as `quietDuringExecution`;
- it does not log `wakeAcknowledged` or `fajrPrayerLogged`;
- it should be included in testing as an edge case.

The default and preferred active wake action remains:

```text
I’m awake
```

## 7. Pause action sheet / Settings behavior

Settings primary language:

```text
Pause Subh wake alarms
Subh won’t ring until you resume.
```

Home paused-state sheet:

```text
Title: Alarms paused
Body: Subh won’t ring until you resume.
Actions: Ring Tomorrow Only / Resume Alarms / Keep Paused
```

Use `Ring This Morning Only` for same-morning targets.

`Ring tomorrow only` creates `DateAlarmOverride.ringDespitePause`. It does not clear global Pause.

## 8. Precedence and restoration

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

## 9. Logging and analytics

Quiet may create a user-intent/state record such as:

```text
quietMorning(targetMorning, selectedPurpose, savedAlarmTime, createdAt, sourceSurface)
quietDuringExecution(targetMorning, selectedPurpose, cancelledAt, sourceSurface)
```

It must not create:

```text
missedFajr
missedFast
deliveryFailure
permissionFailure
wakeSessionNoResponse
wakeAcknowledged
fajrPrayerLogged
```

Pause may create policy-state metadata, but individual inherited paused days should not be logged as manually Quiet unless the user explicitly sets Quiet for that date.

## 10. Delivery requirements

When Quiet is set before execution:

- cancel pending primary alarm for the target morning;
- cancel pending follow-up alarms for the target morning;
- invalidate stale scheduler identifiers for that morning;
- update delivery ledger/reconciliation as intentionally suppressed, not failed.

When Quiet is set during execution through approved confirmation:

- stop/cancel the current and remaining alarms/checks for that active session;
- write cancellation reason `quietDuringExecution` or equivalent;
- do not mark wake acknowledgement or prayer completion.

When Pause is set:

- suppress future wake scheduling while active;
- cancel upcoming scheduled wake alarms as required by platform constraints;
- preserve enough metadata to restore active scheduling on resume;
- continue allowing non-wake app notifications only if separately allowed by the notification spec.

## 11. Copy rules

Use:

```text
Quiet
Alarms paused
Make Tomorrow Morning Quiet?
Make Today Morning Quiet?
Keep Alarm On
Make Quiet
Turn Alarm On
Keep Quiet
Alarm saved for 5:42 AM
Rings Tomorrow Only
Rings This Morning Only
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

## 12. Acceptance criteria

1. Quiet is a one-morning alarm override, not a wake purpose.
2. Pause is app-wide and indefinite, not a wake purpose.
3. Hero Quiet confirmation uses `Make Tomorrow Morning Quiet?` / `Make Today Morning Quiet?` copy.
4. Home Slot 6 never shows Quiet in the Suhoor/Fajr selector.
5. Quiet preserves Fajr/Suhoor purpose and purpose-specific alarm settings.
6. Pause preserves saved plans and manual Quiet dates.
7. Ring-once while paused does not resume all alarms.
8. Quiet and Pause do not create missed-prayer or missed-fast records.
9. Delivery failures, permission blocks, and missing setup do not display as Quiet.
10. Next 7 exposes only a per-row Quiet toggle; it does not expose Pause, purpose, fasting-purpose, or alarm-time editing inline.
11. If active-session Quiet cancellation is exposed, it requires confirmation and does not log wake acknowledgement or Fajr prayer completion.
