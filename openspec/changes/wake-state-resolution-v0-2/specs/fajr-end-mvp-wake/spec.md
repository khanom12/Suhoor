## ADDED Requirements

### Requirement: Fajr-End Default Tracks Origin And Status
The Fajr MVP default SHALL remain 30 minutes before Fajr ends while also exposing wake-time origin, alarm activation, and schedule status in the resolved wake-state payload.

#### Scenario: Fajr default origin is global default
- **GIVEN** a Fajr-mode morning has no date-specific wake override
- **WHEN** the wake state is resolved
- **THEN** the wake time SHALL be 30 minutes before Fajr ends and `wakeTimeOrigin` SHALL be `globalDefaultFajrOffset`

#### Scenario: Fajr endpoint copy remains stable
- **GIVEN** a Fajr-mode morning has a wake time equal to Fajr begins or Fajr ends
- **WHEN** copy state is resolved
- **THEN** the relation text SHALL use endpoint copy rather than minute-offset copy
