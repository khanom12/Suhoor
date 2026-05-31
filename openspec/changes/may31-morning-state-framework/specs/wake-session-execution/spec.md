## MODIFIED Requirements

### Requirement: Default Wake Checks are deterministic
The system SHALL schedule core Wake Checks as deterministic wake-session events using the May 31 purpose-specific boundary, interval, and cutoff rules.

#### Scenario: Fajr mode schedules default Wake Checks
- **GIVEN** a Fajr-mode primary wake is 30 minutes before Fajr ends
- **WHEN** Wake Checks are planned
- **THEN** the system SHALL schedule total attempts at 30, 25, 20, 15, 10, and 5 minutes before Fajr ends
- **AND** it SHALL NOT schedule any Wake Check at the exact Fajr end boundary

#### Scenario: Suhoor mode schedules default Wake Checks
- **GIVEN** a Suhoor-mode primary wake is 30 minutes before Fajr begins
- **WHEN** Wake Checks are planned
- **THEN** the system SHALL schedule total attempts at 30, 25, 20, 15, 10, and 5 minutes before Fajr begins
- **AND** it SHALL NOT schedule any Wake Check at or after Fajr begins

#### Scenario: Cutoff limits Wake Checks
- **GIVEN** the primary wake is too close to the relevant purpose boundary
- **WHEN** Wake Checks are planned
- **THEN** the system SHALL schedule fewer than five Wake Checks or none
- **AND** it SHALL NOT schedule any Wake Check after `relevant window end - 5 minutes`

#### Scenario: Latest new session creation is enforced
- **GIVEN** the current time is later than `relevant window end - 6 minutes`
- **WHEN** a new Wake Session is requested
- **THEN** the system SHALL reject new session creation for that relevant window
- **AND** it SHALL explain that the request is too close to the relevant boundary when surfaced to the user

#### Scenario: Five minutes remain before boundary
- **GIVEN** the selected wake time is exactly five minutes before the relevant boundary
- **WHEN** Wake Checks are planned
- **THEN** the system SHALL schedule one primary attempt
- **AND** it SHALL schedule no follow-up Wake Checks

#### Scenario: Wake Checks use future deterministic event identifiers
- **GIVEN** a Wake Session has wake checks in the active scheduled horizon
- **WHEN** events are materialized for scheduling
- **THEN** each Wake Check SHALL use a deterministic event ID containing the date key and wake-check index
- **AND** each Wake Check SHALL include wake-session metadata where available
- **AND** past Wake Checks SHALL NOT be scheduled

#### Scenario: Stale Wake Checks are reconciled
- **GIVEN** a schedule change removes or moves previously scheduled Wake Checks
- **WHEN** scheduling identifiers are reconciled
- **THEN** stale wake-check identifiers SHALL be included in cancellation candidates
- **AND** unrelated alarms SHALL NOT be cancelled solely because one morning changed

### Requirement: Current-morning confirmations are separate
The system SHALL treat Suhoor wake acknowledgement, Fajr wake acknowledgement, Fajr prayer confirmation, fasting intent, and fast completion as separate current-morning outcomes.

#### Scenario: User confirms awake for Fajr
- **GIVEN** a Fajr Wake Session is scheduled or unconfirmed
- **WHEN** the user taps `I'm awake for Fajr` or `I’m Awake for Fajr`
- **THEN** the Wake Session SHALL be marked confirmed awake for Fajr with `confirmedAt`
- **AND** remaining primary or Wake Check events for that Fajr session SHALL be cancelled
- **AND** a local MorningLog record SHALL be written
- **AND** Fajr prayer SHALL remain unconfirmed until the user confirms prayer

#### Scenario: User confirms awake for Suhoor
- **GIVEN** a Suhoor Wake Session is scheduled or unconfirmed
- **WHEN** the user taps `I'm awake for Suhoor` or `I’m Awake for Suhoor`
- **THEN** the Wake Session SHALL be marked confirmed awake for Suhoor with `confirmedAt`
- **AND** remaining Suhoor primary or Wake Check events for that morning SHALL be cancelled
- **AND** a local MorningLog record SHALL be written
- **AND** no full Fajr wake-check session SHALL be created automatically
- **AND** Fajr wake acknowledgement, Fajr prayer, and fast completion SHALL remain unconfirmed

#### Scenario: Single Fajr-start event after Suhoor
- **GIVEN** Suhoor wake acknowledgement has been logged and Fajr has not begun
- **WHEN** Fajr begins
- **THEN** Subh MAY issue a single Fajr-start AlarmKit event when configured and eligible
- **AND** that event SHALL NOT create Wake Checks by default

#### Scenario: User opts into Fajr follow-up after Suhoor
- **GIVEN** Suhoor wake acknowledgement has been logged
- **WHEN** the user intentionally chooses a Fajr follow-up action such as `Wake Me for Fajr` or `Set Fajr Wake Alarm`
- **THEN** the system SHALL create or configure a normal Fajr Wake Session
- **AND** normal Fajr wake-check rules SHALL apply

#### Scenario: User confirms Fajr prayer
- **GIVEN** the current or late-eligible morning is available for Fajr prayer completion
- **WHEN** the user taps `I prayed Fajr` or `I Prayed Fajr`
- **THEN** the system SHALL record Fajr prayer confirmation for the relevant morning
- **AND** the confirmation SHALL remain separate from awake confirmation

#### Scenario: Suhoor transitions to Fajr
- **GIVEN** the user confirmed Suhoor awake before Fajr begins
- **WHEN** Fajr begins
- **THEN** the system SHALL NOT treat Suhoor awake acknowledgement as Fajr wake acknowledgement
- **AND** the system SHALL NOT treat Suhoor awake acknowledgement as Fajr prayer confirmation

### Requirement: Quiet cancellation is intentional
The system SHALL require explicit user confirmation before cancelling an active Wake Session due to Quiet selection, and SHALL record active-session Quiet cancellation distinctly from awake acknowledgement.

#### Scenario: Quiet is selected while Wake Checks remain pending
- **GIVEN** a Wake Session has future primary or Wake Check events
- **WHEN** the user selects Quiet from an approved alarm-state control
- **THEN** the system SHALL ask whether to cancel remaining alarms/checks for this morning
- **AND** Quiet SHALL NOT appear as the primary active wake CTA

#### Scenario: User keeps Wake Checks
- **GIVEN** the Quiet cancellation confirmation is visible
- **WHEN** the user chooses to keep the alarm or wake checks
- **THEN** the Wake Session SHALL remain active
- **AND** pending wake-session events SHALL remain scheduled

#### Scenario: User confirms active-session Quiet cancellation
- **GIVEN** the Quiet cancellation confirmation is visible
- **WHEN** the user confirms cancellation
- **THEN** remaining wake-session primary and Wake Check events SHALL be cancelled for that morning
- **AND** the Wake Session SHALL be marked with a distinct quiet cancellation reason such as `quietDuringExecution`
- **AND** a local operational record SHALL be written
- **AND** the system SHALL NOT log wake acknowledgement, Fajr prayer completion, or Fajr missed

#### Scenario: User restores active wake from Quiet
- **GIVEN** a morning was marked Quiet through active-session cancellation
- **WHEN** the user turns the alarm back on for that morning
- **THEN** the Wake Session SHALL become scheduled again for the preserved selected purpose when still schedulable
- **AND** the quiet reason SHALL be cleared
