# Subh Planning Horizon, Day Resolution, and Intention Anchoring Specification v4 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-planning-horizon-day-resolution-intention-anchoring-spec-v4.md` |
| Version | 4 |
| Spec status | Active planning horizon and durable-intention specification |
| Date | 2026-05-30 |
| Related specs | Index, Morning Resolution, Quick Mutation, Next 7, Month, Day Detail, Alarm Delivery |
| Owning domain / surface | Generated vs stored future mornings and intention anchoring |

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

This spec defines which future mornings are generated for display, which user decisions become durable records, and how future edits hydrate when they enter Home/Next 7/Month/scheduled horizon.

## 2. Generated vs durable

Generated/default mornings are calculated from defaults, location, prayer times, calendar context, and user settings. They should not be persisted merely because they were displayed.

Durable records are created when the user makes a meaningful decision, such as:

```text
select Fajr/Suhoor for a date
set Quiet for a date
set ring-once exception for a paused date
adjust alarm time for a date/purpose
select fasting purpose for a date
reset a date to defaults
create a recurring/default plan through an approved future flow
```

## 3. Anchoring types

Supported durable anchors may include:

- exact Gregorian morning date;
- Hijri/observance date where product-approved;
- recurring weekday or Islamic recurrence where product-approved;
- immediate current/next morning target;
- Ramadan season defaults.

Quiet is date-specific for MVP. Pause is global and indefinite, not a date-range anchor.

## 4. Horizon behavior

- Home resolves the current/next relevant morning.
- Next 7 resolves the immediate/current relevant morning plus six following mornings.
- Weekly Fajrcast uses the same seven visible mornings as Next 7.
- Month resolves visible dates for display but does not persist them unless edited.
- Alarm Delivery schedules only the active scheduled horizon required by platform/product constraints.

## 5. Hydration

When a durable future edit enters a visible/scheduled horizon, Morning Resolution must hydrate it into the resolved snapshot.

Examples:

- a Quiet date appears as Quiet in Next 7 when it enters the horizon;
- a saved Suhoor date uses the saved Suhoor alarm config;
- a global Pause state appears as Paused for future rows until resumed;
- a manual Quiet date remains Quiet after global Pause resumes.

## 6. Reset behavior

Resetting a selected date to defaults clears date-specific records owned by the editor but does not change global Pause or broad defaults unless explicitly requested.

## 7. Acceptance criteria

1. Displaying future dates does not create records by itself.
2. User edits create durable records with clear anchors.
3. Quiet is a date-specific alarm override.
4. Pause is global and indefinite for MVP.
5. Future edits hydrate consistently across Home, Next 7, Month, Weekly Fajrcast, and Delivery.
6. Weekly Fajrcast remains inspection-only.
