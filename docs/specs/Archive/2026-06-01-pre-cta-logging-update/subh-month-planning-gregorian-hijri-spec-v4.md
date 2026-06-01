# Subh Month Planning, Gregorian/Hijri Browsing, and Day Detail Routing Specification v4 — May 31 Cross-Reference Alignment

| Field | Value |
| --- | --- |
| Canonical filename | `subh-month-planning-gregorian-hijri-spec-v4.md` |
| Version | 4 |
| Spec status | Active month/list planning specification |
| Date | 2026-05-31 |
| Related specs | Index, Next 7, Day Detail, Shared Tags, Planning Horizon, Morning Resolution |
| Owning domain / surface | Month planning and Gregorian/Hijri date browsing |


## May 31, 2026 cross-reference alignment

This v4 update is intentionally narrow. Month Planning remains an inspection and navigation surface, not a dense inline editor. The update aligns references to the active May 31 tag contract and preserves the rule that Month/List views do not gain the new Next 7 right-column Quiet toggle unless a later approved spec explicitly changes Month Planning.

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

Month Planning lets users inspect and plan mornings beyond the immediate Home Hero while preserving the same resolver, tag, and mutation rules as Next 7 and Day Detail.

## 2. Surface role

Month view is an inspection and navigation surface.

It should allow the user to find a date and open Day Detail. It should not become a dense inline editor for Quiet/Pause/purpose state in MVP.

## 3. Calendar presentation

The surface may support:

- Gregorian month browsing;
- Hijri date labels;
- Ramadan and Eid context;
- fasting opportunity context;
- selected-day navigation;
- list or calendar-grid layouts where appropriate.

## 4. Row/day composition

For compact rows or list items:

```text
Date / weekday
Middle-lane opportunity/context tags
Trailing status or wake time
```

Middle-lane tags follow `subh-shared-day-tag-presentation-contract-v3.md`.

Allowed examples:

```text
Ramadan
White Days
Eid
Arafah
Ashura
```

Do not show routine middle-lane tags:

```text
Fajr
Suhoor
Quiet
Paused
Rings once
Fasting
Tahajjud only
Other early worship
```

## 5. Trailing statuses

Month/list rows may show:

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

## 6. Mutation model

- Tapping a date/row opens Day Detail.
- Day Detail owns edits for Fajr/Suhoor, Quiet, ring-once, alarm time, reset, and fasting-purpose changes.
- Month view does not expose inline Quiet/Pause toggles in MVP.
- Month view does not expose a three-state Fajr/Suhoor/Quiet selector.

## 7. Generated vs stored dates

Displaying a month must not create durable date records for every visible date.

Durable records are created only when the user makes a meaningful edit or when another product-approved planning source creates a durable intention.

## 8. Quiet/Pause handling

- Quiet appears as a trailing status for manually quiet dates.
- Paused appears as a trailing status for inherited global Pause.
- Manual Quiet remains Quiet after global Pause resumes.
- Inherited Pause disappears from rows after resume unless another state applies.
- Ring-once exceptions while paused appear as trailing status until consumed/expired.

## 9. Acceptance criteria

1. Month rows use opportunity/context tags only in the middle lane.
2. Fajr/Suhoor/Quiet/Paused do not appear as middle-lane tags.
3. Quiet/Pause edits route through Day Detail.
4. Displaying a month does not create unnecessary durable records.
5. Gregorian and Hijri labels remain clear.
6. Month and Next 7 use the same row doctrine.
