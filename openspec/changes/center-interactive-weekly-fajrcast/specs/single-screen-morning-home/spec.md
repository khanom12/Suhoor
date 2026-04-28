## ADDED Requirements

### Requirement: Weekly Fajrcast uses a centered seven-day context window
The Weekly Fajrcast compact card SHALL show exactly seven date columns centered on the selected morning.

#### Scenario: Selected morning is centered
- **GIVEN** a compact Weekly Fajrcast selected morning can be resolved
- **WHEN** the compact snapshot is built
- **THEN** the visible days SHALL be selected day minus 3 through selected day plus 3
- **AND** the selected day SHALL be the fourth column
- **AND** the week pill SHALL be based on the first and last visible dates

#### Scenario: Default selected morning is next relevant wake
- **GIVEN** no explicit compact Fajrcast selection exists
- **WHEN** today's wake has not passed
- **THEN** the compact card SHALL select today
- **AND** it SHALL still show three mornings before and three mornings after today when schedule data is available

#### Scenario: Today's wake has passed
- **GIVEN** no explicit compact Fajrcast selection exists
- **WHEN** today's wake has passed
- **THEN** the compact card SHALL select tomorrow
- **AND** it SHALL show the three mornings before tomorrow and the three mornings after tomorrow when schedule data is available

### Requirement: Weekly Fajrcast card supports compact selection
The compact Weekly Fajrcast chart SHALL allow selecting visible days without immediately navigating to detail.

#### Scenario: User selects a visible day
- **GIVEN** the compact chart displays seven visible days
- **WHEN** the user taps, drags, or scrubs to another visible day
- **THEN** that day SHALL become selected
- **AND** the compact snapshot SHALL recenter around that selected day
- **AND** the selected guide, selected marker, callout, selected weekday label, footer, and accessibility value SHALL update together

#### Scenario: User opens details
- **GIVEN** the compact card has a current selected day
- **WHEN** the user taps outside an active chart selection gesture
- **THEN** the app SHALL open the Fajrcast detail screen with the current selected day

#### Scenario: Accessible day adjustment is available
- **GIVEN** accessibility adjustment actions are available for the compact card chart
- **WHEN** the user increments or decrements the selected day
- **THEN** the selected day SHALL move to the next or previous visible day
- **AND** the card SHALL rebuild centered on the adjusted selected day

### Requirement: Weekly Fajrcast footer leads with selected-day Fajr boundaries
The compact Weekly Fajrcast footer SHALL first show exact Fajr begin and end times for the selected day.

#### Scenario: Active selected day footer renders
- **GIVEN** the selected compact Fajrcast day has resolved Fajr begin and end times
- **WHEN** the footer renders
- **THEN** the first footer line SHALL follow `Fajr begins at {beginTime} • Fajr ends at {endTime}`
- **AND** the second footer line MAY summarize the selected day's wake relation

#### Scenario: Selected day is off
- **GIVEN** the selected compact Fajrcast day is skipped or inactive
- **WHEN** the footer renders
- **THEN** the first footer line SHALL still show the selected day's Fajr begin and end times
- **AND** the second footer line SHALL state that the selected day's alarm is off for this date
- **AND** the selected callout SHALL show `Off`

#### Scenario: Week-level insight exists
- **GIVEN** the visible centered week includes DST, adjusted, or fasting context
- **WHEN** the compact snapshot is built
- **THEN** the week-level insight SHALL remain available in the compact snapshot
- **AND** it SHALL NOT replace the mandatory selected-day Fajr begin/end footer line

### Requirement: Compact chart stays clean and readable
The compact Weekly Fajrcast chart SHALL keep the Fajr band and boundary lines as the boundary explanation instead of inline chart text.

#### Scenario: Compact chart renders boundary treatment
- **GIVEN** compact Fajrcast chart data exists
- **WHEN** the chart renders
- **THEN** it SHALL draw the Fajr interval band
- **AND** it SHALL draw Fajr begin and Fajr end boundary lines
- **AND** it SHALL NOT render inline `FAJR BEGINS` or `FAJR ENDS` labels inside the chart

#### Scenario: Compact chart text scales
- **GIVEN** the user's text-size setting changes
- **WHEN** the compact Weekly Fajrcast renders
- **THEN** the header, week pill, callout, x-axis, y-axis, and footer text SHALL scale
- **AND** the compact axis labels SHALL use a default base size of at least 13 points or platform equivalent
- **AND** the card SHALL grow rather than clipping or overlapping critical text

#### Scenario: Compact chart retains four y-axis labels
- **GIVEN** compact Fajrcast chart data exists
- **WHEN** the compact chart renders
- **THEN** it SHALL expose exactly four visible y-axis tick labels
