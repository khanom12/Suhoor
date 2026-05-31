# Subh Spec Release Manifest — 2026-05-31

| Field | Value |
| --- | --- |
| Release date | 2026-05-31 |
| Release purpose | May 31 Morning State Framework controlled spec-alignment pass |
| Source scenario | Toronto live app walkthrough on May 31, 2026 after ~10:30 AM and around 12:19 PM |
| Status | Active implementation-facing specification package |
| Primary index | `00-subh-spec-index-v5.md` |
| Primary scenario source | `subh-morning-state-framework-scenario-walkthrough-spec-v1.md` |
| Archive folder | `Archive/may30-pre-may31-scenario-update/` |

## 1. Release intent

This release updates the May 30 reconciled Subh specification set using the May 31 Morning State Framework discussion. It is a controlled alignment pass, not a broad redesign.

The update focuses on:

- Home Hero labels, alarm icon affordance, Quiet confirmation, and live slider feedback;
- sentence-based context card behaviour;
- Next 7 Mornings row layout and per-row Quiet toggle;
- Suhoor/Fajr switching, last-third Suhoor window, and cutoff rules;
- wake-session generation, compression, and boundary rules;
- Suhoor acknowledgement, single Fajr-start event, and optional Fajr follow-up;
- Fajr wake acknowledgement vs prayer completion separation;
- late Fajr logging below the context card after hero rollover;
- testing harness support for 24/48-hour scrubbing, boundary presets, and action-branching.

The release intentionally preserves unrelated May 30 decisions, including MVP indefinite Pause doctrine, pricing/entitlement, sound settings, Fajr calculation methods, Weekly Fajrcast, and Month Planning except for a narrow cross-reference alignment.

## 2. Active files promoted in this release

| Active file | Version | Release status |
| --- | ---: | --- |
| `00-subh-spec-index-v5.md` | 5 | Updated |
| `subh-morning-state-framework-scenario-walkthrough-spec-v1.md` | 1 | New source document |
| `subh-quiet-pause-hero-wake-flow-alignment-spec-v3.md` | 3 | Updated |
| `subh-morning-resolution-contract-state-ownership-spec-v5.md` | 5 | Updated |
| `subh-quick-wake-mode-intent-mutation-contract-v4.md` | 4 | Updated |
| `subh-morning-hero-item-spec-v17.md` | 17 | Updated |
| `subh-alarm-detail-view-screen-spec-v9.md` | 9 | Updated |
| `subh-quiet-mode-quiet-morning-contract-spec-v3.md` | 3 | Updated |
| `subh-wake-sessions-wake-checks-morning-logs-spec-v3.md` | 3 | Updated |
| `subh-alarm-delivery-schedule-reliability-spec-v5.md` | 5 | Updated |
| `subh-next-7-mornings-wake-forecast-spec-v4.md` | 4 | Updated |
| `subh-month-planning-gregorian-hijri-spec-v4.md` | 4 | Cross-reference aligned only |
| `subh-weekly-fajrcast-card-spec-v15.md` | 15 | Carried forward unchanged |
| `subh-shared-day-tag-presentation-contract-v3.md` | 3 | Updated |
| `subh-day-purpose-opportunity-resolution-spec-v3.md` | 3 | Updated |
| `subh-early-worship-boundary-spec-v4.md` | 4 | Updated |
| `subh-planning-horizon-day-resolution-intention-anchoring-spec-v4.md` | 4 | Carried forward unchanged |
| `subh-primary-morning-context-presentation-spec-v3.md` | 3 | Updated |
| `subh-context-tags-integration-addendum-v3.md` | 3 | Updated |
| `subh-context-spec-integrity-review-v3.md` | 3 | Updated |
| `subh-sound-alarm-settings-spec-v2.md` | 2 | Carried forward unchanged |
| `subh-fajr-time-calculation-determination-selection-spec-v2.md` | 2 | Carried forward unchanged |
| `subh-mvp-interaction-inventory-v6.md` | 6 | Updated |
| `subh-mvp-interaction-tier-exposure-matrix-v3.md` | 3 | Carried forward unchanged |
| `subh-pricing-entitlement-spec-v4.md` | 4 | Carried forward unchanged |
| `subh-wake-session-testing-and-simulation-harness-spec-v5.md` | 5 | Updated |

## 3. Archived files

The previous May 30 active versions for all materially updated files have been copied to:

```text
Archive/may30-pre-may31-scenario-update/
```

Archived files are traceability records only. They must not be implemented when they conflict with the active root files.

The prior release manifest `subh-spec-release-manifest-2026-05-30.md` is also archived there.

## 4. Confirmed May 31 behavioural rules

1. The visible purpose selector order is `Suhoor | Fajr`.
2. Quiet and Pause are not wake purposes.
3. Hero Slot 2 uses `Today Morning` / `Tomorrow Morning` in title case.
4. Hero Slot 3 remains minimal: alarm icon + wake time, or a primary alarm-state value such as `Quiet` / `Alarms paused`.
5. The alarm icon/wake-time control must look tappable and opens deliberate Quiet confirmation.
6. Quiet confirmation copy is approved: `Make Tomorrow Morning Quiet?` / `Make Today Morning Quiet?`; body: `No alarm or wake checks will ring. Use this only if you do not need Subh to wake you.`; actions: `Keep Alarm On` / `Make Quiet`.
7. The context card uses sentence-based explanatory copy, not tag chips.
8. Next 7 Mornings row layout is left = wake time or `Quiet` with date below, middle = `Awake for Fajr/Suhoor` with specific opportunity tags, right = Quiet toggle.
9. Opportunity tags must be specific, not generic `Fasting Opportunity` tags.
10. Suhoor window begins at the last third of the night, calculated per day.
11. Wake checks run at 5-minute intervals and never at the exact relevant-window end.
12. Latest wake time is relevant window end minus 5 minutes.
13. Latest new session creation is relevant window end minus 6 minutes.
14. `I’m Awake for Fajr` does not log Fajr prayer completion.
15. `I Prayed Fajr` logs Fajr prayer completion separately.
16. After Suhoor acknowledgement, Subh does not automatically create full Fajr wake checks; it may issue a single Fajr-start event unless the user intentionally opts into Fajr follow-up.
17. Late Fajr logging appears below the context card after hero rollover, not inside the Hero.
18. Late prompt copy is `I Prayed Fajr Earlier Today` before midnight and `I Prayed Fajr Yesterday Morning` after midnight while eligible.
19. Testing must support 24-hour, preferably 48-hour, simulation with minute scrubbing, boundary presets, and action-branching.

## 5. Known backlog / future simulation items

The following remain explicit future simulation or design-hardening items, not fully resolved implementation changes in this pass:

- daylight savings spring-forward and fall-back mornings;
- high-latitude abnormal or missing Fajr conditions;
- Ramadan defaults and transition days;
- Eid / fasting-unavailable contexts;
- travel, timezone, and location-change edge cases;
- prayer-time calculation method changes;
- deeper indefinite Pause copy and visuals beyond preserving May 30 doctrine.

## 6. Implementation caution

Codex and future implementers must not treat this release as permission to redesign unrelated surfaces. Changes must trace to the May 31 working document, this release manifest, the active index, or the specific updated domain specs.
