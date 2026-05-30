# Subh Quiet Mode and Quiet Morning Contract Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-quiet-mode-quiet-morning-contract-spec-v1.md` |
| Version | 1 |
| Spec status | Canonical working spec; created to fill missing Quiet Mode ownership gap |
| Related specs | `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`, `subh-morning-hero-item-spec-v15.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`, `subh-mvp-interaction-inventory-v4.md` |
| Owning domain / surface | Quiet Mode, Quiet Morning overlay, alarm suppression, restore behavior |
| Implementation audit status | Needs implementation audit |

## Purpose

Define Quiet Mode as an intentional alarm-suppression overlay for a Fajr-centered morning. Quiet Mode helps the user stop wake delivery for a specific morning without corrupting Fajr/Suhoor state, prayer/fasting records, delivery diagnostics, or future planning.

Quiet Mode is not a generic failure state. It must not be used to hide permission failures, delivery failures, stale scheduling, missing data, or missed-prayer assumptions.

## What This Spec Owns

- Quiet Mode product meaning.
- Quiet Morning state and logging semantics.
- Preservation/restoration of underlying Fajr or Suhoor state.
- Quiet behavior during an active Wake Session.
- Delivery cancellation expectations when Quiet is confirmed.
- UI copy and confirmation requirements specific to Quiet.

## What This Spec Does Not Own

- Fajr, Fajr end, Maghrib, or final-third calculation.
- Suhoor fasting-intention taxonomy.
- Prayer or fasting completion judgment.
- AlarmKit implementation details beyond Quiet cancellation handoff.
- Menstruation, illness, travel, or exemption tracking as personal-data features.
- Long-term analytics or paid-history surfaces.

## Core principles

1. **Quiet is intentional suppression.** The user is saying “do not wake me for this morning.”
2. **Quiet is not failure.** Permission blocked, delivery failed, stale alarm missing, and missing prayer-time data must not render as Quiet.
3. **Quiet is not judgment.** Quiet must not automatically mean Fajr missed, fast missed, or worship skipped.
4. **Quiet preserves underlying meaning.** If the user quiets a Suhoor morning, the Suhoor/fasting intention remains available for restoration where valid.
5. **Quiet cancels delivery, not history.** It cancels pending primary/wake-check alarms for the relevant morning but does not erase previously logged awake/prayer/fasting confirmations.
6. **Quiet can be private.** The app must not require the user to give a reason.
7. **Quiet must be deliberate during active wake checks.** If alarms are actively trying to wake the user, Subh must ask before cancelling them.

## Definitions

| Term | Definition |
|---|---|
| **Quiet Mode** | User-selected state that suppresses wake delivery for a target morning. |
| **Quiet Morning** | The logged result of Quiet being active/confirmed for a resolved morning. |
| **Underlying mode** | The Fajr or Suhoor state that existed before Quiet was applied or that would otherwise apply. |
| **Quiet overlay** | The state layer that suppresses delivery while preserving underlying morning meaning. |
| **Active Quiet selection** | User selects Quiet for the currently resolved morning. |
| **Future Quiet selection** | User selects Quiet for a future date where planning surfaces support editing. |
| **Quiet confirmation sheet** | The required confirmation sheet when Quiet is selected during an active Wake Session. |

## State model

Quiet should be modeled as an overlay, not as a replacement for the morning.

Conceptual state:

```text
QuietMorningRecord
- morningId
- localDate
- dateKey
- createdAt
- updatedAt
- sourceSurface
- quietScope: immediateMorning | selectedDate | futureRange // future-ready
- underlyingMode: fajr | suhoor | unknown
- preservedSuhoorIntention, if any
- preservedWakeAnchor, if policy allows restoration
- activeWakeSessionId, if applied during active execution
- deliveryCancellationStatus
- userProvidedReason // optional/future, never required
```

Required behavior:

- Quiet must be idempotent. Repeated taps must not create duplicate Quiet records.
- Quiet must preserve enough underlying state to restore Fajr or Suhoor where valid.
- Quiet must not convert the morning into a permission failure or no-data state.
- Quiet must not store sensitive personal reason data unless a future privacy-reviewed feature explicitly asks and the user opts in.

## UI behavior

### Home Hero

When Quiet is selected for the target morning:

```text
[moon icon] Quiet mode
No alarm will ring for {relative day}
```

Rules:

- `Quiet mode` appears in the same primary wake-row slot used by the active wake time so the hero does not jump vertically.
- The relation/status line uses `No alarm will ring for {relative day}`.
- The Fajr boundary visual may remain visible as a static, non-interactive range when Fajr begin/end are available.
- The wake-adjustment handle is removed or disabled while Quiet is active.
- Quiet must not hide reliability warnings caused by permission/delivery failure; those are separate states.

### Active Wake Session confirmation

If the user selects Quiet while the current morning has pending or recently fired Wake Session alarms, show:

```text
Stop wake checks for this morning?

Subh will cancel the remaining alarms and mark this morning as quiet.

[Keep wake checks]
[Stop for this morning]
```

Required behavior:

- `Keep wake checks` dismisses the sheet and leaves the Wake Session unchanged.
- `Stop for this morning` logs Quiet Morning and cancels remaining primary/wake-check alarms for that Wake Session.
- The sheet must not use guilt language or require explanation.

### Restoration controls

When the user exits Quiet:

- selecting Fajr removes Quiet suppression and resolves the Fajr default for that morning unless another date-specific Fajr override validly applies;
- selecting Suhoor removes Quiet suppression and restores the preserved Suhoor intention where valid;
- manual wake-time adjustment restoration follows the latest Quick Wake Mode / Wake Adjustment contract. If that contract says mode switching clears manual adjustment, Quiet must not silently restore a stale manual drag value.

## Delivery behavior

When Quiet becomes active for a morning, the delivery layer must:

1. cancel pending primary alarm identifiers for that morning;
2. cancel pending wake-check identifiers for that morning;
3. cancel any delivery that the resolver marks as suppressed by Quiet for that scope;
4. leave unrelated future dates and unrelated event classes untouched;
5. publish a structured quiet delivery status such as `notScheduledBecauseQuiet`;
6. record the cancellation in the local delivery ledger.

Delivery must not:

```text
rename permissionBlocked as Quiet
rename failed scheduling as Quiet
delete underlying planning intent
cancel unrelated future plans
mark Fajr as missed
mark fast as missed
```

## Logging behavior

Quiet may log:

```text
quietMorningSelected
quietMorningConfirmed
wakeChecksCancelledByQuiet
quietMorningRestoredToFajr
quietMorningRestoredToSuhoor
```

Quiet must not automatically log:

```text
Fajr missed
Fajr skipped
Fast missed
Fast not completed
Prayer not required
```

If future product work adds exemption/not-required logging, it must be explicit, private, opt-in, and separate from Quiet. Quiet itself remains delivery suppression.

## Interaction with Suhoor and fasting

- If Quiet is selected from Suhoor, the Suhoor fasting intention should be preserved where valid.
- Quiet suppresses wake delivery; it does not erase `fastingDayPlanned` unless the user explicitly changes the Suhoor/fasting plan through the appropriate planning surface.
- If the user already tapped `I’m awake for Suhoor`, Quiet must not remove `confirmedAwakeForSuhoor` or `fastingIntentConfirmed`.
- Quiet does not decide whether the user completed the fast.

## Interaction with Fajr prayer logging

- Quiet does not block a separate future/available path for `I prayed Fajr` if the user actually prayed.
- Quiet must not auto-create `confirmedMissed`.
- If the Fajr window passes while Quiet is active, the automatic status may remain `quietMorning` / `prayerUnconfirmed`, not `missed`.

## Edge cases

| Case | Required behavior |
|---|---|
| User taps Quiet repeatedly | One quiet record; no duplicate delivery cancellations beyond idempotent reconciliation. |
| User switches Fajr → Quiet → Fajr | Quiet suppression removed; Fajr resolves through canonical defaults/overrides. |
| User switches Suhoor → Quiet → Suhoor | Quiet suppression removed; preserved Suhoor intention returns where valid. |
| User taps Quiet during active wake checks | Confirmation sheet required before cancellation. |
| User confirms Quiet after already confirming awake | Keep awake confirmation record; cancel remaining delivery only. |
| Permission denied while Fajr active | Show permission/reliability state, not Quiet. |
| Alarm missing because stale delivery was cleared | Show delivery/reconciliation warning, not Quiet. |
| Fajr data unavailable | Show unavailable/missing-data state, not Quiet. |
| Future date set to Quiet | Store as a date/anchor-specific suppression only within the supported planning policy. |

## Acceptance criteria

1. Given Fajr is active, when the user selects Quiet and confirms if required, then Subh cancels that morning’s active wake deliveries and logs `quietMorning` without marking Fajr missed.
2. Given Suhoor is active, when the user selects Quiet, then Subh preserves the Suhoor intention for restoration where valid.
3. Given an active Wake Session has pending wake checks, when the user taps Quiet, then the confirmation sheet appears before cancellation.
4. Given permission or platform delivery fails, then Subh does not display Quiet unless the user explicitly selected Quiet.
5. Given the user exits Quiet, then the canonical resolver restores the selected Fajr or Suhoor state through the same mutation/resolution pipeline used by other mode changes.
