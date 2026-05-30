# Subh Fajr Time Calculation, Determination, and Selection Specification v2 — May 30 Reviewed

| Field | Value |
| --- | --- |
| Canonical filename | `subh-fajr-time-calculation-determination-selection-spec-v2.md` |
| Version | 2 |
| Spec status | Active timing specification; reviewed for Quiet/Pause reconciliation |
| Date | 2026-05-30 |
| Related specs | Index, Suhoor Boundary, Morning Resolution, Alarm Delivery, Hero |
| Owning domain / surface | Fajr prayer-time calculation and time-source selection |

## 1. Reconciliation status

This spec does not own Quiet, Pause, wake-purpose mutation, pricing, or wake-session behavior. It remains the timing source for Fajr begins/Fajr ends and related calculations consumed by the reconciled specs.

## 2. Required outputs for reconciled MVP

Timing resolution must provide, where available:

```text
morningDate
location/timeZone
fajrBegins
fajrEnds / sunrise-equivalent end of Fajr window
maghrib/sunset for the previous evening
calculation method / source
high-latitude or fallback indicators
estimated/uncertain flags
```

## 3. Relationship to other specs

- Fajr purpose uses the Fajr-begins-to-Fajr-ends window.
- Suhoor purpose uses the before-Fajr window and may use final-third calculations from Maghrib/sunset to Fajr begins.
- Alarm Delivery uses resolved times but must not decide purpose or Quiet/Pause.
- Missing or uncertain timing should produce setup/unavailable/issue states, not Quiet.

## 4. Acceptance criteria

1. Fajr timing outputs are stable and reusable by Morning Resolution.
2. Missing timing does not become Quiet/Pause.
3. Timing uncertainty is exposed as timing/setup/reliability information where needed.
4. This spec remains independent from wake-purpose and alarm-state mutation.
