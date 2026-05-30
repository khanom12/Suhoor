# Subh Quiet Morning and Pause Wake Alarms Contract Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-quiet-mode-quiet-morning-contract-spec-v1.md` |
| Version | 1 + May 29 alignment addendum |
| Spec status | Canonical working spec updated for Quiet Morning + indefinite Pause ownership |
| Related specs | `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`, `subh-morning-hero-item-spec-v15.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`, `subh-mvp-interaction-inventory-v4.md` |
| Owning domain / surface | Quiet Morning, indefinite Pause, alarm suppression, restore behavior, one-off ring exception |
| Implementation audit status | Needs implementation audit |



## May 29 Quiet / Pause Contract Alignment Addendum

This May 29 alignment is normative for MVP and supersedes conflicting lower/historical wording in this file.

- `Fajr` and `Suhoor` are the only exposed MVP wake purposes.
- `Quiet` is a one-morning alarm/sound override, not a wake purpose.
- `Pause` is an indefinite app-wide wake-alarm policy, not a wake purpose.
- User-facing MVP copy must not expose `Pre-Fajr`, `Early`, `Fast mode`, `Fasting mode`, `Quiet mode`, or `Pause mode` as visible wake purposes.
- Internal/code terms may remain where required for compatibility, but visible surfaces must use `Fajr`, `Suhoor`, `Quiet`, `Alarms paused`, `Time to wake`, `I’m awake`, `I’m fasting today`, and `I prayed Fajr` according to `subh-quiet-pause-hero-wake-flow-alignment-spec-v1.md`.

This file now owns both Quiet Morning and indefinite Pause behavior for MVP. Where older lower sections say `Quiet Mode`, read that as historical wording for `Quiet` unless the section is explicitly discussing compatibility.

### Quiet

`Quiet` is a one-morning alarm/sound override:

```text
Quiet = Subh will not ring for this specific morning.
```

Quiet preserves the selected `Fajr`/`Suhoor` purpose and both purpose-specific alarm configurations. Quiet is available before the first alarm begins. After the alarm begins, Quiet is no longer available for that wake; the user-facing action is `[ I’m awake ]`.

### Pause

`Alarms paused` is an indefinite app-wide wake-alarm policy:

```text
Pause = Subh wake alarms stay off until the user resumes them.
```

MVP Pause is indefinite only. Do not expose date-range pause, pause-until-date, recurring pause, or reason pickers.

### Date override and global policy model

```text
DateAlarmOverride: none | quiet | ringDespitePause
GlobalWakeAlarmPolicy: active | pausedIndefinitely
ResolvedAlarmState: active | quiet | pausedInherited | ringsOnceDespitePause | blocked | issue
```

Precedence:

1. Setup/blocked/issue states where applicable.
2. Manual Quiet for the date.
3. Global Pause unless the date has `ringDespitePause`.
4. Active alarm for the selected Fajr/Suhoor purpose.

Manual Quiet survives global Resume. `ringDespitePause` expires after the target morning or is cleared when the user selects `Stay paused tomorrow` / `Stay paused this morning`.

### Entry points

- Quiet: Home Hero alarm-state button, Day Detail alarm-state control, Settings pause confirmation as `Quiet tomorrow instead`.
- Pause: Settings / Wake Alarms primary entry point.
- While paused: Home Hero and Day Detail may offer `Ring tomorrow only`, `Resume alarms`, and `Keep paused`.
- Next 7 and Month rows navigate to Day Detail rather than exposing direct quiet/pause toggles in MVP.

### User-facing copy

Use `Quiet`, `Alarms paused`, `Alarm saved for 5:42 AM`, `Rings tomorrow only`, and `Subh won’t ring until you resume.` Avoid `Quiet mode`, `Pause mode`, `Saved wake`, `No wake confirmed`, and `I’m awake` in visible copy.

## Purpose

Define Quiet as intentional one-morning alarm suppression and Pause as indefinite app-wide wake-alarm suppression for the Fajr-centered morning system. Quiet/Pause must not corrupt Fajr/Suhoor purpose, saved alarm settings, prayer/fasting records, delivery diagnostics, or future planning.

Quiet is not a generic failure state. It must not be used to hide permission failures, delivery failures, stale scheduling, missing data, or missed-prayer assumptions.

## What This Spec Owns

- Quiet product meaning.
- Quiet Morning state and logging semantics.
- Preservation/restoration of underlying Fajr or Suhoor state.
- Quiet behavior before alarm execution begins.
- Pause behavior and one-off ring exceptions.
- Delivery cancellation expectations when Quiet/Pause state changes.
- UI copy and confirmation requirements specific to Quiet.

## What This Spec Does Not Own

- Fajr, Fajr end, Maghrib, or final-third calculation.
- Suhoor fasting-intention taxonomy.
- Prayer or fasting completion judgment.
- AlarmKit implementation details beyond Quiet cancellation handoff.
- Menstruation, illness, travel, or exemption tracking as personal-data features.
- Long-term analytics or paid-history surfaces.

## Core principles

1. **Quiet is intentional suppression.** The user is saying “Subh should not ring for this morning.”
2. **Quiet is not failure.** Permission blocked, delivery failed, stale alarm missing, and missing prayer-time data must not render as Quiet.
3. **Quiet is not judgment.** Quiet must not automatically mean Fajr missed, fast missed, or worship skipped.
4. **Quiet preserves underlying meaning.** If the user quiets a Suhoor morning, the Suhoor/fasting intention remains available for restoration where valid.
5. **Quiet cancels delivery, not history.** It cancels pending primary/follow-up-alarm alarms for the relevant morning but does not erase previously logged awake/prayer/fasting confirmations.
6. **Quiet can be private.** The app must not require the user to give a reason.
7. **Quiet is not available after the alarm begins.** Once the first alarm begins, the user-facing action is `I’m awake`; Quiet remains a planning/silent-state decision made before execution.

## Definitions

| Term | Definition |
|---|---|
| **Quiet** | User-selected state that suppresses wake delivery for a target morning. |
| **Quiet Morning** | The logged result of Quiet being active/confirmed for a resolved morning. |
| **Underlying mode** | The Fajr or Suhoor state that existed before Quiet was applied or that would otherwise apply. |
| **Quiet overlay** | The state layer that suppresses delivery while preserving underlying morning meaning. |
| **Active Quiet selection** | User selects Quiet for the currently resolved morning. |
| **Future Quiet selection** | User selects Quiet for a future date where planning surfaces support editing. |
| **Quiet action sheet** | The action sheet used before the alarm begins to turn Quiet on/off for a target morning. |

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
- activeWakeSessionId // historical compatibility only; Quiet is not exposed after first alarm begins in MVP
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
[moon icon] Quiet
No alarm will ring for {relative day}
```

Rules:

- `Quiet` appears in the same primary wake-row slot used by the active wake time so the hero does not jump vertically.
- The relation/status line uses `No alarm will ring for {relative day}`.
- The Fajr boundary visual may remain visible as a static, non-interactive range when Fajr begin/end are available.
- The wake-adjustment handle is removed or disabled while Quiet is active.
- Quiet must not hide reliability warnings caused by permission/delivery failure; those are separate states.

### Active Wake Session confirmation

If the user selects Quiet while the current morning has pending or recently fired Wake Session alarms, show:

```text
Stop follow-up alarms for this morning?

Subh will cancel the remaining alarms and mark this morning as quiet.

[Keep follow-up alarms]
[Stop for this morning]
```

Required behavior:

- `Keep follow-up alarms` dismisses the sheet and leaves the Wake Session unchanged.
- `Stop for this morning` logs Quiet Morning and cancels remaining primary/follow-up-alarm alarms for that Wake Session.
- The sheet must not use guilt language or require explanation.

### Restoration controls

When the user exits Quiet:

- selecting Fajr removes Quiet suppression and resolves the Fajr default for that morning unless another date-specific Fajr override validly applies;
- selecting Suhoor removes Quiet suppression and restores the preserved Suhoor intention where valid;
- manual wake-time adjustment restoration follows the latest Quick Wake Mode / Wake Adjustment contract. If that contract says mode switching clears manual adjustment, Quiet must not silently restore a stale manual drag value.

## Delivery behavior

When Quiet becomes active for a morning, the delivery layer must:

1. cancel pending primary alarm identifiers for that morning;
2. cancel pending follow-up-alarm identifiers for that morning;
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
- If the user already tapped `I’m awake`, Quiet must not remove `confirmedAwakeForSuhoor` or `fastingIntentConfirmed`.
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
| User taps Quiet during active follow-up alarms | Confirmation sheet required before cancellation. |
| User confirms Quiet after already confirming awake | Keep awake acknowledgement record; cancel remaining delivery only. |
| Permission denied while Fajr active | Show permission/reliability state, not Quiet. |
| Alarm missing because stale delivery was cleared | Show delivery/reconciliation warning, not Quiet. |
| Fajr data unavailable | Show unavailable/missing-data state, not Quiet. |
| Future date set to Quiet | Store as a date/anchor-specific suppression only within the supported planning policy. |

## Acceptance criteria

1. Given Fajr is active, when the user selects Quiet and confirms if required, then Subh cancels that morning’s active wake deliveries and logs `quietMorning` without marking Fajr missed.
2. Given Suhoor is active, when the user selects Quiet, then Subh preserves the Suhoor intention for restoration where valid.
3. Given an active Wake Session has pending follow-up alarms, when the user taps Quiet, then the confirmation sheet appears before cancellation.
4. Given permission or platform delivery fails, then Subh does not display Quiet unless the user explicitly selected Quiet.
5. Given the user exits Quiet, then the canonical resolver restores the selected Fajr or Suhoor state through the same mutation/resolution pipeline used by other mode changes.
