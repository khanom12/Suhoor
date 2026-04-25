## ADDED Requirements

### Requirement: Morningcast presents upcoming mornings
The system SHALL present the next upcoming wake items on the Subh home as Morningcast, not as a generic alarm list.

#### Scenario: Upcoming wake list renders on home
- **GIVEN** more than 10 upcoming schedule entries exist
- **WHEN** the Subh home renders Morningcast
- **THEN** it SHALL show the next 10 entries in chronological order
- **AND** the section label SHALL use Morningcast framing

### Requirement: Fajrcast remains visually available
The system SHALL preserve the weekly Fajrcast card as a first-wave Subh home card.

#### Scenario: Weekly Fajrcast renders on home
- **GIVEN** Fajr window data is available
- **WHEN** the Subh home renders
- **THEN** the weekly Fajrcast card SHALL remain visible
- **AND** it SHALL remain navigable to a Fajr-window detail surface
