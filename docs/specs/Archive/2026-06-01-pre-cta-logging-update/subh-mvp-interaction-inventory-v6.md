# Subh MVP Interaction Inventory v6 — May 31 Morning State Framework Update

| Field | Value |
| --- | --- |
| Canonical filename | `subh-mvp-interaction-inventory-v6.md` |
| Version | 6 |
| Spec status | Active interaction inventory summary and scenario-group contract |
| Date | 2026-05-31 |
| Related specs | Index, May 31 Scenario Walkthrough, Quick Mutation, Hero, Detail, Quiet/Pause, Wake Sessions, Pricing, Testing Harness |
| Owning domain / surface | MVP interaction coverage and scenario grouping |

## May 31, 2026 update status

Version 6 adds the May 31 morning-state walkthrough scenarios and supersedes the May 30 deferral of active-session Quiet cancellation and Next 7 inline Quiet. Active-session Quiet remains a confirmed/cautious edge control, not a primary wake CTA. Next 7 inline mutation is limited to the per-row Quiet toggle.

## 1. Purpose

This inventory identifies the MVP interaction groups that must be covered by implementation and testing after the May 31 morning-state framework update.

## 2. Active interaction groups

| Group | Interaction family | Required outcome |
| --- | --- | --- |
| A | Home Hero Fajr planning | User can view/adjust Fajr alarm and keep purpose Fajr. |
| B | Home Hero Suhoor planning | User can select Suhoor, use Suhoor alarm config, and default fasting-purpose logic applies. |
| C | Home Hero Quiet | User can set/clear Quiet from alarm icon/wake-time confirmation. |
| D | Home Hero Pause display | Paused state displays without changing hero height. |
| E | Ring once while paused | User can ring one target morning while Pause remains active. |
| F | Day Detail editing | User can edit selected date purpose, alarm time, Quiet, ring-once, fasting purpose, reset. |
| G | Next 7 Mornings | Rows display seven mornings and expose only a right-column Quiet toggle inline. |
| H | Month planning | Dates/rows display context/status and navigate to Detail. |
| I | Weekly Fajrcast | Inspection-only seven-morning summary. |
| J | Wake Session Fajr | Alarm rings, `I’m awake`, follow-ups cancel, `I prayed Fajr` eligibility works. |
| K | Wake Session Suhoor | Alarm rings, `I’m awake`, optional fasting CTA, single Fajr-start event by default, optional Fajr follow-up if user selects it. |
| L | System dismissal | Explicit system/AlarmKit dismissal records awake acknowledgement source. |
| M | No response | Session ends with `No response recorded`, not missed by default. |
| N | Delivery issues | Permission/setup/delivery failures show issue/setup states, not Quiet. |
| O | Pricing exposure | Core interactions remain Free; Plus reserved for insights/history/etc. |
| P | Testing harness | Simulation can exercise all states without waiting for real mornings. |
| Q | Late Fajr logging | Late prompt below context card logs Fajr completion after hero rollover. |
| R | 24/48-hour simulation | Tester can scrub time and branch actions through the next daily cycle. |

## 3. Deferred scenario families

These historical scenario families are explicitly deferred from active MVP:

```text
Tahajjud-only before-Fajr selection
Other early worship before-Fajr selection
Fasting + Tahajjud combined selection
Generic Pre-Fajr / Early / Fast mode selector states
Quiet as a third purpose segment
Date-range Pause / recurring Pause / pause reason picker
```

Active-session Quiet cancellation is no longer globally deferred. It is allowed only as a confirmed alarm-state cancellation edge case if implemented. It must not replace `I’m awake` as the primary active wake action.

## 4. Compatibility scenario families

Legacy values must be decoded safely:

| Legacy scenario | Active expected behavior |
| --- | --- |
| Existing Pre-Fajr/Early/Fast saved value | Normalize to Suhoor-compatible behavior. |
| Existing Quiet quick-mode record | Normalize to DateAlarmOverride.quiet. |
| Existing non-fasting before-Fajr metadata | Preserve for migration/debug if needed, but do not surface as active MVP. |
| Existing wake-stop/dismiss behavior | Treat explicit dismissal as awake acknowledgement for MVP. |

## 5. Required test scenarios

Minimum scenario coverage:

1. Active Fajr planning → set Quiet → clear Quiet → Fajr plan restored.
2. Active Suhoor planning → set Quiet → switch Fajr/Suhoor while Quiet → saved times preserved.
3. Purpose selector visible order is `Suhoor | Fajr` on Home and Detail.
4. Pause globally → row shows Paused → ring tomorrow only → Pause remains after target morning.
5. Manual Quiet during Pause → resume alarms → manual Quiet remains.
6. Alarm starts → `I’m awake` cancels follow-ups.
7. Approved active-session Quiet cancellation → confirmation → remaining checks cancelled without wake acknowledgement.
8. System dismissal → acknowledgement source recorded → follow-ups cancelled.
9. Suhoor acknowledged → no automatic Fajr wake checks → Fajr-start event fires once.
10. Suhoor acknowledged → user opts into Fajr follow-up → normal Fajr wake-check sequence applies.
11. Fajr alarm acknowledged → `I prayed Fajr` appears after delay → prayer completion logs separately.
12. Fajr alarm acknowledged but prayer not logged → Fajr ends → late prompt below context card appears.
13. Late prompt same day uses `I Prayed Fajr Earlier Today`.
14. Late prompt after midnight uses `I Prayed Fajr Yesterday Morning`.
15. Late prompt expires at next relevant wake window if unused.
16. Suhoor window begins at the last third of the night.
17. Switch into Suhoor before Fajr-minus-6 allowed; after cutoff blocked.
18. Wake checks at 30/25/20/15/10/5 minutes before relevant boundary for default session.
19. Later wake time compresses wake checks naturally.
20. Fajr alarm no response → `Alarm ended` / `No response recorded`.
21. Missing permission → `Turn on alarms`, not Quiet.
22. Next 7 row shows time/Quiet left, date beneath, purpose line middle, specific tags beneath, Quiet toggle right.
23. Next 7 Quiet toggle mutates only Quiet; row body opens Detail.
24. Month row opportunity tags only; trailing status shows Quiet/Paused.
25. Weekly Fajrcast shows summary and mutates nothing.
26. Testing harness can scrub through at least 24 hours and preferably 48 hours.
27. Testing harness allows action-branching on Hero CTAs/toggles while simulated time is active.
28. DST/high-latitude/Ramadan/Eid/location-change scenarios are available as simulation backlog/presets.
29. Pricing gate check: no core wake action requires Plus.
30. Legacy Pre-Fajr/Fast/Quiet-as-mode values migrate/normalize without visible stale copy.

## 6. Acceptance criteria

1. The inventory no longer treats Quiet as a wake purpose.
2. Non-fasting before-Fajr flows are marked deferred.
3. Every core Quiet/Pause/Hero/Wake Session behavior has a testable scenario.
4. Scenario coverage includes system dismissal acknowledgement.
5. Scenario coverage includes May 31 timeline states: daytime, evening, midnight, Suhoor window, Fajr begins, Fajr window, Fajr end, and after Fajr rollover.
6. Scenario coverage includes late Fajr logging outside the Hero.
7. Scenario coverage includes Next 7 inline Quiet toggle and confirms no inline purpose/Pause/time editing.
8. Pricing coverage confirms Free/core access for safety and basic wake utility.
