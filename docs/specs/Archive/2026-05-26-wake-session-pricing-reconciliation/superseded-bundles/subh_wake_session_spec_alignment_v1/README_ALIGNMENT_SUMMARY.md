# Subh Wake Session Spec Alignment Bundle — Change Summary

## Files updated by targeted addenda only

- `subh-morning-hero-item-spec-v15.md`
- `subh-morning-resolution-contract-state-ownership-spec-v3.md`
- `subh-alarm-delivery-schedule-reliability-spec-v3.md`
- `subh-mvp-interaction-inventory-v4.md`
- `subh-planning-horizon-day-resolution-intention-anchoring-spec-v3.md`
- `subh-pricing-entitlement-spec-v2.md`
- `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`

## New specs created

- `00-subh-spec-index-v3.md`
- `subh-quiet-mode-quiet-morning-contract-spec-v1.md`
- `subh-sound-alarm-settings-spec-v1.md`

## Preservation rules followed

- Existing body sections were not rewritten.
- Existing scenario IDs were not removed or renumbered.
- New behavior was added through explicit addenda.
- Missing ownership gaps were filled with new specs rather than spreading full rules across unrelated docs.
- Conflicts are handled by targeted superseding addenda rather than deleting older historical examples.

## Main alignment decisions

- Wake Sessions, Wake Checks, and basic immediate MorningLogs are core/free MVP behavior.
- Long-term insights, adaptive wake support, advanced intervals/counts, and analytics remain future/paid.
- Quiet Mode means intentional suppression, not missed prayer and not delivery failure.
- Sound ramping is owned by audio assets/waveforms, not a promised runtime volume-ramp control.
- The Hero uses a fixed Hero Action Slot to avoid vertical layout jumping.
- Stop/dismiss from Lock Screen does not confirm awake.
- `I’m awake for Fajr`, `I’m awake for Suhoor`, `I prayed Fajr`, and future fast-completion records remain separate outcomes.
