## ADDED Requirements

### Requirement: Alarm config load performs narrow inherited-default migration
The system SHALL migrate persisted alarm configuration whose wake-default fields match known inherited pre-Subh Fajr-start defaults.

#### Scenario: Old default persisted before Subh
- **GIVEN** persisted alarm configuration uses enabled wake, Fajr-start anchor, pre-Fajr state, and 30-minute offset exactly as the old default
- **WHEN** alarm configuration is loaded
- **THEN** the loaded and stored configuration SHALL use supported Fajr end, in-Fajr state, and 30-minute offset

#### Scenario: AppSettings-derived 45-minute Fajr-start default persisted before Subh
- **GIVEN** persisted alarm configuration uses pre-Fajr state, Fajr-start anchor, relative timing, no latest-wake cap, and matching 45-minute wake and suhoor offsets
- **AND** the alarm migration version predates the inherited-default correction
- **WHEN** alarm configuration is loaded
- **THEN** the loaded and stored configuration SHALL use supported Fajr end, in-Fajr state, and 30-minute offset

#### Scenario: Custom persisted settings differ from old default
- **GIVEN** persisted alarm configuration differs from known inherited Fajr-start defaults in anchor, state, timing mode, latest-wake cap, or preset offset
- **WHEN** alarm configuration is loaded
- **THEN** the loaded and stored configuration SHALL preserve the custom wake fields

### Requirement: Cached active windows cannot preserve stale wake defaults
The system SHALL invalidate persisted schedule cache entries whose wake-rule signature differs from the loaded alarm configuration.

#### Scenario: Old active-window cache contains pre-Subh wake decisions
- **GIVEN** persisted schedule cache contains active-window or schedule rows generated from a Fajr-start wake rule
- **AND** the loaded alarm configuration now resolves to supported Fajr end minus 30 minutes
- **WHEN** ScheduleManager initializes
- **THEN** it SHALL discard the stale schedule cache
- **AND** Tomorrow Morning and Morningcast SHALL wait for or render a freshly resolved active window instead of showing the stale Fajr-start rule

### Requirement: Legacy schedule builders honor Fajr-end wake rules
Any remaining legacy schedule builder used for diagnostics or fallback scheduling SHALL compute wake times from the resolved wake rule, including supported Fajr end anchors.

#### Scenario: Generic schedule builder receives the Subh default rule
- **GIVEN** the effective daily config resolves to in-Fajr, supported Fajr end, and 30-minute offset
- **WHEN** a DaySchedule is built through the legacy-compatible builder
- **THEN** the wake date SHALL be 30 minutes before the supported Fajr end boundary
- **AND** the builder SHALL NOT synthesize a pre-Fajr boundary cue for that wake
