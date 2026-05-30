# Subh MVP Interaction Tier Exposure Matrix v3 — May 30 Reconciled

| Field | Value |
| --- | --- |
| Canonical filename | `subh-mvp-interaction-tier-exposure-matrix-v3.md` |
| Version | 3 |
| Spec status | Active Free/Plus interaction exposure matrix |
| Date | 2026-05-30 |
| Related specs | Pricing, Interaction Inventory, Hero, Quiet/Pause, Wake Sessions |
| Owning domain / surface | Tier exposure for MVP interactions |

## May 30, 2026 reconciliation status

This active spec has been reconciled against the finalized Quiet / Pause / Hero / Wake Flow direction. It is implementation-facing. Older wording preserved in `Archive/originals-before-may30-reconciliation/` is historical only and must not be implemented when it conflicts with this active file.

Canonical MVP doctrine used across the active spec set:

```text
Wake purpose: Fajr | Suhoor
Alarm state: active | quiet | paused | rings-once | blocked | issue
Execution state: not started | ringing | follow-up pending | awake acknowledged | fasting logged | Fajr logged | ended/no response | issue
```

Quiet and Pause are not wake purposes. `Suhoor` is the only exposed MVP before-Fajr wake purpose and is fasting/suhoor-oriented. Generic non-fasting `Pre-Fajr`, `Early`, `Tahajjud only`, and `Other early worship` flows are deferred unless a later approved spec explicitly reintroduces them.


## 1. Pricing doctrine

Do not paywall basic wake safety, alarm control, acknowledgement, or current-morning logging.

MVP core utility remains Free. Plus is for history, insights, advanced analytics, exports/sync, accountability, and durable memory beyond basic operation.

## 2. Free/core interactions

| Interaction | Tier |
| --- | --- |
| Select Fajr/Suhoor for current/next morning | Free |
| Adjust current/next alarm time | Free |
| Set/Clear Quiet for a morning | Free |
| Pause Subh wake alarms indefinitely | Free |
| Resume alarms | Free |
| Ring tomorrow/this morning only while paused | Free |
| Wake Session primary alarm | Free |
| Wake Checks/follow-up alarms within default MVP limits | Free |
| `I’m awake` acknowledgement | Free |
| System dismissal acknowledgement | Free |
| `I’m fasting today` current-morning log | Free |
| `I prayed Fajr` current-morning log | Free |
| Next 7 Mornings display | Free |
| Day Detail basic editing | Free |
| Basic delivery/setup troubleshooting | Free |

## 3. Plus/future candidates

| Capability | Tier direction |
| --- | --- |
| Long-term history and trend analytics | Plus |
| Advanced behavioral insights | Plus |
| Detailed wake reliability analytics | Plus |
| Export/sync/history backups | Plus/future |
| Accountability/household/social features | Plus/future, subject to separate spec |
| Advanced custom follow-up patterns beyond MVP defaults | Plus/future if product-approved |
| Durable multi-month planning intelligence | Plus/future if beyond basic planning |

## 4. Acceptance criteria

1. Quiet, Pause, ring-once, acknowledgement, and current-morning logs are Free.
2. Wake Session and basic Wake Checks are Free.
3. Next 7 remains Free.
4. Plus does not block the core alarm experience.
5. Tier labels do not reintroduce Quiet/Pause as wake purposes.
