# Subh Wake Session + Pricing v3 Alignment Bundle

This bundle updates the prior Wake Session alignment package so the active pricing spec is now `subh-pricing-entitlement-spec-v3.md`, not v2.

## Main pricing alignment

`subh-pricing-entitlement-spec-v3.md` is treated as the canonical pricing base because it replaces the earlier multi-tier model with:

```text
Free
Plus
```

The alignment preserves that strategy and clarifies the Wake Session boundary:

```text
Free = complete core wake/planning utility
Plus = durable practice memory, history, insights, ledgers, summaries, export, and accountability
```

## Files included

- `00-subh-spec-index-v3.md`
- `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`
- `subh-quiet-mode-quiet-morning-contract-spec-v1.md`
- `subh-sound-alarm-settings-spec-v1.md`
- `subh-morning-resolution-contract-state-ownership-spec-v3.md`
- `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`
- `subh-alarm-delivery-schedule-reliability-spec-v3.md`
- `subh-morning-hero-item-spec-v15.md`
- `subh-mvp-interaction-inventory-v4.md`
- `subh-pricing-entitlement-spec-v3.md`
- `pricing_v3_wake_session_alignment.diff`

## What changed in pricing v3

The updated pricing spec now explicitly states that these are Free/core when used in the active morning loop:

- Wake Sessions
- core Wake Checks
- awake confirmation
- wake-check cancellation after awake confirmation
- current-morning `I prayed Fajr` check-in when shown
- current-day fasting-intent check-in when shown
- Quiet Morning suppression
- core ramped alarm sound behavior

Plus remains the owner of:

- durable Fajr prayer history
- durable fast history
- Ramadan history and summaries
- Qada ledgers
- historical editing
- trends, summaries, streaks, analytics
- export/sync if implemented as paid
- advanced individual accountability

## Review guidance

Review `pricing_v3_wake_session_alignment.diff` before replacing the repository pricing spec. The changes are intentionally targeted and should not remove unrelated pricing details.
