## MODIFIED Requirements

### Requirement: Current-morning confirmations are separate
The system SHALL treat Suhoor wake acknowledgement, Fajr wake acknowledgement, Fajr prayer confirmation, fasting intent, and fast completion as separate current-morning outcomes.

#### Scenario: User confirms awake for Suhoor
- **GIVEN** a Suhoor Wake Session is active or pending for Today Morning
- **WHEN** the user explicitly taps `I’m Awake for Suhoor`
- **THEN** the Wake Session SHALL be marked confirmed awake for Suhoor with confirmation source
- **AND** remaining Suhoor primary and Wake Check events for that morning SHALL be cancelled
- **AND** the system SHALL transition the Hero toward same-morning Fajr where valid
- **AND** the system SHALL NOT log Fajr prayer completion, fast completion, or Fajr awake acknowledgement
- **AND** the system SHALL NOT create a full Fajr wake-check session by default

#### Scenario: User confirms awake for Fajr
- **GIVEN** a Fajr Wake Session is active or pending for Today Morning
- **WHEN** the user explicitly taps `I’m Awake for Fajr`
- **THEN** the Wake Session SHALL be marked confirmed awake for Fajr with confirmation source
- **AND** remaining Fajr primary and Wake Check events for that morning SHALL be cancelled
- **AND** `I’m Awake for Fajr` SHALL be prevented from appearing again for that morning
- **AND** Fajr prayer SHALL remain unresolved until the user confirms prayer

#### Scenario: Fajr prayer action is sequential
- **GIVEN** the user has explicitly confirmed awake for Fajr
- **WHEN** Fajr is still in-window and prayer is unresolved
- **THEN** the system SHALL make `I Prayed Fajr` eligible only after a short cooldown with a starting target of 1.5 seconds
- **AND** it SHALL NOT show `I’m Awake for Fajr` and `I Prayed Fajr` at the same time

#### Scenario: System dismissal is not awake confirmation
- **GIVEN** a primary alarm or wake check fires for a wake session
- **WHEN** it is dismissed through an ordinary system or AlarmKit dismissal without an explicit awake-confirmation action
- **THEN** the current attempt SHALL be stopped
- **AND** the wake session SHALL remain unresolved
- **AND** later valid wake checks SHALL remain scheduled
- **AND** dismissal source SHALL be recorded for analytics/debugging
- **AND** wake success SHALL NOT be logged

#### Scenario: Next pending attempt is exposed after non-awake dismissal
- **GIVEN** a primary alarm or wake check was dismissed without explicit awake confirmation
- **AND** a later wake check remains pending
- **WHEN** presentation state is resolved
- **THEN** the next pending wake-check time SHALL be exposed as the active Hero primary time

### Requirement: Early-awake confirmations are purpose-specific
The system SHALL support confirmed early-awake actions before active windows and SHALL apply different delivery consequences for Suhoor and Fajr.

#### Scenario: User confirms already awake for Suhoor
- **GIVEN** the local time is after midnight and before the Suhoor window begins
- **AND** Today Morning has a Suhoor wake session pending
- **WHEN** the user confirms `I’m Already Awake for Suhoor`
- **THEN** Suhoor wake SHALL be logged as early
- **AND** upcoming Suhoor alarms/checks SHALL be cancelled or silenced
- **AND** the default Fajr-beginning adhan/event SHALL be preserved where configured and eligible
- **AND** the Hero SHALL transition toward same-morning Fajr
- **AND** Fajr prayer and fast completion SHALL remain unresolved

#### Scenario: User confirms already awake for Fajr
- **GIVEN** the local time is after midnight and before Fajr begins
- **AND** Today Morning has Fajr delivery pending
- **WHEN** the user confirms `I’m Already Awake for Fajr`
- **THEN** Fajr wake SHALL be logged as early
- **AND** Fajr adhan, alarm, and wake checks for the current morning SHALL be cancelled or silenced
- **AND** `I’m Awake for Fajr` SHALL be prevented from appearing later for that morning
- **AND** `I Prayed Fajr` SHALL NOT appear until Fajr begins
- **AND** Fajr prayer and fast completion SHALL remain unresolved

### Requirement: Post-Suhoor Fajr delivery is slider-driven
After active or early Suhoor wake confirmation, the system SHALL preserve the same-morning Fajr-start event without automatically creating a Fajr wake-check session.

#### Scenario: Suhoor confirmation preserves Fajr-start event
- **GIVEN** Suhoor wake has been confirmed before Fajr begins
- **WHEN** the system resolves remaining same-morning delivery
- **THEN** the default Fajr delivery target SHALL be the Fajr beginning adhan/event
- **AND** Fajr Wake Checks SHALL NOT be scheduled by default
- **AND** no separate `Set Fajr Wake Alarm` CTA SHALL be required

#### Scenario: Slider activates later Fajr wake session
- **GIVEN** Suhoor wake has been confirmed and the same-morning Fajr slider is valid
- **WHEN** the user commits a later Fajr slider value
- **THEN** the system SHALL activate a normal Fajr wake session with wake checks
- **AND** it SHALL NOT silently fire both the Fajr-beginning adhan and the later wake session unless a future explicit dual-delivery setting exists
