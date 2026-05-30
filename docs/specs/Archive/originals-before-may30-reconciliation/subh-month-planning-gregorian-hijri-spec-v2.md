

## May 29 Month Planning Quiet / Pause Alignment Addendum

This May 29 alignment is normative for MVP and supersedes conflicting lower/historical wording in this file.

- `Fajr` and `Suhoor` are the only exposed MVP wake purposes.
- `Quiet` is a one-morning alarm/sound override, not a wake purpose.
- `Pause` is an indefinite app-wide wake-alarm policy, not a wake purpose.
- User-facing MVP copy must not expose `Pre-Fajr`, `Early`, `Fast mode`, `Fasting mode`, `Quiet mode`, or `Pause mode` as visible wake purposes.
- Internal/code terms may remain where required for compatibility, but visible surfaces must use `Fajr`, `Suhoor`, `Quiet`, `Alarms paused`, `Time to wake`, `I’m awake`, `I’m fasting today`, and `I prayed Fajr` according to `subh-quiet-pause-hero-wake-flow-alignment-spec-v1.md`.

Month Planning remains a longer-range navigation and planning surface. It must distinguish:

```text
manual Quiet date
inherited Paused state
rings-once exception
active Fajr/Suhoor plan
setup/issue state where relevant
```

Month cells/list rows should navigate to Day Detail for Quiet/Pause edits rather than exposing direct multi-date Pause controls in MVP.

Date-range Pause is out of MVP. Future range silence, if introduced, should be modeled as `Quiet selected mornings`.


# Subh Month Planning — Gregorian and Hijri Month Browsing Spec v2

**Status:** Draft v2 — implementation-ready pending repo mapping
**Date:** 2026-05-22
**Supersedes:** `subh-month-planning-gregorian-hijri-spec-v1.md`
**Feature area:** Future morning planning / month planning
**Primary surfaces:** Home, Plan ahead, Month Picker, Month Detail, Day Detail
**Related specs:** Morning Resolution Contract, Planning Horizon / Day Resolution / Intention Anchoring, Next 7 Mornings, Weekly Fajrcast, Day Detail, Hijri Date Adjustment, Pricing Entitlement

---

## 0. V2 change summary

This v2 update preserves the v1 month-planning model and locks the following refinements:

1. Month Planning belongs inside the Home **Plan ahead** section.
2. The **Plan ahead** section order is:
   1. Next 7 Mornings card
   2. Calendar Months tile
   3. Hijri Months tile
3. The **Plan ahead** heading must use a white/high-contrast text treatment against the Home background.
4. Calendar/Hijri home tiles must keep a stable square/near-square footprint across Dynamic Type changes.
5. Month Picker should use a two-column tile/card grid where space allows, not row-like full-width list cards.
6. Month Picker cards should visually relate to the Calendar Months / Hijri Months home tiles.
7. Month Detail morning rows should visually match the Next 7 Mornings expanded rows.
8. Month Detail rows use the same compact row doctrine: **date context | opportunity/context tags | wake time/status**.
9. Middle-lane tags in Month Detail are opportunity/context tags only.
10. Quiet appears in the trailing lane as `Quiet`, not as a middle-lane tag.
11. User-facing copy should prefer **mornings** over **days** wherever possible.

No change is made to the core v1 rules: current month + next 12 months, no generated records from browsing, one Hijri source of truth, no past morning planning, Day Detail owns edits, and Monthly Fajrcast remains a separate future spec.

---

## 1. Purpose

Subh should support **month-level planning** for future mornings.

This feature is not a generic calendar browser. It is a planning surface that lets the user look beyond the immediate Next 7 Mornings view and intentionally review or adjust upcoming Subh mornings by either:

1. **Calendar month** — Gregorian month planning.
2. **Hijri month** — Islamic month planning.

The user starts from the Home **Plan ahead** section, chooses a calendar system, selects a month, sees a month-level planning screen, and can open an individual morning into the existing Day Detail view.

---

## 2. Product principles

1. **Fajr remains the core anchor.**
   Month planning extends the existing Fajr-centered morning system; it does not create a second scheduling engine.

2. **The feature plans mornings, not alarms.**
   A listed item may resolve to Fajr, Suhoor, Quiet, or another allowed state. Therefore, product copy should use “mornings,” not “alarms,” except when referring to an actual scheduled wake alarm.

3. **Use “mornings” instead of “days” wherever possible.**
   The product is planning wake mornings, not general calendar days.

4. **Defaults are generated, not stored.**
   Opening a month must not create 29, 30, or 31 stored decisions.

5. **Only explicit user edits are persisted.**
   Browsing a month is read/display behavior. Durable records are created only when the user intentionally changes a morning.

6. **Month browsing is not active platform scheduling.**
   Month planning may store future intentions or overrides, but it must not schedule platform alarms for every future morning. Active alarm scheduling remains governed by the existing alarm delivery and scheduling reliability specs.

7. **Hijri logic must use one source of truth.**
   Hijri month labels, Hijri date rows, Ramadan detection, Suhoor defaults, and Day Detail must all use the same Hijri authority and adjustment model.

8. **No past morning planning.**
   Month detail lists should show only actionable / unresolved mornings. Past mornings should not appear in the planning list.

---

## 3. User-facing information architecture

### 3.1 Home Plan ahead section

Add or update a Home section with the heading:

```text
Plan ahead
```

The section order is:

```text
Plan ahead
  [Next 7 Mornings card]
  [Calendar Months tile] [Hijri Months tile]
```

The Next 7 Mornings card appears first because it is the immediate planning surface. The month-planning tiles appear below it because they are longer-range planning entry points.

### 3.2 Plan ahead heading visual treatment

The **Plan ahead** heading must remain readable over the Home background.

Required behavior:

- Use white or the approved high-contrast Home section-heading token.
- Avoid low-opacity grey if it loses contrast against the tinted/dark dawn background.
- The heading should align visually with other Home section headings.

### 3.3 Home month-planning entry tiles

Add a compact two-tile entry area below the Next 7 Mornings card.

Recommended tile copy:

```text
Calendar Months
Plan by Gregorian month
```

```text
Hijri Months
Plan by Islamic month
```

### 3.4 Home tile layout and Dynamic Type behavior

- Tiles are visually paired and should appear as two half-width square or near-square cards where space allows.
- On narrow layouts, very large Dynamic Type, or constrained web/mobile widths, the tiles may stack vertically.
- The external tile footprint should remain stable across ordinary iOS text-size changes.
- Dynamic Type may affect internal text layout, wrapping, or truncation rules, but should not cause the tile shell to grow unpredictably.
- Tiles should feel lighter than full-width Home cards such as the Home hero, Next 7 Mornings, Weekly Fajrcast, and the context window.
- Tiles are navigation surfaces, not data-heavy dashboards.

### 3.5 Copy guardrails

Use:

- “Plan ahead”
- “Next 7 Mornings”
- “Calendar Months”
- “Plan by Gregorian month”
- “Hijri Months”
- “Plan by Islamic month”
- “May mornings”
- “Ramadan mornings”
- “Dhul Hijjah mornings”

Avoid:

- “Next 7 Days” as visible product copy
- “Regular month”
- “Alarm list”
- “All alarms”
- “History calendar”
- “Hegri”
- Any copy that makes Hijri browsing look like a separate product lane

---

## 4. Navigation flow

The feature uses a three-level planning flow.

```text
Home
  → Calendar Months / Hijri Months
    → Month Picker
      → Month Detail
        → Day Detail
```

### 4.1 Home to Month Picker

- Tapping **Calendar Months** opens the Gregorian Month Picker.
- Tapping **Hijri Months** opens the Hijri Month Picker.

### 4.2 Month Picker to Month Detail

- The picker shows the current month plus the next 12 months for the selected calendar system.
- Tapping a month opens its Month Detail screen.

### 4.3 Month Detail to Day Detail

- Tapping a morning row opens the existing Day Detail view for that resolved morning.
- The Day Detail screen should reuse the existing detail behavior, editing rules, and persistence rules.
- Returning from Day Detail should return the user to the selected Month Detail screen.

---

## 5. Browse horizon

### 5.1 Horizon definition

The month picker shows:

```text
Current month + next 12 months
```

This creates up to 13 visible month buckets.

### 5.2 Gregorian horizon

For Calendar Months:

```text
Current Gregorian month + next 12 Gregorian months
```

Example, if the active planning date is May 17, 2026:

```text
May 2026 through May 2027
```

### 5.3 Hijri horizon

For Hijri Months:

```text
Current Hijri month + next 12 Hijri months
```

The current Hijri month is determined by the app’s active Hijri authority, Hijri adjustment, location/time-zone context, and morning-resolution model.

### 5.4 Current month behavior

The current month may be partial.

- Past mornings do not appear in Month Detail.
- Only actionable / unresolved mornings appear.
- If only one actionable morning remains, the Month Detail list shows one morning.
- If no actionable mornings remain in the current month, the Month Picker should keep the current month in the horizon but mark it unavailable, for example:

```text
May 2026
No remaining mornings
```

If a stale deep link opens a current-month detail with no remaining mornings, show a simple empty state and route the user back to the picker or the next available month.

### 5.5 Future month behavior

For a fully future month:

- Show all mornings in that selected month.
- Gregorian months may contain 28, 29, 30, or 31 mornings.
- Hijri months may contain 29 or 30 mornings according to the app’s Hijri authority and adjustment model.

---

## 6. Month Picker behavior

### 6.1 Picker layout

The Month Picker should use a tile/card grid, not a row-heavy table.

Required direction:

- Use two-column half-width cards where space allows.
- Cards should be square or near-square, similar in visual language to the Home Calendar Months / Hijri Months tiles.
- On narrow layouts or large Dynamic Type, cards may stack vertically.
- Card sizing should be stable and predictable.
- Avoid long full-width row cards unless required by extreme accessibility constraints.

### 6.2 Gregorian Month Picker

Recommended title:

```text
Calendar Months
```

Recommended subtitle:

```text
Choose a month to plan your mornings.
```

Each card should show:

- Gregorian month name and year;
- corresponding Hijri date range or Hijri month context;
- remaining or total morning count;
- locked/unavailable state if entitlement or actionability requires it.

Example card:

```text
May 2026
Dhul Qi’dah 14 – Dhul Hijjah 15
12 mornings left
```

Example future card:

```text
June 2026
Dhul Hijjah 16 – Muharram 15
30 mornings
```

### 6.3 Hijri Month Picker

Recommended title:

```text
Hijri Months
```

Recommended subtitle:

```text
Choose an Islamic month to plan your mornings.
```

Each card should show:

- Hijri month name and Hijri year;
- corresponding Gregorian date range;
- remaining or total morning count;
- optional Ramadan/context where allowed;
- locked/unavailable state if entitlement or actionability requires it.

Example card:

```text
Ramadan 1447
Feb 18 – Mar 19
30 mornings
```

```text
Dhul Hijjah 1447
May 18 – Jun 16
29 mornings
```

### 6.4 Picker ordering

- Cards appear in chronological order.
- The current month appears first.
- The 12 following months appear after it.
- The picker should not expose arbitrary past browsing in this feature.

---

## 7. Month Detail screen

### 7.1 Screen structure

Each Month Detail screen contains:

1. Navigation title / selected month identity.
2. Monthly Fajrcast card slot.
3. Month morning list.
4. Optional entitlement or contextual guidance where needed.

Recommended Gregorian structure:

```text
[Navigation title: May 2026]

[Monthly Fajrcast card]

May mornings
[Morning row]
[Morning row]
[Morning row]
...
```

Recommended Hijri structure:

```text
[Navigation title: Ramadan 1447]

[Monthly Fajrcast card]

Ramadan mornings
[Morning row]
[Morning row]
[Morning row]
...
```

### 7.2 Section labels

Use natural month-specific labels:

- “May mornings”
- “June mornings”
- “Ramadan mornings”
- “Dhul Hijjah mornings”

Do not label the section “Alarms.”

### 7.3 Monthly Fajrcast slot

The Monthly Fajrcast placeholder remains at the top of Month Detail.

This spec does not define the Monthly Fajrcast chart design in detail. That should be handled by a separate Monthly Fajrcast Card Spec.

The placeholder should be visually clean and production-safe. It must not create stored decisions or schedule platform alarms.

### 7.4 Month Detail row visual alignment

Month Detail morning rows should visually match the expanded Next 7 Mornings row system.

Required row concept:

```text
primary/secondary date lane | opportunity/context tag lane | trailing wake/status lane
```

Rules:

- Do not create a visually unrelated month-row card style.
- Reuse or closely mirror the Next 7 Mornings row spacing, dividers, typography, and three-lane grid.
- The main difference from Next 7 Mornings is that Month Detail rows may show both Gregorian and Hijri date context in the left lane.
- Row heights should be stable within the selected month list for the current Dynamic Type profile.
- Quiet rows must not shrink.

---

## 8. Month Detail row behavior

### 8.1 Row purpose

Each row represents one resolved Subh morning in the selected month.

The row should summarize the morning enough for scanning and should open Day Detail for full control.

### 8.2 Gregorian Month Detail row emphasis

In Calendar Month mode, the Gregorian date is primary and the Hijri date is secondary.

Example:

```text
Thu, May 21
Dhul Hijjah 4        [White Days]        4:18 AM
```

### 8.3 Hijri Month Detail row emphasis

In Hijri Month mode, the Hijri date is primary and the Gregorian date is secondary.

Example:

```text
Ramadan 12
Thu, Feb 19          [Ramadan]           5:12 AM
```

### 8.4 Opportunity/context tag lane

The middle lane follows the Next 7 Mornings v2 tag doctrine.

Allowed middle-lane tags include:

- `Ramadan`
- `Eid`
- `Fasting unavailable`, or compact `No fast` if needed
- `Ashura`
- `Arafah`
- `Dhul Hijjah`
- `White Days`
- `Shawwal 6`
- other approved observance/context tags supplied by the domain model

Do not show these as middle-lane tags:

- `Fajr`
- `Fasting`
- `Suhoor`
- `Tahajjud`
- `Quiet mode`
- `Mon/Thu`
- `Qada`
- `Kaffarah`
- `Vow`

Ordinary mornings may have an empty middle lane.

### 8.5 Trailing wake/status lane

The rightmost lane shows the resolved wake time or compact status.

Rules:

- Wake-enabled rows show the resolved wake time.
- Quiet rows show `Quiet` in the trailing lane.
- Quiet does not appear as a middle-lane tag.
- The trailing lane should remain visually aligned across rows.
- The trailing lane should use the same time/status treatment as Next 7 Mornings wherever possible.

### 8.6 Row interaction

- Tapping an actionable row opens Day Detail.
- Rows that are not editable because of entitlement may still open a read-only or upgrade-oriented detail state, depending on the entitlement spec.
- Rows that are not actionable because the morning has passed should not appear in the list.

---

## 9. Current month detail

For the current month, the list includes only remaining actionable / unresolved mornings.

Example, if May 1–16 are no longer actionable:

```text
May mornings
May 17
May 18
May 19
...
May 31
```

If May 17 is also no longer actionable according to the app’s morning-resolution boundary, the list begins with May 18.

---

## 10. Selected future month detail

For a future month, show every morning in the selected month.

Example:

```text
June mornings
June 1
June 2
June 3
...
June 30
```

---

## 11. Monthly Fajrcast integration contract

The Month Detail screen reserves a top card area for a future **Monthly Fajrcast** component.

The Month Detail screen must provide the Monthly Fajrcast component with:

- selected calendar mode: Gregorian or Hijri;
- selected month identity;
- selected month date range;
- visible/actionable morning range;
- resolved morning snapshots for the selected month, where available;
- entitlement state;
- Hijri authority / adjustment snapshot when in Hijri mode.

Behavior guardrails:

- The Monthly Fajrcast must reflect the selected month.
- It must not create stored decisions by rendering.
- It must not schedule platform alarms by rendering.
- If it eventually supports tapping or scrubbing, those interactions must coordinate with the same resolved morning rows used by the list.
- Past mornings must not become actionable through the card.

---

## 12. Day Detail integration

The Month Detail screen must not create a separate day-editing model.

When a row is tapped:

- Open the existing Day Detail screen.
- Pass the canonical resolved morning identity.
- Pass the source calendar context: Gregorian month or Hijri month.
- Preserve the selected month navigation context for back navigation.
- Let Day Detail own editing, validation, and persistence.

### 12.1 Source calendar context

The source calendar context matters because Subh stores user meaning, not merely display dates.

- Edits made from **Calendar Month** mode should default to a Gregorian-date planning anchor unless the Day Detail screen explicitly offers another meaning.
- Edits made from **Hijri Month** mode should default to a Hijri-date planning anchor when the user’s action is naturally tied to the Hijri date.
- Observance-specific or Hijri-month-wide rules are out of scope for this spec unless already supported elsewhere.

---

## 13. Hijri source-of-truth rules

### 13.1 Single Hijri authority

The Hijri month planner must use the same Hijri authority used by the rest of Subh.

This includes:

- Hijri month names;
- Hijri year;
- month start/end boundaries;
- 29/30-day month length;
- Ramadan detection;
- observance detection;
- Hijri date adjustment / offset;
- Day Detail date labels;
- any Ramadan or Suhoor default logic.

### 13.2 Hijri adjustment impact

If the user applies a Hijri date adjustment:

- Hijri month picker labels must update.
- Hijri month date ranges must update.
- Hijri row labels must update.
- Ramadan defaults must shift.
- Suhoor/Fasting defaults tied to Ramadan must shift where allowed by entitlement and existing resolver rules.
- Hijri-date and observance-anchored future intentions should move according to the intention anchoring rules.
- Gregorian-date-anchored future intentions should remain on their Gregorian date.
- Completed history must not move.

The month planner must not implement a separate migration rule. It must delegate to the existing intention anchoring and morning-resolution model.

### 13.3 No drift rule

No screen may identify the same morning differently.

For example, it is invalid for:

- the Hijri Month Picker to label a morning as Ramadan 1;
- the Month Detail row to label it as Sha’ban 30;
- and Day Detail to apply a non-Ramadan default.

All surfaces must agree through the same resolved morning snapshot.

---

## 14. State, resolution, and persistence

### 14.1 Generated month data

Month Detail is generated on demand from the existing morning-resolution system.

Opening a month must not create stored records.

Invalid behavior:

- user opens May 2026;
- app writes 31 morning records;
- user exits without editing.

Correct behavior:

- user opens May 2026;
- app resolves visible mornings for display;
- user exits;
- no durable morning decisions are created.

### 14.2 Explicit edits

A durable record is created only when the user explicitly changes a morning in Day Detail or through another approved planning interaction.

Examples:

- changing a future morning from Fajr to Quiet;
- changing a future morning from Fajr to Suhoor where entitlement allows;
- changing wake offset for a specific morning;
- resetting a previously stored override.

### 14.3 Global settings changes

If the user changes a global setting:

- untouched future mornings should re-resolve automatically;
- stored user intentions/overrides should preserve their meaning;
- anchored intentions should follow their anchor rules;
- generated defaults should not be treated as user decisions.

### 14.4 Operational scheduling

Month planning may create future intentions, but it must not schedule all future platform alarms.

The active alarm scheduling system remains responsible for deciding when a future plan becomes an actual scheduled alarm.

---

## 15. Entitlement rules

This feature must use the shared entitlement model. Do not hardcode tier behavior independently inside the Month Planner UI.

During active development, a debug/development entitlement override may expose the full feature set so implementation can be tested end to end. Release/production behavior must remain routed through the real entitlement model unless a later pricing spec changes it.

### 15.1 Free

Free users:

- can use the immediate core experience and Next 7 Mornings according to the pricing spec;
- see month-planning entry points as locked or preview-only;
- cannot use Month Picker / Month Detail for future planning control;
- cannot create future month-level planning edits.

Recommended locked tile behavior:

```text
Calendar Months
Plan by Gregorian month
[Locked]
```

```text
Hijri Months
Plan by Islamic month
[Locked]
```

Tapping a locked tile should open the approved upgrade or feature-preview experience.

### 15.2 Plus

Plus users:

- can access durable month-level history, summaries, analytics, historical editing, Qada ledgers, export/sync, and other paid-layer overlays where those features are implemented;
- can view preserved Plus-layer data after downgrade according to the active pricing entitlement spec;
- must use the same generated future-morning resolver as Free.

### 15.3 Free/core planning

Free/core users:

- can access Calendar Month planning where this surface is implemented;
- can access Hijri Month planning where this surface is implemented;
- can browse the current month plus the next 12 months;
- can plan allowed future Fajr-oriented mornings;
- can use allowed Suhoor / Fajr / Quiet controls across the planning horizon;
- can view Hijri and Ramadan context where the resolver provides it.

The historical Complete tier is superseded by `subh-pricing-entitlement-spec-v3.md` and is not an active MVP pricing concept.

### 15.4 MVP guardrail

Do not reintroduce Tahajjud or non-fasting before-Fajr wake planning through this feature unless a future spec explicitly restores it.

The active MVP quick-mode language remains aligned to:

```text
Fajr | Suhoor
```

---

## 16. Loading, empty, and error states

### 16.1 Loading

Show lightweight skeleton rows/cards or a simple loading state while resolving month data.

Avoid blocking the whole app if only one row fails to resolve.

### 16.2 No remaining mornings

If the current month has no remaining actionable mornings:

- Month Picker should mark the current month as unavailable.
- Month Detail should avoid showing an empty planning screen unless opened through stale navigation.
- A stale Month Detail should show:

```text
No remaining mornings in this month.
Choose another month to plan ahead.
```

### 16.3 Calculation unavailable

If Fajr times or date data cannot be resolved for one or more mornings:

- show a clear unavailable state;
- do not invent wake times;
- do not schedule alarms from incomplete data;
- allow retry once the underlying resolver can provide valid data.

### 16.4 Location or time-zone changes

Month planning should use the same active location and time-zone model as the rest of Subh.

If the active location or time zone changes:

- generated month data should re-resolve;
- untouched future mornings should update;
- stored intentions should preserve their anchor meaning according to the planning horizon and intention anchoring rules.

---

## 17. Accessibility and responsive behavior

### 17.1 Home tiles

- Tiles must be large enough for comfortable touch targets.
- Tile title and subtitle should scale with Dynamic Type.
- The tile shell should remain stable across ordinary text-size changes.
- At large Dynamic Type sizes, internal text may wrap or use approved truncation, but the tile should not unpredictably resize and disrupt the Home layout.
- Lock states must not rely on icon-only communication.

### 17.2 Month Picker cards

- Month cards must be accessible by VoiceOver / screen readers.
- The card should announce the month name, complementary calendar range, morning count, and locked/unavailable state.
- Two-column layout may stack vertically at large Dynamic Type sizes.

### 17.3 Month Detail rows

- Rows must be accessible by VoiceOver / screen readers.
- Date labels should be read in natural order based on selected calendar mode.
- Accessibility may include hidden intention state not visible in the compact tag lane.
- Quiet rows should announce Quiet status clearly.
- Dynamic Type must not clip the date, context tags, or trailing wake/status.

---

## 18. Performance and implementation guidance

### 18.1 Lazy resolution

Month data should be resolved on demand.

Do not eagerly calculate or store every month in the 13-month horizon if only the picker is visible.

### 18.2 Caching

Use safe, invalidatable caching keyed by relevant resolver inputs, such as:

- selected calendar mode;
- selected month identity;
- active location/time zone;
- Hijri authority / adjustment snapshot;
- settings revision;
- entitlement state;
- explicit intention/override revision.

### 18.3 List rendering

Month Detail may contain up to 31 rows. Use simple list virtualization/lazy layout where appropriate, but avoid unnecessary complexity.

### 18.4 No duplicate calculation logic

The Month Planner UI must not independently calculate:

- Fajr begins;
- Fajr ends;
- wake time;
- Ramadan detection;
- Eid or fasting-unavailable context;
- Hijri month boundaries;
- whether a morning is actionable;
- entitlement-allowed actions.

It should request resolved data from the existing domain services.

---

## 19. Suggested data contract

Names are illustrative only. Use existing project naming where available.

```swift
enum MonthPlanningCalendarMode {
    case gregorian
    case hijri
}
```

```swift
struct MonthPlanningPickerMonth {
    let id: MonthPlanningMonthID
    let calendarMode: MonthPlanningCalendarMode
    let title: String
    let subtitle: String
    let complementaryDateRangeText: String
    let visibleMorningCount: Int
    let availability: MonthPlanningAvailability
}
```

```swift
struct MonthPlanningSnapshot {
    let month: MonthPlanningPickerMonth
    let dateRange: MorningDateRange
    let visibleMornings: [ResolvedMorningSnapshot]
    let monthlyFajrcastInput: MonthlyFajrcastInput
    let entitlementState: MonthPlanningEntitlementState
    let hijriAuthoritySnapshot: HijriAuthoritySnapshot?
}
```

```swift
struct MonthPlanningMorningRowDisplay: Identifiable, Equatable {
    let id: String
    let primaryDateLabel: String
    let secondaryDateLabel: String
    let contextTags: [MorningContextTagDisplay]
    let trailingTime: Date?
    let trailingStatusText: String? // e.g. Quiet
    let accessibilityLabel: String
}
```

The actual implementation should map this concept onto existing app models rather than introducing unnecessary parallel types.

---

## 20. Non-goals

This spec does not define:

- the detailed Monthly Fajrcast chart design;
- month-level bulk editing;
- arbitrary past month browsing;
- completed-history browsing;
- Qada history or progress logging;
- a new Hijri adjustment settings screen;
- a second wake/scheduling engine;
- new Tahajjud or non-fasting before-Fajr planning behavior;
- pricing copy beyond entitlement behavior;
- changes to alarm delivery reliability rules.

---

## 21. Acceptance criteria

### 21.1 Home

- Home displays a **Plan ahead** section.
- The Plan ahead heading uses white/high-contrast styling.
- Plan ahead shows Next 7 Mornings above the month-planning tiles.
- Home displays two compact month-planning tiles: Calendar Months and Hijri Months.
- Tile copy matches the approved language.
- Month-planning tile shells maintain stable square/near-square sizing across ordinary text-size changes.
- Free users see locked or preview-only behavior unless a debug/development override is active.
- Free users can enter implemented core month-planning surfaces; Plus may add paid-layer overlays according to entitlement.

### 21.2 Month Picker

- Calendar Month Picker uses grid/tile cards, not row-like full-width cards, where space allows.
- Hijri Month Picker uses grid/tile cards, not row-like full-width cards, where space allows.
- Picker cards visually relate to the Home Calendar/Hijri tiles.
- Calendar Month Picker shows current Gregorian month plus next 12 Gregorian months.
- Hijri Month Picker shows current Hijri month plus next 12 Hijri months.
- The current month appears first.
- Month labels use full, human-readable month names.
- Gregorian cards show relevant Hijri date-range context.
- Hijri cards show relevant Gregorian date-range context.
- Hijri months respect the active Hijri authority and adjustment.
- Current month is marked unavailable if no actionable mornings remain.

### 21.3 Month Detail

- Selected month opens a Month Detail screen.
- Screen includes a Monthly Fajrcast card slot.
- Screen includes a list of mornings, not alarms.
- Month rows visually match the Next 7 Mornings expanded row system.
- Current month excludes past/non-actionable mornings.
- Future months show all mornings in the selected month.
- Gregorian Month Detail rows emphasize Gregorian date first and Hijri date second.
- Hijri Month Detail rows emphasize Hijri date first and Gregorian date second.
- Middle-lane tags are opportunity/context tags only.
- Routine `Fajr`, `Fasting`, `Suhoor`, `Tahajjud`, and `Quiet mode` tags do not appear in the middle lane.
- Quiet appears as trailing `Quiet`.
- Tapping a morning opens the existing Day Detail screen.

### 21.4 Persistence

- Opening a month creates no stored morning records.
- Leaving a month without edits creates no stored morning records.
- Explicit edits create the appropriate anchored intention or override.
- Untouched future mornings re-resolve after global settings changes.
- Hijri-date and observance-anchored intentions follow Hijri adjustment rules.
- Gregorian-date-anchored intentions remain on their Gregorian dates.

### 21.5 Entitlement

- Plus unlocks both Gregorian and Hijri month planning surfaces.
- Free/core supports allowed Suhoor/Fajr/Quiet future planning controls.
- Plus unlocks durable history, historical editing, Qada ledgers, export/sync, analytics, summaries, and other paid-layer overlays where implemented.
- UI behavior is driven by the shared entitlement model.
- Debug/development override may expose unreleased paid-layer overlays without changing Release/production entitlement doctrine.

### 21.6 Guardrails

- No duplicate Hijri logic is introduced.
- No duplicate Fajr/wake calculation logic is introduced.
- No future platform alarms are scheduled merely because a month was opened.
- Past mornings are not displayed in the planning list.
- Tahajjud/non-fasting before-Fajr planning is not reintroduced.

---

## 22. Required follow-up work

1. Create a separate **Monthly Fajrcast Card Spec**.
2. Update the Pricing Entitlement Spec to reference month planning explicitly.
3. Update the Interaction Inventory to include:
   - Home Plan ahead section;
   - Next 7 Mornings expand/collapse;
   - Home tile taps;
   - Month picker card selection;
   - Month detail row taps;
   - locked/preview states;
   - Day Detail return flow.
4. Verify the Planning Horizon / Intention Anchoring spec aligns with:
   - current month + next 12 months;
   - Gregorian-date anchors from Calendar Month mode;
   - Hijri-date anchors from Hijri Month mode;
   - no durable records from browsing alone.
5. Confirm implementation uses existing resolved-morning and scheduling services rather than creating a parallel month-planning engine.

---

## 23. Final product statement

Subh month planning lets users plan meaningful future mornings by either Gregorian month or Hijri month. It extends the existing Fajr-centered morning system without creating a new calendar, alarm, or scheduling engine. The feature lives under Home’s **Plan ahead** section with Next 7 Mornings first and month planning beneath it, shows the current month plus the next 12 months, lists only actionable future mornings, respects Hijri adjustment everywhere, stores only explicit user decisions, and routes each morning into the existing Day Detail experience for precise control.
