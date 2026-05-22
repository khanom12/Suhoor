# next-7-mornings-wake-forecast Specification

## ADDED Requirements

### Requirement: Home shows Next 7 Mornings in Plan ahead
The Home surface SHALL show the Next 7 Mornings forecast as the first item inside the Plan ahead section.

#### Scenario: Plan ahead order
- **GIVEN** the Subh Home surface is visible
- **WHEN** the user scans the `Plan ahead` section
- **THEN** the first planning surface SHALL be the `NEXT 7 MORNINGS` card
- **AND** `Calendar Months` SHALL appear below the forecast card
- **AND** `Hijri Months` SHALL appear below the forecast card

#### Scenario: Forecast naming
- **GIVEN** the forecast card renders on Home
- **WHEN** the card is collapsed or expanded
- **THEN** the header SHALL read `NEXT 7 MORNINGS`
- **AND** the helper copy SHALL read `View and plan your next seven mornings`
- **AND** visible copy SHALL NOT say `NEXT 7 DAYS` or `7-DAY WAKE FORECAST`

### Requirement: Forecast rows use opportunity/context tags only
Expanded Next 7 Mornings rows SHALL use a three-lane model: date, opportunity/context tags, and trailing wake/status.

#### Scenario: Ordinary Fajr morning
- **GIVEN** a resolved ordinary Fajr morning has no meaningful calendar or fasting opportunity context
- **WHEN** the compact forecast row is prepared
- **THEN** the middle tag lane SHALL be empty
- **AND** it SHALL NOT show `Fajr` as a fallback tag
- **AND** the trailing lane SHALL show the resolved wake time when wake delivery is active

#### Scenario: Quiet morning
- **GIVEN** a resolved morning is Quiet
- **WHEN** the compact forecast row is prepared
- **THEN** the middle tag lane SHALL NOT show `Quiet mode`
- **AND** the trailing lane SHALL show `Quiet`
- **AND** the row SHALL remain the same height as other rows for the same Dynamic Type profile

#### Scenario: Meaningful calendar context
- **GIVEN** a resolved morning has Ramadan, Eid, fasting-unavailable, Ashura, Arafah, Dhul Hijjah, White Days, Shawwal 6, or another approved opportunity/context tag
- **WHEN** the compact forecast row is prepared
- **THEN** the middle lane SHALL show the approved context tags up to the compact visible limit
- **AND** it SHALL NOT show routine `Fasting`, `Suhoor`, `Tahajjud`, `Qada`, `Kaffarah`, `Vow`, or `Mon/Thu` tags
- **AND** hidden intention meaning SHALL remain available to accessibility or Day Detail where useful

### Requirement: Forecast interaction is display-only until Day Detail
The Next 7 Mornings card SHALL not mutate planning state from expansion, collapse, or row rendering.

#### Scenario: User expands or collapses
- **GIVEN** the Next 7 Mornings card is visible
- **WHEN** the user expands or collapses it
- **THEN** Subh SHALL NOT change wake mode, intention, overrides, stored records, or scheduled platform alarms

#### Scenario: User taps a row
- **GIVEN** an expanded forecast row is visible
- **WHEN** the user taps the row
- **THEN** Subh SHALL open the existing Day Detail screen for that resolved morning
- **AND** no inline row editing SHALL appear in the forecast card
