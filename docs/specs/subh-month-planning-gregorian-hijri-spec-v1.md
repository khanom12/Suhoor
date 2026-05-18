# Subh Month Planning — Gregorian and Hijri Month Browsing Spec v1

**Status:** Draft v1 — implementation-ready pending repo mapping
**Date:** 2026-05-18
**Feature area:** Future morning planning / month planning
**Primary surfaces:** Home, Month Picker, Month Detail, Day Detail
**Related specs:** Morning Resolution Contract, Planning Horizon / Day Resolution / Intention Anchoring, Next 7 Mornings, Weekly Fajrcast, Day Detail, Hijri Date Adjustment, Pricing Entitlement

---

## 1. Purpose

Subh should support **month-level planning** for future mornings.

This feature is not a generic calendar browser. It is a planning surface that lets the user look beyond the immediate Next 7 Mornings view and intentionally review or adjust upcoming Subh mornings by either:

1. **Calendar month** — Gregorian month planning.
2. **Hijri month** — Islamic month planning.

The user starts from the Home screen, chooses a calendar system, selects a month, sees a month-level planning screen, and can open an individual morning into the existing Day Detail view.

---

## 2. Product principles

1. **Fajr remains the core anchor.**
   Month planning extends the existing Fajr-centered morning system; it does not create a second scheduling engine.

2. **The feature plans mornings, not alarms.**
   A listed item may resolve to Fajr, Suhoor, Quiet, or another allowed state. Therefore, product copy should use “mornings,” not “alarms,” except when referring to an actual scheduled wake alarm.

3. **Defaults are generated, not stored.**
   Opening a month must not create 29, 30, or 31 stored decisions.

4. **Only explicit user edits are persisted.**
   Browsing a month is read/display behavior. Durable records are created only when the user intentionally changes a morning.

5. **Month browsing is not active platform scheduling.**
   Month planning may store future intentions or overrides, but it must not schedule platform alarms for every future day. Active alarm scheduling remains governed by the existing alarm delivery and scheduling reliability specs.

6. **Hijri logic must use one source of truth.**
   Hijri month labels, Hijri date rows, Ramadan detection, Suhoor defaults, and Day Detail must all use the same Hijri authority and adjustment model.

7. **No past morning planning.**
   Month detail lists should show only actionable / unresolved mornings. Past mornings should not appear in the planning list.

---

## 3. User-facing information architecture

### 3.1 Home screen entry points

Add a compact two-tile entry area on Home.

Recommended section heading:

```text
Plan ahead
```

Recommended tile copy:

```text
Calendar Months
Plan by Gregorian month
```

```text
Hijri Months
Plan by Islamic month
```

### 3.2 Tile layout

- Tiles are visually paired and should appear as two half-width square or near-square cards.
- On narrow layouts, large Dynamic Type, or constrained web/mobile widths, the tiles may stack vertically.
- Tiles should feel lighter than full-width Home cards such as Next 7 Mornings, Weekly Fajrcast, and the context window.
- The tiles are navigation surfaces, not data-heavy dashboards.

### 3.3 Copy guardrails

Use:

- “Calendar Months”
- “Plan by Gregorian month”
- “Hijri Months”
- “Plan by Islamic month”
- “May mornings”
- “Ramadan mornings”
- “Dhul Hijjah mornings”

Avoid:

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

### 6.1 Gregorian Month Picker

Recommended title:

```text
Calendar Months
```

Recommended subtitle:

```text
Choose a month to plan your mornings.
```

Each row/card should show:

- Gregorian month name and year
- Remaining or total morning count
- Optional secondary range or context
- Locked/unavailable state if entitlement or actionability requires it

Example rows:

```text
May 2026
12 mornings left
```

```text
June 2026
30 mornings
```

### 6.2 Hijri Month Picker

Recommended title:

```text
Hijri Months
```

Recommended subtitle:

```text
Choose an Islamic month to plan your mornings.
```

Each row/card should show:

- Hijri month name and Hijri year
- Corresponding Gregorian date range
- Remaining or total morning count
- Optional Ramadan/observance context where allowed
- Locked/unavailable state if entitlement or actionability requires it

Example rows:

```text
Ramadan 1447
Feb 18 – Mar 19 · 30 mornings
```

```text
Dhul Hijjah 1447
May 18 – Jun 16 · 29 mornings
```

### 6.3 Picker ordering

- Rows appear in chronological order.
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

Recommended structure:

```text
[Navigation title: May 2026]

[Monthly Fajrcast card]

May mornings
[Morning row]
[Morning row]
[Morning row]
...
```

For Hijri:

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

### 7.3 Current month detail

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

### 7.4 Selected future month detail

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

## 8. Monthly Fajrcast integration slot

The Month Detail screen reserves a top card area for a future **Monthly Fajrcast** component.

This spec does not define the Monthly Fajrcast chart design in detail. That should be handled by a separate Monthly Fajrcast Card Spec.

### 8.1 Required integration contract

The Month Detail screen must provide the Monthly Fajrcast component with:

- selected calendar mode: Gregorian or Hijri
- selected month identity
- selected month date range
- visible/actionable morning range
- resolved morning snapshots for the selected month, where available
- entitlement state
- Hijri authority / adjustment snapshot when in Hijri mode

### 8.2 Behavior guardrails

- The Monthly Fajrcast must reflect the selected month.
- It must not create stored decisions by rendering.
- It must not schedule platform alarms by rendering.
- If it eventually supports tapping or scrubbing, those interactions must coordinate with the same resolved morning rows used by the list.
- Past mornings must not become actionable through the card.

---

## 9. Morning row behavior

### 9.1 Row purpose

Each row represents one resolved Subh morning in the selected month.

The row should summarize the morning enough for scanning and should open Day Detail for full control.

### 9.2 Gregorian Month Detail row emphasis

In Calendar Month mode, the Gregorian date is primary and the Hijri date is secondary.

Example:

```text
Thu, May 21
Dhul Hijjah 4
Wake 4:18 AM · Fajr
```

### 9.3 Hijri Month Detail row emphasis

In Hijri Month mode, the Hijri date is primary and the Gregorian date is secondary.

Example:

```text
Ramadan 12
Thu, Feb 19
Wake 5:12 AM · Suhoor
```

### 9.4 Row content

Rows should use the same resolved-day model used by Home, Next 7 Mornings, Weekly Fajrcast, and Day Detail.

A row may show:

- primary date label
- secondary date label
- wake time, if a wake is active
- “No alarm” / “Quiet” state, if Quiet is active
- mode/state chip, such as Fajr, Suhoor, or Quiet
- indication that the day has an explicit user override or anchored intention
- lock/upgrade affordance if the displayed action is not available in the current tier

### 9.5 Row interaction

- Tapping an actionable row opens Day Detail.
- Rows that are not editable because of entitlement may still open a read-only or upgrade-oriented detail state, depending on the entitlement spec.
- Rows that are not actionable because the morning has passed should not appear in the list.

---

## 10. Day Detail integration

The Month Detail screen must not create a separate day-editing model.

When a row is tapped:

- Open the existing Day Detail screen.
- Pass the canonical resolved morning identity.
- Pass the source calendar context: Gregorian month or Hijri month.
- Preserve the selected month navigation context for back navigation.
- Let Day Detail own editing, validation, and persistence.

### 10.1 Source calendar context

The source calendar context matters because Subh stores user meaning, not merely display dates.

- Edits made from **Calendar Month** mode should default to a Gregorian-date planning anchor unless the Day Detail screen explicitly offers another meaning.
- Edits made from **Hijri Month** mode should default to a Hijri-date planning anchor when the user’s action is naturally tied to the Hijri date.
- Observance-specific or Hijri-month-wide rules are out of scope for this spec unless already supported elsewhere.

---

## 11. Hijri source-of-truth rules

### 11.1 Single Hijri authority

The Hijri month planner must use the same Hijri authority used by the rest of Subh.

This includes:

- Hijri month names
- Hijri year
- month start/end boundaries
- 29/30-day month length
- Ramadan detection
- observance detection
- Hijri date adjustment / offset
- Day Detail date labels
- any Ramadan or Suhoor default logic

### 11.2 Hijri adjustment impact

If the user applies a Hijri date adjustment:

- Hijri month picker labels must update.
- Hijri month date ranges must update.
- Hijri row labels must update.
- Ramadan defaults must shift.
- Suhoor/Fasting defaults tied to Ramadan must shift where allowed by entitlement and existing resolver rules.
- Hijri-date and observance-anchored future intentions should move according to the intention anchoring rules.
- Gregorian-date-anchored future intentions should remain on their Gregorian date.
- Completed history must not move.

The month planner must not implement a separate migration rule. It must delegate to the existing intention anchoring and day-resolution model.

### 11.3 No drift rule

No screen may identify the same morning differently.

For example, it is invalid for:

- the Hijri Month Picker to label a day as Ramadan 1,
- the Month Detail row to label it as Sha’ban 30,
- and Day Detail to apply a non-Ramadan default.

All surfaces must agree through the same resolved morning snapshot.

---

## 12. State, resolution, and persistence

### 12.1 Generated month data

Month Detail is generated on demand from the existing morning-resolution system.

Opening a month must not create stored records.

Invalid behavior:

- user opens May 2026
- app writes 31 day records
- user exits without editing

Correct behavior:

- user opens May 2026
- app resolves visible mornings for display
- user exits
- no durable day decisions are created

### 12.2 Explicit edits

A durable record is created only when the user explicitly changes a morning in Day Detail or through another approved planning interaction.

Examples:

- changing a future morning from Fajr to Quiet
- changing a future morning from Fajr to Suhoor where entitlement allows
- changing wake offset for a specific morning
- resetting a previously stored override

### 12.3 Global settings changes

If the user changes a global setting:

- untouched future mornings should re-resolve automatically
- stored user intentions/overrides should preserve their meaning
- anchored intentions should follow their anchor rules
- generated defaults should not be treated as user decisions

### 12.4 Operational scheduling

Month planning may create future intentions, but it must not schedule all future platform alarms.

The active alarm scheduling system remains responsible for deciding when a future plan becomes an actual scheduled alarm.

---

## 13. Entitlement rules

This feature must use the shared entitlement model. Do not hardcode tier behavior independently inside the Month Planner UI.

### 13.1 Free

Free users:

- can use the immediate core experience and Next 7 Mornings according to the pricing spec
- see month-planning entry points as locked or preview-only
- cannot use Month Picker / Month Detail for future planning control
- cannot create future month-level planning edits

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

### 13.2 Plus

Plus users:

- can access Calendar Month planning
- can access Hijri Month planning
- can browse the current month plus the next 12 months
- can plan allowed future Fajr-oriented mornings
- can use allowed Fajr / Quiet controls across the planning horizon
- can view Hijri and Ramadan context where the resolver provides it
- cannot use Complete-only Suhoor/Fasting capabilities unless the entitlement model permits them

### 13.3 Complete

Complete users:

- receive full month-planning access
- can use Suhoor/Fasting planning where supported
- can receive Ramadan/Suhoor defaults where supported by the resolver
- can use deeper fasting, Ramadan, Qada, and history/progress capabilities as defined in the pricing entitlement spec

### 13.4 MVP guardrail

Do not reintroduce Tahajjud or non-fasting pre-Fajr wake planning through this feature unless a future spec explicitly restores it.

The active MVP quick-mode language remains aligned to:

```text
Suhoor | Fajr | Quiet
```

---

## 14. Loading, empty, and error states

### 14.1 Loading

Show lightweight skeleton rows or a simple loading state while resolving month data.

Avoid blocking the whole app if only one row fails to resolve.

### 14.2 No remaining mornings

If the current month has no remaining actionable mornings:

- Month Picker should mark the current month as unavailable.
- Month Detail should avoid showing an empty planning screen unless opened through stale navigation.
- A stale Month Detail should show:

```text
No remaining mornings in this month.
Choose another month to plan ahead.
```

### 14.3 Calculation unavailable

If Fajr times or date data cannot be resolved for one or more mornings:

- show a clear unavailable state
- do not invent wake times
- do not schedule alarms from incomplete data
- allow retry once the underlying resolver can provide valid data

### 14.4 Location or time-zone changes

Month planning should use the same active location and time-zone model as the rest of Subh.

If the active location or time zone changes:

- generated month data should re-resolve
- untouched future mornings should update
- stored intentions should preserve their anchor meaning according to the planning horizon and intention anchoring rules

---

## 15. Accessibility and responsive behavior

- Tiles must be large enough for comfortable touch targets.
- Month rows must be accessible by VoiceOver / screen readers.
- Date labels should be read in a natural order based on the selected calendar mode.
- Dynamic Type must be supported.
- At larger text sizes, tile subtitles may wrap or stack.
- Rows should avoid truncating the primary date label.
- Lock states must not rely on icon-only communication.
- Web/responsive layouts may stack tiles vertically when half-width layout becomes cramped.

---

## 16. Performance and implementation guidance

### 16.1 Lazy resolution

Month data should be resolved on demand.

Do not eagerly calculate or store every month in the 13-month horizon if only the picker is visible.

### 16.2 Caching

Use safe, invalidatable caching keyed by relevant resolver inputs, such as:

- selected calendar mode
- selected month identity
- active location/time zone
- Hijri authority / adjustment snapshot
- settings revision
- entitlement state
- explicit intention/override revision

### 16.3 List rendering

Month Detail may contain up to 31 rows. Use simple list virtualization/lazy layout where appropriate, but avoid unnecessary complexity.

### 16.4 No duplicate calculation logic

The Month Planner UI must not independently calculate:

- Fajr begins
- Fajr ends
- wake time
- Ramadan detection
- Hijri month boundaries
- whether a morning is actionable
- entitlement-allowed actions

It should request resolved data from the existing domain services.

---

## 17. Suggested data contract

Names are illustrative only. Use existing project naming where available.

```swift
enum MonthPlanningCalendarMode {
    case gregorian
    case hijri
}

struct MonthPlanningPickerMonth {
    let id: MonthPlanningMonthID
    let calendarMode: MonthPlanningCalendarMode
    let title: String
    let subtitle: String
    let visibleMorningCount: Int
    let availability: MonthPlanningAvailability
}

struct MonthPlanningSnapshot {
    let month: MonthPlanningPickerMonth
    let dateRange: MorningDateRange
    let visibleMornings: [ResolvedDaySnapshot]
    let monthlyFajrcastInput: MonthlyFajrcastInput
    let entitlementState: MonthPlanningEntitlementState
    let hijriAuthoritySnapshot: HijriAuthoritySnapshot?
}
```

The actual implementation should map this concept onto existing app models rather than introducing unnecessary parallel types.

---

## 18. Non-goals

This spec does not define:

- the detailed Monthly Fajrcast chart design
- month-level bulk editing
- arbitrary past month browsing
- completed-history browsing
- Qada history or progress logging
- a new Hijri adjustment settings screen
- a second wake/scheduling engine
- new Tahajjud or non-fasting pre-Fajr planning behavior
- pricing copy beyond entitlement behavior
- changes to alarm delivery reliability rules

---

## 19. Acceptance criteria

### 19.1 Home

- Home displays two compact month-planning tiles: Calendar Months and Hijri Months.
- Tile copy matches the approved language.
- Free users see locked or preview-only behavior.
- Plus and Complete users can enter the month picker according to entitlement.

### 19.2 Month Picker

- Calendar Month Picker shows current Gregorian month plus next 12 Gregorian months.
- Hijri Month Picker shows current Hijri month plus next 12 Hijri months.
- The current month appears first.
- Month labels use full, human-readable month names.
- Hijri months respect the active Hijri authority and adjustment.
- Current month is marked unavailable if no actionable mornings remain.

### 19.3 Month Detail

- Selected month opens a Month Detail screen.
- Screen includes a Monthly Fajrcast card slot.
- Screen includes a list of mornings, not alarms.
- Current month excludes past/non-actionable mornings.
- Future months show all mornings in the selected month.
- Tapping a morning opens the existing Day Detail screen.

### 19.4 Persistence

- Opening a month creates no stored day records.
- Leaving a month without edits creates no stored day records.
- Explicit edits create the appropriate anchored intention or override.
- Untouched future days re-resolve after global settings changes.
- Hijri-date and observance-anchored intentions follow Hijri adjustment rules.
- Gregorian-date-anchored intentions remain on their Gregorian dates.

### 19.5 Entitlement

- Plus unlocks both Gregorian and Hijri month planning surfaces.
- Plus supports allowed Fajr/Quiet future planning controls.
- Complete unlocks Suhoor/Fasting planning where supported.
- UI behavior is driven by the shared entitlement model.

### 19.6 Guardrails

- No duplicate Hijri logic is introduced.
- No duplicate Fajr/wake calculation logic is introduced.
- No future platform alarms are scheduled merely because a month was opened.
- Past mornings are not displayed in the planning list.
- Tahajjud/non-fasting pre-Fajr planning is not reintroduced.

---

## 20. Required follow-up work

1. Create a separate **Monthly Fajrcast Card Spec**.
2. Update the Pricing Entitlement Spec to reference month planning explicitly.
3. Update the Interaction Inventory to include:
   - Home tile taps
   - Month picker selection
   - Month detail row taps
   - locked/preview states
   - Day Detail return flow
4. Verify the Planning Horizon / Intention Anchoring spec aligns with:
   - current month + next 12 months
   - Gregorian-date anchors from Calendar Month mode
   - Hijri-date anchors from Hijri Month mode
   - no durable records from browsing alone
5. Confirm implementation uses existing resolved-day and scheduling services rather than creating a parallel month-planning engine.

---

## 21. Final product statement

Subh month planning lets users plan meaningful future mornings by either Gregorian month or Hijri month. It extends the existing Fajr-centered morning system without creating a new calendar, alarm, or scheduling engine. The feature shows the current month plus the next 12 months, lists only actionable future mornings, respects Hijri adjustment everywhere, stores only explicit user decisions, and routes each morning into the existing Day Detail experience for precise control.
