## ADDED Requirements

### Requirement: Core Wake Session lifecycle
The system SHALL maintain one local core Wake Session for each active target morning's wake execution lifecycle.

#### Scenario: Wake Session is created from a resolved morning
- **GIVEN** a resolved scheduled morning has an enabled primary wake event
- **WHEN** the active scheduled horizon is synced
- **THEN** the system SHALL create or update one Wake Session for that date key
- **AND** the Wake Session SHALL store its morning date, mode, planned wake time, prayer window references, primary scheduled event ID, wake-check scheduled event IDs, status, timestamps, quiet reason when applicable, and operational log references

#### Scenario: Wake Session follows the existing morning engine
- **GIVEN** the morning resolver changes a target morning's wake mode or wake time
- **WHEN** the schedule is refreshed
- **THEN** the Wake Session SHALL update from the resolved scheduled events
- **AND** the system SHALL NOT create a separate wake-session-specific morning resolver

#### Scenario: Alarm stop does not confirm awake
- **GIVEN** a platform wake alarm is stopped or dismissed
- **WHEN** Subh records the stop event
- **THEN** the Wake Session SHALL remain unconfirmed unless the user confirms awake inside Subh
- **AND** no Fajr prayer, fasting completion, or missed-prayer outcome SHALL be inferred from the platform stop

#### Scenario: Confirmed or Quiet sessions preserve terminal meaning
- **GIVEN** a Wake Session is confirmed awake, expired unconfirmed, cancelled for the morning, or marked quiet
- **WHEN** the active scheduled horizon is synced
- **THEN** the system SHALL preserve the terminal meaning unless the user explicitly restores an active wake mode from Quiet

### Requirement: Default Wake Checks are deterministic
The system SHALL schedule core Wake Checks as deterministic wake-session events using the MVP default interval and cutoff rules.

#### Scenario: Fajr mode schedules default Wake Checks
- **GIVEN** a Fajr-mode primary wake is 30 minutes before Fajr ends
- **WHEN** Wake Checks are planned
- **THEN** the system SHALL schedule up to five Wake Checks at five-minute intervals after the primary wake
- **AND** the last Wake Check SHALL be no later than five minutes before Fajr ends

#### Scenario: Suhoor mode schedules default Wake Checks
- **GIVEN** a Suhoor-mode primary wake is before Fajr begins
- **WHEN** Wake Checks are planned
- **THEN** the system SHALL schedule up to five Wake Checks at five-minute intervals after the primary wake
- **AND** the last Wake Check SHALL be no later than five minutes before Fajr begins

#### Scenario: Cutoff limits Wake Checks
- **GIVEN** the primary wake is too close to the relevant mode cutoff
- **WHEN** Wake Checks are planned
- **THEN** the system SHALL schedule fewer than five Wake Checks or none
- **AND** it SHALL NOT schedule any Wake Check after the cutoff

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
The system SHALL treat awake confirmation, Fajr prayer confirmation, fasting intent, and fast completion as separate current-morning outcomes.

#### Scenario: User confirms awake for Fajr
- **GIVEN** a Fajr Wake Session is scheduled or unconfirmed
- **WHEN** the user taps `I'm awake for Fajr`
- **THEN** the Wake Session SHALL be marked confirmed awake for Fajr with `confirmedAt`
- **AND** remaining primary or Wake Check events for that morning SHALL be cancelled
- **AND** a local MorningLog record SHALL be written
- **AND** Fajr prayer SHALL remain unconfirmed until the user confirms prayer

#### Scenario: User confirms awake for Suhoor
- **GIVEN** a Suhoor Wake Session is scheduled or unconfirmed
- **WHEN** the user taps `I'm awake for Suhoor`
- **THEN** the Wake Session SHALL be marked confirmed awake for Suhoor with `confirmedAt`
- **AND** remaining Suhoor primary or Wake Check events for that morning SHALL be cancelled
- **AND** a local MorningLog record SHALL be written
- **AND** fasting intent for the current day SHALL be confirmed or planned
- **AND** Fajr prayer and fast completion SHALL remain unconfirmed

#### Scenario: User confirms Fajr prayer
- **GIVEN** the current morning is available in the hero
- **WHEN** the user taps `I prayed Fajr`
- **THEN** the system SHALL record Fajr prayer confirmation for the relevant current morning
- **AND** the confirmation SHALL remain separate from awake confirmation

#### Scenario: Suhoor transitions to Fajr
- **GIVEN** the user confirmed Suhoor awake before Fajr begins
- **WHEN** Fajr begins
- **THEN** the primary current-morning completion CTA SHALL become `I prayed Fajr`
- **AND** Suhoor awake SHALL NOT count as Fajr prayer confirmation

### Requirement: Quiet cancellation is intentional
The system SHALL require explicit user confirmation before cancelling an active Wake Session due to Quiet selection.

#### Scenario: Quiet is selected while Wake Checks remain pending
- **GIVEN** a Wake Session has future primary or Wake Check events
- **WHEN** the user selects Quiet from the hero
- **THEN** the system SHALL ask whether to stop wake checks for this morning
- **AND** the user SHALL be offered `Keep wake checks` and `Stop for this morning`

#### Scenario: User keeps Wake Checks
- **GIVEN** the Quiet cancellation confirmation is visible
- **WHEN** the user chooses `Keep wake checks`
- **THEN** the Wake Session SHALL remain active
- **AND** pending wake-session events SHALL remain scheduled

#### Scenario: User stops for this morning
- **GIVEN** the Quiet cancellation confirmation is visible
- **WHEN** the user chooses `Stop for this morning`
- **THEN** remaining wake-session primary and Wake Check events SHALL be cancelled for that morning
- **AND** the Wake Session SHALL be marked `quietMorning`
- **AND** a local `quietMorning` operational record SHALL be written
- **AND** the system SHALL NOT log Fajr missed

#### Scenario: User restores active wake from Quiet
- **GIVEN** a morning was marked Quiet through active-session cancellation
- **WHEN** the user reselects Fajr or Suhoor for that morning
- **THEN** the Wake Session SHALL become scheduled again for the restored active mode
- **AND** the quiet reason SHALL be cleared

### Requirement: MorningLogs are local operational records
The system SHALL write local core MorningLog operational records for current-morning execution without exposing paid history features.

#### Scenario: Wake Session records are written
- **GIVEN** a Wake Session is created, scheduled, confirmed, cancelled, expired, or marked Quiet
- **WHEN** the event occurs inside Subh
- **THEN** the system SHALL write a local operational MorningLog record with date key, optional wake-session ID, record type, timestamp, optional scheduled event ID, and metadata

#### Scenario: MorningLog avoids judgmental automatic outcomes
- **GIVEN** the user does not confirm awake or prayer
- **WHEN** the Wake Session remains unconfirmed or expires
- **THEN** the system SHALL use factual unconfirmed or expired-unconfirmed wake states
- **AND** it SHALL NOT automatically record missed prayer

#### Scenario: History features remain out of scope
- **GIVEN** MorningLog records exist locally
- **WHEN** the user uses the MVP app
- **THEN** the system SHALL NOT expose long-term analytics, streaks, export, sync, Qada ledgers, or historical editing from these records

### Requirement: Core Wake Session behavior is Free
The system SHALL allow Wake Sessions, core Wake Checks, current-morning awake confirmation, current-morning Fajr prayer confirmation, current-day fasting intent, and Quiet Morning without paid entitlement.

#### Scenario: User is on Free entitlement
- **GIVEN** the user has the Free entitlement snapshot
- **WHEN** core Wake Session behavior is evaluated
- **THEN** Wake Sessions, Wake Checks, current-morning check-ins, and Quiet Morning SHALL be allowed
- **AND** no StoreKit, paywall, or Plus-only engine SHALL be required

### Requirement: Alarm and sound constraints remain platform-honest
The system SHALL use platform-supported alarm behavior without promising unsupported snooze or volume controls.

#### Scenario: AlarmKit wake event is scheduled
- **GIVEN** AlarmKit can schedule a wake-session event
- **WHEN** the event is scheduled for MVP
- **THEN** native snooze SHALL NOT be configured as the Wake Check mechanism
- **AND** Wake Checks SHALL remain separate scheduled wake attempts

#### Scenario: Sound asset is selected
- **GIVEN** a wake sound role resolves to a sound asset
- **WHEN** the alarm is scheduled
- **THEN** the system MAY use a named audio asset
- **AND** it SHALL NOT promise runtime app-level system alarm volume control
