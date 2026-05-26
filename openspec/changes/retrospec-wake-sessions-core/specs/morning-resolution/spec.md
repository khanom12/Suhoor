## ADDED Requirements

### Requirement: Wake execution state attaches to the same resolved morning
The system SHALL attach wake-session execution state to the resolved Subh morning without creating a separate Free, Plus, wake-only, or alarm-only morning engine.

#### Scenario: One morning engine owns wake execution context
- **GIVEN** a morning is resolved for Fajr, Suhoor, or Quiet quick mode
- **WHEN** the active scheduled horizon is synced
- **THEN** any Wake Session SHALL reference the resolved morning date key, planned wake time, prayer window, and mode
- **AND** entitlement SHALL NOT create a separate morning-resolution engine for Free or Plus users

#### Scenario: Wake Session follows schedule changes
- **GIVEN** a user's wake mode, wake offset, prayer window, timezone, or relevant schedule input changes
- **WHEN** the morning is re-resolved
- **THEN** the Wake Session SHALL update from the new resolved scheduled events
- **AND** stale wake-check identifiers SHALL be eligible for cancellation through schedule reconciliation

### Requirement: Wake, prayer, fasting, Quiet, and delivery states remain separate
The system SHALL keep awake confirmation, Fajr prayer confirmation, fasting intent, fast completion, Quiet Morning, alarm delivery, and unconfirmed execution outcomes as separate state concepts.

#### Scenario: Awake confirmation does not confirm prayer
- **GIVEN** a user confirms awake for Fajr
- **WHEN** the morning state is updated
- **THEN** `confirmedAwakeForFajr` SHALL be recorded
- **AND** `fajrPrayerConfirmed` SHALL remain unconfirmed until the user explicitly confirms prayer

#### Scenario: Suhoor confirmation does not complete Fajr or the fast
- **GIVEN** a user confirms awake for Suhoor
- **WHEN** the morning state is updated
- **THEN** `confirmedAwakeForSuhoor` SHALL be recorded
- **AND** fasting intent for the current day SHALL be confirmed or planned
- **AND** Fajr prayer and fast completion SHALL remain unconfirmed

#### Scenario: Alarm stop is operational only
- **GIVEN** a platform alarm is stopped, dismissed, or otherwise no longer sounding
- **WHEN** Subh records or observes that event
- **THEN** the Wake Session SHALL NOT be marked confirmed awake
- **AND** the system SHALL NOT infer Fajr prayer, fast completion, or missed prayer from the platform stop

#### Scenario: Quiet Morning is intentional suppression
- **GIVEN** the user chooses Quiet for an active morning
- **WHEN** the user confirms stopping wake checks for the morning
- **THEN** the morning SHALL record `quietMorning` or an equivalent quiet outcome
- **AND** the system SHALL NOT treat the quiet outcome as permission failure, delivery failure, or missed prayer

#### Scenario: Expired wake execution remains factual
- **GIVEN** the wake window passes without user confirmation
- **WHEN** the Wake Session expires
- **THEN** the system SHALL record an unconfirmed or expired-unconfirmed wake outcome
- **AND** the system SHALL NOT automatically record a missed Fajr prayer
