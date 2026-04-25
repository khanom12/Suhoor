## ADDED Requirements

### Requirement: Wake resolution has one authority
The system SHALL derive production wake times from the morning-resolution engine rather than from independent Fajr-start offset calculations in views, compatibility builders, or schedule consumers.

#### Scenario: A surface needs tomorrow's wake time
- **GIVEN** Tomorrow Morning, Morningcast, Fajrcast, scheduling, or a detail view needs a wake time
- **WHEN** it renders, schedules, or explains that day
- **THEN** it SHALL consume `DaySchedule.wakeDate`, a resolved snapshot decision log, or a resolver-owned wake helper
- **AND** it SHALL NOT recompute wake time from unrelated local settings such as `baseWakeOffsetMinutes`

### Requirement: Compatibility builders use resolver-owned wake rules
Compatibility schedule builders SHALL delegate wake-anchor and wake-time computation to the morning-resolution pathway.

#### Scenario: A compatibility builder receives a Fajr-end rule
- **GIVEN** an effective config resolves to in-Fajr, supported Fajr end, and a 30-minute buffer
- **WHEN** a compatibility schedule is built
- **THEN** the builder SHALL use the resolver-owned Fajr-end wake computation
- **AND** the resulting schedule SHALL match the resolved morning engine for the same inputs

### Requirement: Caches are projections, not authorities
Schedule caches SHALL store resolver output projections and SHALL be invalidated when resolver-relevant wake inputs change.

#### Scenario: Wake defaults change after cache persistence
- **GIVEN** cached schedules were created from a previous wake rule
- **WHEN** the current alarm defaults resolve a different wake rule signature
- **THEN** the app SHALL discard the cache before it can feed Tomorrow Morning, Morningcast, Fajrcast, or scheduling
