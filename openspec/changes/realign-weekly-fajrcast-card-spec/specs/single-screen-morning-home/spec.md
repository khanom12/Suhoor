## ADDED Requirements

### Requirement: Weekly Fajrcast card matches compact recreation contract
The compact Weekly Fajrcast card SHALL render as a dark glass card with header, week pill, top divider, compact seven-day chart, bottom divider, and one concise footer summary.

#### Scenario: Weekly Fajrcast card renders its fixed structure
- **GIVEN** a compact Weekly Fajrcast snapshot is available
- **WHEN** the card renders
- **THEN** it SHALL show the `WEEKLY FAJRCAST` title
- **AND** it SHALL show a right-aligned Gregorian and Hijri week pill
- **AND** it SHALL render the compact chart between two subtle dividers
- **AND** it SHALL render only `snapshot.summary.primaryText` as the visual footer summary

#### Scenario: Compact chart renders the weekly visual grammar
- **GIVEN** seven compact Fajrcast points are available
- **WHEN** the compact chart snapshot renders
- **THEN** it SHALL expose weekday initials for the seven points
- **AND** it SHALL use four compact y-axis ticks
- **AND** it SHALL draw the Fajr interval band and boundary lines with low-opacity white styling
- **AND** it SHALL keep the selected callout, guide, marker, and weekday label aligned

### Requirement: Weekly Fajrcast footer summarizes the selected alarm
The compact Weekly Fajrcast footer primary text SHALL summarize the selected day's alarm using the selected-day subject and wake relationship.

#### Scenario: Tomorrow is selected
- **GIVEN** tomorrow is the selected compact Fajrcast point
- **WHEN** the compact snapshot is built
- **THEN** the footer primary text SHALL begin with `Tomorrow's alarm is`
- **AND** the compact selected-day callout label SHALL be `TOMORROW`

#### Scenario: Selected day is skipped
- **GIVEN** the selected compact Fajrcast point is skipped
- **WHEN** the compact snapshot is built
- **THEN** the footer primary text SHALL state that the selected day's alarm is off for this date
- **AND** the selected-day display SHALL use `Off` without a time suffix

### Requirement: Compact Fajrcast secondary summary remains available
The compact Weekly Fajrcast snapshot SHALL preserve secondary week-level summary text for meaningful weekly signals even when the visual footer displays only the primary sentence.

#### Scenario: Adjusted mornings exist in the week
- **GIVEN** one or more compact Fajrcast rows are adjusted away from the default plan
- **WHEN** the compact snapshot is built
- **THEN** `summary.secondaryText` SHALL identify the adjusted morning count

#### Scenario: No meaningful secondary signal exists
- **GIVEN** no DST, adjusted, or fasting weekly signal exists
- **WHEN** the compact snapshot is built
- **THEN** `summary.secondaryText` SHALL be nil
