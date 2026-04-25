# fajr-end-mvp-wake Specification

## Purpose
TBD - created by archiving change define-subh-morning-system. Update Purpose after archive.
## Requirements
### Requirement: Fresh install default wake uses Fajr end
The system SHALL set the first-wave default wake to 30 minutes before the supported Fajr end boundary.

#### Scenario: Fresh install creates default wake settings
- **GIVEN** no persisted wake settings exist
- **WHEN** Subh creates default alarm configuration
- **THEN** the default wake anchor SHALL be supported Fajr end
- **AND** the default wake offset SHALL be 30 minutes before that boundary

### Requirement: Inherited Fajr-start defaults migrate to Subh default
The system SHALL migrate persisted settings that match known inherited pre-Subh Fajr-start defaults to the new Subh default of 30 minutes before supported Fajr end.

#### Scenario: Existing settings match the old factory default
- **GIVEN** persisted settings use the old factory default wake anchor and offset
- **WHEN** Subh loads alarm configuration after the redesign
- **THEN** the system SHALL migrate those settings to supported Fajr end minus 30 minutes
- **AND** the migrated settings SHALL be persisted

#### Scenario: Existing settings match the inherited 45-minute Fajr-start default
- **GIVEN** persisted settings use pre-Fajr state, Fajr-start anchor, relative timing, no latest-wake cap, and matching 45-minute wake and suhoor offsets
- **WHEN** Subh loads alarm configuration after the redesign
- **THEN** the system SHALL migrate those settings to supported Fajr end minus 30 minutes
- **AND** the migrated settings SHALL be persisted

### Requirement: Custom wake settings are preserved
The system SHALL preserve persisted wake settings that do not match known inherited pre-Subh Fajr-start defaults.

#### Scenario: User customized wake settings
- **GIVEN** persisted settings contain a custom wake anchor, state, timing mode, latest-wake cap, or non-inherited offset
- **WHEN** Subh loads alarm configuration after the redesign
- **THEN** the system SHALL preserve the custom values
- **AND** it SHALL NOT overwrite the user's customization with the new factory default

### Requirement: Fajr end trust language is transparent
The system SHALL avoid overstating the precision or authority of the supported Fajr end boundary.

#### Scenario: Supported boundary is sunrise-derived
- **GIVEN** the current provider uses a sunrise-derived boundary for supported Fajr end
- **WHEN** the user sees wake explanation copy
- **THEN** the system SHALL describe the boundary as supported, configured, or provider-derived
- **AND** the system SHALL NOT imply a hidden religious ruling beyond the configured calculation method

### Requirement: Schedule cache cannot preserve stale wake defaults
The system SHALL invalidate persisted schedule cache entries whose wake-rule signature differs from the loaded alarm configuration.

#### Scenario: Cached active window was generated from a pre-Subh wake rule
- **GIVEN** persisted schedule cache contains schedules or active-window rows generated from a Fajr-start wake rule
- **AND** the loaded alarm configuration now resolves to supported Fajr end minus 30 minutes
- **WHEN** ScheduleManager initializes
- **THEN** it SHALL discard the stale cache
- **AND** Tomorrow Morning and Morningcast SHALL render only freshly resolved rows for the current wake rule

### Requirement: Compatibility schedule builders honor Fajr end
Compatibility schedule builders SHALL compute wake dates from the resolved wake rule instead of assuming a Fajr-start-minus-offset model.

#### Scenario: Generic schedule builder receives the Subh default wake rule
- **GIVEN** an effective daily config resolves to in-Fajr, supported Fajr end, and 30-minute offset
- **WHEN** the generic DaySchedule builder computes the day
- **THEN** the wake date SHALL be 30 minutes before the supported Fajr end boundary
- **AND** the builder SHALL NOT synthesize a pre-Fajr boundary cue for that wake
