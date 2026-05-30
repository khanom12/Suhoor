# Subh Wake Session Testing and Simulation Harness Specification v4 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-wake-session-testing-and-simulation-harness-spec-v4.md` |
| Version | 4 |
| Spec status | Active debug/test harness specification |
| Date | 2026-05-30 |
| Related specs | Index, Hero, Wake Sessions, Alarm Delivery, Quiet/Pause, Interaction Inventory |
| Owning domain / surface | Debug-only testing, time simulation, and QA support |

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

The harness lets development and QA test Subh’s morning states without waiting for real Fajr/Suhoor windows.

It should reduce complexity for testers by centering around scenario groups and visible Home/Detail behavior, not a wall of low-level controls.

## 2. Debug-only requirement

The harness must be excluded from production user builds unless explicitly protected behind a debug/internal entitlement.

## 3. Core harness capabilities

Required capabilities:

```text
Simulation Mode toggle
Simulated current date/time
Scenario launcher
Home Hero live simulation
Day Detail simulation
Wake Session controls
Pending alarm inspector
Morning log inspector
Permission/setup simulator
Cleanup/reset tools
```

## 4. Preferred information architecture

Use progressive disclosure:

1. **Scenario Launcher** — primary entry for common states.
2. **Simulated Time** — current simulated date/time and jump controls.
3. **Live Surface Preview** — Home/Detail reflect the simulated resolved snapshot.
4. **Execution Controls** — fire primary alarm, fire follow-up, acknowledge, system dismiss, end no response.
5. **Inspectors** — scheduled alarms, logs, resolver snapshot, delivery ledger.
6. **Advanced Tools** — cleanup/reset, permission failures, raw state explorer.

Do not make testers start with a huge unstructured lab full of equally prominent controls.

## 5. Required scenario groups

| Group | Scenarios |
| --- | --- |
| Planning | Active Fajr, Active Suhoor, adjusted alarm time, purpose switch preservation |
| Quiet | Set Quiet, clear Quiet, Quiet Fajr, Quiet Suhoor, Quiet while paused/resume interactions |
| Pause | Global Pause, resume, ring tomorrow only, clear ring-once |
| Setup/issue | Turn on alarms, Set location, Alarm issue, delivery reconciliation failure |
| Fajr execution | primary alarm, follow-up pending, final alarm, I’m awake, I prayed Fajr |
| Suhoor execution | primary alarm, I’m awake, I’m fasting today, Fajr begins, I’m awake for Fajr, I prayed Fajr |
| System dismissal | explicit system/AlarmKit dismissal as awake acknowledgement |
| No response | ended/no response without missed-prayer inference |
| Rows/cards | Next 7, Month, Weekly Fajrcast display-only behavior |
| Pricing gates | Free/core access to Quiet/Pause/Wake Sessions/current logs |

## 6. Simulated time

The harness must allow:

- setting simulated date;
- setting simulated time;
- jumping to before alarm;
- jumping to alarm time;
- jumping to follow-up pending;
- jumping to Fajr begins;
- jumping to before Fajr ends;
- jumping to Fajr end;
- returning to real time.

Home and Detail should consume the simulated resolver snapshot so the tester sees the real UI state, not just synthetic labels inside Settings.

## 7. Execution controls

Execution controls should include:

```text
Fire primary alarm
Fire follow-up alarm
Tap I’m awake
Simulate system dismissal
End with no response
Tap I’m fasting today
Tap I prayed Fajr
Advance to Fajr begins
Advance to Fajr end
```

Do not include an active-session Quiet control. Quiet must be tested before execution begins.

## 8. Inspectors

Inspectors should show:

- resolved morning snapshot;
- scheduled primary/follow-up alarm identifiers;
- delivery ledger entries;
- wake session state;
- morning log entries;
- acknowledgement source;
- global Pause policy;
- date overrides.

## 9. Acceptance criteria

1. A tester can simulate Quiet/Pause/Hero states without waiting for real morning times.
2. Home Hero updates from simulated time/resolution.
3. Scenario Launcher covers all reconciled scenario groups.
4. Active wake execution has `I’m awake`, not Quiet or Stop checks.
5. System dismissal scenario records awake acknowledgement.
6. Next 7/Month/Weekly scenarios confirm display/navigation-only behavior.
7. The harness is easier to use than a flat list of technical controls.
