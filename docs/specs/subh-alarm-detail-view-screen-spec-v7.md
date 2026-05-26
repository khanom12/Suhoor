# Subh Alarm Detail View Screen Specification

| Field | Value |
| --- | --- |
| Canonical filename | `subh-alarm-detail-view-screen-spec-v7.md` |
| Version | 7 |
| Spec status | Product / implementation direction; canonical Desktop working spec |
| Supersedes | Archive/alarm_detailed_view_screen_spec_v6.md |
| Related specs | `00-subh-spec-index-v3.md`, `subh-morning-resolution-contract-state-ownership-spec-v3.md`, `subh-quick-wake-mode-intent-mutation-contract-v2.md`, `subh-morning-hero-item-spec-v15.md`, `subh-day-purpose-opportunity-resolution-spec-v1.md`, `subh-alarm-delivery-schedule-reliability-spec-v3.md` |
| Owning domain / surface | Selected morning detail editor |
| Implementation audit status | Needs implementation audit |

## Purpose
Specify the selected-morning detail screen, including immediate editing, reset, context explanation, mode-specific copy, Suhoor fasting controls, audio behavior, and accessibility.

## What This Spec Owns
- Alarm Detail screen structure and interaction model.
- Immediate save behavior and immediate Reset to Defaults.
- Mode-specific context, fasting, audio, and accessibility rules for the detail surface.

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

- The mode selector is `Suhoor | Fajr | Quiet`.
- `Suhoor` is the only before-Fajr option exposed by Alarm Detail in MVP.
- Alarm Detail must not expose `Tahajjud only`, `Other early worship`, or a generic non-fasting `Pre-Fajr` intention selector.
- Selecting `Suhoor` means the selected date is a before-Fajr wake for suhoor/fasting.
- The Suhoor intention defaults to the date's applicable Sunnah fasting opportunities; if none exist, it defaults to `Voluntary fast`.
- Explicit fasting-purpose overrides remain available as fasting-purpose choices where supported, but they do not create additional wake modes.
- The selected day saves immediately when the user changes mode, fasting purpose, wake time, Fajr-at-Fajr-begins audio, or reset state.
- `Reset to Defaults` applies immediately. Older staged reset and draft-until-Done requirements are superseded for MVP.
- During Ramadan, returning to Suhoor restores the locked Ramadan fasting purpose.
- On Eid or forbidden fasting days, fasting-unavailable behavior must be explicit and must not offer Suhoor as a normal fasting plan unless a later product decision defines a non-fasting before-Fajr path.

## 0. v7 source-of-truth alignment

This v7 revision preserves the v6 screen structure, hero parity requirements, visual direction, context-card responsibilities, Ramadan/Eid behavior, adhan behavior, accessibility requirements, and implementation guidance unless explicitly clarified here.

The purpose of this revision is to align the Alarm Detailed View with:

1. `00-subh-spec-index-v3.md`;
2. `subh-mvp-interaction-inventory-v4.md`;
3. `subh-quick-wake-mode-intent-mutation-contract-v2.md`;
4. `subh-morning-hero-item-spec-v15.md`;
5. the parent `subh-morning-resolution-contract-state-ownership-spec-v3.md`.

The Alarm Detailed View is an **immediate-save surface** for one selected day in MVP. User edits apply to the selected date as soon as the user changes the relevant control, then the canonical morning is re-resolved.

Canonical user-intent commands for this screen include, as applicable:

```text
selectQuickWakeMode(.suhoor | .fajr | .quiet)
selectFastingIntention(...)
adjustWakeTime(...)
resetDateToDefaults()
setFajrAdhanAtFajrBegins(...)
```

Rules stabilized by the shared mutation contract:

- `Early`, `Fast`, and `Pre-Fajr` are legacy exposed mode labels; use `Suhoor`.
- `Other early worship` and `Tahajjud only` are not selectable MVP intentions.
- Detail-screen edits save immediately for MVP.
- `Reset to Defaults` applies immediately for MVP.
- Switching modes clears ordinary manual wake-time adjustment and returns to the selected mode's default wake anchor unless the shared resolver returns a stronger calendar-locked resolved state.
- Quiet is intentional date-specific suppression; it is not permission failure, delivery failure, missing data, or generic alarm unavailability.
- This screen does not schedule or cancel platform alarms directly. Schedule refresh happens downstream after the canonical selected-day state is saved and re-resolved.

---

## 1. Purpose

The Alarm Detailed View is the focused, editable screen for **one selected day**.

The Home hero supports quick interaction for the immediate upcoming wake. The Alarm Detailed View extends that same interaction model to any selected day from the upcoming forecast / daily list, while exposing only the additional day-specific controls that do not belong on the Home screen.

The screen must let the user:

1. See the selected day clearly.
2. Adjust that day’s wake time with the same slider used on the Home hero.
3. Select the day’s wake mode: `Suhoor`, `Fajr`, or `Quiet`, matching the Home hero exactly.
4. Understand whether the day has Sunnah fasting opportunities.
5. If `Suhoor` is selected, show Suhoor fasting-purpose details rather than a generic before-Fajr intention picker.
6. Outside Ramadan, default `Suhoor` to the day’s Sunnah fasting opportunities when they exist, or `Voluntary fast` when no specific opportunity exists.
7. During Ramadan, default the day to `Suhoor` + `Ramadan fast`, and lock the fasting intention.
8. On Eid or forbidden fasting days, make fasting unavailable and do not offer a normal Suhoor fasting plan unless a later product decision defines a non-fasting before-Fajr path.
10. For eligible non-Ramadan fasting wakes, decide whether the later Fajr adhan event should play.
11. Save selected-day edits immediately.
12. Provide a prominent `Reset to Defaults` action when that date has user adjustments, and apply that reset immediately.

The screen must not become a broad settings, delivery-status, source-management, rule-explanation, or diagnostics page.

## 2. v7 revision goals

This revision aligns the Alarm Detailed View with the updated Home hero interaction model and the shared Quick Wake Mode and Intent Mutation Contract, while preserving the v6 MVP behavior set.

### Changes retained from v6 and clarified in v7

- Rename the before-Fajr wake mode to `Suhoor`.
- Align the mode selector with the Home hero: `Suhoor | Fajr | Quiet`.
- Remove `Tahajjud only` and `Other early worship` from MVP selectable intentions.
- When the user selects `Suhoor`, default the fasting intention to the day’s opportunity set, or to `Voluntary fast` when no specific opportunity exists.
- During Ramadan, default to locked `Suhoor` + `Ramadan fast`.
- On Eid or forbidden fasting days, make fasting unavailable and do not create a normal Suhoor fasting plan.
- Lock the default wake anchors: `Suhoor` wakes 30 minutes before Fajr begins; `Fajr` wakes 30 minutes before Fajr ends.
- Save selected-day edits immediately.
- Add a prominent `Reset to Defaults` action when the selected date has adjustments; for MVP, reset applies immediately.
- Route quick-mode, fasting-intention, adhan, wake-adjustment, and reset changes through the shared mutation contract.
- Preserve `Other fast` only as a fasting-purpose override where supported.
- Ensure permission or delivery failure never becomes `Quiet Mode`.

## 3. Scope boundary

### In scope

- Alarm Detailed View title.
- Hero positioning and Home hero parity.
- Hero date line placement.
- Wake adjustment slider preservation.
- Mode selector behavior.
- Context card copy and layout.
- Fasting-opportunity visibility and chip presentation.
- Pre-Fajr intention selection, including `Other early worship`.
- Fasting-intention default and override behavior.
- Fajr adhan-at-Fajr-begins toggle visibility.
- Quiet Mode wording and visual parity.
- Detail-screen draft state, Done commit, and staged Reset to Defaults behavior.

### Adjacent but not in scope

- The canonical fasting-opportunity engine may need adjustment if Monday / Thursday or other opportunities are not currently surfaced correctly.
- The fasting-intention taxonomy may need to be reused or exposed to this screen if it already exists elsewhere.
- Home hero component extraction may be required to guarantee exact parity.

### Out of scope

Do not change as part of this revision:

- global alarm settings
- notification delivery semantics
- AlarmKit behavior
- Fajr begin/end calculation
- Hijri calendar calculation
- onboarding
- Progress/history semantics
- analytics
- recurring plan management
- source/provenance management
- iftar management
- broad audio profile management

---

## 4. Screen title

The top navigation/title text must be:

```text
Detailed View for the Day
```

Do not use:

```text
Detailed Daily View
```

Do not use the selected date as the screen title, for example:

```text
Sun, May 3
```

The selected date belongs inside the hero.

---

## 5. Required screen structure

The screen has two main regions:

1. **Hero region** — exact reuse / mirror of the Home hero layout and behavior.
2. **Context card region** — one liquid-glass card below the hero selector, containing day significance and mode-specific controls.

Required order:

1. Navigation title: `Detailed View for the Day`.
2. Hero region.
3. Hero date line directly above the primary wake time.
4. Primary wake time or `Quiet Mode` state.
5. Relative wake description.
6. Wake adjustment slider region.
7. Mode selector.
8. Context card.

Do not add default sections for source, delivery, rule details, trust, fallback, or wake reliability.

---

## 6. Hero parity and fixed wake-time anchor

The Alarm Detailed View hero must match the Home hero one-to-one.

### Required parity

- Reuse the Home hero component directly where practical.
- If direct reuse is not practical, extract a shared hero container/model so both screens stay synchronized.
- Match shape, sizing, typography, spacing, animations, slider behavior, selector treatment, icon behavior, and transition behavior.
- Do not create detail-only vertical compression, extra top padding, or alternate spacing.
- Do not reposition the slider or selector compared with the Home hero.
- Mode changes must animate with the same motion language as the Home hero.

### Fixed wake-time anchor requirement

The primary wake time is the layout anchor.

Requirement:

```text
The primary wake time in the Alarm Detailed View must occupy the same vertical position as the primary wake time in the Home hero on the same device, orientation, Dynamic Type size, and safe-area context.
```

This means:

- The detail hero must not sit lower than the Home hero.
- The date line must not push the wake time downward.
- Removing the Home hero `Today` / `Tomorrow` line must not change the wake-time position.
- Adding the Gregorian · Hijri date must use the same visual slot above the wake time, not create a new vertical stack that shifts the wake time.
- If a visible navigation bar changes top insets, the hero region must compensate so the wake time still aligns with the Home hero.

### Measurement requirement

For QA, compare screenshots of:

1. Home hero.
2. Alarm Detailed View hero for the same day and same mode.

The center/baseline of the primary wake time should visually align. A small rendering tolerance is acceptable, but the detail wake time must not appear meaningfully lower.

---

## 7. Hero date line

The detail hero shows the selected date instead of the Home hero location / relative-day information.

### Format

```text
Friday, May 1 · 14 Dhul Qi’dah
```

### Requirements

- Use Gregorian date + centered dot + Hijri date.
- Place the date directly above the primary wake time.
- Keep the styling quiet and consistent with the Home hero’s secondary text treatment.
- Prefer one line when possible.
- Allow wrapping for Dynamic Type, but wrapping must not push the primary wake time downward. If needed, the date line may wrap upward, reduce to a shorter date format, or use an accessibility-specific layout.
- Do not show location in the detail hero.
- Do not show `Today`, `Tomorrow`, or other relative-day text in the detail hero.

---

## 8. Mode selector

The mode selector must be the same selector used by the Home hero.

Modes:

```text
Suhoor | Fajr | Quiet
```

Do not use:

```text
legacy before-Fajr / Fasting / Early selector label sets
```

The detail view and Home hero must use the same labels, order, visual treatment, and resolver semantics.

### Mode meanings

| Mode | Meaning | Slider | Context card |
|---|---|---|---|
| Pre-Fajr | Wake before Fajr begins | Active | Day opportunity sentence + intention controls, including Other early worship |
| Fajr | Fajr-centered wake | Active | Day opportunity sentence |
| Quiet | No wake alarm for this date | Inactive / stable region | Quiet Mode sentence + day opportunity sentence |

### Default modes

| Date context | Default mode | Default wake anchor |
|---|---|---|
| Ordinary non-Ramadan day | Fajr | 30 minutes before Fajr ends |
| Non-Ramadan Pre-Fajr selection | Pre-Fajr | 30 minutes before Fajr begins |
| Ramadan day | Pre-Fajr | 30 minutes before Fajr begins |

### Quiet Mode hero state

The primary state text must be:

```text
Quiet Mode
```

Do not show only:

```text
Quiet
```

The Quiet Mode moon icon must remain visible exactly as it does on the Home hero. The icon must not disappear on the detail screen.

## 9. Wake adjustment slider

The adjustment slider is required and must remain the primary time-control utility.

Do not replace it with:

- a dropdown
- a time picker
- a settings row
- a modal selector
- manual time input

### Requirements

- Reuse the Home hero slider behavior and visual treatment.
- Dragging updates the primary wake time and relative text immediately.
- Releasing commits a date-specific wake-time change immediately through the shared mutation contract.
- Accessibility increment / decrement actions must work.
- The slider is active for `Pre-Fajr` and `Fajr`.
- Quiet Mode should preserve the same layout footprint without exposing an active slider.

### Fajr mode

Fajr mode is the default outside Ramadan.

Wake behavior:

- Wake is anchored relative to Fajr end.
- Default wake time is 30 minutes before Fajr ends.
- Wake audio uses Fajr adhan audio.
- The alarm is still on.

Example:

```text
5:22 AM
Wake 30 minutes before Fajr ends
```

### Pre-Fajr mode

Pre-Fajr mode is a wake before Fajr begins.

Wake behavior:

- Wake is anchored relative to Fajr begins.
- Default wake time is 30 minutes before Fajr begins.
- Wake audio uses the generic wake alarm.
- Fajr adhan may play later when Fajr begins, depending on intention and Ramadan rules.

Example:

```text
4:35 AM
Wake 45 minutes before Fajr begins
```

---

## 10. Context card design

A liquid-glass context card appears below the hero / selector for all modes.

### Visual requirements

- Use the same liquid-glass card treatment as the Home screen supporting cards, such as the upcoming-days and weekly Fajr cards.
- Animate card content when mode or purpose changes.
- Keep transitions calm and consistent with the Home hero.
- Keep the card concise.
- Do not make the card look like a grouped settings list.

### Card responsibilities

The card may show:

- a plain sentence describing the selected day or current mode
- inline day/opportunity tags
- Pre-Fajr intention selection
- fasting-intention selection / override
- Fajr adhan toggle for eligible non-Ramadan fasting wakes

The card must not show:

- `Use usual plan`
- delivery status
- AlarmKit / notification fallback details
- source or provenance details
- rule explanations
- supported Fajr boundary language
- trust notes
- Fajr calculation diagnostics

---

## 11. Context card first sentence and copy principles

The first text in the context card must describe the current day or current mode in plain sentence form.

Do not use:

```text
Use usual plan
```

### Copy principles

All copy on this screen must be:

- plain English
- short enough to scan quickly
- understandable to users across age groups and English-reading comfort levels
- free of developer jargon
- free of duplicated meaning across nearby labels, chips, and controls
- reviewed both sentence-by-sentence and as a full screen

Avoid saying the same thing in multiple places. If a chip already communicates the selected fast type, the sentence should support it, not repeat it awkwardly.

---

## 12. Fasting-opportunity visibility in all modes

The context card must always address fasting opportunities in `Fajr`, `Pre-Fajr`, and `Quiet` modes.

### If Sunnah fasting opportunities exist

Show a sentence with inline opportunity chips.

Example:

```text
This day has Sunnah fasting opportunities: [Monday fast] [White Days fast] [Shawwal Six fast].
```

### If no Sunnah fasting opportunities exist

Show:

```text
There are no Sunnah fasting opportunities for this day.
```

When relevant, a second short sentence may explain that the user can still choose `Pre-Fajr` to plan another kind of fast:

```text
You can still choose Pre-Fajr to plan a Voluntary, Qada, Vow, Kaffarah, or Other fast.
```

Do not show empty chip rows.

---

## 13. Fasting-opportunity detection requirements

The detail screen must use the app’s canonical fasting-opportunity logic. It must not create a separate one-off opportunity engine.

The opportunity set must include all opportunities already supported by the app, including at minimum:

- Ramadan, handled separately and locked
- Monday / Thursday fasts
- White Days
- Shawwal Six, when still applicable
- Arafah
- Ashura / related Muharram opportunities supported by the app
- First nine of Dhul Hijjah, where supported by the app
- any other app-supported Sunnah fasting opportunity

### Monday / Thursday requirement

If the selected Gregorian day is Monday or Thursday and the app recognizes Monday / Thursday fasting, the context card must show the corresponding opportunity chip.

Examples:

```text
[Monday fast]
[Thursday fast]
```

Do not omit Monday / Thursday opportunities when they apply.

### Ramadan exception

During Ramadan, do not present other fasting opportunities as alternatives. Ramadan is the governing fast context.

---

## 14. Inline opportunity chip presentation

Opportunity tags should appear as inline, color-coded chips integrated into the sentence or immediately following it.

### Requirements

- Use the same color/tag styling system used elsewhere for fasting or day-significance tags.
- Chips should be baseline-aligned with surrounding text where possible.
- Chips should feel like part of the sentence, not like a disconnected list.
- Chips may wrap naturally across lines.
- Wrapping must preserve readable spacing and line height.
- Chips must not make the paragraph look broken, staggered, or misaligned.
- Multiple chips should maintain consistent spacing.
- VoiceOver must announce the sentence and the chip values in a logical order.

### Acceptable visual pattern

```text
This day has Sunnah fasting opportunities: [Monday fast] [White Days fast].
```

### Avoid

```text
This day has Sunnah fasting opportunities:

[Monday fast]
[White Days fast]
```

unless Dynamic Type requires stacked layout.

---

## 15. Mode-specific context copy

### Fajr mode with opportunities

```text
This day has Sunnah fasting opportunities: [Monday fast] [White Days fast].
```

### Fajr mode without opportunities

```text
There are no Sunnah fasting opportunities for this day. You can still choose Pre-Fajr and select Fasting to plan a Voluntary, Qada, Vow, Kaffarah, or Other fast.
```

### deferred Tahajjud-only with opportunities

```text
You are waking before Fajr for Tahajjud only. This day also has Sunnah fasting opportunities: [Monday fast] [White Days fast].
```

### deferred Tahajjud-only without opportunities

```text
You are waking before Fajr for Tahajjud only. There are no Sunnah fasting opportunities for this day.
```

Tahajjud-only mode should preserve day-significance information, but it must not show the fasting-intention selector.

### deferred Other early worship with opportunities

```text
You are waking before Fajr for other early worship. This day also has Sunnah fasting opportunities: [Monday fast] [White Days fast].
```

### deferred Other early worship without opportunities

```text
You are waking before Fajr for other early worship. There are no Sunnah fasting opportunities for this day.
```

### Suhoor with opportunities, default state

```text
You are waking before Fajr to fast. This fast will use today’s Sunnah opportunities by default: [Monday fast] [White Days fast].
```

If multiple opportunities apply, show all compatible default opportunities, capped only by the detail screen’s normal wrapping and readability rules.

### Suhoor without opportunities, default state

```text
You are waking before Fajr to fast. This will be saved as a Voluntary fast unless you choose another fast type.
```

### Suhoor with explicit override

Examples:

```text
You are waking before Fajr for a Qada fast.
```

```text
You are waking before Fajr for a Vow fast.
```

```text
You are waking before Fajr for a Kaffarah fast.
```

When an explicit fast type is selected, show the selected fast-type chip and hide the day’s opportunity chips from the selected fasting-intention area.

### Ramadan Pre-Fajr state

```text
You are waking before Fajr for Ramadan. Ramadan fast is locked for this date.
```

During Ramadan, the intention is locked to `Fasting` and the fasting intention is locked to `Ramadan fast`.

### Eid Pre-Fajr state

```text
You are waking before Fajr for Tahajjud only. Fasting is unavailable on Eid.
```

### Quiet Mode with opportunities

```text
Quiet Mode is on for this date. No alarm will ring. This day has Sunnah fasting opportunities: [Monday fast] [White Days fast].
```

### Quiet Mode without opportunities

```text
Quiet Mode is on for this date. No alarm will ring. There are no Sunnah fasting opportunities for this day.
```

## 16. Pre-Fajr intention control

When `Pre-Fajr` is selected, show a compact intention control.

Allowed intentions:

```text
Tahajjud only | Fasting | Other early worship
```

Do not include:

```text
Fasting + Tahajjud
Other
```

Use the explicit label `Other early worship` rather than unqualified `Other` so it cannot be confused with `Other fast` in the fasting-intention selector.

### Behavior

| Intention | Meaning | Fasting-intention selector |
|---|---|---|
| Tahajjud only | User is waking before Fajr for Tahajjud only | Hidden |
| Fasting | User is waking before Fajr for fasting / suhoor | Visible |
| Other early worship | User is waking before Fajr for another non-fasting worship purpose | Hidden |

Tahajjud and fasting should not be combined into a separate selectable state. `Other early worship` is also non-fasting; it must not create fasting completion requirements or fasting analytics credit.

### Default when selecting Pre-Fajr

- In Ramadan, `Pre-Fajr` defaults to locked `Fasting` / `Ramadan fast`.
- Outside Ramadan, `Pre-Fajr` defaults to `Tahajjud only`.
- Outside Ramadan, the user may switch the intention to `Fasting` if fasting is available for that date, or to `Other early worship` for a non-fasting Pre-Fajr purpose.
- On Eid days, `Fasting` is unavailable and `Pre-Fajr` defaults to `Tahajjud only` unless a product-approved non-fasting `Other early worship` choice is explicitly selected.

### Mode switching preservation

If the user changes from `Pre-Fajr` to `Fajr` or `Quiet`, preserve the selected Pre-Fajr intention for that date.

If the user later returns to `Pre-Fajr`, restore the preserved intention unless Ramadan or Eid rules override it.

Manual wake-time adjustment is not preserved across mode changes. Returning to `Pre-Fajr` uses the default Pre-Fajr wake anchor unless the user adjusts again.

## 17. Fasting-intention behavior

When the user selects `Pre-Fajr` + `Fasting`, the context card must show the selected fasting intention.

### Default if opportunities exist

All applicable Sunnah fasting opportunities for the selected date apply by default.

Examples:

```text
Selected fasting intention: [Monday fast]
```

```text
Selected fasting intention: [Monday fast] [White Days fast]
```

```text
Selected fasting intention: [Shawwal Six fast]
```

The user should be able to see the opportunity tags that are currently applying.

### Default if no opportunities exist

Default selection:

```text
[Voluntary fast]
```

### Override behavior outside Ramadan

The user may override the day’s default fasting opportunities with a specific fast type on non-Ramadan days where fasting is available.

Use the existing app fasting-intention taxonomy/list. Do not create a separate detail-screen-only list.

The selector should include the existing supported options, including at minimum. These are fasting intentions and are distinct from the Pre-Fajr non-fasting `Other early worship` intention:

- Voluntary fast
- Qada fast
- Vow / Nadhr fast
- Kaffarah fast
- Other fast

Implementation note: if the existing app already has a canonical enum/list for fasting intentions, source this selector from that enum/list so labels, ordering, persistence, and localization remain consistent.

### Returning to today’s opportunities

When Sunnah fasting opportunities exist, selecting `Voluntary fast` should restore the default opportunity-based purpose for that day.

This means:

- the selected display returns to the opportunity chips
- the explicit Qada / Vow / Kaffarah / Other chip disappears
- `Voluntary fast` must not appear as a duplicate generic chip beside the opportunity chips

Rationale: the day’s Sunnah opportunities are voluntary fasts. `Voluntary fast` is the user-friendly way to return from a specific override back to the opportunity set.

### Ramadan lock

During Ramadan:

- `Pre-Fajr` defaults to `Fasting`
- fasting intention is `Ramadan fast`
- intention is locked
- fasting intention is locked
- no other fasting intention is selectable

### Eid unavailability

On Eid days:

- `Fasting` is unavailable
- the fasting-intention selector is hidden
- `Pre-Fajr` defaults to `Tahajjud only`; `Other early worship` may remain available only as a non-fasting explicit choice when product rules allow it

### Duplication rule

Do not show duplicate options or duplicate selected chips.

In particular, `Voluntary fast` must not appear twice.

## 18. Ramadan behavior

Ramadan is special and locked.

### Ramadan defaults

```text
Mode: Pre-Fajr
Intention: Fasting
Fasting intention: Ramadan fast
Wake anchor: 30 minutes before Fajr begins
```

### Ramadan requirements

- Ramadan dates default to pre-Fajr waking.
- The wake anchor is Fajr begins.
- `Ramadan fast` is locked.
- The Pre-Fajr intention is locked to `Fasting` while the selected mode is `Pre-Fajr`.
- No other fasting purpose should be selectable during Ramadan.
- Other fasting opportunities should not be presented as alternatives during Ramadan.
- The user should not be asked whether Ramadan is the purpose.

### Ramadan mode changes

The user may still choose:

- `Fajr`, if they do not want a pre-Fajr suhoor wake for that date.
- `Quiet`, if they do not want a wake alarm for that date.

Ramadan remains the governing day context even if the user changes the wake mode.

If the user returns to `Pre-Fajr`, the screen must immediately restore:

```text
Suhoor + Ramadan fast
```

The user must not be able to return to `Pre-Fajr` during Ramadan and see `Tahajjud only`, `Other early worship`, `Voluntary fast`, Qada, Vow, Kaffarah, Other fast, or any non-Ramadan Sunnah opportunity as the selected intention.

## 19. Audio behavior

Do not expose broad audio selection.

The user should not see a general chooser such as:

```text
Fajr adhan | Wake alarm | Both
```

Audio should be automatic based on mode and intention.

### Automatic audio rules

| State | Wake-time audio | Fajr-begins audio | User-facing audio setting |
|---|---|---|---|
| Fajr | Fajr adhan audio wakes the user | Not separate by default | None |
| Suhoor, non-Ramadan | Generic wake alarm | Fajr adhan at Fajr begins | Toggle allowed |
| deferred Tahajjud-only, non-Ramadan | Generic wake alarm | Fajr adhan at Fajr begins by default | None |
| Quiet, non-Ramadan | No wake alarm | No extra event by default | None |
| Ramadan Pre-Fajr | Generic wake alarm | Fajr adhan at Fajr begins | Locked on |
| Ramadan Fajr | Fajr adhan audio wakes the user | Ramadan Fajr behavior remains on | Locked on |
| Ramadan Quiet | No wake alarm | Ramadan behavior follows existing locked Ramadan policy | Locked note only if needed |

### Fajr adhan toggle

The only exposed audio setting is:

```text
Fajr adhan at Fajr begins
```

This setting appears only when:

- mode is `Pre-Fajr`
- intention is `Fasting`
- date is not Ramadan

Default:

```text
On
```

If the user turns it off, the pre-Fajr wake alarm remains enabled. Only the later Fajr adhan event is disabled for that date.

Quiet suppresses wake alarm, notification, and adhan behavior for that date.

## 20. Internal alarm-state correction

The implementation must distinguish between:

1. whether an alarm/event is enabled
2. which audio is used for that alarm/event

Selecting Fajr adhan as the wake audio must **not** mean the alarm is off.

Required internal rule:

```text
Alarm off = Quiet Mode only
```

If the user is in `Fajr` mode and the wake sound is Fajr adhan, the alarm is still on. The wake alarm is enabled; its audio asset is Fajr adhan.

---

## 21. Detail-screen mutation and immediate-save contract

The Alarm Detailed View presents one selected day. MVP changes persist immediately through the shared mutation contract.

Required command flow:

```text
open selected date
    ↓
load canonical resolved snapshot
    ↓
user changes mode / intention / fasting intention / adhan toggle / wake time / reset
    ↓
commit selected-day mutation immediately
    ↓
Morning Resolution re-resolves selected date and affected surfaces
    ↓
Alarm Delivery refreshes only if the committed selected date is inside the active scheduled horizon
```

Rules:

- Tapping the currently selected mode or intention is idempotent.
- Switching modes clears ordinary manual wake-time adjustment and applies the selected mode's default wake anchor.
- Changing Suhoor fasting-purpose details stays within the Suhoor path and must not re-expose deferred non-Suhoor before-Fajr intentions.
- Selecting `Quiet` commits intentional suppression for the selected date and preserves the underlying Suhoor/Fajr state for restoration through the shared resolver.
- Permission failure, delivery failure, or missing platform pending state must never stage or commit `Quiet`.
- The screen must not call AlarmKit, UserNotifications, or delivery cancellation directly.

## 22. Navigation, Done, and Reset to Defaults

The Alarm Detailed View uses immediate-save edits with a deliberate exit affordance.

### Done exit

- The top-right navigation action is `Done`.
- The ordinary user-facing exit path is `Done`.
- Do not present a standard Back button as the primary exit action.
- Tapping `Done` returns to the previous screen; edits already committed as the user changed them.

### Platform back gestures

If the platform exposes an implicit back/swipe gesture, the implementation must ensure it cannot discard a visible committed edit.

Do not allow a silent exit that contradicts the immediate-save state shown on screen.

### Reset to Defaults

Show a prominent `Reset to Defaults` action when the selected date has user adjustments or date-specific overrides.

This action is separate from `Done` and must not behave like navigation.

Reset behavior:

| Date context | Reset result |
|---|---|
| Ordinary non-Ramadan day | `Fajr`, wake 30 minutes before Fajr ends |
| Non-Ramadan date with Suhoor override | Returns to ordinary `Fajr`, wake 30 minutes before Fajr ends |
| Ramadan day | `Suhoor` + `Ramadan fast`, wake 30 minutes before Fajr begins |
| Eid day | Default non-fasting behavior; fasting unavailable |

For MVP, `Reset to Defaults` commits immediately. `Done` remains the exit action, not the reset persistence boundary.


## 23. Persistence requirements

All settings on this screen are date-specific.

Expected date-specific persistence may include:

- selected wake mode: Pre-Fajr, Fajr, Quiet
- one-day wake timing override from the slider
- Pre-Fajr intention: Tahajjud only, Fasting, or Other early worship
- fasting-intention selection / override
- default opportunity-based fasting intention when opportunities apply
- Fajr adhan-at-Fajr-begins enabled state for non-Ramadan Suhoor

Do not introduce global settings from this screen.

The screen should persist user meaning, not a generated default copy. If the user opens a default day and taps `Done` without changing anything, the app should not create an unnecessary date-specific override record.

A committed `Other early worship` Pre-Fajr intention should be restorable after switching away from and back to `Pre-Fajr`, unless Ramadan or Eid rules override the selected-day state.

---

## 24. Accessibility requirements

- The navigation title should announce `Detailed View for the Day`.
- The hero should announce the selected Gregorian and Hijri dates.
- The primary wake time or `Quiet Mode` state should be announced clearly.
- The Quiet Mode moon icon should remain decorative unless it adds necessary meaning.
- The slider should support increment and decrement actions.
- The mode selector should expose selected state.
- Pre-Fajr intention selection should expose selected state, including `Other early worship` when selected or available.
- Fasting-intention selection should expose selected state.
- Inline opportunity chips should be read in the same logical order they appear visually.
- Locked Ramadan states should be announced as locked or unavailable.
- Dynamic Type should not clip the date line, primary wake time, slider labels, selector labels, context-card text, or inline chips.
- Mode changes should not cause large disorienting layout jumps.

---

## 25. Acceptance criteria

The implementation is successful when:

- The top title says `Detailed View for the Day`.
- The selected date is not used as the screen title.
- The detail hero visually matches the Home hero one-to-one.
- The detail hero primary wake time is in the same vertical position as the Home hero primary wake time.
- The detail hero is not pushed lower than the Home hero.
- The Gregorian · Hijri date appears directly above the primary wake time.
- The date line does not push the primary wake time downward.
- The Home hero relative-day line is not shown in the detail hero.
- The location line is not shown in the detail hero.
- Everything below the primary wake time remains aligned with the Home hero.
- The adjustment slider is present and active for `Pre-Fajr` and `Fajr`.
- The slider behaves like the Home hero slider.
- The mode selector matches the Home hero selector.
- Quiet state displays `Quiet Mode`.
- The Quiet Mode moon icon remains visible in the detail hero.
- The context card appears below the hero for all modes.
- The context card uses the same liquid-glass treatment as Home supporting cards.
- The context card does not show `Use usual plan`.
- Fajr mode card copy explains whether Sunnah fasting opportunities exist.
- Pre-Fajr mode card copy explains whether Sunnah fasting opportunities exist.
- Quiet Mode card copy says no alarm will ring.
- If no Sunnah fasting opportunities exist, the card says so plainly.
- Monday opportunities appear on Mondays when applicable.
- Thursday opportunities appear on Thursdays when applicable.
- Opportunity chips use the approved color/tag styling.
- Opportunity chips are integrated cleanly with sentence copy.
- Selecting `Pre-Fajr` reveals or exposes `Tahajjud only`, `Fasting`, and `Other early worship` intention options.
- `Fasting + Tahajjud` and unqualified `Other` do not appear as Pre-Fajr intentions; the non-fasting Other option is explicitly labeled `Other early worship`.
- Selecting `deferred Tahajjud-only` or `deferred Other early worship` keeps fasting opportunities informational only.
- Selecting `Suhoor` defaults to all applicable Sunnah fasting opportunities when they exist.
- Selecting `Suhoor` defaults to `Voluntary fast` when no opportunity exists.
- Selecting Qada / Vow / Kaffarah / Other fast replaces opportunity chips with the selected fasting-intention chip.
- Selecting `Voluntary fast` returns to opportunity chips when opportunities exist.
- The fasting-intention selector uses the existing app fasting-intention list/taxonomy.
- `Voluntary fast` does not appear twice.
- Ramadan defaults to `Pre-Fajr` + `Fasting` + `Ramadan fast`.
- Ramadan fasting intention is locked and cannot be overridden.
- Broad audio selection controls are not shown.
- The only exposed audio setting is the eligible non-Ramadan `Suhoor` Fajr adhan toggle.
- Selecting Fajr adhan as wake audio does not mark the alarm as off internally.
- Quiet Mode is the only user-facing way to turn off the wake alarm.
- Source, rule, delivery, fallback, trust, and reliability sections are not shown.
- All edits remain date-specific.
- Full-screen copy reads naturally without redundant labels, repeated meanings, or awkward sentence/chip alignment.

---

## 26. Non-goals

This screen is not responsible for:

- global alarm behavior settings
- full audio profile management
- notification reliability education
- AlarmKit explanation
- source/provenance management
- recurring plan deletion
- detailed Islamic observance education
- full fasting-program management
- iftar management
- debugging Fajr calculation fallbacks
- manual time-entry alternatives to the slider

---

## 27. Recommended v7 implementation slice

1. Change the navigation title to `Detailed View for the Day`.
2. Refactor/reuse the Home hero so the detail hero matches it one-to-one.
3. Fix hero vertical positioning so the primary wake time is anchored to the exact Home hero wake-time position.
4. Ensure the Gregorian · Hijri date sits above the wake time without pushing it down.
5. Preserve the Home hero slider, selector, animations, and Quiet Mode moon icon.
6. Add or update the always-present liquid-glass context card below the hero.
7. Remove `Use usual plan` from all card states.
8. Add mode-specific sentence copy for Fajr, deferred Tahajjud-only, deferred Other early worship, Suhoor, and Quiet Mode.
9. Ensure every mode states whether Sunnah fasting opportunities exist.
10. Ensure Monday / Thursday opportunities are detected and shown when applicable.
11. Render opportunity tags as inline, color-coded chips integrated with sentence copy.
12. Keep `Pre-Fajr` intention options explicit and contract-aligned: `Tahajjud only`, `Fasting`, and `Other early worship`.
13. Default `Suhoor` to all applicable opportunity chips when opportunities exist.
14. Replace opportunity chips with selected fasting-intention chips for Qada / Vow / Kaffarah / Other fast overrides.
15. Use `Voluntary fast` as the return path to opportunity chips when opportunities exist.
16. Source fasting-intention options from the existing app fasting-intention taxonomy and remove duplicate `Voluntary fast` entries.
17. Keep Ramadan locked to `Ramadan fast`.
18. Keep only the eligible non-Ramadan `Suhoor` Fajr adhan toggle.
19. Preserve the internal alarm semantics: Fajr adhan audio does not mean alarm off.
20. Add snapshot/presentation coverage for Fajr with opportunities, Fajr without opportunities, deferred Tahajjud-only, deferred Other early worship, Suhoor with opportunities, Suhoor with no opportunities, Suhoor with override, Quiet Mode with opportunities, Quiet Mode without opportunities, Monday / Thursday opportunity days, Ramadan states, and Eid states.



---

## 28. v7 non-removal guardrail

This v7 update is a reconciliation patch, not a screen redesign. Do not remove v6 title, hero parity, date-line placement, context-card structure, opportunity chip behavior, Ramadan/Eid rules, Fajr adhan-at-Fajr-begins toggle, Done exit, Reset-to-Defaults presence, accessibility requirements, or non-goals unless a later named spec explicitly supersedes them.

The behavior-level additions in v7 are the shared mutation-contract alignment, Suhoor MVP terminology, distinction between `Other fast` and deferred Other early worship, immediate-save Detail edits, immediate Reset to Defaults, and Quiet-versus-delivery-failure separation.
