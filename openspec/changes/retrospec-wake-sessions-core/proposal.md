## Why

The wake-session implementation was completed directly from the cleaned canonical product specs rather than through a pre-existing OpenSpec change. This retrospec records the implemented contract so future work keeps Wake Sessions, Wake Checks, immediate MorningLogs, Quiet Morning, and current-morning check-ins in the same free/core Fajr-centered morning engine.

## What Changes

- Add a core wake-session execution lifecycle for one target morning, including scheduled, active, fired/unconfirmed, confirmed, expired, cancelled, and quiet outcomes.
- Add deterministic core Wake Checks: primary wake plus up to five 5-minute follow-up wake attempts, bounded by the relevant Fajr cutoff and active scheduled horizon.
- Add local MorningLog operational records for current-morning execution without introducing paid history, analytics, export, cloud sync, Qada ledger, or historical editing UI.
- Separate awake confirmation, Fajr prayer confirmation, fasting intent, and fast completion. Alarm stop/dismissal remains operational only and does not confirm awake.
- Add current/current-morning hero check-ins for `I'm awake for Fajr`, `I'm awake for Suhoor`, and `I prayed Fajr`.
- Add intentional Quiet active-session cancellation with a confirmation dialog, cancellation of remaining wake-session events, and `quietMorning` logging without missed-prayer logging.
- Add a fixed Home Hero Action Slot so active-session CTAs and confirmed states do not shift the hero stack vertically.
- Keep Wake Sessions, core Wake Checks, Quiet Morning, awake confirmation, current-morning Fajr check-in, and current-day fasting intent as Free/core behavior.
- Preserve the existing one-engine morning-resolution path, existing AlarmKit/notification adapters, and existing local persistence patterns.

## Capabilities

### New Capabilities

- `wake-session-execution`: Core/free wake-session lifecycle, wake-check scheduling, current-morning confirmations, local operational MorningLogs, Quiet cancellation, and entitlement guardrails.

### Modified Capabilities

- `morning-resolution`: Clarify that wake, prayer, fasting intent, fast completion, Quiet Morning, and delivery/confirmation outcomes are separate state concepts on the same resolved morning.
- `single-screen-morning-home`: Add the fixed Hero Action Slot behavior for current-morning wake/prayer confirmations and Quiet active-session handling.

## Impact

- Affected implementation areas: `Subh/Core/Morning/WakeSessionStore.swift`, `MorningScheduleResolver`, `SchedulingIdentifierSet`, `AlarmScheduler`, `RoutineScheduler`, `ScheduleService`, `MorningHomePresentation`, `SubhHomeView`, `MorningHomeSnapshot`, `MorningHeroUIIdentifier`, `SubhEntitlement`, Home/Alarm preview wiring, and related tests.
- Local persistence adds a new `Subh.WakeSessionsAndMorningLogs` UserDefaults payload. Existing saved wake settings and legacy compatibility namespaces remain readable.
- Existing scheduled alarms are affected through normal resolver-driven reconciliation. Awake confirmation and Quiet cancellation cancel only remaining wake-session primary/wake-check events for the relevant morning.
- Native AlarmKit snooze is not used for MVP wake sessions. AlarmKit fire/stop observability remains limited to what the platform adapter can expose.
- No new production dependency, StoreKit integration, paywall, cloud sync, export, adaptive wake checks, advanced interval personalization, analytics, household/family features, or historical ledger UI is introduced.
