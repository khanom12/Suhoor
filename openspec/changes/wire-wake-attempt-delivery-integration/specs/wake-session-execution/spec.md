## MODIFIED Requirements

### Requirement: Default Wake Checks are deterministic
The system SHALL schedule Wake Checks as deterministic wake-session events using the selected Wake Attempt mode, fixed five-minute interval, and relevant mode cutoff rules.

#### Scenario: Single alarm only schedules no Wake Checks
- **GIVEN** a resolved Fajr or Suhoor Wake Session uses Single alarm only
- **WHEN** events are materialized for scheduling
- **THEN** the system SHALL materialize exactly one primary wake event for that Wake Session
- **AND** it SHALL NOT materialize Wake Check events for that Wake Session

#### Scenario: Repeat until awake schedules independent Fajr Wake Checks
- **GIVEN** a Fajr-mode primary wake is before Fajr ends
- **AND** Wake Attempts is set to Repeat until I'm awake
- **WHEN** Wake Checks are planned
- **THEN** the system SHALL schedule independent Wake Check events every five minutes after the primary wake
- **AND** the last Wake Check SHALL be no later than five minutes before Fajr ends
- **AND** no Wake Check SHALL be scheduled at the exact Fajr end boundary
- **AND** the number of Wake Checks SHALL be derived from the primary wake time and boundary, not from a user-selected or fixed product attempt count

#### Scenario: Repeat until awake schedules independent Suhoor Wake Checks
- **GIVEN** a Suhoor-mode primary wake is before Fajr begins
- **AND** Wake Attempts is set to Repeat until I'm awake
- **WHEN** Wake Checks are planned
- **THEN** the system SHALL schedule independent Wake Check events every five minutes after the primary wake
- **AND** the last Wake Check SHALL be no later than five minutes before Fajr begins
- **AND** no Wake Check SHALL be scheduled at the exact Fajr begin boundary

#### Scenario: Wake Checks are scheduled as separate platform deliveries
- **GIVEN** a Repeat until I'm awake Wake Session has a primary event and Wake Check events in the active scheduled horizon
- **WHEN** platform scheduling runs
- **THEN** each future primary and Wake Check event SHALL be submitted as its own notification or AlarmKit delivery
- **AND** native snooze SHALL NOT be configured as the Wake Check mechanism
- **AND** a nil native snooze duration SHALL be treated as intentional for Wake Attempts

#### Scenario: Wake Checks use future deterministic event identifiers
- **GIVEN** a Wake Session has wake checks in the active scheduled horizon
- **WHEN** events are materialized for scheduling
- **THEN** each Wake Check SHALL use a deterministic event ID containing the date key and wake-check index
- **AND** each Wake Check SHALL include wake-session metadata where available
- **AND** past Wake Checks SHALL NOT be scheduled

#### Scenario: Stale Wake Checks are reconciled
- **GIVEN** a schedule change removes or moves previously scheduled Wake Checks
- **WHEN** scheduling identifiers are reconciled
- **THEN** stale wake-check identifiers SHALL be included in cancellation candidates
- **AND** unrelated alarms SHALL NOT be cancelled solely because one morning changed
