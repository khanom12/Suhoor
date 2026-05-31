# Subh Wake Session Testing Harness v4 Update Report

Date: 2026-05-30
Updated spec: `subh-wake-session-testing-and-simulation-harness-spec-v4.md`
Supersedes: `subh-wake-session-testing-and-simulation-harness-spec-v3.md`

## 1. Reason for update

The previous v3 testing harness spec was directionally useful, but it still contained behaviors from the older wake model and did not provide enough detail for end-to-end testing of the reconciled Quiet / Pause / Hero / Wake Flow model.

The v4 update was created to make the testing harness both:

1. **implementation-grade** — specific enough for Codex/developers to implement scenarios, architecture, assertions, logs, scheduler behavior, and automated tests; and
2. **tester-friendly** — easy for Omar to use without facing a large subsystem-heavy lab.

## 2. Main model correction

The spec now consistently tests this model:

```text
Wake purpose: Fajr | Suhoor
Alarm state: active | quiet | paused | rings-once | blocked | issue
```

This replaces the older model where Quiet could appear as a mode or selector option.

## 3. Removed or corrected old behavior

### 3.1 Quiet is no longer a mode

Updated the test harness so Quiet is tested as:

```text
Quiet for this morning = one-morning alarm-state override
```

Not as:

```text
Fajr | Suhoor | Quiet
```

Why: The current product model separates wake purpose from alarm state. Quiet suppresses delivery; it does not explain why/when the user intends to wake.

### 3.2 Removed active-session Quiet flow

The older v3 spec included “Quiet During Follow-up Alarms.” v4 removes that as an active supported test flow.

New rule:

```text
Quiet is available before alarm execution begins.
Quiet is not exposed after the first alarm begins.
```

Why: This aligns the test harness with the reconciled Quiet/Pause/Hero/Wake Flow model and prevents the UI from offering a confusing state mutation during active wake execution.

### 3.3 Removed `Stop checks`

v4 explicitly forbids `Stop checks` as an active user-facing control.

Active wake execution must expose:

```text
I’m awake
```

Why: The wake session is now organized around meaningful acknowledgement, not technical cancellation language.

### 3.4 Corrected system dismissal behavior

The older v3 text said alarm stop/dismissal did not confirm awake. v4 aligns to the current MVP direction:

```text
Explicit system / AlarmKit dismissal counts as awake acknowledgement where supported.
acknowledgedBy = systemAlarmDismiss
```

Why: This removes the contradiction between wake-session tests and the latest reconciled model. v4 still requires the source to be captured separately from in-app acknowledgement.

## 4. Added high-detail testing coverage

### 4.1 Quiet scenarios

v4 now includes explicit scenarios for:

- Active Fajr → Quiet;
- Active Suhoor → Quiet;
- Quiet → Turn alarm on;
- Quiet + switch Fajr/Suhoor;
- Quiet while global Pause active;
- Quiet unavailable after first alarm begins;
- Quiet logging semantics.

Why: These are the core cases needed to prove Quiet behaves as a one-morning suppression state without corrupting wake purpose, scheduler, or logs.

### 4.2 Pause scenarios

v4 adds full Pause testing:

- Global Pause Fajr;
- Global Pause Suhoor;
- Pause → Ring tomorrow/this morning only;
- clear ring-once exception;
- Pause → Resume;
- Pause during active wake execution;
- Pause logging semantics.

Why: Pause was under-specified in v3, but it is one of the main model changes and needs end-to-end testing across UI, scheduler, and logs.

### 4.3 Suhoor → Fajr handoff scenarios

v4 adds a dedicated handoff scenario pack:

```text
Suhoor wake → I’m fasting today → Fajr begins → I’m awake for Fajr → I prayed Fajr
```

It also tests branches where fasting is not logged, Suhoor is not acknowledged, or Fajr prayer is not logged before Fajr ends.

Why: Suhoor wake acknowledgement must not automatically become Fajr wake acknowledgement or Fajr prayer completion.

### 4.4 Date-context scenarios

v4 adds required date contexts:

- ordinary non-Ramadan morning;
- Ramadan;
- Monday;
- Thursday;
- White Days;
- Eid / fasting unavailable;
- very early Fajr season;
- very late Fajr season;
- DST spring/fall transitions;
- timezone/location change;
- missing location;
- missing prayer times;
- past/today/tomorrow/future dates.

Why: Omar specifically wanted confidence across all occasions, dates, and states.

### 4.5 Cross-surface consistency

v4 requires consistency testing across:

```text
Home Hero
Day Detail
Next 7 Mornings
Month Planning
Weekly Fajrcast
Scheduler
Morning Log
Diagnostics
```

Why: Quiet/Pause drift can occur when one surface independently interprets state. v4 requires all surfaces to consume the canonical resolver.

## 5. UX improvements added

### 5.1 Tester-first information architecture

The spec keeps the top-level harness simple:

```text
Preview Home UI
Run Real Alarm Test
Diagnostics
```

Why: Omar had identified the earlier lab as overwhelming. v4 preserves depth but keeps it behind guided scenario cards and collapsed diagnostics.

### 5.2 Scenario card standard

Every scenario card must include:

- title;
- one-sentence purpose;
- wake purpose;
- alarm state;
- date context;
- calculated times summary;
- whether real alarms ring;
- estimated test time;
- primary action;
- secondary details.

Why: Omar should know what a scenario tests before launching it.

### 5.3 Typography and button guidance

v4 adds explicit UX guidance for:

- screen titles;
- section headings;
- scenario card titles/body text;
- metadata chips;
- diagnostic tables;
- primary/secondary button size;
- minimum touch targets.

Why: The test harness must itself be usable and readable, not just technically complete.

### 5.4 Simulation dock requirements

The Home simulation dock must show:

- test mode state;
- scenario name;
- wake purpose;
- alarm state;
- simulated time/date;
- location;
- Fajr time range;
- alarm time;
- expected Hero slots;
- Previous / Next / Jump / Inspect / Exit controls.

Why: Omar should be able to test the actual Home UI while still seeing enough context to know what he is looking at.

### 5.5 Hero Slot Inspector

v4 adds a required Hero Slot Inspector with expected vs actual comparison for all six Hero slots.

Why: The Hero section was one of the main areas where implementation drift occurred.

## 6. Time availability improvements

### 6.1 Standard scenarios must pre-calculate times

v4 adds a strong rule:

```text
Every standard scenario must have complete time data before launch.
```

Required values include:

- simulated current time;
- Fajr begins;
- Fajr ends / sunrise boundary;
- selected saved alarm time;
- primary alarm time;
- follow-up times;
- cutoff boundary;
- location;
- timezone;
- prayer-time source.

Why: Omar noticed cases where the Hero showed `No time available`. Standard scenarios should feel like the real app with real calculated times.

### 6.2 Block broken scenarios before launch

If a normal scenario cannot calculate times, the scenario card must block launch and show a setup issue.

Why: Broken test setup should not look like a normal product state.

### 6.3 Missing time is now a dedicated issue scenario

`No time available` is only allowed in dedicated issue-state tests such as missing location or missing prayer times.

Why: This makes unavailable-time behavior testable without letting it contaminate normal Fajr/Suhoor tests.

## 7. Real Alarm Test updates

v4 keeps real AlarmKit mapped playback but clarifies the UX and expectations.

Required behavior:

- real and simulated schedules shown before scheduling;
- primary only through primary + 5 follow-ups;
- default primary + 5;
- five-minute follow-up spacing preserved;
- explicit confirmation sheet;
- Cancel Test Alarms always visible when real mapped alarms exist;
- system dismissal behaviour tested and logged.

Why: Real Alarm Test should validate actual device behavior but remain safe and understandable.

## 8. Diagnostics improvements

v4 expands Diagnostics into:

- Hero Slot Inspector;
- Time Inspector;
- Surface Consistency;
- Scheduled Test Alarms;
- Test Event Log;
- Permission / Setup Simulation;
- Reset Test Mode;
- Advanced Technical Details.

Why: Diagnostics need to be deep enough to explain failures, but not be the primary testing workflow.

## 9. Automated testing improvements

v4 adds required unit, integration, UI/snapshot, and end-to-end simulated tests.

Key new assertions:

- Quiet is not a wake purpose;
- Pause is not a wake purpose;
- standard scenarios never produce accidental `No time available`;
- Quiet/Pause/ring-once scheduler behavior;
- Suhoor and Fajr acknowledgements remain separate;
- row middle-lane tags exclude routine states;
- cross-surface consistency;
- current wake actions remain free/core.

## 10. Files produced

- `subh-wake-session-testing-and-simulation-harness-spec-v4.md`
- `subh-wake-session-testing-harness-v4-update-report.md`

## 11. Remaining implementation note

This was a spec update only. The codebase still needs a focused implementation pass to build or align the harness according to v4.
