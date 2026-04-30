## ADDED Requirements

### Requirement: Platform delivery consumes resolved wake events
The system SHALL schedule platform wake delivery from resolver-materialized `ScheduledEvent` values instead of recomputing the default wake time in scheduling adapters.

#### Scenario: Default wake event is scheduled
- **GIVEN** the default daily wake rule resolves to supported Fajr end minus 30 minutes
- **WHEN** the system schedules notification or AlarmKit delivery for that morning
- **THEN** platform delivery SHALL use the resolved wake event fire date
- **AND** scheduling adapters SHALL NOT derive a second wake time independently

#### Scenario: Date-specific override changes one morning
- **GIVEN** a date-specific override changes the resolved wake plan for one date
- **WHEN** the system schedules that date
- **THEN** platform delivery SHALL use the overridden resolved event for that date
- **AND** the override SHALL NOT create a second wake engine for other dates
