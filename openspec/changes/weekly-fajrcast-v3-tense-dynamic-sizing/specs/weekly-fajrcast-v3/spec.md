## ADDED Requirements

### Requirement: Weekly Fajrcast footer uses focused-day temporal tense
The compact Weekly Fajrcast snapshot SHALL provide footer strings for the focused day using the correct temporal tense for that focused day.

#### Scenario: Focused Fajr window is upcoming
- **GIVEN** the focused day's Fajr window has not begun
- **WHEN** the compact snapshot is built
- **THEN** the primary footer line SHALL use `Fajr begins` and `Fajr ends`
- **AND** the secondary footer line SHALL describe an active or off alarm using present/future tense

#### Scenario: Focused Fajr window is in progress
- **GIVEN** the focused day is today
- **AND** the focused day's Fajr begin time has passed
- **AND** the focused day's Fajr end time has not passed
- **WHEN** the compact snapshot is built
- **THEN** the primary footer line SHALL use `Fajr began` and `Fajr ends`

#### Scenario: Focused Fajr window is completed
- **GIVEN** the focused day's Fajr window has ended
- **WHEN** the compact snapshot is built
- **THEN** the primary footer line SHALL use `Fajr began` and `Fajr ended`
- **AND** the secondary footer line SHALL describe active or off alarm state using past tense

### Requirement: Weekly Fajrcast dynamic sizing follows v3 guardrails
The compact Weekly Fajrcast card SHALL scale readable text and minimum layout dimensions across text-size stops rather than preserving one fixed compact height.

#### Scenario: Default text size renders baseline card
- **GIVEN** the user uses the default text-size stop
- **WHEN** the compact card renders
- **THEN** the card SHALL use at least the v3 baseline card height, chart height, y-axis rail width, and base typography sizes

#### Scenario: Larger text increases layout space
- **GIVEN** the user uses a larger text-size stop
- **WHEN** the compact card renders
- **THEN** the card SHALL increase minimum card height
- **AND** it SHALL increase chart region height
- **AND** it SHALL widen the y-axis rail
- **AND** it SHALL keep footer text wrappable rather than clipping Fajr begin/end times

### Requirement: Weekly Fajrcast marker rendering remains truthful
The compact Weekly Fajrcast chart SHALL render a marker only when the focused day data provides a real active wake time or planned wake anchor.

#### Scenario: Active alarm or off-with-anchor exists
- **GIVEN** a visible day has an active wake time or planned wake anchor
- **WHEN** the compact chart renders
- **THEN** the day MAY render an active or off marker at the provided time
- **AND** the y-axis scale MAY include that marker time

#### Scenario: Marker data is unavailable
- **GIVEN** a visible day has no active wake time and no planned wake anchor
- **WHEN** the compact chart renders
- **THEN** the chart SHALL NOT invent a marker position
- **AND** the y-axis scale SHALL NOT include an unavailable marker value
