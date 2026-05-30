# Subh MVP Interaction Tier Exposure Matrix

| Field | Value |
| --- | --- |
| Canonical filename | `subh-mvp-interaction-tier-exposure-matrix-v2.md` |
| Version | 2 |
| Spec status | Draft; reconciled companion overlay for MVP interaction inventory and Pricing v3 |
| Date | 2026-05-26 |
| Supersedes | `subh-mvp-interaction-tier-exposure-matrix-v1.md` |
| Related specs | `00-subh-spec-index-v3.md`, `subh-mvp-interaction-inventory-v4.md`, `subh-pricing-entitlement-spec-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`, `subh-quick-wake-mode-intent-mutation-contract-v2.md`, `subh-day-purpose-opportunity-resolution-spec-v1.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md`, `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`, `subh-quiet-mode-quiet-morning-contract-spec-v1.md`, `subh-sound-alarm-settings-spec-v1.md`, `subh-morning-hero-item-spec-v15.md`, `subh-alarm-detail-view-screen-spec-v7.md`, `subh-next-7-mornings-wake-forecast-spec-v2.md`, `subh-weekly-fajrcast-card-spec-v14.md` |
| Owning domain / surface | Free / Plus exposure overlay for MVP interaction scenarios, paywall entry points, downgrade/upgrade interaction traceability |
| Implementation audit status | Needs implementation audit |



## May 29 Tier Exposure Alignment Addendum

Quiet, indefinite Pause, one-off ringing while paused, wake acknowledgement, current-morning fasting status, and current-morning Fajr prayer logging are Free/core utility.

Paid tiers may expose advanced history, insights, summaries, recurring planning, or accountability around these events, but not the basic controls themselves.

Use `Quiet`, `Alarms paused`, and `Rings once` in user-facing scenario labels. Avoid `Quiet mode`, `Pause mode`, and `Wake checks active` as visible product labels.

## Purpose

Map the stable MVP scenario IDs from `subh-mvp-interaction-inventory-v4.md` onto the active Pricing v3 model.

This document replaces the archived multi-tier exposure matrix. The archived v1 matrix is preserved in `Archive/2026-05-26-wake-session-pricing-reconciliation/superseded-root-specs/` for audit history.

## Pricing Model

The active MVP pricing model is:

```text
Free
Plus
```

Free is the complete core Fajr-centered morning utility.

Plus is the durable memory, history, insight, ledger, export/sync, and advanced accountability layer.

Archived multi-tier pricing concepts from v1 are not active MVP tiers and must not be used for new gating decisions.

## Source Alignment

1. Subh has one morning-resolution engine.
2. The active MVP wake-purpose selector is `Fajr | Suhoor`; Quiet is an alarm-state override, not a quick mode.
3. Suhoor, Fajr, Quiet, wake adjustment, Wake Sessions, core Wake Checks, immediate awake confirmations, current-morning prayer check-ins, current-day fasting-intent check-ins, Next 7 Mornings, Weekly Fajrcast, and core planning controls are Free/core utility.
4. Plus owns durable history, historical editing, analytics, Qada ledgers, summaries, streaks/trends, export/sync, and advanced accountability.
5. Pricing must not create separate Free and Plus morning engines.
6. Pricing must not weaken alarm reliability, hide degraded states, or make permission/reliability recovery paid-only.
7. Pricing must not convert opportunity into intention, awake confirmation into prayer completion, or Quiet into missed prayer.

## Exposure Vocabulary

| Term | Meaning |
| --- | --- |
| `Free/core` | Available to all users as part of the core morning system. |
| `Plus` | Requires active Plus access unless a future promotion explicitly grants temporary access. |
| `Read-only preserved` | Previously created Plus-layer data remains visible in limited form after downgrade, but editing/export/analytics actions may be locked. |
| `Preview` | A Free user may see enough context to understand the paid layer without mutating paid-only history or analytics. |
| `Future/deferred` | Not active MVP pricing scope; requires a later spec. |

## Group Exposure Matrix

| Group | Scenario range | Area | Free exposure | Plus exposure | Notes |
| --- | ---: | --- | --- | --- | --- |
| A | S001-S020 | First launch and onboarding | Free/core | Same | Setup, location, prayer method, and reliability onboarding are never paywalled. |
| B | S021-S027 | Home arrival and hero viewing | Free/core | Same | Hero, immediate plan clarity, and current morning state are core utility. |
| C | S028-S034 | Home hero: Fajr mode | Free/core | Same | Fajr wake planning and adjustment are Free. |
| D | S035-S045 | Home hero: Suhoor mode and intention | Free/core | Same | Suhoor is the only exposed before-Fajr MVP wake purpose and is Free. |
| E | S046-S055 | Suhoor fasting behavior | Free/core for active planning and current-day intent | Durable fast history and analytics are Plus | Planning a fast and confirming current-day intent are not paid-only. |
| F | S056-S062 | Quiet mode | Free/core | Quiet patterns may appear in Plus insights | Quiet is intentional suppression, not a paid feature or failure state. |
| G | S063-S070 | Wake-time adjustment | Free/core | Same | Core wake control remains Free for supported modes/horizons. |
| H | S071-S073 | Adhan / sound exposure | Free/core for supported sound settings and reliability | Future premium sound libraries require a later spec | Ramped wake behavior is an audio-asset policy, not a paid runtime volume promise. |
| I | S074-S080 | Next 7 Mornings forecast | Free/core | Plus may enrich with history overlays only if later scoped | Forecast display/editing remains Free and does not schedule every visible day. |
| J | S081-S088 | Day Detail entry and viewing | Free/core | Historical context overlays may be Plus | Detail must not become the only way to access core wake controls. |
| K | S089-S109 | Day Detail editing | Free/core for current/future wake planning | Historical editing is Plus | Immediate Day Detail wake edits save through the shared mutation contract. |
| L | S110-S115 | Browse by Month entry | Free/core if implemented | Plus may add historical overlays | Month planning is still one morning engine, not a paid wake engine. |
| M | S116-S122 | Gregorian month browsing | Free/core if implemented | Plus may add history/summary layers | Future planning records remain separate from active scheduled horizon. |
| N | S123-S129 | Hijri month browsing | Free/core if implemented | Plus may add history/summary layers | Hijri correctness and planning clarity are not paid-only. |
| O | S130-S134 | Monthly Fajrcast | Free/core if implemented as planning context | Plus may add historical trend interpretation | Exact scope remains owned by the month-planning and Fajrcast specs. |
| P | S135-S143 | Monthly day list and future edits | Free/core for future wake planning | Plus for historical editing/analytics | Future edits hydrate later through the resolver. |
| Q | S144-S154 | Adjusted Days repository | Free/core for active/future planning overrides | Plus for historical review and bulk insight layers | Preserve source-of-truth separation for overrides. |
| R | S155-S159 | Weekly Fajrcast | Free/core | Plus may add trend interpretation over history | Weekly Fajrcast is not a paid-only surface. |
| S | S160-S167 | Settings entry and visible sections | Free/core | Plus settings only for paid-layer features | Settings correctness, privacy, and reliability surfaces are universal. |
| T | S168-S175 | Location settings | Free/core | Same | Location correctness is never paywalled. |
| U | S176-S182 | Prayer time settings | Free/core | Same | Calculation choices must remain visible and auditable. |
| V | S183-S189 | Hijri calendar settings | Free/core | Same unless a paid history layer uses additional controls | Calendar correctness is not a paid entitlement. |
| W | S190-S199 | Recurring boundary rules / presets | Free/core if implemented for wake planning | Advanced automation can be Plus only with a future spec | Do not invent paid automation scope in implementation. |
| X | S200-S204 | About and feedback | Free/core | Same | Universal, no entitlement gating. |
| Y | S205-S211 | Permissions after onboarding | Free/core | Same | Reliability warnings and recovery are never paywalled. |
| Z | S212-S219 | Alarm execution and post-alarm behavior | Free/core | Plus can expose accumulated execution history | Wake Sessions, wake checks, and awake confirmation are Free/core. |
| AA | S220-S225 | Cross-surface consistency | Free/core | Same | Same resolver and state graph across entitlements. |
| AB | S226-S235 | Rapid and repeated interactions | Free/core for exposed controls | Plus-specific controls need the same idempotency guarantees | Locked/preview paid-layer actions must not corrupt core morning state. |

## Plus-Owned Interaction Families

Plus may own or gate these interaction families when implemented:

- durable Fajr prayer history;
- durable fast history;
- Ramadan history and summaries;
- Qada ledgers;
- historical editing;
- summaries, trends, streaks, and analytics;
- export, sync, or backup if implemented as paid;
- advanced accountability;
- adaptive support if a later spec explicitly scopes it as paid.

Plus must not gate these active-morning actions:

- Fajr mode;
- Suhoor mode;
- Quiet mode;
- wake-time adjustment;
- Wake Sessions;
- core Wake Checks;
- awake confirmation;
- current-morning `I prayed Fajr` check-in when shown;
- current-day `I’m fasting today` intent check-in when shown;
- Next 7 Mornings;
- Weekly Fajrcast;
- reliability warnings and recovery.

## Paywall Routing

Do not show a paywall when the user is trying to complete the active morning loop.

A Plus paywall may appear when the user opens or attempts to mutate a durable paid-layer surface:

| Trigger | Expected routing |
| --- | --- |
| Open full Fajr history from Free | Plus paywall or locked preview. |
| Open full fast history from Free | Plus paywall or locked preview. |
| Open Qada ledger from Free | Plus paywall or read-only preserved summary. |
| Edit historical prayer/fast records from Free | Plus paywall unless a later free-lite rule exists. |
| Export/sync records from Free | Plus paywall if export/sync is paid. |
| Open advanced accountability from Free | Plus paywall. |
| Confirm awake, pray, fast intent, or Quiet in the current morning | No paywall. |

## Downgrade and Preservation

When Plus expires or downgrades to Free:

1. Core wake planning and Wake Sessions continue.
2. Active scheduled wake alarms remain eligible if resolver-supported and permission-allowed.
3. Plus-layer histories, summaries, ledgers, and exports become locked, read-only, or previewed according to their owner specs.
4. No user-created Plus-layer data is deleted because entitlement changed.
5. Paid-only reminders, exports, sync jobs, or accountability prompts are cancelled or suppressed if they are no longer entitlement-supported.

## Archived V1 Treatment

The prior matrix used a multi-tier model and hardcoded working prices. It is archived as historical material only. Its scenario group structure remains useful for audit context, but its pricing gates are superseded by this v2 matrix and `subh-pricing-entitlement-spec-v3.md`.

## Acceptance Checklist

- [ ] Free + Plus are the only active MVP pricing tiers.
- [ ] No core wake-planning, Wake Session, wake-check, confirmation, Quiet, Next 7 Mornings, or Weekly Fajrcast interaction is paid-only.
- [ ] Plus gates durable history, historical editing, Qada ledgers, summaries, export/sync, analytics, and advanced accountability.
- [ ] Downgrade preserves user data and cancels only unsupported paid-layer scheduled work.
- [ ] Pricing does not create a second morning engine.
