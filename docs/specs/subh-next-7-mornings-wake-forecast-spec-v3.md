# Subh Next 7 Mornings Wake Forecast Specification v3 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-next-7-mornings-wake-forecast-spec-v3.md` |
| Version | 3 |
| Spec status | Active Home planning/forecast card spec |
| Date | 2026-05-30 |
| Related specs | Index, Hero, Detail, Morning Resolution, Shared Tags, Month, Weekly Fajrcast |
| Owning domain / surface | Home / Plan ahead / Next 7 Mornings |

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

Next 7 Mornings gives the user a compact forecast of upcoming resolved mornings without becoming a dense settings table.

It answers:

```text
What are the next seven mornings, and will Subh ring?
```

## 2. Placement and collapse behavior

- The section label should use `Plan ahead`.
- The card/list label is `Next 7 Mornings`.
- It is collapsed by default unless the app has a product-approved reason to expand it.
- It should appear below the primary Hero and supporting planning context.

Do not use `Next 10` in active MVP copy.

## 3. Seven-morning horizon

The list contains:

```text
Immediate/current relevant morning + following six mornings
```

The same seven visible dates should be available to Weekly Fajrcast for inspection-only summary.

## 4. Row composition

Each row should contain:

```text
Date / weekday label
Middle-lane opportunity/context tags
Trailing status or wake time
Optional secondary explanatory text where space allows
```

Middle lane follows the Shared Day Tag contract:

```text
Allowed: Ramadan, White Days, Eid, Arafah, Ashura, etc.
Not allowed as middle tags: Fajr, Suhoor, Quiet, Paused, Rings once, Fasting.
```

## 5. Trailing status values

Rows may show:

```text
5:42 AM
4:51 AM
Quiet
Paused
Rings once
Turn on alarms
Set location
Alarm issue
```

`Paused` is approved compact row copy. Home Hero uses `Alarms paused`.

## 6. Mutation model

Rows are navigation surfaces, not inline editors.

- Tapping a row opens Day Detail for that morning.
- No inline Quiet toggle in MVP.
- No inline Pause toggle in MVP.
- No inline Fajr/Suhoor selector in MVP.
- No inline fasting-purpose selector in MVP.

This keeps the compact card readable and prevents accidental wake-plan changes.

## 7. Quiet/Pause display

Quiet row:

```text
Middle tags: opportunity/context only
Trailing status: Quiet
Optional secondary: Alarm saved for 5:42 AM
```

Paused row:

```text
Middle tags: opportunity/context only
Trailing status: Paused
Optional secondary: Alarm saved for 5:42 AM
```

Rings-once row:

```text
Middle tags: opportunity/context only
Trailing status: Rings once or wake time + rings-once copy
```

## 8. Hydration and persistence

Next 7 consumes canonical Morning Resolution output. It must not create durable records for generated/default days just by displaying them.

Future durable edits made in Day Detail should hydrate into Next 7 when their date enters the visible horizon.

## 9. Acceptance criteria

1. The card is called `Next 7 Mornings`.
2. It shows seven mornings, not ten.
3. Rows navigate to Day Detail for changes.
4. Rows do not expose inline Quiet/Pause/purpose controls.
5. Middle-lane tags are opportunity/context only.
6. Quiet/Paused/Rings once appear as trailing statuses.
7. Routine Fajr/Suhoor labels do not appear as middle-lane tags.
8. Weekly Fajrcast uses the same seven visible dates and remains inspection-only.
