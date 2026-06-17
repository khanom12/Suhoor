## ADDED Requirements

### Requirement: Default wake times resolve through the canonical morning pipeline
The system SHALL store global default Fajr and Suhoor wake rules in the existing alarm configuration model and SHALL resolve them through the canonical morning planning, schedule resolution, wake-session, and wake-check pipeline.

#### Scenario: Default Fajr morning uses the configured Fajr rule
- **GIVEN** a future morning has no date-specific wake override and no early-worship fast intention
- **AND** the configured Fajr default is 30 minutes before Fajr ends
- **WHEN** the morning is resolved
- **THEN** the resolved wake time SHALL be Fajr ends minus 30 minutes
- **AND** wake checks SHALL be generated from that resolved wake time according to the existing wake-check settings
- **AND** no separate default-wake schedule generator SHALL be used

#### Scenario: Generated Suhoor morning uses the configured Suhoor rule
- **GIVEN** a future morning resolves as a selected fast or other early-worship morning
- **AND** the configured Suhoor default is 60 minutes before Fajr begins
- **WHEN** the morning is resolved
- **THEN** the resolved wake time SHALL be Fajr begins minus 60 minutes
- **AND** Fajr-boundary delivery SHALL remain separate from wake attempts

### Requirement: Default wake rule precedence is explicit
The system SHALL resolve a morning wake time by applying date-specific manual overrides first, then global default wake rules for the resolved purpose, then system fallback behavior when required.

#### Scenario: Manual wake override wins over changed defaults
- **GIVEN** a future morning has a date-specific manual wake-time override
- **WHEN** the global Fajr or Suhoor default changes
- **THEN** the morning SHALL keep its manual wake time
- **AND** the schedule refresh SHALL NOT rewrite the manual override

#### Scenario: Future default-based morning follows changed defaults
- **GIVEN** a future morning has no manual wake override and no protected wake session
- **WHEN** the global Fajr default changes to Fajr begins
- **THEN** the next schedule refresh SHALL resolve that morning at Fajr begins

### Requirement: Fajr default validation protects the Fajr window
The system SHALL validate saved Fajr default rules across the next 12 months and SHALL keep a 10-minute safety buffer before Fajr ends.

#### Scenario: Fajr begins supports at-start and safe after-start values
- **GIVEN** the shortest Fajr window over the next 12 months is known
- **WHEN** the user chooses Fajr begins with an at-start or after-start value no later than the shortest window minus 10 minutes
- **THEN** the rule SHALL be valid

#### Scenario: Fajr ends supports safe before-end values
- **GIVEN** the shortest Fajr window over the next 12 months is known
- **WHEN** the user chooses Fajr ends with a before-end value from 10 minutes through the shortest Fajr window
- **THEN** the rule SHALL be valid

#### Scenario: Invalid Fajr defaults need review instead of silent boundary switching
- **GIVEN** a saved Fajr default no longer fits the current location or prayer-time settings
- **WHEN** the settings and schedule refresh path revalidates the rule
- **THEN** the system SHALL mark the setting as needing review
- **AND** it SHALL use a safe temporary fallback for scheduling when necessary
- **AND** it SHALL NOT silently switch between Fajr begins and Fajr ends

### Requirement: Suhoor defaults remain before Fajr begins
The system SHALL support Suhoor default wake rules only before Fajr begins.

#### Scenario: Suhoor before Fajr begins resolves
- **GIVEN** the Suhoor default is 60 minutes before Fajr begins
- **WHEN** a generated Suhoor morning is resolved
- **THEN** the wake time SHALL be Fajr begins minus 60 minutes

#### Scenario: Suhoor cannot use Fajr ends
- **GIVEN** a Suhoor default rule refers to Fajr ends
- **WHEN** the rule is validated
- **THEN** validation SHALL reject the rule
- **AND** the system SHALL NOT resolve it silently

### Requirement: Default changes protect sensitive mornings and sessions
The system SHALL apply changed defaults only to future default-based mornings that have not been manually changed and do not have protected wake-session state.

#### Scenario: Protected wake session is not rewritten
- **GIVEN** a future default-based morning already has an active, fired, completed, quiet, or already-passed wake session
- **WHEN** the global default changes and schedules refresh
- **THEN** the existing wake-session timing SHALL be preserved

#### Scenario: Cancelled Suhoor can still hand off to Fajr
- **GIVEN** an execution flow cancels a Suhoor wake session before Fajr and schedules the same morning's Fajr wake path
- **WHEN** the wake session store receives the Fajr draft
- **THEN** the handoff SHALL be allowed
- **AND** this exception SHALL NOT allow global default changes to overwrite manual or quiet mornings

### Requirement: Settings exposes default wake times under Wake Alarms
The Settings surface SHALL include a Wake Alarms > Default Wake Times detail screen for managing future default Fajr and Suhoor wake rules.

#### Scenario: Settings root shows default wake times
- **GIVEN** the user opens Settings
- **WHEN** the Wake Alarms section renders
- **THEN** the first row SHALL be Default Wake Times
- **AND** the subtitle SHALL summarize the current Fajr and Suhoor defaults or show that review is needed

#### Scenario: Detail screen explains preserved manual changes
- **GIVEN** the user opens Default Wake Times
- **WHEN** the detail screen renders
- **THEN** it SHALL include Fajr wake default and Suhoor wake default sections
- **AND** it SHALL state that manual changes are kept
- **AND** it SHALL explain why unavailable options may be unavailable without relying on color alone
