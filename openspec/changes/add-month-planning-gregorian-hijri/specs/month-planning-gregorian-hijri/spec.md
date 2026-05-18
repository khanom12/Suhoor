# month-planning-gregorian-hijri Specification

## ADDED Requirements

### Requirement: Home exposes Month Planning entry points
The Home surface SHALL expose compact Month Planning entry tiles for Gregorian and Hijri month browsing.

#### Scenario: Plan ahead tiles are visible
- **GIVEN** the Subh Home surface is visible
- **WHEN** the user scans the supporting planning surfaces
- **THEN** the Home SHALL show a `Plan ahead` entry area
- **AND** it SHALL show a `Calendar Months` tile with subtitle `Plan by Gregorian month`
- **AND** it SHALL show a `Hijri Months` tile with subtitle `Plan by Islamic month`
- **AND** the tiles SHALL be navigation surfaces rather than data-heavy cards

#### Scenario: Free user taps a locked tile
- **GIVEN** the current entitlement does not allow Month Planning
- **WHEN** the user taps either Month Planning tile
- **THEN** the app SHALL show a locked preview or upgrade experience
- **AND** it SHALL NOT open Month Picker or Month Detail planning controls

### Requirement: Month picker horizon is current month plus next twelve
The Month Picker SHALL show the current month plus the next 12 months for the selected calendar mode.

#### Scenario: Gregorian picker horizon
- **GIVEN** the user opens Calendar Months
- **WHEN** the picker generates its rows
- **THEN** it SHALL show the current Gregorian month first
- **AND** it SHALL show the next 12 Gregorian months in chronological order
- **AND** it SHALL NOT add arbitrary past browsing

#### Scenario: Hijri picker horizon
- **GIVEN** the user opens Hijri Months
- **WHEN** the picker generates its rows
- **THEN** it SHALL show the current Hijri month first using the existing Hijri authority and adjustment model
- **AND** it SHALL show the next 12 Hijri months in chronological order
- **AND** it SHALL NOT duplicate Hijri calculation logic

### Requirement: Current month detail shows only actionable mornings
Month Detail SHALL exclude past and non-actionable mornings from the current month using the existing morning actionability boundary.

#### Scenario: Current month has remaining mornings
- **GIVEN** the selected month is the current month
- **WHEN** Month Detail resolves rows
- **THEN** only actionable or unresolved mornings SHALL appear
- **AND** today SHALL appear only when the existing wake/actionability boundary says it is still actionable

#### Scenario: Current month has no remaining mornings
- **GIVEN** the current month has no actionable mornings left
- **WHEN** Month Picker renders
- **THEN** it SHALL keep the current month in the horizon
- **AND** it SHALL mark it unavailable with copy such as `No remaining mornings`
- **WHEN** stale navigation opens that empty Month Detail
- **THEN** it SHALL show `No remaining mornings in this month. Choose another month to plan ahead.`

### Requirement: Future month detail shows all mornings
Month Detail SHALL show all resolvable mornings in a fully future selected month.

#### Scenario: Future Gregorian month
- **GIVEN** the selected Gregorian month is fully in the future
- **WHEN** Month Detail resolves rows
- **THEN** it SHALL show all mornings in that Gregorian month
- **AND** the month MAY contain 28, 29, 30, or 31 mornings

#### Scenario: Future Hijri month
- **GIVEN** the selected Hijri month is fully in the future
- **WHEN** Month Detail resolves rows
- **THEN** it SHALL show all mornings in that Hijri month according to the existing Hijri authority and adjustment model
- **AND** the month MAY contain 29 or 30 mornings

### Requirement: Month Detail is a morning planning surface
Month Detail SHALL present the selected month as a list of resolved Subh mornings, not as an alarm calendar.

#### Scenario: Gregorian Month Detail copy
- **GIVEN** the selected mode is Calendar Months
- **WHEN** Month Detail renders
- **THEN** the navigation title SHALL use the Gregorian month identity such as `May 2026`
- **AND** the section label SHALL use copy such as `May mornings`
- **AND** rows SHALL emphasize Gregorian date first and Hijri date second
- **AND** the section SHALL NOT be labeled `Alarms`

#### Scenario: Hijri Month Detail copy
- **GIVEN** the selected mode is Hijri Months
- **WHEN** Month Detail renders
- **THEN** the navigation title SHALL use the Hijri month identity such as `Ramadan 1447`
- **AND** the section label SHALL use copy such as `Ramadan mornings`
- **AND** rows SHALL emphasize Hijri date first and Gregorian date second
- **AND** the section SHALL NOT be labeled `Alarms`

### Requirement: Monthly Fajrcast placeholder is passive
Month Detail SHALL include a production-safe Monthly Fajrcast placeholder slot that can later be replaced by the full chart.

#### Scenario: Placeholder receives planning context
- **GIVEN** Month Detail has resolved its selected month
- **WHEN** the Monthly Fajrcast placeholder renders
- **THEN** it SHALL be capable of receiving calendar mode, month identity, selected month date range, visible/actionable morning range, resolved morning snapshots, entitlement state, and Hijri adjustment context where relevant
- **AND** rendering the placeholder SHALL NOT create stored decisions
- **AND** rendering the placeholder SHALL NOT schedule platform alarms

### Requirement: Month rows route to existing Day Detail
Each Month Detail row SHALL open the existing selected-day detail flow for the canonical resolved morning.

#### Scenario: User opens a month row
- **GIVEN** Month Detail shows resolved morning rows
- **WHEN** the user taps a row
- **THEN** the app SHALL open the existing Day Detail screen for that morning's canonical `DaySchedule`
- **AND** the navigation stack SHALL return to the selected Month Detail when the user goes back
- **AND** Month Planning SHALL NOT introduce a separate day-editing model

### Requirement: Month browsing is generated display behavior
Month Planning SHALL NOT persist generated day records or schedule platform alarms merely because a month was opened.

#### Scenario: User browses without editing
- **GIVEN** the user opens Month Picker or Month Detail
- **WHEN** the user leaves without editing a day
- **THEN** Subh SHALL NOT create durable day-specific records for the generated month rows
- **AND** Subh SHALL NOT schedule future platform alarms for those visible rows

### Requirement: Month Planning follows shared entitlement
Month Planning SHALL use the shared entitlement model rather than independent tier checks.

#### Scenario: Plus access
- **GIVEN** the user has Plus entitlement
- **WHEN** they open Calendar Months or Hijri Months
- **THEN** they SHALL be allowed to browse current month plus next 12 months
- **AND** allowed Fajr and Quiet planning controls SHALL remain available through existing detail behavior
- **AND** Complete-only Suhoor/Fasting controls SHALL not become newly available because the row came from Month Planning

#### Scenario: Complete access
- **GIVEN** the user has Complete entitlement
- **WHEN** they open Month Planning
- **THEN** they SHALL receive full Month Planning access
- **AND** Suhoor/Fasting planning SHALL be available where the existing resolver and Day Detail support it
