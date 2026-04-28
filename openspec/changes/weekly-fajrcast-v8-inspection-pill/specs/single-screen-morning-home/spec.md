## ADDED Requirements

### Requirement: Home Weekly Fajrcast pill reflects active inspection
The Home/Wake Weekly Fajrcast header date pill SHALL show the anchored seven-day range at rest and the inspected day's single-date text during active inspection.

#### Scenario: Resting card shows anchored range
- **GIVEN** the Weekly Fajrcast card is visible
- **AND** no chart inspection gesture is active
- **WHEN** the header date pill is rendered
- **THEN** it SHALL show the anchored seven-day Gregorian + Hijri range
- **AND** it SHALL NOT show a single focused day date

#### Scenario: Scrubbing shows inspected single date
- **GIVEN** the Weekly Fajrcast card is visible
- **WHEN** the user touches, drags, or scrubs to a visible day
- **THEN** the header date pill SHALL show that inspected day's Gregorian + Hijri single-date text
- **AND** the visible seven-day window, Fajr band, y-axis scale, and static overlay SHALL remain anchored

#### Scenario: Release restores range pill
- **GIVEN** the Weekly Fajrcast header date pill is showing an inspected single-date value
- **WHEN** the chart inspection gesture ends
- **THEN** the card SHALL snap focus back using the existing snap-back behavior
- **AND** the header date pill SHALL return to the anchored seven-day range text

#### Scenario: Accessible adjustment keeps inspected date visible
- **GIVEN** the Weekly Fajrcast card receives an accessibility increment or decrement action
- **WHEN** the focused visible day changes
- **THEN** the header date pill SHALL show the inspected day's single-date text
- **AND** it MAY remain in date mode until focus is reset or touch release behavior runs
