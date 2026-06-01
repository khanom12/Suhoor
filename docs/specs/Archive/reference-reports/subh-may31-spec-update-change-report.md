# Subh May 31 Spec Update Change Report

| Field | Value |
| --- | --- |
| Update date | 2026-05-31 |
| Package | May 31 Morning State Framework spec alignment |
| Source | User-provided latest spec folder plus May 31 morning-state working document and final clarifications |
| Method | Controlled traceable update; no broad rewrite |

## 1. Integrity approach used

This pass treated the May 31 working document as the behavioural source for a narrow spec update. Existing May 30 decisions were preserved unless they directly conflicted with the May 31 decisions.

The update deliberately separated:

- wake purpose from wake delivery;
- Quiet from Pause;
- Hero minimal state from context-card explanation;
- Fajr wake acknowledgement from Fajr prayer completion;
- Suhoor wake session from Fajr-start event;
- Fajr-start event from optional Fajr follow-up wake session;
- Next 7 inline Quiet toggle from Month/Weekly non-mutating planning surfaces.

## 2. Files materially updated

| File | Key changes |
| --- | --- |
| `00-subh-spec-index-v5.md` | New active index for the May 31 release, conflict rules, active spec map, confirmed behaviour rules. |
| `subh-morning-state-framework-scenario-walkthrough-spec-v1.md` | New central source document capturing the May 31 Toronto mental simulation and cross-surface rules. |
| `subh-quiet-pause-hero-wake-flow-alignment-spec-v3.md` | Cross-spec alignment for visible selector order, Quiet confirmation, active-session cancellation edge case, wake-check rules, Fajr logging separation, and late prompt placement. |
| `subh-morning-hero-item-spec-v17.md` | Hero Row 2 label, alarm icon affordance, minimal Slot 3, Quiet confirmation, live slider feedback, post-Fajr rollover. |
| `subh-alarm-detail-view-screen-spec-v9.md` | Detail view mirrors hero rules, separates Fajr wake acknowledgement from prayer completion, includes late logging route. |
| `subh-next-7-mornings-wake-forecast-spec-v4.md` | New three-column row layout, left time/date hierarchy, middle purpose line, specific tags, right Quiet toggle. |
| `subh-primary-morning-context-presentation-spec-v3.md` | Context card changed to sentence-based explanatory copy; no context-card tag chips. |
| `subh-shared-day-tag-presentation-contract-v3.md` | Reinforces that tags are specific opportunities only; Fajr/Suhoor/Quiet/Pause are not tags. |
| `subh-context-tags-integration-addendum-v3.md` | Aligns Context Card vs Next 7 tag treatment. |
| `subh-day-purpose-opportunity-resolution-spec-v3.md` | Separates opportunity/intention/wake purpose/outcome; adds late Fajr logging credit. |
| `subh-quiet-mode-quiet-morning-contract-spec-v3.md` | Adds approved Quiet confirmation copy and active-session Quiet cancellation edge case. |
| `subh-wake-sessions-wake-checks-morning-logs-spec-v3.md` | Adds 5-minute checks, boundary-minus-5/minus-6 rules, Suhoor/Fajr handoff, optional Fajr follow-up, separate Fajr prayer logging. |
| `subh-alarm-delivery-schedule-reliability-spec-v5.md` | Aligns AlarmKit delivery with compressed attempts, Fajr-start event, and cancellation rules. |
| `subh-early-worship-boundary-spec-v4.md` | Confirms last-third Suhoor window and scheduling cutoff. |
| `subh-quick-wake-mode-intent-mutation-contract-v4.md` | Adds switching confirmation, Next 7 Quiet toggle mutation, optional Fajr follow-up and late-log mutations. |
| `subh-morning-resolution-contract-state-ownership-spec-v5.md` | Adds resolver fields for hero labels, late prompt, wake-session boundaries, Fajr follow-up. |
| `subh-mvp-interaction-inventory-v6.md` | Adds interaction coverage for May 31 scenario states and late logging. |
| `subh-context-spec-integrity-review-v3.md` | Adds drift-prevention checklist for May 31 contradictions. |
| `subh-wake-session-testing-and-simulation-harness-spec-v5.md` | Adds 24/48-hour scrubbing, boundary presets, action-branching, expected-state preview, edge-case simulation backlog. |

## 3. Narrow cross-reference update

| File | Change |
| --- | --- |
| `subh-month-planning-gregorian-hijri-spec-v4.md` | Bumped from v3 to v4 only to update the shared tag contract reference to v3 and preserve Month Planning as non-mutating inspection/navigation. |

## 4. Files intentionally carried forward without material change

| File | Reason |
| --- | --- |
| `subh-fajr-time-calculation-determination-selection-spec-v2.md` | May 31 changes consume calculated Fajr times but do not change calculation method. |
| `subh-planning-horizon-day-resolution-intention-anchoring-spec-v4.md` | Existing planning horizon model remains compatible. |
| `subh-pricing-entitlement-spec-v4.md` | No pricing or entitlement changes were requested. |
| `subh-mvp-interaction-tier-exposure-matrix-v3.md` | No tier exposure changes were requested. |
| `subh-sound-alarm-settings-spec-v2.md` | No sound-setting changes were requested. |
| `subh-weekly-fajrcast-card-spec-v15.md` | Weekly summary remains non-mutating and does not receive the Next 7 inline Quiet toggle. |

## 5. Archived material

The previous May 30 active versions for updated specs were copied to:

```text
Archive/may30-pre-may31-scenario-update/
```

The previous release manifest was also archived there.

## 6. Key contradictions corrected

| Prior/conflicting direction | May 31 corrected direction |
| --- | --- |
| Visible selector appears as Fajr/Suhoor in some places | Visible selector order is `Suhoor | Fajr`; enum order may remain internal only. |
| Next 7 forbids inline controls | Next 7 now has exactly one inline mutation: right-column Quiet toggle. |
| Context card uses tag-like presentation | Context card uses sentence-based copy; tags stay in compact planning rows. |
| Active-session Quiet unavailable | Active-session Quiet cancellation is an approved, confirmed edge case through alarm-state control; not the primary active wake action. |
| Suhoor acknowledgement could lead to Fajr wake checks by default | Default is a single Fajr-start event only; Fajr checks require explicit opt-in. |
| Fajr wake acknowledgement could imply completion | `I’m Awake for Fajr` does not log prayer; `I Prayed Fajr` logs completion separately. |
| Late Fajr logging could remain in Hero after rollover | Late prompt appears below context card, separate from next-morning Hero. |

## 7. Validation checks performed on the spec package

- Updated filenames and internal canonical filename/version/date metadata for the affected specs.
- Archived previous versions for materially updated files.
- Removed the explicit old testing-harness statement that active-session Quiet is unavailable after the first alarm.
- Updated the stale Month Planning reference from shared tag contract v2 to v3.
- Archived the May 30 release manifest and created the May 31 release manifest.
- Preserved unrelated active specs without material rewrite.

## 8. Remaining non-final areas

These are not implementation blockers for the May 31 changes, but they should receive future simulation/design review:

- daylight savings time spring-forward/fall-back;
- high-latitude Fajr behaviour;
- Ramadan defaults and transition behaviour;
- Eid/fasting-unavailable days;
- travel and location-change rescheduling;
- deep indefinite Pause visual/copy treatment beyond the preserved May 30 model.

## 9. Implementation note

Codex should use the active root files in this package, not archived files. The highest-level implementation sequence is:

1. sync the local specifications folder with this package;
2. archive prior local specs/reports/artifacts;
3. create or update OpenSpec change artifacts;
4. implement scoped code changes;
5. update tests and simulation harness;
6. validate;
7. provide a completion report;
8. commit and push to `main` only after validation succeeds.
