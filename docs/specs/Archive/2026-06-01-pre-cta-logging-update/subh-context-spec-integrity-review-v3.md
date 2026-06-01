# Subh Context Spec Integrity Review v3 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-context-spec-integrity-review-v3.md` |
| Version | 3 |
| Spec status | Active integrity-review checklist |
| Date | 2026-05-31 |
| Related specs | Entire active spec set |
| Owning domain / surface | Spec quality, drift control, and implementation audit support |

## 1. Purpose

This review file records the key integrity traps that the May 31 update must prevent from reappearing.

## 2. Resolved drift traps

| Trap | Correct active rule |
| --- | --- |
| Quiet as third wake-purpose segment | Quiet is `DateAlarmOverride.quiet`; visible selector is `Suhoor | Fajr`. |
| Pause as a mode | Pause is `GlobalWakeAlarmPolicy.pausedIndefinitely`. |
| Pre-Fajr/Early/Fast as visible purposes | Suhoor is the only MVP before-Fajr purpose. |
| Tahajjud-only / Other early worship in MVP | Deferred; not active MVP UI/resolution. |
| Hero labels as `Today` / `Tomorrow` only | Use `Today Morning` / `Tomorrow Morning` in title case. |
| Hero adds explanatory text under wake time | Hero Slot 3 remains minimal; context card explains. |
| Alarm icon looks decorative | Alarm icon/wake time must look tappable and open Quiet confirmation. |
| Context card uses tags as explanation | Context card uses plain sentence-based copy. |
| Generic `Fasting Opportunity` row tag | Use specific tags such as Monday, Thursday, White Days, Ramadan. |
| Tags mixing purpose/status/context | Next 7 purpose line is separate; tag lane = opportunity/context only. |
| Next 7 no inline editing at all | May 31 allows only the right-column Quiet toggle; other edits route to Detail. |
| Active wake flow exposes Stop checks | Not visible; use `I’m awake`. |
| Active-session Quiet treated as normal acknowledgement | If exposed, it is confirmed cancellation and does not log wake/prayer completion. |
| Suhoor acknowledgement auto-creates Fajr checks | Default is a single Fajr-start event only; Fajr follow-up is opt-in. |
| `I’m Awake for Fajr` logs prayer completion | It logs wake acknowledgement only. `I Prayed Fajr` logs prayer completion. |
| Late Fajr logging stays in hero after rollover | It appears below the context card as a separate previous-morning prompt. |
| Follow-ups run to exact Fajr/Fajr-end boundary | Final attempt is no later than boundary minus 5 minutes. |

## 3. Audit checklist for future changes

Before accepting a future spec or implementation change, verify:

1. Home and Detail selectors remain `Suhoor | Fajr` visibly.
2. Quiet/Pause remain separate alarm-state/policy layers.
3. Suhoor remains fasting-oriented in MVP.
4. Non-fasting before-Fajr planning is not reintroduced accidentally.
5. Active wake flow exposes `I’m awake` as primary action.
6. Follow-ups use 5-minute intervals and respect Fajr/Suhoor boundaries.
7. System dismissal acknowledgement behavior remains deliberate and tested.
8. Next 7 inline mutation is limited to the Quiet toggle.
9. Month and Weekly Fajrcast remain non-mutating unless later explicitly changed.
10. Context card remains sentence-based and non-technical.
11. Late Fajr logging remains separate from the next-morning Hero.
12. Pricing does not paywall safety/basic wake utility.
13. Original archived specs are not used as implementation source without reconciling conflicts.
