# fajr-end-mvp-wake Delta

## Modified Requirements

### Requirement: Fresh install default wake uses Fajr end
The system SHALL set the first-wave default wake to 30 minutes before the supported Fajr end boundary.

#### Scenario: Fresh install creates default wake settings
- **GIVEN** no persisted wake settings exist
- **WHEN** Subh creates default alarm configuration
- **THEN** the default wake anchor SHALL be supported Fajr end
- **AND** the default wake offset SHALL be 30 minutes before that boundary

#### Scenario: Debug install state is reset before stores load
- **GIVEN** a DEBUG developer install has cleared local persisted state before the alarm config store initializes
- **WHEN** the alarm config store creates defaults
- **THEN** it SHALL use supported Fajr end minus 30 minutes
- **AND** it SHALL NOT resurrect stale Fajr-start defaults from the previous developer build

