# Subh Context Spec Integrity Review v4 — June 1 CTA Drift-Control Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-context-spec-integrity-review-v4.md` |
| Version | 4 |
| Spec status | Active integrity-review checklist |
| Date | 2026-06-01 |
| Related specs | Entire active spec set |
| Owning domain / surface | Spec quality, drift control, and implementation audit support |

## June 1, 2026 CTA/logging reconciliation

This version is reconciled with `subh-cta-logging-and-wake-action-spec-v2.md`. If earlier text in this file conflicts with the CTA spec, use the June 1 rules below:

- Active wake CTAs live in the Hero: **I’m Awake for Suhoor** and **I’m Awake for Fajr**.
- Logging and early-awake actions live in the context-card action area, not in the Hero and not as a separate standalone CTA card.
- Ordinary system/AlarmKit dismissal does not by itself mean the user is awake. It dismisses the current alarm attempt and the Hero must advance to the next pending wake-check time when one exists.
- Only explicit awake confirmation, confirmed early-awake action, or an explicitly supported platform action mapped to awake confirmation cancels remaining wake checks as wake success.
- **I’m Awake for Fajr** and **I Prayed Fajr** must not appear simultaneously.
- Late Fajr and fast completion use compact check/X prompt rows and must distinguish ✓, ✕, and unrecorded.
- Silence/unanswered is never treated as no.

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
| Active wake flow exposes Stop checks | Not visible; use `I’m Awake`. |
| Active-session Quiet treated as normal acknowledgement | If exposed, it is confirmed cancellation and does not log wake/prayer completion. |
| Suhoor acknowledgement auto-creates Fajr checks | Default is a single Fajr-start event only; post-Suhoor Fajr slider activation is opt-in. |
| `I’m Awake for Fajr` logs prayer completion | It logs wake acknowledgement only. `I Prayed Fajr` logs prayer completion. |
| Late Fajr logging stays in hero after rollover | It appears inside the context-card action area as a separate previous-morning prompt. |
| Follow-ups run to exact Fajr/Fajr-end boundary | Final attempt is no later than boundary minus 5 minutes. |

## 3. Audit checklist for future changes

Before accepting a future spec or implementation change, verify:

1. Home and Detail selectors remain `Suhoor | Fajr` visibly.
2. Quiet/Pause remain separate alarm-state/policy layers.
3. Suhoor remains fasting-oriented in MVP.
4. Non-fasting before-Fajr planning is not reintroduced accidentally.
5. Active wake flow exposes `I’m Awake` as primary action.
6. Follow-ups use 5-minute intervals and respect Fajr/Suhoor boundaries.
7. System dismissal without explicit awake confirmation behavior remains deliberate and tested.
8. Next 7 inline mutation is limited to the Quiet toggle.
9. Month and Weekly Fajrcast remain non-mutating unless later explicitly changed.
10. Context card remains sentence-based and non-technical.
11. Late Fajr logging remains separate from the next-morning Hero.
12. Pricing does not paywall safety/basic wake utility.
13. Original archived specs are not used as implementation source without reconciling conflicts.

---

## June 1 Addendum: New Drift Traps

Future changes must avoid these regressions:

| Drift trap | Correct rule |
| --- | --- |
| Treating system dismissal as awake success | Ordinary dismissal only stops the current attempt and advances to the next check if one exists. |
| Reintroducing **I’m fasting today** as an active wake CTA | Fast completion is after Maghrib through check/X prompt rows. |
| Showing **I’m Awake for Fajr** and **I Prayed Fajr** together | They are sequential with a short cooldown. |
| Adding a separate **Set Fajr Wake Alarm** CTA after Suhoor | Post-Suhoor Fajr is defaulted in the Hero; slider activation creates checks. |
| Moving logging actions into the Hero | Logging lives in the context-card action area. |
| Inferring no from silence | Unanswered prompts are unresolved/expired, not no. |

