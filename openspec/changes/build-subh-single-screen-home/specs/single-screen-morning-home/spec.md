## ADDED Requirements

### Requirement: Morning home snapshot drives the MVP cards
The system SHALL provide a `MorningHomeSnapshot` or equivalent presentation model that contains exactly the first-wave home inputs: tomorrow, weekly Fajrcast, Morningcast, permission state, and context flags.

#### Scenario: Home snapshot is built
- **GIVEN** schedule data is available
- **WHEN** the home snapshot is created
- **THEN** it SHALL contain a tomorrow-morning item
- **AND** it SHALL contain one weekly Fajrcast snapshot
- **AND** it SHALL contain no more than 10 Morningcast items
- **AND** it SHALL expose permission or reliability state for visible degradation messaging

### Requirement: Subh home owns primary navigation
The system SHALL render the Subh home inside one `NavigationStack` with settings in the toolbar and card-driven detail navigation.

#### Scenario: User opens settings from home
- **GIVEN** Subh home is visible
- **WHEN** the user taps the settings control
- **THEN** settings SHALL open without switching to a separate bottom-tab area
