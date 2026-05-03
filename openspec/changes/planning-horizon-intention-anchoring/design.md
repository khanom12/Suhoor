## Current Implementation Anchors

- `ScheduledDateSource` already stores durable user-added Gregorian single days, Gregorian ranges, Hijri single days, recurring Islamic sources, and Islamic quick-add groups.
- `ScheduledDateSourceResolver` already materializes sources into `ResolvedScheduledDateEntry` with provenance and implicit Ramadan context.
- Hijri-based quick adds are already migrated from fixed Gregorian single days into `HijriSingleDaySource`.
- `ActiveWindowSnapshotBuilder` already separates `visibleDays` from `scheduledDays`; delivery planning already iterates `snapshot.scheduledDays`.
- `DeliveryReconciliation` already consumes resolver-materialized `ScheduledEvent`s and skips past/suppressed events.
- `HijriAdjustmentChangeStore` already records future Hijri source date movement for review.
- Completion records and fast logs are date-keyed historical observations and are not source records.

## Proposed Ownership Boundaries

- Planning owns horizon roles and durable user meaning anchors.
- Morning resolution owns day meaning, user intention, wake boundary, wake time, alarm activation, materialized events, copy state, and completion requirements for a resolved date.
- Active window building owns which resolved days are visible and which are operationally scheduled.
- Alarm delivery owns expected platform deliveries, pending-state reconciliation, stale cancellation, and delivery diagnostics.
- SwiftUI surfaces remain adapters that display snapshots and emit intents.

## Planning Model

Reuse `ScheduledDateSource` as the durable user-planning record and add anchor metadata rather than introducing a duplicate planning store. Each source exposes a `MorningIntentAnchor` derived from its kind/origin when older persisted data lacks explicit metadata.

Anchor examples:

- Manual one-day plan: `gregorianDate(dateKey)`.
- Manual date range: `gregorianRange(startDateKey, endDateKey)`.
- Hijri quick add such as Arafah/Ashura/White Days: `observance(observanceID, occurrenceID)` or `hijriDate`.
- Recurring Monday/Thursday: `weekdayPattern`.
- Ramadan/default Ramadan: `hijriMonthWindow`.
- Default plan: `defaultSetting`.
- Immediate alarm suppression: model-supported as `immediateAlarm` for narrowly scoped future work.
- Completed history: model-supported as `completionHistory`, but stored completion records remain fixed by date.

## Resolver Pipeline

The planning layer feeds resolved provenance into the existing morning pipeline:

1. Resolve date sources and implicit contexts into `ResolvedScheduledDateEntry`.
2. Carry planning anchor metadata in provenance.
3. Resolve day purpose and wake state through existing morning resolvers.
4. Build `ActiveAlarmWindowSnapshot`.
5. Expose `PlanningWindowSnapshot` from the active window for visible/editable/scheduled/history role sets.
6. Send only `scheduledDays` materialized events to delivery.

## Persistence and Migration

Persist anchor metadata on `ScheduledDateSource` with Codable compatibility defaults. Bump the scheduled-date-source cleanup migration so existing records are re-saved with derived planning metadata. Existing behavior is preserved because derived anchors follow the existing source kind/origin.

`HijriAdjustmentChange` gains optional anchor/review metadata so moved future plans can explain why they moved without mutating completed history.

## Scheduler Handoff

Delivery continues to plan from `ActiveAlarmWindowSnapshot.scheduledDays` only. Display rows from Next 10, Weekly Fajrcast, or month browsing are never schedule scope unless the window builder placed them in `scheduledDays`.

## Testing Strategy

- Unit tests for derived anchors and Codable migration/defaulting.
- Resolver tests proving provenance carries anchors.
- Hijri tests proving observance/Hijri anchored plans move when Hijri month adjustment changes and Gregorian anchors stay fixed.
- Delivery planning tests proving visible-only rows do not schedule expected deliveries.
- Completion/history tests proving completed records remain keyed to their original date.

## Compatibility Risks

- Existing JSON payloads must decode without anchor fields.
- Equality of cached window snapshots changes when provenance gains metadata; tests should assert behavior rather than raw encoded shape.
- Some future product decisions remain open, so immediate-alarm and completion-history anchors are model-supported without adding new UI flows.

## Rollout Order

1. Validate OpenSpec change.
2. Add compatible anchor and horizon models.
3. Thread anchors through provenance and Hijri adjustment review records.
4. Add planning-window snapshot adapter.
5. Add targeted tests.
6. Run OpenSpec validation, focused tests, and an app build.
7. Commit and push to `main` when validation is clean.
