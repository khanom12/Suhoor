# Subh Active Specification Index v6 — June 1 CTA, Logging, Early-Awake, and Wake-Check Display Reconciliation

| Field | Value |
| --- | --- |
| Canonical filename | `00-subh-spec-index-v6.md` |
| Version | 6 |
| Spec status | Active index and source-of-truth map |
| Date | 2026-06-01 |
| Owning domain / surface | Entire active Subh spec library |

## 1. Purpose

This index defines the active implementation-facing specification set after the June 1 CTA/logging reconciliation.

This pass updates the May 31 morning-state specification set with the newer CTA, logging, early-awake, wake-check display, fast-completion, historical logging, and future Qada-candidate decisions.

The core changes are deliberately scoped:

- active wake CTAs live in the Hero;
- logging and early-awake actions live in the context-card action area;
- **I’m Awake for Fajr** and **I Prayed Fajr** are sequential, never simultaneous;
- ordinary system/AlarmKit dismissal does not equal wake acknowledgement;
- the Hero primary time advances to the next pending wake-check time after each non-awake dismissal;
- early-awake actions require confirmation and have different Suhoor/Fajr delivery consequences;
- fast completion appears after Maghrib when Suhoor was selected, and every Ramadan day;
- late Fajr and fast completion use compact check/X prompts with ✓, ✕, and unrecorded states;
- explicit Fajr ✕ and Ramadan fast ✕ feed future Qada-candidate foundations;
- post-Suhoor Fajr behaviour is represented through the Hero/Fajr slider, not through a separate **Set Fajr Wake Alarm** CTA.

## 2. Canonical source hierarchy

When specs conflict, use this precedence:

1. `subh-cta-logging-and-wake-action-spec-v2.md` for CTA/logging/early-awake/wake-check-display details.
2. `subh-morning-resolution-contract-state-ownership-spec-v6.md` for resolved state ownership and surface outputs.
3. `subh-wake-sessions-wake-checks-morning-logs-spec-v4.md` for execution/logging lifecycle.
4. `subh-alarm-delivery-schedule-reliability-spec-v6.md` for delivery/reconciliation mechanics.
5. Surface specs for presentation details.
6. Older May 31 language only where it does not conflict with June 1 decisions.

## 3. Canonical visible action vocabulary

Use these visible user-facing actions and prompts:

```text
I’m Awake for Suhoor
I’m Awake for Fajr
I’m Already Awake for Suhoor
I’m Already Awake for Fajr
I Prayed Fajr
I prayed Fajr earlier today? ✓ ✕
I prayed Fajr yesterday morning? ✓ ✕
I completed my fast today? ✓ ✕
I completed my fast yesterday? ✓ ✕
```

Do not reintroduce these as active visible CTA patterns:

```text
I’m fasting today
Set Fajr Wake Alarm
Wake me for Fajr
Stop checks
System dismissal = awake
```

## 4. Active spec map

| Spec file | Status in this package | Notes |
| --- | --- | --- |
| `00-subh-spec-index-v6.md` | Updated | Updated index and conflict hierarchy. |
| `subh-alarm-delivery-schedule-reliability-spec-v6.md` | Updated | Updated for early-awake delivery, non-awake dismissal, post-Suhoor Fajr default. |
| `subh-alarm-detail-view-screen-spec-v10.md` | Updated | Updated to mirror Home/context action rules. |
| `subh-context-spec-integrity-review-v4.md` | Updated | Updated drift traps. |
| `subh-context-tags-integration-addendum-v3.md` | Carried forward | Carried forward without material CTA/logging changes. |
| `subh-cta-logging-and-wake-action-spec-v2.md` | Updated | New canonical CTA/logging feature spec. |
| `subh-day-purpose-opportunity-resolution-spec-v4.md` | Updated | Updated fast eligibility, Fajr/fast check-X, Qada candidate logic. |
| `subh-early-worship-boundary-spec-v5.md` | Updated | Updated early-awake availability and confirmation. |
| `subh-fajr-time-calculation-determination-selection-spec-v2.md` | Carried forward | Carried forward without material CTA/logging changes. |
| `subh-month-planning-gregorian-hijri-spec-v4.md` | Carried forward | Carried forward without material CTA/logging changes. |
| `subh-morning-hero-item-spec-v18.md` | Updated | Updated Hero active CTAs and next wake-check display. |
| `subh-morning-resolution-contract-state-ownership-spec-v6.md` | Updated | Updated resolved outputs and state ownership. |
| `subh-morning-state-framework-scenario-walkthrough-spec-v2.md` | Updated | Updated scenario walkthrough addenda. |
| `subh-mvp-interaction-inventory-v7.md` | Updated | Updated interaction inventory. |
| `subh-mvp-interaction-tier-exposure-matrix-v4.md` | Updated | Updated tier exposure for current/late check-ins. |
| `subh-next-7-mornings-wake-forecast-spec-v4.md` | Carried forward | Carried forward without material CTA/logging changes. |
| `subh-planning-horizon-day-resolution-intention-anchoring-spec-v5.md` | Updated | Clarified historical logs separate from planning records. |
| `subh-pricing-entitlement-spec-v5.md` | Updated | Updated pricing/free core language for CTA/logging. |
| `subh-primary-morning-context-presentation-spec-v4.md` | Updated | Updated context-card action area. |
| `subh-quick-wake-mode-intent-mutation-contract-v5.md` | Updated | Updated mutations. |
| `subh-quiet-mode-quiet-morning-contract-spec-v4.md` | Updated | Clarified Quiet vs early-awake. |
| `subh-quiet-pause-hero-wake-flow-alignment-spec-v4.md` | Updated | Updated cross-surface CTA alignment. |
| `subh-shared-day-tag-presentation-contract-v3.md` | Carried forward | Carried forward without material CTA/logging changes. |
| `subh-sound-alarm-settings-spec-v3.md` | Updated | Updated Fajr adhan/event delivery distinctions. |
| `subh-wake-session-testing-and-simulation-harness-spec-v6.md` | Updated | Updated testing scenarios. |
| `subh-wake-sessions-wake-checks-morning-logs-spec-v4.md` | Updated | Updated wake/log lifecycle. |
| `subh-weekly-fajrcast-card-spec-v15.md` | Carried forward | Carried forward without material CTA/logging changes. |


## 5. Implementation acceptance checks

Codex/implementation must verify:

1. no root active spec instructs ordinary system dismissal to count as awake success;
2. no active wake flow requires a separate **Set Fajr Wake Alarm** CTA after Suhoor;
3. no active Hero state shows **I’m Awake for Fajr** and **I Prayed Fajr** simultaneously;
4. the Hero displays the next pending wake-check time after non-awake dismissal;
5. early-awake confirmation for Suhoor keeps the Fajr-beginning adhan/event;
6. early-awake confirmation for Fajr silences the Fajr adhan/alarm/checks;
7. late Fajr and fast completion prompts distinguish ✓, ✕, and unrecorded;
8. explicit ✕ creates Qada relevance only where specified;
9. expired unresolved prompts do not create Qada candidates.
