## ADDED Requirements

### Requirement: Fresh install default wake uses Fajr end
The system SHALL set the first-wave default wake to 30 minutes before the supported Fajr end boundary.

#### Scenario: Fresh install creates default wake settings
- **GIVEN** no persisted wake settings exist
- **WHEN** Subh creates default alarm configuration
- **THEN** the default wake anchor SHALL be supported Fajr end
- **AND** the default wake offset SHALL be 30 minutes before that boundary

### Requirement: Old factory default migrates to Subh default
The system SHALL migrate persisted settings that exactly match the old factory default of 30 minutes before Fajr start to the new Subh default of 30 minutes before supported Fajr end.

#### Scenario: Existing settings match the old factory default
- **GIVEN** persisted settings use the old factory default wake anchor and offset
- **WHEN** Subh loads alarm configuration after the redesign
- **THEN** the system SHALL migrate those settings to supported Fajr end minus 30 minutes
- **AND** the migrated settings SHALL be persisted

### Requirement: Custom wake settings are preserved
The system SHALL preserve persisted wake settings that do not exactly match the old factory default.

#### Scenario: User customized wake settings
- **GIVEN** persisted settings contain a custom wake anchor, enabled state, or offset
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
