## Current Implementation Anchors

- `Subh/Features/Home/SubhHomeView.swift` owns the single primary Home `NavigationStack`, Tomorrow Morning hero, Next 7 Days card, and Weekly Fajrcast card.
- `Subh/Features/Alarms/AlarmDayDetailView.swift` owns selected-day editing, validation, and persistence.
- `ScheduleManager` exposes `currentDate`, `activeDay(for:)`, `rollingHijriMonths`, `monthEntries(for:)`, Hijri adjustment previews, and the active window snapshot.
- `ActiveDayResolver` and `ResolvedDayPipeline` already build canonical `ActiveAlarmDay`/`ResolvedDaySnapshot` values for arbitrary future dates.
- `WakeListDataProvider` already resolves Hijri month entries through the adjusted Hijri calendar.
- `MorningWakeResolutionService` and `WakeStateSelectionResolver` expose the resolved mode, activation, wake time, and Quiet state needed for compact rows.
- `AdjustedHijriCalendar` is the existing Hijri authority/adjustment path used by settings and labels.

## Approach

1. Add a small shared entitlement model:
   - `SubhEntitlementTier`
   - `SubhEntitlementSnapshot`
   - `SubhEntitlementStore`
   - `SubhFeatureGate.monthPlanning`

   The Month Planner UI consumes this model instead of hardcoding tier checks inside views. The model grants Month Planning to Plus and Complete, and locks it for Free.

2. Add Month Planning presentation models:
   - `MonthPlanningCalendarMode`
   - `MonthPlanningMonthIdentity`
   - `MonthPlanningPickerMonth`
   - `MonthPlanningSnapshot`
   - `MonthPlanningMorningRow`
   - `MonthlyFajrcastPlaceholderSnapshot`

   These models are generated from existing `ActiveAlarmDay` values and Hijri calendar services. They do not store decisions or schedule alarms.

3. Add SwiftUI surfaces:
   - Home `Plan ahead` two-tile entry.
   - `MonthPlanningPickerView`.
   - `MonthPlanningDetailView`.
   - `MonthlyFajrcastPlaceholderCard`.
   - `MonthPlanningMorningRowView`.
   - Feature preview/upgrade sheet for locked Free access.

4. Keep detail resolution lazy:
   - Picker generation resolves only the current month enough to count remaining actionable mornings.
   - Future picker items use calendar date ranges for counts.
   - Detail rows resolve only the selected month.

5. Keep Day Detail as the only edit surface:
   - Month rows pass the selected `DaySchedule` to `AlarmDayDetailView`.
   - Month source context is carried to Day Detail for future anchor-aware behavior.
   - Plus-origin Month Planning limits Complete-only Suhoor controls in the detail route without changing the default Home behavior.

## Entitlement Decision

The supplied Month Planning v1 spec supersedes older working pricing notes for this feature by granting Plus access to both Gregorian and Hijri month planning for allowed Fajr/Quiet controls. Complete retains Suhoor/Fasting planning capabilities where already supported.

## Reliability and Privacy

Month browsing remains read/display behavior. The implementation must not call scheduling refresh or platform delivery APIs from picker/detail rendering. It uses local resolver inputs already present in the app and adds no analytics or external data flow.

## Testing Strategy

- Unit tests for picker horizon count and chronological order.
- Unit tests for current month remaining-morning filtering via wake/actionability boundary.
- Unit tests for Gregorian/Hijri row label priority.
- Unit tests for month-planning entitlement gates.
- Local validation through OpenSpec, focused XCTest, and an Xcode build/test command where available.
