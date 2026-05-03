## Why

Morning resolution now owns the canonical Subh morning, and alarm delivery now owns platform deliverability. The remaining foundation gap is planning ownership: Subh can know many future religious/calendar opportunities, show a useful window, let the user plan ahead, and schedule only a narrow operational horizon, but those concepts must not collapse into one another.

This change is needed so generated display rows never become durable user decisions, month browsing never schedules alarms by itself, future user meaning survives Hijri/calendar correction through explicit anchors, and completed history stays attached to what actually happened.

## What Changes

- Add a durable `planning-horizon-intention-anchoring` capability that separates knowledge range, display horizon, edit horizon, active scheduled horizon, and history horizon.
- Reuse existing `ScheduledDateSource`, provenance, Hijri adjustment, active-window, morning-resolution, and delivery-reconciliation models where they already express the domain.
- Add explicit planning anchors to durable scheduled-date sources and resolved provenance so future user decisions can be Gregorian-date, Hijri-date, observance, weekday, Hijri-month-window, default-setting, immediate-alarm, or completion-history anchored.
- Add a planning-window snapshot that exposes visible, editable, active-scheduled, and historical date sets without letting display surfaces define scheduler scope.
- Preserve the rule that Next 10 and month browsing are generated display/planning surfaces: browsing or viewing alone stores nothing and schedules nothing.
- Keep Hijri/observance anchored future plans movable when calendar adjustments change, while Gregorian-date anchors and completed history remain fixed.
- Keep delivery downstream: delivery consumes only resolver-materialized events from `scheduledDays` and reports status without rewriting anchors, intentions, or Quiet state.

## Scope

In scope:

- OpenSpec coverage for planning horizons, anchored future intentions, Hijri movement, display-only generated days, active scheduled handoff, history preservation, and immediate alarm scope.
- Compatibility-first model additions around `ScheduledDateSource`, `ResolvedScheduledDateProvenance`, Hijri adjustment review records, and `ActiveAlarmWindowSnapshot`.
- Tests for anchor persistence, Hijri movement semantics, display-vs-scheduled horizon separation, delivery handoff, and history immobility.

Out of scope:

- Visual redesign of Next 10, month browsing, Home Hero, Alarm Detail, or Weekly Fajrcast.
- A separate Ramadan, Qada, Tahajjud, fasting, month-browsing, or alarm engine.
- Resolving open product decisions such as exact month browse range, Arafah authority policy, or a full review center.
- Replacing the alarm delivery transaction or prayer-time calculation stack.
- Remote telemetry or new data collection.

## Capabilities

### New Capabilities

- `planning-horizon-intention-anchoring`: Defines horizon separation, durable intention anchors, future calendar movement, history preservation, active alarm scope, and the handoff from planning into morning resolution.

### Modified Capabilities

- `morning-resolution`: Clarify that anchored durable planning meaning feeds the canonical resolver before date-specific overrides and that display-only generated days are not user intentions.
- `alarm-delivery-reliability`: Clarify that delivery schedules only the active scheduled horizon selected by the window builder, not the visible/display horizon.

## Risks

- Existing persisted date sources need compatibility defaults for anchor metadata without changing their practical behavior.
- Hijri movement touches sensitive calendar behavior; future observance/Hijri anchored plans may move, but Gregorian-date plans and completed history must not.
- Adding horizon vocabulary could create conceptual noise unless it is kept near domain models and surfaced only where useful.
- Full physical alarm reliability still depends on iOS platform limits; this change should preserve honest delivery diagnostics rather than claiming more certainty.

## Impact

- Affected code areas include `Subh/Core/Scheduling`, `Subh/Core/Services/ActiveWindowBuilder.swift`, `Subh/Core/Services/ScheduleService.swift`, `Subh/Core/Hijri`, delivery reconciliation tests, Hijri/date-source tests, and OpenSpec docs.
- Existing scheduled alarms should only change through the existing active-window delivery handoff.
- Existing user date sources remain readable; new metadata is added with compatibility defaults.
- No new production dependency is expected.
