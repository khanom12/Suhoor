# Morning Hero Item Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-morning-hero-item-spec-v15.md` |
| Version | 15 |
| Spec status | Product / implementation direction; canonical Desktop working spec; aligned to Next 7 Mornings horizon |
| Supersedes | `subh-morning-hero-item-spec-v14.md`; Archive/Morning_Hero_Item_Specification_v13.md |
| Related specs | `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-quick-wake-mode-intent-mutation-contract-v2.md`, `subh-early-worship-boundary-spec-v2.md`, `subh-next-7-mornings-wake-forecast-spec-v2.md`, `subh-weekly-fajrcast-card-spec-v14.md`, `subh-wake-sessions-wake-checks-morning-logs-spec-v1.md`, `subh-quiet-mode-quiet-morning-contract-spec-v1.md`, `subh-sound-alarm-settings-spec-v1.md` |
| Owning domain / surface | Home / Morning Hero surface |
| Implementation audit status | Needs implementation audit |

## Purpose
Specify the Home hero that answers what tomorrow morning looks like, including wake state, boundary visual, quick mode selection, relation copy, accessibility, and low-friction interaction.

## What This Spec Owns
- Visible Home hero hierarchy and state presentation.
- Quick wake selector placement and Home commit behavior.
- Hero wake-boundary visual, animation, accessibility, and display rules.

## Normative Requirements
The normative requirements in this spec are the explicit MUST, SHALL, required, acceptance, and scenario statements below. Recommendations, implementation guidance, examples, and future-direction notes are advisory unless this spec or a later canonical spec promotes them to requirements.

## Out of Scope / Deferred
- Code/spec divergence classification is deferred to a later implementation audit.
- App code, tests, and OpenSpec library artifacts are out of scope for this docs-only cleanup.
- Historical archive filenames are kept only as historical references and are not promoted back into the active spec set.

## Open Questions and Deferred Work
Open questions, TODO-style notes, future ideas, and implementation audit prompts below are retained as the working queue for later spec improvement. This cleanup standardizes them as deferred work rather than claiming they are resolved.

## Cleanup Notes
- This file was renamed and header-normalized in the Desktop working-spec cleanup pass.
- The Desktop folder remains the canonical working-spec location.
- Implementation completeness claims in older prose should be treated as historical context until the later audit updates this field.

## MVP Suhoor Alignment Addendum
This addendum is normative for MVP and supersedes conflicting lower sections in this file.

- The Home hero quick selector is `Suhoor | Fajr | Quiet`.
- `Suhoor` is the only exposed before-Fajr quick mode in MVP.
- The hero must not expose `Tahajjud only`, `Other early worship`, or generic `Pre-Fajr` as selectable modes or intentions.
- Selecting `Suhoor` immediately commits a before-Fajr suhoor/fasting wake for the target morning.
- Suhoor defaults to applicable Sunnah fasting opportunities when they exist; otherwise it defaults to `Voluntary fast`.
- Quiet remains intentional delivery suppression and must preserve the underlying Suhoor or Fajr state for restoration.
- Legacy `Fast`, `Early`, and `Pre-Fajr` visible labels are superseded by `Suhoor`.

## v15 Next 7 Mornings / Weekly Fajrcast Alignment Addendum

This addendum is normative for v15 and supersedes lower historical Home-surface references to `Next 10 Mornings`.

- On Home, the near-term forecast card is `Next 7 Mornings`.
- `Next 7 Mornings` appears collapsed by default with its `NEXT 7 MORNINGS` header visible.
- When expanded, it shows seven rows: the next immediate alarm / next relevant morning plus the following six mornings.
- Weekly Fajrcast uses the same seven visible dates as Next 7 Mornings.
- The Morning Hero remains the immediate answer surface; the forecast and chart provide matching weekly context below it.


## Wake Sessions / Hero Action Slot Alignment Addendum

This addendum is normative for the current MVP wake-execution pass and supersedes conflicting lower hero wording only for wake confirmation, wake checks, immediate morning logs, and active-window CTAs.

- The Morning Hero consumes Wake Session, MorningLog, and resolved morning snapshot state from the canonical system layer. It must not infer awake, prayer, fasting, or missed outcomes locally.
- The Hero must include a fixed-height **Hero Action Slot** inside the settled hero stack. The slot content may change, but the surrounding hero layout must not jump vertically across planning, active-window, fired, confirmed, or Quiet states.
- In ordinary planning state, the Hero Action Slot preserves the existing wake-adjustment control where that control is valid for the selected mode.
- In an active confirmation window before the primary alarm fires, the slot preserves the adjustment control and may add a compact mode-specific action: `Already awake? [I’m awake]`.
- After the primary alarm or a wake check has fired, and before awake confirmation, the slot replaces the adjuster with the prominent mode-specific CTA: `I’m awake for Fajr` or `I’m awake for Suhoor`.
- `I’m awake for Fajr` confirms only Fajr awake status. It must not mark `I prayed Fajr`.
- `I’m awake for Suhoor` confirms Suhoor awake status and the fasting intention for that morning. It must not mark `I prayed Fajr` and must not mark fast completion.
- After Fajr begins, a Suhoor user who already confirmed Suhoor awake should see `I prayed Fajr` as the primary next completion CTA. A Suhoor user who did not confirm Suhoor awake should see `I’m awake for Fajr` first, then `I prayed Fajr`.
- `I prayed Fajr` remains a separate user action and separate log outcome from both Fajr awake confirmation and Suhoor awake confirmation.
- Selecting Quiet during an active Wake Session must route through the Quiet confirmation sheet defined by the Quiet Mode contract before remaining alarms or wake checks are cancelled.
- The Hero may emit user intents such as `confirmAwakeForFajr`, `confirmAwakeForSuhoor`, `confirmFajrPrayer`, `selectQuickWakeMode(.quiet)`, and `confirmQuietMorning`, but it must not directly cancel platform alarms.
- Lock Screen `Open Subh` actions should route the user to the relevant hero state. Lock Screen `Stop` alone must not mark the user awake.
- The active MVP selector label set is `Suhoor | Fajr | Quiet`. Legacy `Pre-Fajr`, `Fast`, or `Early` examples retained lower in this document are historical or compatibility wording unless a later approved spec reintroduces them.

## 0. v15 source-of-truth alignment

This v15 revision preserves the v13 visual, layout, animation, Dynamic Type, accessibility, and Home-surface behavior unless explicitly clarified here. The purpose of this revision is to align the Morning Hero with:

1. `00-subh-spec-index-v3.md`;
2. `subh-mvp-interaction-inventory-v4.md`;
3. `subh-quick-wake-mode-intent-mutation-contract-v2.md`;
4. the parent `subh-morning-resolution-contract-state-ownership-spec-v3.md`.

The Morning Hero is an **immediate-commit surface** for the next relevant morning. It may preview UI changes while the user taps, drags, or scrubs, but committed user actions must be expressed as normalized wake-mode / intention mutation commands and then re-resolved through the canonical morning-resolution pipeline.

The Hero must not create a second wake resolver, fasting resolver, Quiet resolver, or scheduler. It emits user intent, consumes the updated resolved snapshot, and keeps visual presentation synchronized with that snapshot.

Canonical user-intent commands for this surface include, as applicable:

```text
selectQuickWakeMode(.suhoor | .fajr | .quiet)
selectFastingIntention(...)
adjustWakeTime(...)
```

Rules stabilized by the shared mutation contract:

- `Fast`, `Early`, and `Pre-Fajr` are legacy visible labels; use `Suhoor`.
- `Suhoor` is the MVP before-Fajr quick mode and implies suhoor/fasting intent.
- `Other early worship` and `Tahajjud only` are not exposed in MVP.
- Home Hero changes commit immediately for the target morning.
- Tapping the already-selected mode is idempotent and must not create duplicate override records.
- Switching between `Suhoor`, `Fajr`, and `Quiet` resets the wake time to that mode's default anchor unless the shared resolver explicitly returns a different valid resolved state.
- Quiet is intentional alarm suppression for the target morning; it is not permission failure, delivery failure, missing data, or generic alarm unavailability.
- The Hero does not schedule or cancel platform alarms directly; schedule refresh happens downstream after the canonical state is committed and re-resolved.

---

## 1. Scope

This specification defines the **Morning Hero item** at the top of the home screen.

The hero describes the **next relevant Fajr-centered morning** in one centered, high-confidence summary. It is not a chart, not a card, and not a forecast list. It is the user's immediate orientation point.

It should answer:

```text
Which location are these Fajr times resolved for?
What is the next meaningful morning?
When am I waking?
Where does my wake time sit inside the active wake-boundary window?
How does that wake time relate to Fajr?
```

The Gregorian + Hijri date row is intentionally hidden in v15. Date data may remain resolved by the data layer and may return in a later iteration, but the visible top row for this version is the location line.

## 2. One-sentence definition

**The Morning Hero is a calm, centered summary of the next relevant morning, showing the prayer-time location, relative day, wake time or wake state, a wake-boundary position visual when applicable, and the wake relation to the active boundary.**

## 3. Product intent

The app is a Fajr-centered morning system. The Morning Hero is the most immediate expression of that system.

The hero should not behave like a generic clock, generic alarm preview, or decorative welcome message. It should resolve the next meaningful Fajr-centered morning and explain it clearly.

At a glance, the user should understand:

- which location the shown Fajr times are resolved for
- whether the hero is about today, tomorrow, or another upcoming morning
- whether a wake alarm is active, off, unavailable, or not set
- the wake time when one exists
- where that wake time sits inside the active wake-boundary window when the visual is applicable
- how that wake time relates to Fajr

The date line is not part of the visible hero stack in v15. This is a temporary design decision; the resolved Gregorian and Hijri date rules are retained for future reactivation.

## 4. Current screenshot baseline

Earlier drafts had mismatched legacy before-Fajr labels between Home and Detail. v15 resolves the active MVP selector on both surfaces to:

```text
Suhoor | Fajr | Quiet
```

Default / Fajr quick-select example:

```text
[location icon] East York
Tomorrow

[alarm icon] 5:43 AM

4:43 AM  ●━━━━━━⏰━━●  6:13 AM
Wake up 30 min before Fajr ends

[ Pre-Fajr | Fajr selected | Quiet ]
```

Manual-location example:

```text
Toronto
Tomorrow

[alarm icon] 5:43 AM

4:43 AM  ●━━━━━━⏰━━●  6:13 AM
Wake up 30 min before Fajr ends

[ Pre-Fajr | Fajr selected | Quiet ]
```

Pre-Fajr quick-select example, default Tahajjud-only intention:

```text
[location icon] East York
Tomorrow

[alarm icon] 4:13 AM

2:16 AM  │━━━━━━⏰━━●  4:43 AM
Wake up 30 min before Fajr begins

[ Pre-Fajr selected | Fajr | Quiet ]
[ Tahajjud only selected | Fasting | Other early worship ]
```

Suhoor example:

```text
[location icon] East York
Tomorrow

[alarm icon] 4:13 AM

2:16 AM  │━━━━━━⏰━━●  4:43 AM
Wake up 30 min before Fajr begins

[ Pre-Fajr selected | Fajr | Quiet ]
[ Tahajjud only | Fasting selected | Other early worship ]
Fasting intention: [Monday fast] [White Days fast]
```

deferred Other early worship example:

```text
[location icon] East York
Tomorrow

[alarm icon] 4:13 AM

2:16 AM  │━━━━━━⏰━━●  4:43 AM
Wake up 30 min before Fajr begins

[ Pre-Fajr selected | Fajr | Quiet ]
[ Tahajjud only | Fasting | Other early worship selected ]
```

Quiet quick-select example:

```text
[location icon] East York
Tomorrow

[moon icon] Quiet mode

4:43 AM  ●━━━━━━━━━━●  6:13 AM
No alarm will ring for tomorrow

[ Suhoor | Fajr | Quiet selected ]
```

Main changes retained and clarified in v15:

1. Align the Home hero and Alarm Detailed View mode labels to `Suhoor | Fajr | Quiet`.
2. Remove `Fast` as a Home hero mode label.
3. Remove `Early` as a detail-view mode label.
4. Keep `Fajr` selected by default for ordinary non-Ramadan mornings.
5. `Fajr` uses the default wake rule: 30 min before Fajr ends.
6. `Pre-Fajr` uses the default wake rule: 30 min before Fajr begins.
7. When `Pre-Fajr` is selected outside Ramadan, the Home hero shows or exposes a Pre-Fajr intention selector with `Tahajjud only`, `Fasting`, and `Other early worship`.
8. Outside Ramadan, `Pre-Fajr` defaults to `Tahajjud only`.
9. If the user selects `Fasting`, the fasting intention defaults to the opportunity set present for that date.
10. If no specific fasting opportunity exists, `Fasting` defaults to `Voluntary fast`.
11. During Ramadan, the default hero state is `Pre-Fajr` + `Fasting` + `Ramadan fast`.
12. During Ramadan, the user cannot change the Pre-Fajr intention or fasting intention; they may switch to `Fajr` or `Quiet`.
13. When the user returns to `Pre-Fajr` during Ramadan, the hero restores `Fasting` + `Ramadan fast` automatically.
14. On Eid days, fasting is unavailable; selecting `Pre-Fajr` lands on `Tahajjud only`.
15. `Quiet` removes/suppresses the active wake alarm for the target morning while keeping the Fajr boundary times visible in a static, non-interactive range row when Fajr data is available.
16. The quick wake-state selector changes the primary wake row, range visual, and relation/status line through the Quick Wake Mode and Intent Mutation Contract and shared wake-state resolver; the hero view must not create, cancel, verify, or schedule platform alarms directly.
17. Continue to update the primary wake row and relation/status line live when the user drags the alarm icon on an interactive range bar.
18. Use the default within-Fajr adjuster for default Fajr mornings whose wake time is between Fajr begins and Fajr ends.
19. Use the early-worship adjuster for selected Pre-Fajr, fasting, Ramadan, Qada/custom fast, Tahajjud-only, and Other early worship mornings whose wake time is between the final-third start and Fajr begins.
20. In the early-worship adjuster, the left boundary is a vertical line/tick marking the start of the final third of the night, not an endpoint circle. The right boundary remains the Fajr-begins endpoint circle.
21. When the early-worship adjuster is scrubbed all the way left, the relation/status line says exactly `Wake up for the last third of the night`.
22. Use endpoint-specific relation/status text when the wake adjuster is exactly at Fajr begin or Fajr end: `Wake up as Fajr begins` or `Wake up as Fajr ends`.
23. Red text is not endpoint-specific; it appears only when the wake time is 14 min or less before Fajr ends.
24. Keep all readable text responsive to the seven standard iPhone text-size stops.
25. Retain the full Gregorian + Hijri month-name date rules for possible future reactivation, but do not allocate visible space for the hidden date row in v15.
26. The `Suhoor | Fajr | Quiet` selector must use the same translucent liquid-glass surface language as the Next 7 Mornings card, not an opaque or frosted gray segmented-control treatment.
27. Preserve the approved selector-highlight glide between `Pre-Fajr`, `Fajr`, and `Quiet`.
28. The relation/status line above the selector must change by fade-through or in-place text transition only; it must not slide in from the left, right, top, or bottom.
29. The primary wake time must rapidly roll between active wake times when switching `Fajr ↔ Pre-Fajr`.
30. The wake-boundary row itself must remain anchored; only the alarm icon travels during `Fajr ↔ Pre-Fajr` adjuster transitions.
31. Switching to or from `Quiet` must not cause the hero stack to jump vertically; `[moon icon] Quiet mode` replaces the primary wake time inside the same visual slot.
32. On Home, `Next 7 Mornings` appears collapsed by default with its header visible.
33. The Weekly Fajrcast remains a separate card, is not collapsed by this revision, and uses the same seven visible dates as Next 7 Mornings.
34. v15 formally routes all quick-mode, Pre-Fajr-intention, fasting-intention, and wake-adjustment changes through the shared Quick Wake Mode and Intent Mutation Contract.
35. `Other early worship` is preserved as a canonical Pre-Fajr intention and must not be collapsed into `Other fast`, `Tahajjud only`, or `Fasting`.
36. Home Hero mutations commit immediately for the target morning and then consume the re-resolved canonical snapshot.
37. Repeated taps, rapid switching, and drag-then-mode-change sequences must produce one final consistent resolved state without duplicate date-specific records.
38. Permission or delivery failure must not be rendered as `Quiet mode`.

## 5. Core mental model

> **Resolve the next Fajr-centered morning for the selected or detected location, then explain the relevant wake window plainly.**

The hero should not require the user to infer meaning from the Weekly Fajrcast chart. The chart gives broader context; the hero gives the immediate answer.

There are seven separate concepts:

- **Location context:** the selected or detected place used to resolve Fajr begin and Fajr end.
- **Target morning:** the next relevant morning shown in the hero.
- **Wake quick mode:** the user's immediate target-morning choice: `Pre-Fajr`, `Fajr`, or `Quiet`.
- **Pre-Fajr intention:** when `Pre-Fajr` is selected, the user’s intention is `Tahajjud only`, `Fasting`, or `Other early worship`.
- **Fasting intention:** when `Pre-Fajr` + `Fasting` is selected, the app resolves the applicable fasting intention: Ramadan, opportunity-based Sunnah fasts, Voluntary, Qada, Vow, Kaffarah, or `Other fast`, depending on date and user override rules.
- **Default Fajr window:** the Fajr begins → Fajr ends interval used for ordinary/default Fajr mornings.
- **Early-worship window:** the final-third start → Fajr begins interval used for Pre-Fajr, fasting, Ramadan, Qada/custom fast, Tahajjud-only mornings, and Other early worship mornings.

The hero should receive these values from the data layer. It should not calculate Fajr end, final-third start, infer Hijri dates, invent wake times, invent location display names, create alarms, cancel alarms, or compose complex tense/context strings locally when the snapshot already provides them.

The final-third start is owned by the Early Worship Boundary resolver: it is calculated from the previous evening's Maghrib/sunset to the target morning's Fajr begins, then taking the start of the final third of that night. The hero consumes the resolved value; it does not duplicate the calculation.

Quick-select state changes are owned by the shared wake-state / alarm-state resolver and the Quick Wake Mode and Intent Mutation Contract. The hero emits a user intent such as `selectQuickWakeMode(.preFajr)`, `selectQuickWakeMode(.fajr)`, or `selectQuickWakeMode(.quiet)`; the resolver returns the updated snapshot and coordinates persistence and schedule-refresh handoff through the single alarm-state pipeline.

Pre-Fajr intention changes and fasting-intention changes must also route through the shared mutation contract or the same date-specific intent pipeline. The hero must not directly create fasting plans, adhan events, Quiet records, or alarms locally.

## 6. Hero anatomy

The hero is a vertical centered stack with six base visible content rows when the wake-boundary visual is applicable, plus conditional Pre-Fajr intention controls.

Base structure:

1. **Location line**
2. **Relative day label**
3. **Primary wake row**
4. **Wake-boundary range visual / wake-time drag control**
5. **Wake relation/status line**
6. **Quick wake-state selector**

Conditional structure when `Pre-Fajr` is selected:

7. **Pre-Fajr intention selector:** `Tahajjud only | Fasting | Other early worship`
8. **Fasting-intention display/selector**, only when `Fasting` is selected and the date is not Ramadan-locked

Recommended base structure:

```text
{locationIcon optional} {locationDisplayText}
{relativeDayLabel}

{alarmIcon optional} {wakeDisplayText}

{leftBoundaryTime}  {wakeBoundaryBarWithBoundaryMarkersAndOptionalAlarmHandle}  {rightBoundaryTime}
{relationText}

{quickWakeStateSelector: Suhoor | Fajr | Quiet}
{conditionalPreFajrIntentionControls}
```

Default / Fajr quick-select example:

```text
[location icon] East York
Tomorrow

⏰ 5:43 AM

4:43 AM  ●━━━━━━⏰━━●  6:13 AM
Wake up 30 min before Fajr ends

[ Pre-Fajr | Fajr selected | Quiet ]
```

Manual-location example:

```text
Toronto
Tomorrow

⏰ 5:43 AM

4:43 AM  ●━━━━━━⏰━━●  6:13 AM
Wake up 30 min before Fajr ends

[ Pre-Fajr | Fajr selected | Quiet ]
```

Pre-Fajr quick-select example:

```text
[location icon] East York
Tomorrow

⏰ 4:13 AM

2:16 AM  │━━━━━━⏰━━●  4:43 AM
Wake up 30 min before Fajr begins

[ Pre-Fajr selected | Fajr | Quiet ]
[ Tahajjud only selected | Fasting | Other early worship ]
```

Quiet quick-select example:

```text
[location icon] East York
Tomorrow

[moon icon] Quiet mode

4:43 AM  ●━━━━━━━━━━●  6:13 AM
No alarm will ring for tomorrow

[ Suhoor | Fajr | Quiet selected ]
```

When the wake-boundary visual is not applicable because required timing data is unavailable or the wake time falls outside the supported range, the hero remains a centered vertical stack and omits the fourth visual row. In that case, the relation/status line sits directly below the primary wake row, and the quick wake-state selector remains below the relation/status line when the control is available.

The Gregorian + Hijri date line is hidden in v15 and must not reserve a blank row in the visible hero stack.

## 7. Content rules

### 7.1 Location line

The location line is the first visible row in the hero.

Preferred automatic/current-location format:

```text
[location icon] Location name
```

Examples:

```text
[location icon] East York
[location icon] Toronto
```

Preferred manual-location format:

```text
Location name
```

Examples:

```text
Toronto
Mississauga
Makkah
```

Rules:

- The location line shows the location used to resolve the displayed Fajr begin and Fajr end times.
- If automatic/current-location mode is active and location services are being used for the resolved location, show the location icon followed by the detected location display name.
- If the user manually selected a location, show the selected location display name without the location icon.
- Do not show the location icon for a manually selected location, because the icon would imply location services/current-location mode.
- Prefer a human-readable neighborhood, locality, or city label. Do not show latitude/longitude in the hero.
- If the detected place has both a neighborhood and city, the data layer should choose the most useful short display name for the user, for example `East York` or `Toronto`.
- If the resolved location is unavailable, use a calm fallback such as `Location unavailable` or `Choose location`, depending on the app state.
- The location line should be preformatted by the data layer.
- The location line uses the same visual font style previously used by the visible date line: same base size, weight, and secondary opacity. Replacing the date with location must not make the top row heavier or larger by default.
- The location icon should scale with the location-line text and remain optically centered with that text.

### 7.2 Date line — temporarily hidden / reserved for future reactivation

The Gregorian + Hijri date line is not visible in v15.

Rules:

- Do not render the date line in the visible hero stack by default.
- Do not reserve blank vertical space for the hidden date line.
- The data layer may continue resolving date values so they are available for future display, detail screens, analytics, or accessibility decisions.
- If the date line is reactivated in a later iteration, use the full Gregorian + full Hijri month-name rules below.

Future preferred format:

```text
Full Gregorian month + day • Full Hijri month + day
```

Future example:

```text
April 29th • Dhul Qadah 12
```

Future date-line rules:

- Use a centered point/bullet delimiter: `•`.
- Do **not** include the weekday in the visible Gregorian date line.
- In English, use a full Gregorian month name plus day, for example `April 29th`.
- The English day may use the app's ordinal style, such as `29th`, when that is already part of the product date style. If the localization system does not support ordinal suffixes cleanly, `April 29` is acceptable.
- Use the full Hijri month name plus day, for example `Dhul Qadah 12`.
- Do **not** use compact Hijri tokens such as `ZQ12` in the hero date line.
- Hijri date should use the app's resolved Hijri/calendar value.
- User-adjusted Hijri dates take priority over automatic or calendar-derived values.
- If Hijri text is unavailable, fall back to Gregorian-only rather than leaving blank space.
- The date line keeps the same visual font style it had in v1/v2/v3: same base size, weight, and secondary opacity.

Canonical English Gregorian month display names:

| Month number | Display name |
|---:|---|
| 1 | January |
| 2 | February |
| 3 | March |
| 4 | April |
| 5 | May |
| 6 | June |
| 7 | July |
| 8 | August |
| 9 | September |
| 10 | October |
| 11 | November |
| 12 | December |

Canonical English Hijri month display names for the hero:

| Hijri month number | Display name |
|---:|---|
| 1 | Muharram |
| 2 | Safar |
| 3 | Rabi al-Awwal |
| 4 | Rabi al-Thani |
| 5 | Jumada al-Awwal |
| 6 | Jumada al-Thani |
| 7 | Rajab |
| 8 | Shaban |
| 9 | Ramadan |
| 10 | Shawwal |
| 11 | Dhul Qadah |
| 12 | Dhul Hijjah |

Spelling rules:

- Normalize source/calendar variations into the display names above for the hero row if and when the date row returns.
- Use `Dhul Qadah`, not compact forms such as `ZQ`, `DhuQ`, or `Zulqada`, in the hero date line.
- Use `Dhul Hijjah`, not `Dhul-Hijjah`, unless a future app-wide transliteration decision deliberately introduces hyphenation.
- Keep these product-display spellings consistent across the hero, accessibility text, and any immediate alarm-editing confirmation copy if the date is surfaced.
- Localized builds may replace these English names with locale-specific month names, but they should still use full month names rather than compact hero tokens.

Future fallback examples:

```text
April 29th
April 29 • Dhul Qadah 12
April 29
```

### 7.3 Relative day label

The relative day label is the second visible row in the hero, directly below the location line.

Preferred examples:

```text
Today
Tomorrow
Monday
Tuesday
```

Rules:

- Use `Today` when the relevant wake/alarm moment is still upcoming today.
- Use `Tomorrow` when today's relevant wake/alarm moment has passed and the next relevant morning is tomorrow.
- Use weekday names only when the target morning is beyond tomorrow.
- The relative label should be preformatted by the data layer.
- The relative label keeps the same visual font style it had in v1 through v3. Moving it below the location line must not reduce its intended prominence.

### 7.4 Primary wake row

The primary wake row is the hero's main content.

Active alarm example:

```text
[alarm icon] 5:43 AM
```

Off state example:

```text
[alarm-off icon] Alarm off
```

No-alarm example:

```text
No alarm set
```

Quiet state example:

```text
[moon icon] Quiet mode
```

Unavailable example:

```text
Wake time unavailable
```

Rules:

- The large primary row should never show a guessed time.
- The alarm icon should scale with text size.
- The icon must not be the only indicator of state; visible text and accessibility text must also describe the state.
- Use monospaced digits for the time where possible.
- AM/PM should be visually smaller than the main digits, vertically centered with the main time digits, and still scale with the user's text setting.
- In `Quiet` mode, the primary row should say exactly `Quiet mode`, with the moon icon when the app's icon set supports it.
- `Quiet mode` is centered in the same primary wake row slot used by active wake times.
- `Quiet mode` uses the same primary-row typography treatment as the active wake time: same optical size family, weight direction, line-height behavior, alignment rules, and dynamic type scaling.
- The primary row container must keep the same settled height across `Pre-Fajr`, `Fajr`, and `Quiet` so the hero does not jump vertically when the mode changes.

### 7.5 Wake-boundary range visual / wake adjuster

The fourth hero row is a compact wake-boundary range visual. When enabled, it is also a direct wake-time adjuster.

The same visual and dynamic behavior is used for default Fajr mornings and early-worship mornings. The only deliberate visual difference is the left boundary marker in early-worship mode: it is a vertical line/tick, not an endpoint circle.

#### 7.5.1 Default / within-Fajr mode

Use this mode for default Fajr mornings when the wake time or planned wake anchor sits inside the Fajr begins → Fajr ends window.

Preferred format:

```text
{fajrBeginTime}  {beginEndpointCircle}━━{draggableAlarmIcon}━━{endEndpointCircle}  {fajrEndTime}
```

Example:

```text
4:43 AM  ●━━━━━━⏰━━●  6:13 AM
```

Default-mode visual rules:

- Show only the two times visibly in this row: Fajr begin time on the left and Fajr end time on the right.
- Do not show visible `Fajr begins` or `Fajr ends` labels in the default hero row.
- The horizontal bar represents the Fajr window from begin to end.
- The beginning of the bar is marked by a visible endpoint circle.
- The end of the bar is marked by a visible endpoint circle.
- The endpoint circles should feel heavier and more intentional than the track, so the user can read them as the Fajr window boundaries.
- The wake/alarm position must be represented by the alarm icon, not by a generic dot, in the active alarm state.
- The alarm icon is positioned relative to the Fajr begin and Fajr end times.
- A position of `0.0` means the wake/alarm is exactly at Fajr begin.
- A position of `1.0` means the wake/alarm is exactly at Fajr end.
- When a resolved active wake time or planned wake anchor exists inside the Fajr window, the position may be represented as `(wakeTime - fajrBeginTime) / (fajrEndTime - fajrBeginTime)`.

#### 7.5.2 Early-worship mode: fasting, Tahajjud, and Other early worship mornings

Use this mode for mornings with selected Pre-Fajr, intended fasting, Ramadan fasting support, Qada/custom fast support, intended Tahajjud-only, or intended Other early worship.

The adjustment range is:

```text
finalThirdStart → Fajr begins
```

Preferred format:

```text
{finalThirdStartTime}  {leftBoundaryLine}━━{draggableAlarmIcon}━━{fajrBeginEndpointCircle}  {fajrBeginTime}
```

Example:

```text
2:16 AM  │━━━━━━⏰━━●  4:43 AM
```

Left-boundary example:

```text
2:16 AM  │⏰━━━━━━●  4:43 AM
```

Early-worship visual rules:

- Show only the two times visibly in this row: final-third start time on the left and Fajr begin time on the right.
- Do not show visible `final third` or `Fajr begins` labels in the compact hero row.
- The horizontal bar represents the early-worship window from final-third start to Fajr begins.
- The left boundary is a vertical line/tick, not a dot and not an endpoint circle.
- The right boundary remains an endpoint circle marking Fajr begins.
- The left vertical line/tick should feel as intentional as the default endpoint circles, but it should be visually distinct so the user can learn that this boundary means the start of the final third rather than the start of Fajr.
- The wake/alarm position must be represented by the alarm icon, not by a generic dot, in the active alarm state.
- A position of `0.0` means the wake/alarm is exactly at the start of the final third of the night.
- A position of `1.0` means the wake/alarm is exactly at Fajr begins.
- When a resolved active wake time or planned wake anchor exists inside the early-worship window, the position may be represented as `(wakeTime - finalThirdStartTime) / (fajrBeginTime - finalThirdStartTime)`.
- The final-third start must come from the domain/resolver layer. The renderer must not calculate it locally.

#### 7.5.3 Shared visual rules

- The renderer may compute the visual ratio from already-resolved times or use a supplied `wakeWindowPositionRatio`, but it must never invent missing wake, Fajr begin, Fajr end, or final-third-start values.
- If no active alarm or planned wake anchor exists, the row may show the boundary times, boundary markers, and track without a draggable alarm icon.
- In `Quiet` quick-select mode, the row should show the relevant Fajr boundary times as a static visual with no alarm icon, no off-state indicator, and no draggable handle.
- If the alarm is off but a planned wake anchor exists inside the supported range, the bar may show a visually distinct alarm-off indicator at the planned anchor position instead of the active alarm icon.
- Fajr begin and Fajr end must use the same resolved data used by the Weekly Fajrcast card.
- Fajr end must come from location-resolved prayer/solar boundary data, not from a renderer-invented offset.
- At large text sizes or narrow widths, the visual may use a measured fallback layout, but the boundary times, boundary meaning, and wake-position meaning must remain available.

Eligibility rules:

- Use `interactiveWithinFajrWindow` when the active wake time or planned wake anchor is inside the Fajr begins → Fajr ends window and the resolved day is not an early-worship morning.
- Use `interactiveEarlyWorshipWindow` when the resolved day has selected `Pre-Fajr`, intended fasting, intended Tahajjud-only, or intended Other early worship and the active wake time or planned wake anchor is inside the final-third start → Fajr begins window.
- Fasting opportunities alone do not activate the early-worship adjuster. The fast must be intended, scheduled, auto-activated by Ramadan support, or otherwise resolved as an intended fasting state.
- If final-third start is unavailable, do not show the early-worship adjuster. Use the app's existing fallback/missing-data behavior and do not invent a final-third boundary.
- If the wake time is outside the supported range for the current mode, do not show the interactive adjuster. Use a future alternate treatment once specified.
- In `Quiet` quick-select mode, use `staticWithinFajrWindow` when Fajr begin and Fajr end are available. The static row shows the Fajr begins → Fajr ends boundary times and endpoint circles, but it does not include an alarm icon and it is not adjustable.
- If Fajr begin or Fajr end is unavailable, do not show the default within-Fajr bar or endpoint circles.
- If the row is hidden because of unavailable data or unsupported timing, do not preserve a blank placeholder row unless needed for a loading skeleton.

Interaction rules:

- When `wakeAdjustmentEnabled` is true, the alarm icon on the bar is draggable.
- Dragging the alarm icon left or right changes the immediate wake time for the target morning.
- In default / within-Fajr mode, the draggable region is Fajr begins → Fajr ends. Dragging beyond the begin endpoint clamps to Fajr begins; dragging beyond the end endpoint clamps to Fajr ends.
- In early-worship mode, the draggable region is final-third start → Fajr begins. Dragging beyond the left boundary clamps to the start of the final third; dragging beyond the right endpoint clamps to Fajr begins.
- While dragging, update the primary wake row live so the large wake time reflects the tentative dragged time.
- While dragging, update the relation/status line live so it reflects the tentative dragged time.
- In default / within-Fajr mode, ordinary non-endpoint positions use `Wake up {X} min before Fajr ends`; the left endpoint uses `Wake up as Fajr begins`; the right endpoint uses `Wake up as Fajr ends`.
- In early-worship mode, ordinary non-endpoint positions use `Wake up {X} min before Fajr begins`; the left endpoint uses `Wake up for the last third of the night`; the right endpoint uses `Wake up as Fajr begins`.
- The relation/status line must follow the mode-aware patterns in Section 7.6. Apply red text only when the wake time is 14 min or less before Fajr ends.
- The location line and relative day label do not change during this drag.
- The hidden date line does not appear during this drag.
- On release, commit the updated wake time according to the app's wake-time persistence policy.
- If the app uses commit-on-release, the visible hero may show transient local values while dragging and then reconcile with the saved snapshot after persistence succeeds.
- If persistence fails, restore the previous wake time and show the app's standard non-disruptive error treatment.
- The visual hit target for the draggable alarm icon should be at least 44 px/pt even if the rendered glyph is smaller.
- Touch feedback should feel calm and precise; use reduced-motion behavior when required by system settings.
- Selector-triggered changes between `Pre-Fajr`, `Fajr`, and `Quiet` are not treated as abrupt data swaps. They must follow the quick-mode transition rules in Section 7.8.

Allowed fallback layout when the one-line visual cannot fit:

```text
4:43 AM        6:13 AM
●━━━━━━⏰━━●
```

Early-worship fallback layout:

```text
2:16 AM        4:43 AM
│━━━━━━⏰━━●
```

Accessibility text for the default row must still expose the full meaning:

```text
Fajr begins at 4:43 AM. Fajr ends at 6:13 AM. Wake up 30 min before Fajr ends.
```

Accessibility text for the early-worship row must expose the final-third meaning:

```text
Final third of the night begins at 2:16 AM. Fajr begins at 4:43 AM. Wake up 30 min before Fajr begins.
```

When the default row is interactive, expose it as an adjustable wake-time control:

```text
Wake alarm at 5:43 AM. Wake up 30 min before Fajr ends. Adjustable between Fajr begin and Fajr end.
```

When the early-worship row is interactive, expose it as an adjustable wake-time control:

```text
Wake alarm at 4:13 AM. Wake up 30 min before Fajr begins. Adjustable between the final third of the night and Fajr begins.
```

### 7.6 Wake relation/status line

The relation/status line is the final informational text row in the v15 hero. The quick wake-state selector sits below it.

When the wake-boundary visual is eligible, the relation/status line sits below the visual. When the visual is hidden because of unavailable data or unsupported timing, the relation/status line sits below the primary wake row. In both cases, the quick wake-state selector remains below the relation/status line when available.

Its visual font style and sizing should match the location line exactly: same base size, weight, line-height behavior, and dynamic text scaling. The relation/status line normally uses the same secondary opacity treatment as the location line. Red is reserved only for the urgent end-of-Fajr warning state defined below. It should also continue to match the hidden/reserved date-line style for future consistency.

#### 7.6.1 Default / within-Fajr relation patterns

Default non-endpoint pattern:

```text
Wake up {X} min before Fajr ends
```

Exact endpoint patterns:

```text
Wake up as Fajr begins
Wake up as Fajr ends
```

Examples:

```text
Wake up 30 min before Fajr ends
Wake up 28 min before Fajr ends
Wake up as Fajr begins
Wake up as Fajr ends
```

Default / within-Fajr rules:

- For any active wake time, default wake time, or user-adjusted wake time inside the Fajr begins → Fajr ends window that is not exactly equal to Fajr begin or Fajr end, use: `Wake up {X} min before Fajr ends`.
- If the wake adjuster is placed exactly at Fajr begin, the visible relation/status line must say exactly: `Wake up as Fajr begins`.
- If the wake adjuster is placed exactly at Fajr end, the visible relation/status line must say exactly: `Wake up as Fajr ends`.
- The exact endpoint copy applies both while the user is dragging and after release if the endpoint wake time is saved.
- For the default non-endpoint pattern, `X` is the whole-minute difference between the current wake time and the resolved Fajr end time for the target morning.
- Do not show `Wake up 0 min before Fajr ends`; use `Wake up as Fajr ends` instead.

#### 7.6.2 Early-worship relation patterns

Early-worship non-endpoint pattern:

```text
Wake up {X} min before Fajr begins
```

Early-worship endpoint patterns:

```text
Wake up for the last third of the night
Wake up as Fajr begins
```

Examples:

```text
Wake up 45 min before Fajr begins
Wake up 30 min before Fajr begins
Wake up for the last third of the night
Wake up as Fajr begins
```

Early-worship rules:

- Use these patterns only when the resolved day has selected `Pre-Fajr`, intended fasting, intended Tahajjud-only, or intended Other early worship and the active wake time is inside the final-third start → Fajr begins window.
- For non-endpoint early-worship positions, `X` is the whole-minute difference between the current wake time and the resolved Fajr begin time for the target morning.
- If the early-worship adjuster is dragged all the way left and clamped to the final-third start, the visible relation/status line must say exactly: `Wake up for the last third of the night`.
- If the early-worship adjuster is dragged all the way right and clamped to Fajr begins, the visible relation/status line must say exactly: `Wake up as Fajr begins`.
- Do not show `Wake up 0 min before Fajr begins`; use `Wake up as Fajr begins` instead.
- Do not show a relation to Fajr ends for early-worship positions unless the day is actually using the default / within-Fajr mode.

#### 7.6.3 Quiet relation pattern

Quiet pattern:

```text
No alarm will ring for {relative day}
```

Examples:

```text
No alarm will ring for tomorrow
```

Quiet rules:

- Use this pattern when `selectedQuickWakeMode = quiet` or when the resolved wake state is `quietHours` for the target morning.
- The primary wake row should say exactly `Quiet mode`.
- The wake-boundary range visual should remain static when Fajr begin/end data is available, with no alarm icon and no drag interaction.
- Do not show `Wake up {X} min...` copy when the selected quick mode is `Quiet`, because no wake alarm is active.

#### 7.6.4 Relation/status-line transition rules

Mode changes must not make this line feel chaotic.

Required behavior:

- The relation/status line uses a stable row frame.
- When the text changes because the user selects `Pre-Fajr`, `Fajr`, or `Quiet`, change the line with a restrained fade-through or direct text content transition.
- Do not animate this text from the left, right, top, or bottom.
- Do not pair this line with a directional slide, even when the adjuster marker uses directional motion.
- Do not let the line's row height collapse or expand during ordinary `Pre-Fajr`, `Fajr`, and `Quiet` transitions.
- Recommended transition timing: **120–180 ms** for the outgoing/incoming text opacity change.
- The incoming text should settle in the exact same baseline position as the outgoing text.
- During active user dragging of the alarm icon, this line may update live from the tentative dragged time, but those live drag updates should still stay in place rather than sliding.

#### 7.6.5 Shared relation/status-line rules

- Determine endpoint equality after applying the app's alarm-minute granularity, clamping, and rounding rules.
- Apply red text only when the wake time is 14 min or less before Fajr ends. Use the app's semantic red/critical text token rather than an arbitrary hardcoded red when such a token exists.
- Compute the warning threshold from the same rounded whole-minute value used for display: `minutesBeforeFajrEnd = resolvedFajrEnd - wakeTime`, after applying the app's alarm-minute granularity, clamping, and rounding rules.
- This red treatment is an urgency warning for a short wake-to-wudhu-to-prayer window. It applies to `Wake up 14 min before Fajr ends`, any smaller whole-minute value, and `Wake up as Fajr ends`.
- Do not apply red merely because the wake adjuster is at an endpoint. `Wake up as Fajr begins` and `Wake up for the last third of the night` use the normal relation/status-line treatment unless the resolved wake time is also 14 min or less before Fajr ends.
- Do not apply red to `Quiet` state copy because there is no active wake alarm to warn about.
- Red is a color override only. The relation/status text keeps the same base size, weight, line-height behavior, and dynamic text scaling as the location line.
- Do not show any custom-wake phrasing in the hero.
- Use compact minute wording in minute-based patterns: `min`, not `minutes`.
- Do not use alternate active-wake phrases that break the approved patterns.
- Do not use `before Fajr begins` for ordinary/default within-Fajr mode. That wording is reserved for early-worship mode.
- Relation/status text should be precomposed by the data layer when possible. During an active drag, the renderer may recalculate the temporary relation/status text from the tentative wake time and the resolved boundary values for the active mode.
- If no active alarm exists, this line should describe the wake state instead of pretending there is a relation.
- Do not style this line as a larger title or label; it must use the same visual style and sizing as the location line, with the red color exception only for the urgent `14 min or less before Fajr ends` state.
- During an active drag of the wake-boundary alarm icon, this line updates live and remains below the visual.

No-alarm examples:

```text
No wake alarm is set for tomorrow
Alarm is off for this date
Quiet hours are active
```

### 7.7 Quick wake-state selector

The quick wake-state selector lets the user quickly choose the target morning's main wake mode without opening a deeper editor.

Preferred visual form:

```text
[ Suhoor | Fajr | Quiet ]
```

Required segment order:

```text
Pre-Fajr   Fajr   Quiet
```

Rules:

- Use a single segmented pill with a liquid-glass treatment.
- The pill contains three equal logical segments: `Pre-Fajr`, `Fajr`, and `Quiet`.
- `Pre-Fajr` is on the left.
- `Fajr` is in the center.
- `Quiet` is on the right.
- The selected segment must be visually clear through shape, fill/material emphasis, weight, or inset highlight.
- The selected segment must not be indicated by color alone.
- The control should remain visually calm and should not look like three unrelated floating chips.
- The control is interactive and must meet the platform minimum touch-target guidance; each segment should expose at least a 44 px/pt effective hit target.
- Labels should scale with the same seven-stop dynamic text model as the rest of the hero.
- At large text sizes, allow the segmented pill to grow vertically or horizontally within the measured hero layout rather than clipping labels.
- Do not hide the quick wake-state selector merely because the wake-boundary visual is unavailable; hide or disable individual segments only when the app cannot truthfully perform the state change.

Visual aesthetic rules remain unchanged from v12: the selector must match the translucent, premium liquid-glass language used by the Weekly Fajrcast card and the Next 7 Mornings card, and it must not use a separate opaque gray segmented-control style.

Selection behavior:

| Selected segment | Meaning | Default wake effect | Hero visual effect |
|---|---|---|---|
| `Pre-Fajr` | The user wants a wake before Fajr begins. | Set active wake to 30 min before Fajr begins. | Use early-worship mode when final-third start and Fajr begin are available. |
| `Fajr` | Ordinary/default Fajr wake state. | Set active wake to 30 min before Fajr ends. | Use default within-Fajr mode when Fajr begin and Fajr end are available. |
| `Quiet` | No wake alarm should ring for the target morning. | Remove/suppress the active wake alarm. | Show a static Fajr begin → Fajr end visual with no alarm icon and no drag handle when Fajr data is available. |

Detailed rules:

- `Fajr` is selected by default for ordinary non-Ramadan mornings when the target morning has no stronger explicit user state and no quiet state.
- Ramadan mornings default to `Pre-Fajr`.
- Selecting `Pre-Fajr` sets the default wake to 30 min before Fajr begins.
- Outside Ramadan, selecting `Pre-Fajr` defaults the Pre-Fajr intention to `Tahajjud only`.
- Outside Ramadan, the user may change the Pre-Fajr intention to `Fasting` when fasting is available, or to `Other early worship` for a non-fasting pre-Fajr wake that is not represented by `Tahajjud only`.
- On Eid days, fasting is unavailable and selecting `Pre-Fajr` defaults to `Tahajjud only`; `Other early worship` may remain available as a non-fasting early-worship reason only if product-approved for that context.
- During Ramadan, selecting `Pre-Fajr` restores locked `Fasting` + `Ramadan fast`; `Tahajjud only` and `Other early worship` are not selectable while Ramadan owns the Pre-Fajr intention.
- Selecting `Fajr` clears the active Pre-Fajr wake mode for the target morning unless another explicit calendar-locked state owns that day; the previously selected Pre-Fajr intention is preserved for restoration when allowed, but active manual wake-time adjustment is cleared.
- Selecting `Fajr` sets the default wake to 30 min before Fajr ends.
- The default `Fajr` relation/status line is `Wake up 30 min before Fajr ends`.
- Selecting `Quiet` suppresses the target morning's active wake alarm by user choice; permission failure, platform delivery failure, missing pending delivery, or degraded reliability must not be shown as Quiet.
- The `Quiet` primary row should say exactly `Quiet mode`.
- `Quiet mode` must occupy the same primary row slot used by the large wake time so the hero does not move vertically when Quiet is selected.
- The `Quiet` relation/status line should use the exact pattern `No alarm will ring for {relative day}`.
- In `Quiet`, the range visual is static and non-interactive. It may show Fajr begin/end boundary times and endpoint circles, but it must not show a draggable alarm icon.
- Dragging an interactive adjuster after choosing `Pre-Fajr` or `Fajr` preserves the selected quick mode and changes only the wake time within that mode's allowed range.
- Manual wake-time adjustments are not preserved when the user switches modes. Switching modes returns to the selected mode’s default wake anchor unless the user adjusts again.
- Quick wake-state selector changes must go through the Quick Wake Mode and Intent Mutation Contract and the shared wake-state / alarm-state resolver. The hero view emits an intent and receives an updated snapshot; it must not directly create, cancel, verify, or schedule platform alarms.
- If persistence or downstream delivery refresh fails after a quick-select change, preserve the canonical user intent where appropriate and use the app's standard non-disruptive error treatment. Delivery failure must not rewrite the selected mode to Quiet.

#### 7.7.1 Pre-Fajr intention controls

When `Pre-Fajr` is selected, the Home hero shows a compact intention control.

Allowed intentions:

```text
Tahajjud only | Fasting | Other early worship
```

Default outside Ramadan:

```text
Tahajjud only
```

Rules:

- Show or expose the Pre-Fajr intention control only when `Pre-Fajr` is selected.
- Hide the Pre-Fajr intention control when `Fajr` or `Quiet` is selected, while preserving the last selected Pre-Fajr intention for the target morning through the shared mutation contract.
- During Ramadan, the intention control is locked to `Fasting` or hidden with clear locked Ramadan state; the user cannot change it to `Tahajjud only` or `Other early worship` while the selected mode is Ramadan `Pre-Fajr`.
- On Eid days, `Fasting` is unavailable and the control resolves to `Tahajjud only` unless a product-approved non-fasting `Other early worship` path is explicitly available.
- Include `Other early worship` as a preserved Pre-Fajr intention. It may be displayed as a third segment, a compact overflow choice, or a detail affordance if narrow-width constraints require it, but it must not be silently dropped, stored as `Other fast`, or coerced to `Tahajjud only`.
- Do not persist, announce, or analyze unqualified `Other`; if a compact visible `Other` label is used for space, it must map unambiguously to `Other early worship`.
- Do not include `Fasting + Tahajjud` as a combined Home hero intention.

#### 7.7.2 Fasting-intention behavior in the Home hero

When the user selects `Pre-Fajr` + `Fasting`, show the fasting intention state. When the user selects `Pre-Fajr` + `Other early worship`, do not show the fasting-intention state because the selected Pre-Fajr intention is non-fasting.

Default behavior outside Ramadan:

- If the day has one opportunity, use that opportunity.
- If the day has multiple compatible opportunities, use the full compatible opportunity set.
- If the day is Monday or Thursday and that opportunity is active, the fasting intention is Monday/Thursday Sunnah fast.
- If the day is both a White Day and Monday/Thursday, the fasting intention includes both opportunities.
- If the day is eligible for Shawwal Six, the fasting intention defaults to Shawwal Sunnah fast.
- If no specific opportunity exists, default to `Voluntary fast`.

Examples:

```text
Fasting intention: [Monday fast]
Fasting intention: [White Days fast] [Monday fast]
Fasting intention: [Shawwal Six fast]
Fasting intention: [Voluntary fast]
```

The user may override the fasting intention on non-Ramadan days where fasting is available, using the app’s canonical fasting-intention taxonomy.

During Ramadan:

```text
Fasting intention: [Ramadan fast]
```

Rules:

- Ramadan fasting intention is locked.
- No non-Ramadan opportunities appear as alternatives during Ramadan.
- The user may switch out of `Pre-Fajr` into `Fajr` or `Quiet`.
- If the user returns to `Pre-Fajr`, the hero restores `Fasting` + `Ramadan fast`.

Accessibility rules:

- Expose the segmented control as a group named `Wake mode` or equivalent.
- Each segment must expose selected/unselected state.
- Suggested labels: `Pre-Fajr, selected`, `Fajr, selected`, `Quiet, selected`.
- The `Pre-Fajr` action should announce that it wakes 30 min before Fajr begins.
- The `Fajr` action should announce that it wakes 30 min before Fajr ends.
- The `Quiet` action should announce that no wake alarm will ring for the target morning.
- The selected Pre-Fajr intention should also be reflected in the hero accessibility summary when `Pre-Fajr` is selected.

### 7.8 Quick-mode transition and animation rules

Quick-mode changes affect both state and presentation. The animation should make the selected state feel smooth and intentional, but it must not make the hero feel chaotic.

The currently approved behavior is the selector movement inside the `Suhoor | Fajr | Quiet` container. Preserve that sliding selected-state behavior. The refinements below constrain the rest of the hero so text, time, and adjuster transitions stay stable and understandable.

#### 7.8.1 General transition principles

- Animate visible changes caused by selecting `Pre-Fajr`, `Fajr`, or `Quiet`, but use the correct animation type for each row.
- Do not animate the location line or relative day label unless their resolved values actually change.
- Do not move the entire hero stack upward, downward, left, or right merely because the selected mode changed.
- Keep row frames stable across ordinary `Pre-Fajr`, `Fajr`, and `Quiet` transitions.
- The primary wake row, wake-boundary visual row, relation/status line, and selector row should keep their vertical positions during mode changes.
- Do not let any row enter from offscreen or from a different side of the hero during a mode change.
- Use the larger of the outgoing and incoming measured row heights during the transition, and keep the settled row heights visually consistent across normal `Pre-Fajr`, `Fajr`, and `Quiet` states.
- If a genuinely unavailable-data fallback requires a shorter layout, use a gentle opacity transition and measured layout change. Do not let ordinary mode changes trigger that fallback collapse.
- Do not invent prayer times, final-third boundaries, wake times, or marker positions for the sake of animation. Animate only between the current resolved snapshot and the next resolved or safely previewable snapshot.
- Motion is feedback, not meaning. Text, selected state, accessible labels, and resolved data must still communicate the final state.

Recommended duration family:

| Element | Preferred duration | Max ordinary duration |
|---|---:|---:|
| Selector highlight glide | 180–240 ms | 280 ms |
| Relation/status line fade-through | 120–180 ms | 220 ms |
| Primary time numeric roll | 260–360 ms | 420 ms |
| Adjuster marker handoff | 320–420 ms | 480 ms |
| Quiet crossfade | 180–260 ms | 320 ms |

Use calm ease-in-out or restrained spring curves. Avoid bounce, overshoot, elastic movement, or sequential delays that make the hero feel busy.

#### 7.8.2 Selector animation

The segmented pill should use a single moving selected-state treatment rather than three disconnected button redraws.

This behavior is approved and should be preserved.

Required behavior:

- On tap, the selected segment highlight glides or morphs to the newly selected segment.
- The pill container itself remains stationary and keeps the same overall width and height during the change.
- Label emphasis transitions with the highlight: selected label becomes slightly stronger while the previous label returns to the unselected treatment.
- The movement should feel smooth but quick; target about **180–240 ms** for the selected highlight movement.
- Use a restrained spring or ease-out curve with little or no bounce.
- The selector may show immediate pressed feedback before the resolver returns, but the committed selected state must reconcile to the resolver's returned snapshot.
- If the resolver rejects or fails the state change, animate back to the previous selected segment and use the app's standard non-disruptive error treatment.

#### 7.8.3 Relation/status-line animation

The relation/status line sits directly above the quick wake-state selector. Its animation must be stable and non-directional.

Required behavior:

- Use a fade-through, crossfade, or native content transition that keeps the text in the same row position.
- Do not slide this text in from the left, right, top, or bottom.
- Do not use different directions for different mode changes.
- Do not let the line appear from below when switching into or out of `Quiet`.
- Keep the same text baseline and row box before, during, and after the transition.
- Recommended timing: **120–180 ms**.
- The line may update after the primary time roll starts, but it should not stream through every intermediate minute during a mode change.
- During active user dragging of the alarm icon, the line may update live from the tentative dragged time; this is separate from quick-mode transition animation and should still avoid directional slide effects.

Approved examples:

```text
Wake up 30 min before Fajr ends
```

fades into:

```text
Wake up 30 min before Fajr begins
```

or:

```text
No alarm will ring for tomorrow
```

without moving laterally or vertically.

#### 7.8.4 Primary wake-row animation

The primary wake row has two different animation behaviors depending on the target state.

##### Active wake time to active wake time: `Fajr ↔ Pre-Fajr`

When switching between `Fajr` and `Pre-Fajr`, animate the visible time itself rather than replacing it with a simple fade.

Required behavior:

- Keep the primary row box fixed in place.
- Keep the alarm icon and AM/PM marker optically centered with the large time digits.
- Animate the main time digits as a rapid monotonic minute roll from the old wake time to the new wake time.
- When moving from `Fajr` to `Pre-Fajr`, the time rolls earlier/downward in clock time.
- When moving from `Pre-Fajr` to `Fajr`, the time rolls later/upward in clock time.
- The displayed sequence must never move in the wrong temporal direction.
- The final displayed time must land exactly on the resolver's returned wake time.
- Use monospaced digits where possible to avoid width jitter during the roll.
- The AM/PM marker stays in the same visual slot. If the transition crosses AM/PM, fade or content-transition the suffix in place; do not slide it.
- The alarm icon remains in the same primary-row slot during the numeric time roll; the wake-boundary row handles the marker-travel animation separately.
- Recommended duration: **260–360 ms**. The animation should feel quick enough that the user reads it as a state change, not as a slow countdown timer.
- If the minute distance is large, the renderer may skip intermediate minute values to preserve timing. Skipped values must still preserve monotonic direction and avoid random-looking jumps.

Example:

```text
5:40 AM → 4:09 AM
```

should feel like a rapid backward roll through earlier times until it lands on `4:09 AM`.

Example:

```text
4:09 AM → 5:40 AM
```

should feel like a rapid forward roll through later times until it lands on `5:40 AM`.

##### Active wake time to Quiet, or Quiet to active wake time

When switching into or out of `Quiet`, do not use a numeric roll.

Required behavior when entering `Quiet`:

- Crossfade the active wake time row into `[moon icon] Quiet mode`.
- Keep the primary row slot the same height as the active wake-time row.
- `Quiet mode` is centered in the row and uses the same primary-row typography treatment as the time.
- Do not move the location line, relative day label, range visual, relation/status line, selector, or next card.
- Recommended duration: **180–260 ms**.

Required behavior when leaving `Quiet`:

- Crossfade `[moon icon] Quiet mode` into the resolved active wake time.
- Keep the primary row slot fixed.
- Do not roll from a nonexistent quiet time. The numeric roll applies only between two active wake times.
- Recommended duration: **180–260 ms**.

#### 7.8.5 Wake-boundary visual animation

The wake-boundary row must not enter the screen from the left or right during ordinary quick-mode changes.

Required behavior for all mode transitions:

- The wake-boundary row frame remains fixed in place.
- The horizontal track remains visually anchored in the same row position.
- The row's left and right boundary time labels do not slide. They crossfade or content-transition in place.
- Both boundary time labels should transition at the same time so the row does not appear to rebuild from one side.
- Endpoint markers and the left early-worship line/tick morph or crossfade in place.
- The entire row must not translate, page, or sweep into the screen.
- The alarm icon is the only element that should visibly travel along the track during `Fajr ↔ Pre-Fajr` transitions.
- If no alarm icon exists because `Quiet` is selected, the row remains as a static Fajr begins → Fajr ends visual with no drag handle.

##### `Fajr → Pre-Fajr` adjuster marker handoff

Moving from `Fajr` to `Pre-Fajr` means the user is choosing an earlier wake. The motion should read as moving earlier in time.

Required behavior:

1. Start from the within-Fajr row: `Fajr begins → Fajr ends`.
2. Keep the track row anchored. Do not slide the full adjuster asset.
3. Move the outgoing alarm icon leftward along the current track until it reaches the left boundary / Fajr-begins handoff point.
4. Fade the outgoing alarm icon out as it reaches that left boundary.
5. Crossfade the boundary time labels from `{fajrBeginTime} / {fajrEndTime}` to `{finalThirdStartTime} / {fajrBeginTime}` in place.
6. Morph or crossfade the left boundary marker from endpoint circle to vertical line/tick in place.
7. Fade the incoming alarm icon in at or near the right endpoint of the early-worship track, because that endpoint is Fajr begins.
8. Move the incoming alarm icon leftward from the right endpoint to the resolved Pre-Fajr wake position, normally 30 min before Fajr begins.
9. End with the early-worship row: `final-third start → Fajr begins`.

The user should understand that the wake moved earlier: the outgoing icon exits left from the Fajr window, then the incoming icon appears near Fajr begins and settles leftward in the early-worship window.

##### `Pre-Fajr → Fajr` adjuster marker handoff

Moving from `Pre-Fajr` to `Fajr` means the user is choosing a later wake. The motion should read as moving forward in time.

Required behavior:

1. Start from the early-worship row: `final-third start → Fajr begins`.
2. Keep the track row anchored. Do not slide the full adjuster asset.
3. Move the outgoing alarm icon rightward along the current track until it reaches the right boundary / Fajr-begins handoff point.
4. Fade the outgoing alarm icon out as it reaches that right boundary.
5. Crossfade the boundary time labels from `{finalThirdStartTime} / {fajrBeginTime}` to `{fajrBeginTime} / {fajrEndTime}` in place.
6. Morph or crossfade the left boundary marker from vertical line/tick to endpoint circle in place.
7. Fade the incoming alarm icon in at or near the left endpoint of the within-Fajr track, because that endpoint is Fajr begins.
8. Move the incoming alarm icon rightward from the left endpoint to the resolved Fajr wake position, normally 30 min before Fajr ends.
9. End with the within-Fajr row: `Fajr begins → Fajr ends`.

The user should understand that the wake moved later: the outgoing icon exits right from the early-worship window, then the incoming icon appears at Fajr begins and settles rightward in the Fajr window.

##### Transitions to `Quiet`

Required behavior when switching from `Fajr` or `Pre-Fajr` to `Quiet`:

- Keep the wake-boundary row in the same vertical position.
- Fade the active alarm icon out. Do not animate a draggable icon after the state is quiet.
- Crossfade the boundary labels to the static Fajr begins → Fajr ends labels when Fajr data is available.
- Show the endpoint circles for the static Fajr begins → Fajr ends row.
- Remove drag affordance and hit-target behavior after the transition completes.
- Do not slide the full row into place.
- Do not collapse the row's height.

Required behavior when switching from `Quiet` to `Fajr` or `Pre-Fajr`:

- Keep the wake-boundary row in the same vertical position.
- Crossfade the static labels to the active mode's boundary labels.
- Fade in the alarm icon at the resolved default or saved wake position for the selected mode.
- Restore drag affordance only when the resolved mode supports adjustment and the required times are available.
- Do not slide the full row into place.

#### 7.8.6 Quiet-mode layout rule

`Quiet` is a state change, not a layout collapse.

Required behavior:

- The primary row says exactly `[moon icon] Quiet mode`.
- The primary row remains in the same vertical slot used by the wake time.
- The primary row uses the same primary typography treatment as the wake time.
- The primary row container height must not become vertically shorter than the active wake-time row.
- The wake-boundary row remains visible as a static Fajr begins → Fajr ends visual when Fajr data is available.
- The relation/status line remains in the same vertical slot and crossfades to `No alarm will ring for {relative day}`.
- The quick selector remains in the same vertical slot and uses the approved selected-highlight glide.
- The hero stack must not jump upward or downward when entering or leaving `Quiet`.

Implementation guidance:

- Use fixed-or-measured stable row slots for ordinary mode transitions: primary row, wake-boundary row, relation/status row, selector row.
- Measure active wake and quiet primary-row content, then use the larger ordinary-mode row height for both.
- Do not base the primary-row height solely on the natural height of `Quiet mode`, because that will make the hero visually shrink.
- If platform layout recalculates after the resolver snapshot returns, hold the previous measured transition frame until the animation completes.

#### 7.8.7 Reduced motion

When Reduce Motion is enabled:

- Replace marker travel and numeric time rolling with short crossfades or direct content updates.
- Keep the selector highlight movement minimal or use a fade between selected states.
- Preserve layout stability rules, especially the no-jump rule for `Quiet`.
- Keep transition duration at or below **150 ms** when motion is reduced.
- Do not remove state feedback; only reduce physical movement.

## 8. Home surface supporting-card behavior

This hero revision also locks the immediate Home-surface relationship to the supporting cards.

### Next 7 Mornings

- `Next 7 Mornings` appears collapsed by default below the hero.
- The `NEXT 7 MORNINGS` header remains visible in the collapsed state.
- The user can expand the card to reveal seven rows.
- The seven rows are the same dates as Weekly Fajrcast, in the same order.
- Expanding or collapsing the card is a UI interaction only; it does not change wake state, intention, alarm scheduling, or date-specific overrides.

### Weekly Fajrcast

- Weekly Fajrcast remains a separate chart card.
- Weekly Fajrcast is not collapsed by this revision.
- Weekly Fajrcast uses the same seven visible dates as Next 7 Mornings.
- This revision does not remove the current Weekly Fajrcast inspection interaction.


## 9. Visual direction

The hero should feel:

```text
calm
premium
centered
immediate
uncluttered
```

It sits directly on the atmospheric background, not inside a visible glass card.

Recommended visual behavior:

- Center align all hero text and visual rows.
- Keep the hero visually lighter than a full card but stronger than secondary forecast content.
- Use white foreground text.
- Use opacity and scale to create hierarchy.
- Do not introduce heavy dividers, boxes, chips, or badges around the informational rows.
- Use one deliberate translucent liquid-glass segmented pill only for the `Suhoor | Fajr | Quiet` quick wake-state selector.
- The selector must feel glassy and integrated with the background, matching the Next 7 Mornings card surface language rather than an opaque or frosted gray segmented-control treatment.
- Keep special context wording text-based rather than chip-heavy.
- The top row should read as location context, not as a new title or header.

Suggested hierarchy:

1. Primary wake time or primary wake state: strongest.
2. Relative day label: strong.
3. Wake-boundary range visual / wake adjuster: functional and readable when eligible.
4. Location line: secondary but important context for the shown prayer times.
5. Wake relation/status line: explanatory text, same visual style as the location line / hidden date-line style.
6. Quick wake-state selector: final compact control row, visually restrained but clearly tappable.

The hidden date row should not create visual space or leave the top of the hero feeling like something is missing.

## 10. Base typography at text stop 4

Stop 4 is the default design baseline.

| Element | Base size | Weight / behavior |
|---|---:|---|
| Location line | 17 | regular, secondary opacity; first visible row |
| Location icon | visual token | scales with location line; shown only for automatic/current-location mode |
| Hidden/reserved date line | 17 | regular, secondary opacity; not visible in v15 |
| Relative day label | 28 | regular or medium; second visible row |
| Alarm icon | 22 | scales with primary row; vertically centered with time digits |
| Wake time main digits | 68 | light/regular, monospaced digits preferred |
| Wake time suffix | 28 | regular, vertically centered with time digits |
| Wake state text, e.g. `Alarm off` | 44 | regular/medium |
| Quiet primary text, e.g. `[moon icon] Quiet mode` | primary wake row token | same optical typography treatment as the wake time; centered in the primary row slot |
| Boundary time labels | 15 | regular, monospaced digits preferred |
| Wake-boundary range bar track | visual token | subtle horizontal track; measured with the row |
| Wake-boundary endpoint markers | visual token | visible boundary markers; default mode uses two endpoint circles, early-worship mode uses a left vertical line and right endpoint circle |
| Wake-boundary wake indicator | visual token | alarm icon marker positioned on the bar; draggable when enabled |
| Relation/status line | 17 | same font style and sizing as location line / hidden date line: regular, secondary opacity; final informational text row; red only when wake time is 14 min or less before Fajr ends |
| Quick wake-state selector labels | 15 | regular or medium; segmented pill labels; selected segment may use slightly stronger weight |
| Quick wake-state selector pill | visual token | same liquid-glass surface family as the Next 7 Mornings card; three equal logical segments; selected highlight moves smoothly; 44 px/pt effective hit target per segment |

Opacity guidance:

| Element | Suggested opacity |
|---|---:|
| Location line | 70–80% |
| Location icon | match location line; do not overpower text |
| Hidden/reserved date line | 70–80% if reactivated later |
| Relative day label | 100% |
| Primary wake row | 100% |
| Boundary time labels | 85–95% |
| Wake-boundary range bar track | subtle, visually quieter than text |
| Wake-boundary endpoint markers | stronger than the track; readable as boundaries |
| Wake-boundary wake indicator | strongest visual in the range row; readable as the wake/alarm position |
| Relation/status line | 70–80%, matching the location line / hidden date-line style; use semantic red only when wake time is 14 min or less before Fajr ends |
| Quick wake-state selector | translucent readable glass treatment; no opaque gray slab; selected segment visibly stronger than unselected segments without relying on color alone |

The wake-boundary range visual should not be so faint that it feels decorative. It is functional information, and when enabled it is also an adjustment control. The quick wake-state selector is also functional and must remain readable and tappable at every text-size stop.

## 11. Seven-stop dynamic text guardrails

Use the same overall approach as the Weekly Fajrcast card: **dynamic measured layout with seven-stop guardrails**. Text sizes scale from the base typography tokens, but real measured text wins over fixed dimensions.

Map the seven standard iPhone text-size stops like this:

| Text stop | iOS-style category | Approx scale from base | Min hero region height | Min content stack height | Min bottom gap before next card |
|---:|---|---:|---:|---:|---:|
| 1 | extra small | 0.88× | 294 | 194 | 28 |
| 2 | small | 0.94× | 302 | 204 | 30 |
| 3 | medium | 0.98× | 310 | 212 | 32 |
| 4 | default / large | 1.00× | 320 | 222 | 36 |
| 5 | extra large | 1.08× | 346 | 250 | 38 |
| 6 | extra extra large | 1.17× | 382 | 286 | 42 |
| 7 | extra extra extra large | 1.28× | 426 | 328 | 46 |

Definitions:

- **Hero region height** is the vertical area reserved for the hero between the upper safe-area/header area and the next card.
- **Content stack height** is the measured height of the visible location line, relative label, primary wake row, optional wake-boundary range visual / wake adjuster, relation/status line, quick wake-state selector, and row gaps.
- **Bottom gap before next card** is the minimum breathing room between the quick wake-state selector and the top of the Weekly Fajrcast card.

Rules:

- The hero region height is `max(stopMinimumHeroRegionHeight, measuredContentStackHeight + measuredTopAndBottomBreathing)`.
- The content stack height is measured, not hardcoded.
- The next card should move down when text grows.
- Do not preserve unused blank space if the content does not need it.
- Do not reserve vertical space for the hidden date row.
- Do not reintroduce the reduced relative-label-to-primary-row gap as extra padding above or below the hero.
- Do not clip the wake-boundary range visual or quick wake-state selector to keep the screen compact.
- Do not freeze the boundary time labels, location line, relation/status line, quick wake-state selector labels, or hidden/reserved date line at a tiny fixed size while the wake time scales.
- During quick-mode transitions, preserve a stable measured transition frame so the hero does not jump vertically between `Pre-Fajr`, `Fajr`, and `Quiet`.
- For accessibility text sizes beyond these seven stops, continue the measured-growth model rather than compressing the hero.

## 12. Spacing rules

At stop 4, use these baseline gaps:

| Gap | Stop 4 target |
|---|---:|
| Location line to relative label | 4 |
| Relative label to primary wake row | 11 |
| Primary wake row to wake-boundary range visual / wake adjuster | 8 |
| Wake-boundary range visual / wake adjuster to relation/status line | 12 |
| Relation/status line to quick wake-state selector | 14 |
| Quick wake-state selector to next card | 36 minimum |

Dynamic behavior:

- The hidden date row must not add a gap, placeholder, or spacer.
- The relative-label-to-primary-wake-row gap should remain roughly half of the earlier 22 px/pt treatment.
- Smaller stops may reduce that gap to about 9–10 px/pt, but the hero should not feel cramped.
- Larger stops may grow that gap only as needed for readable scaled text; do not return to the old 22 px/pt gap unless measured typography genuinely requires it.
- If text becomes tight, grow the hero region before collapsing the relationship between lines.
- The primary wake row should remain optically centered even with the alarm icon.
- The wake-boundary range visual should remain close enough to the primary wake row to read as the wake-time position, not as a separate card or chart.
- The relation/status line should remain close enough to the wake-boundary range visual to read as the textual explanation of that visual.
- The quick wake-state selector should sit below the relation/status line as a separate interactive control, not as part of the relation sentence.
- Switching to or from `Quiet` must not change the vertical position of the location line, relative day label, primary row slot, range visual row, relation/status line, or selector.
- When the wake-boundary range visual is hidden because required data is unavailable or the wake time is outside the supported range, the relation/status line sits beneath the primary wake row; do not preserve the missing visual row as blank space. The quick wake-state selector remains below the relation/status line when available.

## 13. Primary row alignment rule

The primary row should be centered as one visual group:

```text
[icon] [time digits] [AM/PM]
```

Rules:

- The icon, time digits, and suffix are aligned as a single row.
- The alarm icon should be vertically centered to the visual middle of the large time digits.
- The AM/PM marker should also be vertically centered to the visual middle of the large time digits.
- Do not align the icon or AM/PM marker to the bottom of the row by default.
- Do not rely on default baseline alignment if it makes the icon or AM/PM marker sit low against the time digits.
- If the platform's text layout baseline-aligns these elements, apply an optical offset so their centers align with the time digits' visual center.
- The group is centered in the hero, not the digits alone.
- If the icon creates visual imbalance, use a smaller icon or slightly reduce icon opacity; do not move the whole row off-center.
- In `Quiet`, the moon icon and `Quiet mode` text should be centered as one group in the same primary row slot.
- `Quiet mode` must not use a smaller natural row height that pulls the hero upward.
- At large text sizes, the row may keep the icon and time on one line as long as it fits. If not, the icon may move into a secondary status treatment, but the wake time must remain prominent.

## 14. State handling

### 14.1 Active alarm

Automatic-location example:

```text
[location icon] East York
Tomorrow

[alarm icon] 5:43 AM

4:43 AM  ●━━━━━━⏰━━●  6:13 AM
Wake up 30 min before Fajr ends

[ Pre-Fajr | Fajr selected | Quiet ]
```

Manual-location example:

```text
Toronto
Tomorrow

[alarm icon] 5:43 AM

4:43 AM  ●━━━━━━⏰━━●  6:13 AM
Wake up 30 min before Fajr ends

[ Pre-Fajr | Fajr selected | Quiet ]
```

### 14.2 Alarm off with planned wake anchor

Example:

```text
[location icon] East York
Tomorrow

[alarm-off icon] Alarm off

4:43 AM  ●━━━━━━[alarm-off icon]━━●  6:13 AM
Planned wake was 30 min before Fajr ends

[ Pre-Fajr | Fajr selected | Quiet ]
```

If the planned wake anchor should not be exposed, use:

```text
Alarm is off for tomorrow
```

### 14.3 No alarm

Example:

```text
[location icon] East York
Tomorrow

No alarm set

4:43 AM  ●━━━━━━━━━━●  6:13 AM
No wake alarm is set for tomorrow

[ Suhoor | Fajr | Quiet ]
```

A no-alarm state must not show a draggable alarm icon unless the product deliberately supports creating an alarm from this control in a later spec.

### 14.4 Quiet morning

Example:

```text
[location icon] East York
Tomorrow

[moon icon] Quiet mode

4:43 AM  ●━━━━━━━━━━●  6:13 AM
No alarm will ring for tomorrow

[ Suhoor | Fajr | Quiet selected ]
```

Rules:

- The primary wake row should say exactly `[moon icon] Quiet mode` when the moon icon is available, or `Quiet mode` when icons are unavailable.
- `Quiet mode` replaces the large wake time inside the same primary row slot; it must not cause the hero stack to jump upward.
- `Quiet mode` uses the same primary-row typography treatment as the active wake time and remains centered in the row.
- Keep the Fajr begin/end range visible when Fajr data is available.
- The Fajr range visual is static in quiet mode.
- Do not show an alarm icon, off icon, or draggable handle in the range visual.
- Do not allow wake-time scrubbing while `Quiet` is selected.
- The relation/status line should use `No alarm will ring for {relative day}` or a precomposed equivalent with the same meaning.
- The quick wake-state selector shows `Quiet` as the selected segment.
- Do not show `Quiet mode` for permission failure, delivery failure, missing pending platform request, location failure, or unavailable Fajr data. Those are degraded, blocked, or unavailable states, not user-selected Quiet.

### 14.5 Fasting or Tahajjud day

On intended fasting, Ramadan fasting, Qada/custom fasting, Tahajjud-only mornings, or Other early worship mornings, show the early-worship adjuster instead of hiding the visual row.

Example:

```text
[location icon] East York
Tomorrow

[alarm icon] 4:13 AM

2:16 AM  │━━━━━━⏰━━●  4:43 AM
Wake up 30 min before Fajr begins

[ Pre-Fajr selected | Fajr | Quiet ]
```

Left-boundary example:

```text
[location icon] East York
Tomorrow

[alarm icon] 2:16 AM

2:16 AM  │⏰━━━━━━●  4:43 AM
Wake up for the last third of the night

[ Pre-Fajr selected | Fajr | Quiet ]
```

Right-boundary example:

```text
[location icon] East York
Tomorrow

[alarm icon] 4:43 AM

2:16 AM  │━━━━━━⏰●  4:43 AM
Wake up as Fajr begins

[ Pre-Fajr selected | Fajr | Quiet ]
```

Rules:

- Use the early-worship adjuster only when the resolved day has selected `Pre-Fajr`, intended fasting, intended Tahajjud-only, or intended Other early worship.
- The left time is the resolved start of the final third of the night.
- The right time is the resolved Fajr begin time.
- The left boundary marker is a vertical line/tick, not a dot or endpoint circle.
- The right boundary marker is the endpoint circle for Fajr begins.
- The alarm icon remains the draggable wake indicator.
- Dragging updates the primary wake time and relation/status line live.
- Dragging all the way left clamps to final-third start and shows `Wake up for the last third of the night`.
- Dragging all the way right clamps to Fajr begins and shows `Wake up as Fajr begins`.
- Fasting opportunity tags alone do not activate this visual. The day must be selected as Pre-Fajr or resolved as intended fasting, Ramadan fasting support, Qada/custom fasting, intended Tahajjud-only wake, or intended Other early worship wake.
- If the final-third start cannot be resolved, do not invent the boundary or show a misleading early-worship adjuster.

### 14.6 Quick wake-state selector outcomes

The quick wake-state selector changes the target morning state through the shared resolver.

#### Fajr selected

```text
[location icon] East York
Tomorrow

[alarm icon] 5:43 AM

4:43 AM  ●━━━━━━⏰━━●  6:13 AM
Wake up 30 min before Fajr ends

[ Pre-Fajr | Fajr selected | Quiet ]
```

Rules:

- `Fajr` is selected by default for ordinary non-Ramadan mornings.
- The default wake is 30 min before Fajr ends.
- The active range is Fajr begins → Fajr ends.
- The alarm icon is draggable when adjustment is enabled.

#### Pre-Fajr selected, Tahajjud only

```text
[location icon] East York
Tomorrow

[alarm icon] 4:13 AM

2:16 AM  │━━━━━━⏰━━●  4:43 AM
Wake up 30 min before Fajr begins

[ Pre-Fajr selected | Fajr | Quiet ]
[ Tahajjud only selected | Fasting | Other early worship ]
```

Rules:

- Outside Ramadan, `Pre-Fajr` defaults to `Tahajjud only`.
- The default wake is 30 min before Fajr begins.
- The active range is final-third start → Fajr begins.
- The alarm icon is draggable when adjustment is enabled.

#### Pre-Fajr selected, Fasting

```text
[location icon] East York
Tomorrow

[alarm icon] 4:13 AM

2:16 AM  │━━━━━━⏰━━●  4:43 AM
Wake up 30 min before Fajr begins

[ Pre-Fajr selected | Fajr | Quiet ]
[ Tahajjud only | Fasting selected | Other early worship ]
Fasting intention: [Monday fast]
```

Rules:

- `Pre-Fajr` + `Fasting` marks the target morning as intended fasting unless Ramadan already owns that state.
- The fasting intention defaults to the date’s opportunity set when opportunities exist.
- If no specific opportunity exists, the fasting intention defaults to `Voluntary fast`.
- The default wake is 30 min before Fajr begins.
- The active range is final-third start → Fajr begins.

#### Pre-Fajr selected, Other early worship

```text
[location icon] East York
Tomorrow

[alarm icon] 4:13 AM

2:16 AM  │━━━━━━⏰━━●  4:43 AM
Wake up 30 min before Fajr begins

[ Pre-Fajr selected | Fajr | Quiet ]
[ Tahajjud only | Fasting | Other early worship selected ]
```

Rules:

- `Other early worship` is a non-fasting Pre-Fajr intention.
- It uses the early-worship window and the same default wake anchor as other Pre-Fajr states: 30 min before Fajr begins.
- It does not create a fasting intention, fasting completion requirement, or fasting analytics credit.
- It must remain distinct from `Other fast`, which appears only inside the fasting-intention taxonomy after `Pre-Fajr` + `Fasting` is selected.
- If the visual Hero cannot comfortably show three intention choices at a given Dynamic Type size, `Other early worship` may move into a compact overflow/detail affordance, but the resolved state must still be displayable, restorable, and accessible.

#### Ramadan Pre-Fajr selected

```text
[location icon] East York
Tomorrow

[alarm icon] 4:13 AM

2:16 AM  │━━━━━━⏰━━●  4:43 AM
Wake up 30 min before Fajr begins

[ Pre-Fajr selected | Fajr | Quiet ]
Fasting intention: [Ramadan fast]
```

Rules:

- Ramadan defaults to `Pre-Fajr`.
- Ramadan locks intention to `Fasting`.
- Ramadan locks fasting intention to `Ramadan fast`.
- The user may switch to `Fajr` or `Quiet`, but returning to `Pre-Fajr` restores the locked Ramadan state.

#### Quiet selected

```text
[location icon] East York
Tomorrow

[moon icon] Quiet mode

4:43 AM  ●━━━━━━━━━━●  6:13 AM
No alarm will ring for tomorrow

[ Suhoor | Fajr | Quiet selected ]
```

Rules:

- `Quiet` suppresses the active wake alarm for the target morning.
- The primary wake row says `[moon icon] Quiet mode` when the moon icon is available, or `Quiet mode` when icons are unavailable.
- The primary row keeps the same vertical slot, typography treatment, and container height as active wake modes; no hero jump is allowed.
- The Fajr begin/end range remains visible when available.
- The range visual is static and non-interactive.
- No alarm icon appears in the range visual.

### 14.7 Missing Fajr data

Example:

```text
[location icon] East York
Tomorrow

Wake time unavailable

Fajr times are not available yet
```

Rules:

- Do not show guessed Fajr begin or end times.
- Do not show a range bar when the Fajr begin/end window is unavailable.
- Do not show a relation/status line that depends on missing Fajr data.
- Keep the layout stable with a calm fallback.

### 14.8 Location unavailable

Example:

```text
Location unavailable
Tomorrow

Wake time unavailable

Choose a location to calculate Fajr times
```

Rules:

- Do not show detected-location styling if no detected or manually selected location is available.
- Do not show a location icon unless automatic/current-location mode is actually the source of the displayed location.
- Do not show guessed Fajr times for a location that is not resolved.

## 15. Special context handling

The hero may need to reflect day-specific context such as Ramadan, fasting, Tahajjud, adjusted time, quiet state, or one-day override.

Recommended approach for v15:

- Do **not** add chips or badges in the hero yet.
- Use the relation/status line when context changes the meaning of the wake time.
- Keep the hero focused on the immediate morning.
- Use the default within-Fajr adjuster for ordinary/default Fajr mornings and for `Fajr` quick-select mode.
- Use the early-worship adjuster for intended fasting, `Pre-Fajr` quick-select mode, intended Tahajjud-only mornings, or intended Other early worship mornings when final-third start and Fajr begins are available.
- Do not activate the early-worship adjuster for fasting opportunities unless the fast is intended, scheduled, auto-activated by Ramadan support, or otherwise resolved as intended fasting.
- The location line remains a location line; do not use it for special-context labels. Use the quick wake-state selector to show the selected `Pre-Fajr`, `Fajr`, or `Quiet` state.

Examples:

```text
Fasting day • Wake up {X} min before Fajr begins
Tahajjud wake • Wake up {X} min before Fajr begins
Ramadan morning • Wake up for the last third of the night
Adjusted • Wake up {X} min before Fajr ends
```

Priority when multiple contexts exist:

1. Ramadan
2. Fasting
3. Tahajjud
4. Adjusted
5. Ordinary day

The data layer should choose the highest-priority context and precompose the visible relation/context text using the mode-aware relation rules from Section 7.6. It should also decide whether the wake-boundary visual is eligible for default within-Fajr mode, eligible for early-worship mode, hidden for out-of-range timing, or unavailable.

## 16. Mutation contract boundary

The Hero renders a resolved snapshot and emits normalized mutation commands. It must not mutate persistent models directly from the view layer.

Required behavior:

- A tap on `Pre-Fajr`, `Fajr`, or `Quiet` emits `selectQuickWakeMode(...)` for the current target morning.
- A tap on a Pre-Fajr intention emits `selectPreFajrIntention(...)` for the current target morning.
- A tap or selection inside fasting-intention controls emits `selectFastingIntention(...)` for the current target morning.
- A wake adjuster drag may preview time locally while the drag is active, but release emits `adjustWakeTime(...)` and the Hero reconciles to the re-resolved snapshot.
- The Hero commit mode is immediate. There is no Day-Detail-style draft buffer on Home.
- Repeated taps on the currently selected mode or intention are idempotent.
- Rapid switching resolves to the final user-selected command sequence and must not create duplicate overrides.
- Any scheduling side effect is downstream of Morning Resolution and Alarm Delivery. The Hero never calls AlarmKit or UserNotifications directly.

## 17. Data contract

The hero should receive a resolved snapshot.

```text
MorningHeroSnapshot
- targetDateKey
- visibleTopLineMode location | date
- locationSource automaticDetected | manualSelected | unavailable
- locationDisplayText optional
- locationLineText optional
- locationIconName optional
- showLocationIcon true | false
- locationServicesMode active | inactive | unavailable
- relativeDayLabel
- gregorianDateText optional
- gregorianMonthDisplayName optional
- hijriDateText optional
- hijriMonthDisplayName optional
- hijriDateSource userOverride | autoAdjusted | calendarDerived | unavailable
- dateLineText optional
- dateLineVisible true | false
- selectedQuickWakeMode preFajr | fajr | quiet | unavailable
- selectedQuickWakeModeSelectionSource defaultFajr | defaultRamadanPreFajr | userSelected | inferredFromPreFajrPlan | inferredFromFastingPlan | inferredFromTahajjudOnlyPlan | inferredFromQuietState | unavailable
- preFajrIntention tahajjudOnly | fasting | otherEarlyWorship | lockedRamadanFasting | unavailable optional
- preFajrIntentionSelectionSource defaultTahajjudOnly | userSelected | restoredFromInactiveMode | ramadanLocked | eidFastingUnavailable | unavailable optional
- fastingIntentionDisplayText optional
- fastingIntentionChips [FastingIntentionChipDisplay]
- fastingIntentionLocked true | false
- fastingUnavailableReason none | eid | ramadanAlternativeBlocked | other optional
- quickWakeStateSelectorVisible true | false
- quickWakeStateSelectorAvailableSegments [preFajr, fajr, quiet]
- quickWakeStateSelectorSelectedSegment preFajr | fajr | quiet | none
- selectedQuickWakeModeCommitPolicy commitImmediately | commitOnRelease | resolverDefined
- wakeState active | offWithAnchor | noAlarm | quietHours | unavailable
- wakeTime optional
- plannedWakeAnchorTime optional
- wakeDisplayText
- wakeIconName optional
- wakeBoundaryKind defaultFajrWindow | earlyWorshipWindow | none | unavailable
- wakeBoundaryReason defaultFajrMorning | selectedPreFajr | selectedQuiet | intendedFasting | intendedTahajjudOnly | ramadanPreFajr | eidFastingUnavailable | fallbackMissingNightData | none
- relationBoundary finalThirdStart | fajrBegin | fajrEnd | none | unavailable
- relationOffsetMinutes optional
- relationText optional
- relationLinePosition aboveQuickWakeStateSelector
- relationLineTone normal | urgentRed | stateText optional
- finalThirdStartTime optional
- finalThirdStartDisplayText optional
- fajrBeginTime optional
- fajrEndTime optional
- fajrBeginDisplayText optional
- fajrEndDisplayText optional
- fajrEndSource locationResolved | unavailable
- fajrWindowState upcoming | inProgress | completed | unavailable
- wakeWindowPositionRatio optional
- wakeWindowIndicatorState active | offAnchor | none | unavailable
- wakeWindowIndicatorIconName optional
- leftBoundaryMarkerStyle endpointCircle | verticalLine | none
- rightBoundaryMarkerStyle endpointCircle | none
- wakeBoundaryVisualMode interactiveWithinFajrWindow | staticWithinFajrWindow | interactiveEarlyWorshipWindow | staticEarlyWorshipWindow | hiddenOutOfWindow | hiddenUnavailable
- wakeAdjustmentEnabled true | false
- wakeAdjustmentMinTime optional
- wakeAdjustmentMaxTime optional
- wakeAdjustmentStepMinutes optional
- wakeAdjustmentCommitPolicy commitOnRelease | liveCommit
- defaultFajrWakeOffsetBeforeEndMinutes default 30
- defaultPreFajrWakeOffsetBeforeBeginMinutes default 30
- quietModeSuppressesAlarm true | false
- wakeBoundaryAccessibilityText optional
- wakeBoundaryFallbackText optional
- specialContext none | ramadan | fasting | tahajjudOnly | quiet | adjusted
- specialContextText optional
- accessibilitySummary
- loadingState ready | loading | partial | missingData | error
```

Rules:

- In v15, `visibleTopLineMode` should be `location` by default.
- `locationLineText` should already be formatted for display and should represent the location used to resolve the visible Fajr begin/end values.
- `locationDisplayText` should be a human-readable place label, such as `East York` or `Toronto`, not a latitude/longitude pair.
- `showLocationIcon = true` only when `locationSource = automaticDetected` and the app is using automatic/current-location mode for the resolved prayer-time location.
- `showLocationIcon = false` when `locationSource = manualSelected`.
- The renderer must not show a location icon for a manually selected location.
- If `locationSource = unavailable`, the renderer should use the supplied fallback `locationLineText` and should not show guessed Fajr times.
- `dateLineVisible` should be `false` in v15.
- `dateLineText` may still be resolved for future use, but it should not be rendered or given vertical space when `dateLineVisible = false`.
- If `dateLineVisible` is later changed to `true`, `dateLineText` should already be formatted for display with no visible weekday and full month names, for example `April 29 • Dhul Qadah 12`.
- `dateLineText` should not use compact Hijri tokens such as `ZQ12` in the default hero presentation when the date line returns.
- `gregorianMonthDisplayName` and `hijriMonthDisplayName`, when supplied, should match the display-name tables in Section 7.2 or the active localization's equivalent month-name set.
- `wakeDisplayText` should already be formatted for the primary row.
- `selectedQuickWakeMode = fajr` for ordinary/default Fajr mornings unless a stronger explicit state applies.
- `selectedQuickWakeMode = preFajr` when the target morning is selected as Pre-Fajr, resolved as Ramadan Pre-Fajr, or otherwise resolved as a pre-Fajr wake for this surface.
- `selectedQuickWakeMode = quiet` when the target morning is intentionally selected or resolved as Quiet. Do not use this value for permission failure, delivery failure, missing data, or generic no-alarm states.
- `quickWakeStateSelectorVisible` is `true` in the v15 hero unless the app is in a loading, missing-data, or unsupported state where mode changes cannot be performed truthfully.
- The renderer may keep the previous visible snapshot in presentation state to animate `Pre-Fajr`, `Fajr`, and `Quiet` transitions. The authoritative selected mode, wake time, boundary kind, and relation text still come from the shared resolver.
- Quick-select actions must be routed through the Quick Wake Mode and Intent Mutation Contract and the shared wake-state / alarm-state resolver. The hero renderer must not create, cancel, verify, or schedule platform alarms locally.
- Selecting `Pre-Fajr` should produce an active wake default of 30 min before Fajr begins. Outside Ramadan the default Pre-Fajr intention is `Tahajjud only`; during Ramadan the locked intention is `Fasting` with `Ramadan fast`. If the user selects or restores `Other early worship`, the resolved state remains non-fasting and uses the early-worship window.
- Selecting `Fajr` should produce an active wake default of 30 min before Fajr ends. Per the Quick Wake contract, changing the main quick wake mode clears active manual wake-time adjustment unless a later approved spec explicitly changes that rule.
- Selecting `Quiet` should suppress the active wake alarm by user choice and set `wakeDisplayText` to `Quiet mode`; permission failure, platform delivery failure, or degraded reliability must not be rendered as Quiet.
- `wakeBoundaryKind = defaultFajrWindow` when the active adjustment range is Fajr begins → Fajr ends.
- `wakeBoundaryKind = earlyWorshipWindow` when the active adjustment range is final-third start → Fajr begins.
- `wakeBoundaryReason` should come from the same resolver that determines whether the day is a default Fajr morning, selected Pre-Fajr morning, selected Quiet morning, intended fasting morning, intended Tahajjud-only morning, intended Other early worship morning, Ramadan morning, Eid fasting-unavailable morning, or a fallback state.
- `finalThirdStartTime` and `finalThirdStartDisplayText` are required for `interactiveEarlyWorshipWindow` and `staticEarlyWorshipWindow` modes.
- `relationText` should already use the mode-aware presentation from Section 7.6.
- For default / within-Fajr mode, `relationText` uses `Wake up {X} min before Fajr ends` for non-endpoint wake times, `Wake up as Fajr begins` at the Fajr-begin endpoint, and `Wake up as Fajr ends` at the Fajr-end endpoint.
- For early-worship mode, `relationText` uses `Wake up {X} min before Fajr begins` for non-endpoint wake times, `Wake up for the last third of the night` at the final-third-start endpoint, and `Wake up as Fajr begins` at the Fajr-begin endpoint.
- Adjusted wake times follow the same mode-aware relation rules and must not surface custom-wake wording.
- `relationLineTone` should be `urgentRed` only when the active wake time is 14 min or less before the resolved Fajr end time, using the same rounded whole-minute value shown in the relation/status line; otherwise use `normal` for active-wake relation/status text or `stateText` for no-alarm/off/quiet/unavailable state text.
- `relationLinePosition` is `aboveQuickWakeStateSelector` in v15.
- During a drag interaction, the renderer may produce transient `wakeDisplayText`, `relationText`, and `relationLineTone` values locally, but the saved snapshot should reconcile to the committed wake time after persistence succeeds.
- `fajrBeginDisplayText`, `fajrEndDisplayText`, and `finalThirdStartDisplayText` should already be formatted for visible range time labels.
- `wakeBoundaryVisualMode = interactiveWithinFajrWindow` only when the active wake time or planned wake anchor is inside the Fajr begins → Fajr ends window and the day is not using the early-worship treatment.
- `wakeBoundaryVisualMode = staticWithinFajrWindow` may be used for `Quiet` mode when Fajr begin and Fajr end are available; in that mode there is no alarm icon and no drag interaction.
- `wakeBoundaryVisualMode = interactiveEarlyWorshipWindow` only when the day has selected Pre-Fajr, intended fasting, Ramadan Pre-Fajr, intended Tahajjud-only wake, or intended Other early worship wake and the active wake time or planned wake anchor is inside the final-third start → Fajr begins window.
- `wakeBoundaryVisualMode = hiddenOutOfWindow` when the wake time is outside the supported range and no alternate visual has been specified yet.
- `wakeWindowPositionRatio` should be `0.0` at the left boundary and `1.0` at the right boundary when supplied.
- If `wakeWindowPositionRatio` is absent, the renderer may derive the visual position only from supplied, resolved `wakeTime` or `plannedWakeAnchorTime` and the resolved left/right boundary times for the active mode.
- `wakeWindowIndicatorIconName` should resolve to the alarm icon for active alarms and a distinct off-state icon for off-with-anchor states.
- For default / within-Fajr mode, `leftBoundaryMarkerStyle = endpointCircle` and `rightBoundaryMarkerStyle = endpointCircle`.
- For early-worship mode, `leftBoundaryMarkerStyle = verticalLine` and `rightBoundaryMarkerStyle = endpointCircle`.
- `wakeAdjustmentMinTime` and `wakeAdjustmentMaxTime` should equal `fajrBeginTime` and `fajrEndTime` for the interactive within-Fajr adjuster.
- `wakeAdjustmentMinTime` and `wakeAdjustmentMaxTime` should equal `finalThirdStartTime` and `fajrBeginTime` for the interactive early-worship adjuster.
- `wakeAdjustmentStepMinutes` should be supplied by the data layer or design system; if absent, use the app's standard alarm-minute granularity.
- `wakeBoundaryAccessibilityText` should expose the full meaning of the visible range because the compact visual row shows times and markers only.
- `fajrEndSource` should be `locationResolved` when Fajr end is shown.
- The renderer should not invent marker times, Fajr end times, final-third-start times, relation offsets, Hijri month names, location display names, or special-context priority.

## 18. Accessibility requirements

Expose the hero as one coherent summary.

Active alarm example:

```text
East York. Tomorrow. Fajr mode selected. Wake alarm at 5:43 AM. Wake up 30 min before Fajr ends. Fajr begins at 4:43 AM. Fajr ends at 6:13 AM.
```

Manual-location example:

```text
Toronto. Tomorrow. Fajr mode selected. Wake alarm at 5:43 AM. Wake up 30 min before Fajr ends. Fajr begins at 4:43 AM. Fajr ends at 6:13 AM.
```

No-alarm example:

```text
East York. Tomorrow. Quiet mode selected. No alarm will ring for tomorrow. Fajr begins at 4:43 AM. Fajr ends at 6:13 AM.
```

Rules:

- The summary should include the location used for the displayed Fajr times.
- The summary should include the selected quick mode when the quick wake-state selector is visible: `Pre-Fajr mode selected`, `Fajr mode selected`, or `Quiet mode selected`.
- The icon must not be the only accessible indicator of location-source or alarm state.
- Automatic/current-location mode should be distinguishable from manual-location mode when that distinction is useful to the user.
- The wake-boundary range visual must not be the only accessible indicator of Fajr begin/end or final-third meaning.
- The hidden date row is not required in the visible summary in v15, but resolved date text may be included in accessibility if the product chooses to preserve date context.
- If date text is included in accessibility, screen reader text should use full Hijri month names in the default English presentation.
- Use the same Fajr begin/end values as visible text.
- Use the same wake relation as the visible relation/status line, including `Wake up as Fajr begins`, `Wake up as Fajr ends`, and `Wake up for the last third of the night` endpoint wording.
- Urgent short-window states must not rely on red color alone; accessibility text should preserve the relation wording and may include concise urgency context when the wake time is 14 min or less before Fajr ends.
- Use the same tense as visible text for in-progress or completed edge cases.
- All text must respond to dynamic type.
- Reduced motion should be respected for any hero transitions.
- Motion is never the only indicator of a mode change; selected state, text, accessible labels, and wake-boundary meaning must also update.

When the wake-boundary row is interactive, expose the alarm icon control with adjustable behavior.

Recommended interactive accessibility values:

Default mode:

```text
Wake alarm at 5:43 AM. Wake up 30 min before Fajr ends. Adjustable between Fajr begin at 4:43 AM and Fajr end at 6:13 AM.
```

Early-worship mode:

```text
Wake alarm at 4:13 AM. Wake up 30 min before Fajr begins. Adjustable between the final third of the night at 2:16 AM and Fajr begin at 4:43 AM.
```

Accessible adjustment rules:

- Increment moves the wake time later by `wakeAdjustmentStepMinutes`.
- Decrement moves the wake time earlier by `wakeAdjustmentStepMinutes`.
- Adjustment is clamped to the active mode: Fajr begins → Fajr ends for default mode, or final-third start → Fajr begins for early-worship mode.
- The primary wake row, relation/status line, and accessibility value must update after each adjustment.
- If the row is hidden because the required timing data is unavailable, do not expose a phantom adjustable control.

## 19. Loading behavior

The loading state should preserve the current text-size stop's hero region height.

Recommended loading skeleton:

```text
Location line placeholder
Relative label placeholder
Large wake-time placeholder
Wake-boundary range visual / wake adjuster placeholder
Relation/status line placeholder
```

Rules:

- Avoid layout jumps when data resolves.
- Do not briefly show stale Fajr times during recalculation.
- If location or prayer-time data is being refreshed, keep previous content only if it is clearly still valid for the same target date and same resolved location mode.
- The hidden date row should not receive a visible loading placeholder in v15.
- The wake-boundary range visual / wake adjuster placeholder should reserve room for the left boundary time, left boundary marker, bar, right boundary marker, right boundary time, and possible alarm-icon wake indicator when the row is eligible.
- If the location is still resolving, the location placeholder should use the same top-row font style as the loaded location line.

## 20. Responsive behavior

### 20.1 Narrow widths

On narrow devices:

- Keep the location line and relative day centered.
- Preserve the primary wake value as the strongest element.
- Allow the wake-boundary range visual to use its measured fallback layout before truncating.
- Avoid shrinking only the secondary text while leaving the main time large.
- Do not reserve space for the hidden date row.
- Grow the hero region and push lower content down when measured text requires it.

### 20.2 Larger widths

On wider layouts:

- Keep the hero centered and compact.
- Do not stretch the hero into a wide horizontal dashboard.
- Preserve a calm vertical rhythm.
- Cap the hero content width if needed so the location, primary wake row, and wake-boundary range visual remain easy to scan.

### 20.3 Localization

The hero must handle longer localized location names, month names if the date row returns, AM/PM formats, Hijri month labels if surfaced, and relation/status text.

Required behavior:

- Prefer wrapping or measured fallback layouts over clipping for important content.
- Keep the visible date line hidden in v15.
- If the date line returns later, keep it weekday-free and use full Gregorian and Hijri month names by default in the English hero row.
- If location text becomes long, use the app's standard short place display name before clipping.
- Do not use the location icon for manual-location mode in any locale.
- Allow the wake-boundary range visual to shift into its approved fallback layout.
- Do not assume English-only location names, month names, or fixed-width meridiem suffixes.
- Keep the accessibility summary grammatically correct in the user's locale.

## 21. Locked initial requirements

These should be treated as v15 locked requirements:

1. The hero describes the next relevant morning.
2. The location line is the first visible row.
3. Automatic/current-location mode shows a location icon plus the detected location display name.
4. Manual-location mode shows the selected location display name without the location icon.
5. The visible location must represent the place used to resolve the displayed Fajr times.
6. The Gregorian + Hijri date line is hidden temporarily in v15.
7. The hidden date line does not reserve blank vertical space.
8. If the date line returns later, it should use the full Gregorian + full Hijri month-name rules retained in Section 7.2.
9. The hero shows a relative day label directly below the location line.
10. The primary wake time/status is the largest informational element.
11. The spacing between the relative day label and the primary wake row remains reduced to roughly half of the previous 22 px/pt treatment.
12. The alarm icon and AM/PM marker are vertically centered with the large time digits.
13. The wake-boundary range visual appears directly below the primary wake row whenever that row is eligible.
14. The relation/status line is the final informational text row and sits above the quick wake-state selector.
15. The quick wake-state selector is the final base hero row in v15; conditional Pre-Fajr intention controls may appear below it when Pre-Fajr is selected.
16. The quick wake-state selector is a translucent liquid-glass segmented pill with three states in this order: `Pre-Fajr`, `Fajr`, `Quiet`.
17. The selector must reuse the same liquid-glass surface language as the Next 7 Mornings card and must not use a flat, opaque, or frosted gray visual treatment.
18. Selector changes must preserve the approved sliding selected-state treatment inside the container.
19. `Fajr` is selected by default for ordinary/default mornings and sets the default wake to 30 min before Fajr ends.
20. `Pre-Fajr` sets the target morning to a pre-Fajr wake, defaults to Tahajjud only outside Ramadan, exposes/restores `Fasting` and `Other early worship` when applicable, and sets the default wake to 30 min before Fajr begins.
21. `Quiet` suppresses the active wake alarm and shows `[moon icon] Quiet mode` as the primary wake row when the moon icon is available.
22. In `Quiet`, the range visual is static, non-interactive, and has no alarm icon.
23. Quick wake-state selector changes must route through the Quick Wake Mode and Intent Mutation Contract and the shared wake-state / alarm-state resolver; the hero renderer must not create, cancel, verify, or schedule platform alarms directly.
24. The active-wake relation/status line must use the approved mode-aware patterns from Section 7.6.
25. For default / within-Fajr mode, the relation/status line uses `Wake up {X} min before Fajr ends` except when the wake time is exactly at Fajr begin or Fajr end.
26. Default-mode endpoint relation/status text uses `Wake up as Fajr begins` or `Wake up as Fajr ends`.
27. For early-worship mode, the relation/status line uses `Wake up {X} min before Fajr begins` except when the wake time is exactly at final-third start or Fajr begin.
28. Early-worship endpoint relation/status text uses `Wake up for the last third of the night` at the left boundary and `Wake up as Fajr begins` at the right boundary.
29. Quiet relation/status text uses `No alarm will ring for {relative day}` or a precomposed equivalent with the same meaning.
30. The relation/status line uses red only when the wake time is 14 min or less before Fajr ends, including the exact `Wake up as Fajr ends` state.
31. The relation/status line uses the same font style, sizing, and visual treatment as the location line / hidden date-line style, with red as the only urgent short-window text-color exception.
32. Fajr begin and Fajr end times are visible in the default within-Fajr range visual whenever that row is eligible and Fajr data is available.
33. Final-third start and Fajr begin times are visible in the early-worship range visual whenever that row is eligible and required data is available.
34. The default within-Fajr row is visual and compact: Fajr begin time, endpoint circle, bar, optional alarm icon at wake position, endpoint circle, Fajr end time.
35. The early-worship row is visual and compact: final-third start time, vertical line/tick, bar, optional alarm icon at wake position, endpoint circle, Fajr begin time.
36. The active wake indicator in either interactive range row is the alarm icon, not a generic dot.
37. When enabled, dragging the alarm icon changes the immediate wake time for the target morning.
38. Dragging the alarm icon updates the primary wake time and relation/status line live.
39. The relation/status line changes by fade-through or in-place content transition only; it must not slide in from any direction.
40. The primary wake time rapidly rolls between resolved active wake times during `Fajr ↔ Pre-Fajr` transitions.
41. `Fajr → Pre-Fajr` transitions keep the wake-boundary row anchored, move only the alarm icon earlier/leftward, fade it through the Fajr-begins handoff, then reintroduce it from the right side of the early-worship bar.
42. `Pre-Fajr → Fajr` transitions keep the wake-boundary row anchored, move only the alarm icon later/rightward, fade it through the Fajr-begins handoff, then reintroduce it from the left side of the within-Fajr bar.
43. Switching to or from `Quiet` must keep the hero vertically stable; `[moon icon] Quiet mode` replaces the primary wake time inside the same row slot.
44. The default within-Fajr wake adjuster appears only when the wake time or planned wake anchor is inside the Fajr begins → Fajr ends window.
45. The early-worship wake adjuster appears only when the resolved day has selected Pre-Fajr, intended fasting, intended Tahajjud-only, or intended Other early worship and the wake time or planned wake anchor is inside the final-third start → Fajr begins window.
46. Fajr/final-third labels are not shown visibly in the compact hero row, but their meaning must be exposed to accessibility.
47. Fajr end is location-resolved, not renderer-derived.
48. Final-third start is resolver-derived, not renderer-derived.
49. All readable text scales across seven standard iPhone text-size stops.
50. Measured content can grow the hero region and push lower cards down.
51. No essential text or visual meaning may be clipped to preserve compactness.
52. No alarm, off, quiet, and unavailable states must be visibly and accessibly distinct.
53. Special context should remain text-based outside of the deliberate quick wake-state selector.
54. The hero remains centered, calm, and visually restrained.
## 22. Recreation checklist

### 22.1 Content

- [ ] Location line appears as the first visible row.
- [ ] Automatic/current-location mode shows a location icon plus the detected location name.
- [ ] Manual-location mode shows the selected location name without the location icon.
- [ ] Location line represents the place used to resolve the displayed Fajr times.
- [ ] Date line is hidden in v15.
- [ ] Hidden date line does not reserve a blank row or blank gap.
- [ ] If date text is resolved for future use, it uses full Gregorian and Hijri month names.
- [ ] Relative day appears below the location line.
- [ ] Primary wake time/status appears.
- [ ] Alarm/off/no-alarm/quiet state is clear.
- [ ] Default within-Fajr mode shows Fajr begin and Fajr end times as visible time labels.
- [ ] Default within-Fajr mode shows endpoint circles at both ends of the bar.
- [ ] Early-worship mode shows final-third start and Fajr begin times as visible time labels.
- [ ] Early-worship mode shows a vertical line/tick at the left boundary and an endpoint circle at the Fajr-begins boundary.
- [ ] Active wake/alarm indicator is the alarm icon, positioned relative to the active boundary window.
- [ ] Relation/status line appears as the final informational text row above the quick wake-state selector.
- [ ] Active-wake relation/status line uses the approved mode-aware patterns from Section 7.6.
- [ ] Default, active, and adjusted wake relation/status line uses `Wake up {X} min before Fajr ends` wording in default / within-Fajr mode, except at exact Fajr begin/end endpoints.
- [ ] Early-worship relation/status line uses `Wake up {X} min before Fajr begins` wording in early-worship mode, except at exact final-third-start/Fajr-begin endpoints.
- [ ] Left-boundary early-worship relation/status text uses `Wake up for the last third of the night`.
- [ ] Relation/status line turns red only when wake time is 14 min or less before Fajr ends.
- [ ] Red short-window warning does not rely on color alone.
- [ ] Relation/status line uses the same font style, sizing, and visual treatment as the location line / hidden date-line style, with red as the only urgent short-window text-color exception.
- [ ] Dragging the alarm icon updates the large wake time.
- [ ] Dragging the alarm icon updates the relation/status line.
- [ ] Fasting, Tahajjud-only, and Other early worship days use the early-worship adjuster when final-third start and Fajr begin are available.
- [ ] Fasting opportunity alone does not activate the early-worship adjuster.
- [ ] Quick wake-state selector appears below the relation/status line when available.
- [ ] Quick wake-state selector is a single translucent liquid-glass segmented pill using the same surface language as the Next 7 Mornings card.
- [ ] Quick wake-state selector does not appear as a flat, opaque, or frosted gray bar.
- [ ] Selected segment highlight moves smoothly when the user changes modes.
- [ ] Segment order is `Pre-Fajr`, `Fajr`, `Quiet`.
- [ ] Pre-Fajr intention choices include or expose `Tahajjud only`, `Fasting`, and `Other early worship` without confusing `Other early worship` with `Other fast`.
- [ ] `Fajr` default sets wake to 30 min before Fajr ends.
- [ ] `Pre-Fajr` selection sets wake to 30 min before Fajr begins, defaults to Tahajjud only outside Ramadan, exposes/restores Fasting and Other early worship when applicable, and uses early-worship mode when available.
- [ ] `Quiet` selection shows `[moon icon] Quiet mode`, suppresses the alarm, keeps the primary row height stable, and removes the alarm handle from the range visual.
- [ ] Quick wake-state selector changes route through the shared resolver rather than local alarm creation.
- [ ] `Fajr → Pre-Fajr` keeps the adjuster row anchored, moves only the alarm icon earlier/leftward, and reintroduces the marker from the right side of the early-worship bar.
- [ ] `Pre-Fajr → Fajr` keeps the adjuster row anchored, moves only the alarm icon later/rightward, and reintroduces the marker from the left side of the within-Fajr bar.
- [ ] Switching to or from `Quiet` does not move the hero stack vertically or shrink the primary row container.
- [ ] Relation/status text uses in-place fade-through only and never slides in from any direction.
- [ ] Primary wake time uses rapid monotonic time rolling for active `Fajr ↔ Pre-Fajr` transitions.
- [ ] Boundary time labels crossfade in place during mode changes; the full adjuster row does not slide into the screen.
- [ ] Missing location, Fajr data, or final-third data does not produce guessed times or guessed marker positions.

### 22.2 Dynamic sizing

- [ ] Stop 4 uses the base typography tokens.
- [ ] Stops 1–7 use the scale and height guardrails.
- [ ] Text and visual rows are measured, not clipped.
- [ ] Hero region grows when needed.
- [ ] Hidden date row does not contribute to measured content height.
- [ ] Relative-label-to-primary-row spacing uses the reduced v3/v15 gap.
- [ ] Removed spacing is not reintroduced as unrelated padding.
- [ ] Quick-mode transitions preserve stable row frames and do not create vertical jumps.
- [ ] Wake-boundary range visual can use its approved fallback layout at larger text sizes or narrow widths.
- [ ] Next card moves down rather than overlapping.
- [ ] Alarm icon and AM/PM marker remain vertically centered with the large time digits at every stop.
- [ ] Location icon remains optically centered with the location text when shown.
- [ ] AM/PM remains readable at every stop.

### 22.3 Accessibility

- [ ] VoiceOver summary includes location, relative day, selected quick mode, wake state, relation, Fajr begin, and Fajr end.
- [ ] Automatic/current-location mode is not represented by icon alone.
- [ ] Manual-location mode does not expose a misleading location-services icon.
- [ ] Icon state is represented in text.
- [ ] Wake-boundary range visual meaning is represented in text.
- [ ] Interactive wake-boundary row adjustment is exposed through accessible increment/decrement actions when enabled.
- [ ] Quick wake-state selector exposes selected/unselected state for `Pre-Fajr`, `Fajr`, and `Quiet`.
- [ ] Hidden date row is not required visually; if date is exposed accessibly, full month names are used in the default English summary.
- [ ] Dynamic text applies to every readable line.
- [ ] Reduced Motion replaces directional transitions with short crossfades or instant state changes while preserving selected-state feedback.
- [ ] No state relies on color alone.

## 23. Remaining open ambiguity for next iteration

The main design decisions still worth refining:

1. Whether the hidden Gregorian + Hijri date line should return, and if so whether it should appear above location, below location, or in a different surface.
2. Whether the location line should prefer neighborhood, city, or `neighborhood, city` when both are available.
3. Whether the primary row should always include the alarm icon, or whether the icon should move to the relation/status line at larger text sizes.
4. Whether special context should appear in the relation/status line, for example `Fasting day • Wake up {X} min before Fajr begins`, or remain reserved for lower cards.
5. Whether the current screenshot's `Wake alarm` label should disappear entirely or survive as a small semantic label in some states.
6. Whether early-worship mode should ever allow wake times after Fajr begins with a warning, or whether the hero adjuster should remain hard-clamped to final-third start → Fajr begins.
7. Whether no-alarm states should eventually support creating an alarm by dragging on the wake-boundary range row.
8. Whether out-of-range wake times should use a separate visual treatment, a textual-only treatment, or a future expanded adjuster.
9. Whether the large wake time should stay at 68 pt at stop 4 or come down slightly to make room for the wake-boundary range visual.

Additional open item:

- Whether `Other early worship` should be displayed as an inline third segment on all supported sizes or move into a compact overflow/detail affordance at narrow widths and larger Dynamic Type stops.

## 24. Final design intent

The Morning Hero should feel like the app's immediate answer to the question: **what does my next Fajr-centered morning look like here?**

It should be calmer and simpler than the Weekly Fajrcast card, but just as truthful. In v15, the top of the hero prioritizes the location used for the Fajr calculation rather than the date. This makes the resolved prayer-time context immediately visible before the user reads the target morning or wake state.

The v15 composition starts with the location line, then the relative day, then the primary wake time or quiet-state text. The compact wake-boundary visual appears below the primary row when eligible. On default Fajr mornings, it shows the Fajr begins → Fajr ends window with endpoint circles at both ends and the alarm icon positioned along the bar. On Pre-Fajr, Tahajjud-only, or Other early worship mornings, it shows the final-third start → Fajr begins window with a vertical line/tick at the left boundary, an endpoint circle at Fajr begins, and the alarm icon positioned along the bar. In Quiet mode, it keeps the Fajr begins → Fajr ends visual as static information with no wake marker and no draggable handle.

The relation/status line sits below the visual and gives the textual explanation. Default within-Fajr examples include `Wake up 30 min before Fajr ends`, `Wake up as Fajr begins`, and `Wake up as Fajr ends`. Early-worship examples include `Wake up 30 min before Fajr begins`, `Wake up for the last third of the night`, and `Wake up as Fajr begins`. Quiet mode uses `No alarm will ring for tomorrow` in tomorrow examples and the equivalent `No alarm will ring for {relative day}` pattern generally. The line turns red only when the wake time is 14 min or less before Fajr ends, because the remaining wake-to-wudhu-to-prayer window is short.

The quick wake-state selector is the final row. It is a single translucent liquid-glass segmented pill with `Pre-Fajr`, `Fajr`, and `Quiet`, using the same surface language as the Next 7 Mornings card rather than a flat, opaque, or frosted gray control. `Fajr` is selected by default. Selecting `Pre-Fajr` moves the target morning into the early-worship wake model, defaults the wake to 30 min before Fajr begins, and defaults the intention to Tahajjud only outside Ramadan while still supporting explicit Fasting and Other early worship intentions. Selecting `Fajr` restores the ordinary Fajr wake model, defaults the wake to 30 min before Fajr ends, and clears active manual wake-time adjustment. Selecting `Quiet` suppresses the wake alarm for the target morning by user choice while preserving Fajr begin/end timing context; delivery or permission failure is not Quiet.

Mode changes should feel smooth but controlled. The selector's sliding highlight is preserved. The primary wake time rapidly rolls between resolved active wake times for `Fajr ↔ Pre-Fajr`. The relation/status line changes only through an in-place fade or content transition, never by sliding in from a direction. The wake-boundary row remains anchored; its boundary labels crossfade in place and only the alarm icon travels along the bar. `Fajr → Pre-Fajr` communicates an earlier wake by moving the alarm icon leftward through the Fajr-begins handoff and reintroducing it near the right side of the early-worship bar. `Pre-Fajr → Fajr` communicates a later wake with the opposite motion. Entering or leaving `Quiet` crossfades the primary row to or from `[moon icon] Quiet mode` without moving or shrinking the hero stack.

When the wake time is inside the active boundary window, the alarm icon on the bar can become an adjustment control. Dragging it should update the large wake time and relation/status line immediately, then commit the new wake time according to the app's persistence policy. Default mornings clamp the drag to Fajr begins → Fajr ends. Pre-Fajr, Tahajjud-only, and Other early worship mornings clamp the drag to final-third start → Fajr begins. Quiet mode has no draggable wake marker.

The Gregorian + Hijri date row is intentionally hidden in this version. Date data and the full month-name rules remain available for a future iteration, but the hidden row should not reserve visible space.

The experience should remain stable and readable across all seven standard iPhone text-size stops. As text grows, the hero region should grow and push lower cards down rather than clipping, hiding, or freezing important text. The result should feel precise, calm, premium, and trustworthy whether the user has an automatic detected location, a manually selected location, an active Fajr alarm, a selected Pre-Fajr state, Pre-Fajr Tahajjud-only intention, Pre-Fajr fasting intention, Pre-Fajr Other early worship intention, Quiet mode, Ramadan context, fasting context, Tahajjud context, or incomplete Fajr/final-third data.


---

## 25. v15 non-removal guardrail

This v15 update is a reconciliation patch, not a visual redesign. Do not remove v13 layout, Liquid Glass treatment, selector animation, wake-boundary visual behavior, hidden date-line policy, dynamic-type rules, accessibility rules, Next 7 Mornings collapsed note, or Weekly Fajrcast host note unless a later named spec explicitly supersedes them.

The only behavior-level additions in v15 are the shared mutation-contract alignment, preservation of `Other early worship`, distinction from `Other fast`, immediate-commit clarification for Home Hero actions, and Quiet-versus-delivery-failure separation.
