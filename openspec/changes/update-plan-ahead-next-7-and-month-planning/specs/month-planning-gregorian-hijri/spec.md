# month-planning-gregorian-hijri Specification

## ADDED Requirements

### Requirement: Month Planning lives under Home Plan ahead
The Home surface SHALL expose Month Planning below Next 7 Mornings inside the Plan ahead section.

#### Scenario: Home planning order
- **GIVEN** the Subh Home surface is visible
- **WHEN** the user scans `Plan ahead`
- **THEN** `NEXT 7 MORNINGS` SHALL appear first
- **AND** `Calendar Months` with subtitle `Plan by Gregorian month` SHALL appear below it
- **AND** `Hijri Months` with subtitle `Plan by Islamic month` SHALL appear below it

#### Scenario: High contrast heading
- **GIVEN** Home renders over the dawn background
- **WHEN** the `Plan ahead` heading is visible
- **THEN** the heading SHALL use white or an approved high-contrast Home heading treatment

### Requirement: Month Picker uses card grid
Gregorian and Hijri Month Pickers SHALL present month choices as tile/card grids where space allows.

#### Scenario: Picker cards render
- **GIVEN** the user opens Calendar Months or Hijri Months
- **WHEN** the picker has resolved its horizon
- **THEN** it SHALL show current month plus the next 12 months
- **AND** month choices SHALL use two-column near-square cards where space allows
- **AND** cards MAY stack vertically for narrow layouts or large Dynamic Type

#### Scenario: Complementary calendar context
- **GIVEN** Calendar Months picker cards render
- **WHEN** a Gregorian month card is visible
- **THEN** it SHALL include relevant Hijri date-range context where available
- **GIVEN** Hijri Months picker cards render
- **WHEN** a Hijri month card is visible
- **THEN** it SHALL include corresponding Gregorian date-range context where available

### Requirement: Month Detail rows mirror compact planning rows
Month Detail rows SHALL visually match the Next 7 Mornings expanded row doctrine while preserving month-specific date emphasis.

#### Scenario: Gregorian Month Detail row
- **GIVEN** Calendar Month Detail renders a resolved morning
- **WHEN** the row is prepared
- **THEN** the left lane SHALL show Gregorian date first and Hijri date second
- **AND** the middle lane SHALL show only opportunity/context tags
- **AND** the trailing lane SHALL show wake time or `Quiet`

#### Scenario: Hijri Month Detail row
- **GIVEN** Hijri Month Detail renders a resolved morning
- **WHEN** the row is prepared
- **THEN** the left lane SHALL show Hijri date first and Gregorian date second
- **AND** the middle lane SHALL show only opportunity/context tags
- **AND** the trailing lane SHALL show wake time or `Quiet`

#### Scenario: Forbidden routine tags
- **GIVEN** a Month Detail row is prepared
- **WHEN** it has ordinary Fajr, Suhoor, fasting intention, Quiet, Qada, Kaffarah, Vow, Monday/Thursday, or legacy Tahajjud meaning
- **THEN** those meanings SHALL NOT appear as middle-lane tags
- **AND** any supported hidden meaning SHALL remain in accessibility or Day Detail

### Requirement: Month Planning remains generated display behavior
Month Planning SHALL continue to use the existing resolver, Hijri authority, entitlement, Day Detail, persistence, and scheduling systems.

#### Scenario: User browses months
- **GIVEN** the user opens Month Picker or Month Detail
- **WHEN** rows and Monthly Fajrcast placeholders render
- **THEN** Subh SHALL NOT create durable morning records
- **AND** Subh SHALL NOT schedule future platform alarms

#### Scenario: User taps a month row
- **GIVEN** Month Detail shows a resolved morning row
- **WHEN** the user taps it
- **THEN** Subh SHALL open the existing Day Detail screen with source calendar context
- **AND** Day Detail SHALL own edits, validation, and persistence
