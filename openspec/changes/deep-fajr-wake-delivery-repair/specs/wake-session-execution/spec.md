## MODIFIED Requirements

### Requirement: Current-morning confirmations are separate
The system SHALL treat awake confirmation, Fajr prayer confirmation, fasting intent, and fast completion as separate current-morning outcomes.

#### Scenario: User confirms awake for Fajr
- **GIVEN** a Fajr Wake Session is scheduled or unconfirmed
- **WHEN** the user taps `I'm awake for Fajr`
- **THEN** the Wake Session SHALL be marked confirmed awake for Fajr with `confirmedAt`
- **AND** remaining primary or Wake Check events for that morning SHALL be cancelled across current resolved events, deterministic date-key wake/check identifiers, persisted expected deliveries, and known prior-mode Subh identifiers
- **AND** delivery repair SHALL NOT recreate cancelled wake-session deliveries for that confirmed morning
- **AND** a local MorningLog record SHALL be written
- **AND** Fajr prayer SHALL remain unconfirmed until the user confirms prayer

#### Scenario: User confirms awake for Suhoor
- **GIVEN** a Suhoor Wake Session is scheduled or unconfirmed
- **WHEN** the user taps `I'm awake for Suhoor`
- **THEN** the Wake Session SHALL be marked confirmed awake for Suhoor with `confirmedAt`
- **AND** remaining Suhoor primary or Wake Check events for that morning SHALL be cancelled across current resolved events, deterministic date-key wake/check identifiers, persisted expected deliveries, and known prior-mode Subh identifiers
- **AND** delivery repair SHALL NOT recreate cancelled wake-session deliveries for that confirmed morning
- **AND** a local MorningLog record SHALL be written
- **AND** fasting intent for the current day SHALL be confirmed or planned only through its explicit flow
- **AND** Fajr prayer and fast completion SHALL remain unconfirmed

## ADDED Requirements

### Requirement: Platform delivery callbacks record factual Wake Session events
The system SHALL map observable platform delivery callbacks to factual Wake Session records without inferring religious or completion outcomes.

#### Scenario: Wake delivery fires
- **GIVEN** a notification or AlarmKit delivery can be mapped to a Wake Session event
- **WHEN** the platform reports the delivery as fired or presented
- **THEN** the Wake Session SHALL record the primary alarm or wake check fired fact
- **AND** it SHALL NOT mark the user awake, prayed, missed prayer, fasting, or completed a fast

#### Scenario: Wake delivery is stopped or dismissed
- **GIVEN** a notification or AlarmKit delivery can be mapped to a Wake Session event
- **WHEN** the platform reports stop or dismissal information
- **THEN** the Wake Session SHALL record the stop or dismissal source when supported
- **AND** it SHALL NOT confirm awake unless a supported acknowledgement flow explicitly defines that behavior

### Requirement: Mode-switch cancellation removes prior wake checks
The system SHALL prevent Fajr, Suhoor, and Quiet mode transitions from leaving orphaned wake-session deliveries.

#### Scenario: Active morning switches modes
- **GIVEN** a morning has pending wake-session primary or check deliveries
- **WHEN** the user changes between Fajr, Suhoor, and Quiet modes
- **THEN** stale Subh-owned wake-session deliveries for that date SHALL be cancelled
- **AND** only deliveries required by the newly resolved morning plan SHALL remain or be scheduled
