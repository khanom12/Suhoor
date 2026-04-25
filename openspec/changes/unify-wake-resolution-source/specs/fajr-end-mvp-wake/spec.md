## MODIFIED Requirements

### Requirement: Fresh install default wake uses Fajr end
The system SHALL set the first-wave default wake to 30 minutes before the supported Fajr end boundary and SHALL propagate that resolved wake through all first-wave schedule, display, detail, and cache consumers.

#### Scenario: Fresh install creates default wake settings
- **GIVEN** no persisted wake settings exist
- **WHEN** Subh creates default alarm configuration and resolves morning schedules
- **THEN** the default wake anchor SHALL be supported Fajr end
- **AND** the default wake offset SHALL be 30 minutes before that boundary
- **AND** Tomorrow Morning, Morningcast, Fajrcast, and scheduling SHALL all show or use the same resolved wake

### Requirement: Compatibility schedule builders honor Fajr end
Compatibility schedule builders SHALL compute wake dates through resolver-owned wake logic instead of assuming a Fajr-start-minus-offset model.

#### Scenario: Generic schedule builder receives the Subh default wake rule
- **GIVEN** an effective daily config resolves to in-Fajr, supported Fajr end, and 30-minute offset
- **WHEN** the generic DaySchedule builder computes the day
- **THEN** the wake date SHALL be 30 minutes before the supported Fajr end boundary
- **AND** the builder SHALL NOT synthesize a pre-Fajr boundary cue for that wake
- **AND** the computation SHALL remain aligned with the morning-resolution engine
