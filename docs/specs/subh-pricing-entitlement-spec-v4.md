# Subh Pricing and Entitlement Specification v4 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-pricing-entitlement-spec-v4.md` |
| Version | 4 |
| Spec status | Active pricing and entitlement doctrine |
| Date | 2026-05-30 |
| Related specs | Tier Matrix, Interaction Inventory, Hero, Quiet/Pause, Wake Sessions, Next 7 |
| Owning domain / surface | Pricing, paywall seams, and entitlement principles |

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

Pricing must support adoption and trust without weakening the core wake utility.

The app’s basic promise is that Subh helps the user wake for Fajr/Suhoor and manage mornings safely. That basic promise must not be paywalled.

## 2. Free/core principle

Free includes the operational morning loop:

```text
understand next morning
select Fajr/Suhoor
set a basic alarm
Quiet one morning
Pause/resume Subh wake alarms
ring one morning while paused
receive the wake alarm
receive basic follow-ups/Wake Checks
acknowledge I’m awake
log I’m fasting today
log I prayed Fajr
see Next 7 Mornings
use Day Detail for basic edits
```

## 3. Plus principle

Plus is appropriate for value beyond core operation:

```text
long-term memory
history and trends
advanced analytics
behavior-shaping insights
exports/sync
advanced customization
accountability/household features
premium seasonal intelligence
```

Plus must not hold the user hostage during a morning wake flow.

## 4. No-paywall controls

Do not paywall:

- Quiet;
- Pause/resume;
- ring-once while paused;
- wake acknowledgement;
- current-morning Fajr/fasting log CTAs;
- safety/setup troubleshooting needed to make alarms work;
- basic Wake Sessions and Wake Checks;
- active alarm dismissal/acknowledgement.

## 5. Copy/tier naming

Pricing copy should not describe Fajr, Suhoor, Quiet, and Pause as parallel modes.

Use:

```text
Fajr and Suhoor wake planning
Quiet mornings
Alarms paused
Wake Sessions
Wake Checks
```

Avoid:

```text
Quiet mode
Pause mode
Fasting mode
Pre-Fajr mode
```

## 6. Acceptance criteria

1. Core alarm utility is usable without Plus.
2. Quiet/Pause are Free.
3. Current-morning acknowledgement/logging is Free.
4. Plus surfaces appear around insight/history/customization, not during urgent wake execution.
5. Pricing language matches the reconciled vocabulary.
