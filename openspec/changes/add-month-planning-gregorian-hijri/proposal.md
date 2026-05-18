## Summary

Add Month Planning so Subh users can browse current and future Fajr-centered mornings by Gregorian calendar month or Hijri month, then open any visible morning in the existing Day Detail surface.

## Problem

Subh currently answers the next morning and a near-term forecast, but users who need to plan beyond the immediate week have no calm month-level surface. The product should support month planning without drifting into a generic calendar browser, without storing generated defaults, and without scheduling every visible future morning.

The provided working spec `subh-month-planning-gregorian-hijri-spec-v1.md` locks this behavior:

- Home gets compact `Calendar Months` and `Hijri Months` entry tiles under `Plan ahead`.
- Month pickers show the current month plus the next 12 months for the selected calendar system.
- Current month detail excludes past or non-actionable mornings using the existing wake/actionability boundary.
- Future month detail shows all mornings in the selected month.
- Month Detail includes a production-safe Monthly Fajrcast placeholder slot, not the final chart.
- Rows use the same resolved Subh morning model as Home, Next 7 Mornings, Weekly Fajrcast, and Day Detail.
- Day edits stay owned by the existing Day Detail screen.

## Scope

- OpenSpec and docs ingestion for the Month Planning v1 spec.
- Shared month-planning entitlement access model for Free, Plus, and Complete behavior.
- Gregorian and Hijri picker item generation.
- Selected month detail snapshot generation and row presentation.
- SwiftUI Home tiles, picker, detail, row, empty/loading, lock/preview, and Monthly Fajrcast placeholder views.
- Day Detail navigation from Month Detail while preserving back navigation.
- Focused unit coverage for horizon, current-month filtering, label ordering, and entitlement behavior.

## Non-Goals

- Do not implement the final Monthly Fajrcast chart.
- Do not add month-wide observance rules.
- Do not create a parallel Fajr, Hijri, alarm, or scheduling engine.
- Do not reintroduce Tahajjud or non-fasting pre-Fajr behavior.
- Do not schedule platform alarms from Month Planning browsing.
- Do not persist generated month rows unless the user explicitly edits through approved existing flows.
- Do not do a broad Suhoor-to-Subh repository rename.

## User-Visible Impact

Users will see a compact `Plan ahead` area on Home with two tiles:

- `Calendar Months` / `Plan by Gregorian month`
- `Hijri Months` / `Plan by Islamic month`

Free users see a locked/preview experience. Plus and Complete users can browse current month plus the next 12 Gregorian or Hijri months. Month Detail lists mornings, not alarms, and opens the existing Day Detail for editing.

## Persistence, Scheduling, and Migration Impact

This change adds generated presentation snapshots and navigation surfaces. It does not migrate existing data, create durable day records by browsing, or schedule platform alarms from month rows. Existing alarm delivery remains governed by the active schedule window.
