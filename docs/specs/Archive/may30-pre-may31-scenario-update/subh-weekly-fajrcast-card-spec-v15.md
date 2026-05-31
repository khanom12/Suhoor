# Subh Weekly Fajrcast Card Specification v15 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-weekly-fajrcast-card-spec-v15.md` |
| Version | 15 |
| Spec status | Active inspection-only weekly summary spec |
| Date | 2026-05-30 |
| Related specs | Index, Next 7, Shared Tags, Morning Resolution |
| Owning domain / surface | Weekly Fajrcast summary card |

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

Weekly Fajrcast summarizes the same seven visible mornings used by Next 7 Mornings. It helps the user inspect the week’s Fajr/Suhoor rhythm and context without becoming another editor.

## 2. Core rule

Weekly Fajrcast is inspection-only for MVP.

It must not mutate:

- Fajr/Suhoor purpose;
- Quiet;
- Pause;
- ring-once exception;
- fasting-purpose selection;
- alarm-time slider values;
- completion logs.

## 3. Data source

Use canonical Morning Resolution output for the same seven dates shown by Next 7 Mornings.

Do not compute a separate weekly truth.

## 4. Presentation

Weekly Fajrcast may show:

- Fajr time trend;
- Suhoor/Fajr wake-time trend where useful;
- meaningful opportunity/context markers;
- compact alarm-state indications when helpful;
- educational or planning summary copy.

It must follow the shared tag rule:

```text
Opportunity/context markers are separate from wake purpose and alarm state.
```

## 5. Quiet/Pause display

Quiet, Paused, and Rings once may be summarized as alarm-state indicators, not opportunity tags and not wake purposes.

## 6. Acceptance criteria

1. Weekly Fajrcast uses the same seven dates as Next 7.
2. It does not mutate state.
3. It does not expose inline Quiet/Pause controls.
4. It does not show Fajr/Suhoor/Quiet/Paused as middle-lane opportunity tags.
5. Tapping through, if supported, routes to Day Detail for edits.
