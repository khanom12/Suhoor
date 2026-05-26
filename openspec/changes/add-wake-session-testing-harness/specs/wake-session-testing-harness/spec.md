## ADDED Requirements

### Requirement: Debug harness uses the real morning execution engine
The system SHALL provide a debug/internal Wake Session Testing Harness that drives the existing morning-resolution, Wake Session, scheduling, Hero state, and MorningLog paths through controlled test inputs rather than a second product engine.

#### Scenario: Test scenario creates a Wake Session
- **GIVEN** a debug/internal build with Wake Session Lab access
- **WHEN** the tester starts a compressed Fajr or Suhoor scenario
- **THEN** the system SHALL create or update a test-scoped Wake Session through the same Wake Session store used by production execution
- **AND** the test session SHALL reference a resolved morning date key, planned wake time, mode, Fajr boundaries, primary event, and wake-check events
- **AND** the system SHALL NOT create a separate Fajr, Suhoor, Ramadan, or testing-only wake engine

#### Scenario: Test controls fake the world around the app
- **GIVEN** the harness is active
- **WHEN** simulated time, prayer windows, permission state, alarm-fired events, or scheduler mode change
- **THEN** those controls SHALL feed the app through injectable clock, scenario-window, scheduler, and event-recording seams
- **AND** SwiftUI lab controls SHALL NOT directly mutate production schedule state or platform alarms outside those seams

### Requirement: Harness supports injected time and compressed prayer windows
The system SHALL support an injected clock and debug-only compressed Fajr/Suhoor windows for Wake Session testing while preserving production clock and prayer-window behavior.

#### Scenario: Compressed Fajr test window
- **GIVEN** the tester starts `Start Fajr Wake Session Test` at simulated time `T`
- **WHEN** the harness resolves the test scenario
- **THEN** Fajr begins SHALL be `T + 1 minute`
- **AND** primary wake SHALL be `T + 2 minutes`
- **AND** Fajr ends SHALL be `T + 8 minutes`
- **AND** test wake checks SHALL use a one-minute interval only for the test scenario

#### Scenario: Compressed Suhoor test window
- **GIVEN** the tester starts `Start Suhoor Wake Session Test` at simulated time `T`
- **WHEN** the harness resolves the test scenario
- **THEN** final third begins SHALL be `T`
- **AND** primary Suhoor wake SHALL be `T + 2 minutes`
- **AND** Fajr begins SHALL be `T + 8 minutes`
- **AND** test wake checks SHALL use a one-minute interval only for the test scenario

#### Scenario: Production defaults are unchanged
- **GIVEN** the app runs outside the harness path
- **WHEN** a production Wake Session is planned
- **THEN** primary alarm plus up to five Wake Checks SHALL remain available
- **AND** the production Wake Check interval SHALL remain five minutes
- **AND** the Fajr cutoff SHALL remain five minutes before Fajr ends
- **AND** the Suhoor cutoff SHALL remain five minutes before Fajr begins

### Requirement: Fake scheduler records deterministic test delivery behavior
The system SHALL provide a fake scheduler adapter for unit, integration, and lab testing that records scheduled alarms, cancellation requests, remaining pending alarms, simulated failures, and reconciliation state without ringing real alarms.

#### Scenario: Fake scheduler records scheduled test alarms
- **GIVEN** a compressed test scenario with primary and Wake Check events
- **WHEN** the fake scheduler schedules the scenario
- **THEN** it SHALL record deterministic test alarm IDs
- **AND** it SHALL record fire dates, roles, mode, channel, status, and `isTest`
- **AND** it SHALL expose remaining pending test alarms to the lab inspector

#### Scenario: Fake scheduler cancels stale IDs on reschedule
- **GIVEN** a test Wake Session has a scheduled primary alarm and Wake Checks
- **WHEN** the wake time is rescheduled
- **THEN** the fake scheduler SHALL record cancellation requests for stale primary and Wake Check IDs
- **AND** it SHALL schedule the new expected IDs
- **AND** it SHALL leave no duplicate pending Wake Checks for the same test session

#### Scenario: Permission failure stays distinct from Quiet
- **GIVEN** the fake scheduler is configured to simulate AlarmKit or notification permission failure
- **WHEN** scheduling is attempted
- **THEN** the harness SHALL record a permission-blocked delivery state
- **AND** the resolved wake intent SHALL remain Fajr or Suhoor
- **AND** the system SHALL NOT log Quiet Morning or missed Fajr because of the permission failure

### Requirement: Wake Session Lab is debug/internal only
The system SHALL expose a Wake Session Lab under Settings > Developer only in debug/internal builds and SHALL prevent production/release builds from exposing unsafe test controls.

#### Scenario: Debug build shows lab entry point
- **GIVEN** the app is built with `DEBUG` or `INTERNAL_TESTING`
- **WHEN** the tester opens Settings
- **THEN** a Developer entry point SHALL allow opening Wake Session Lab
- **AND** the lab SHALL show a visible `TEST MODE ACTIVE` or equivalent test-mode banner when a scenario is active

#### Scenario: Release build hides lab entry point
- **GIVEN** the app is built for production release without internal testing enabled
- **WHEN** the user opens Settings
- **THEN** Wake Session Lab, fake clock controls, compressed scenario buttons, simulated alarm controls, test log inspectors, and real compressed AlarmKit test buttons SHALL NOT be visible or routeable

### Requirement: Lab scenario controls cover core wake and transition cases
The system SHALL provide debug/internal scenario controls for compressed Fajr, compressed Suhoor, Suhoor-not-confirmed to Fajr, Quiet during wake checks, slider reschedule, alarm stop versus awake confirmation, permission failure, cross-surface consistency, and real AlarmKit compressed testing.

#### Scenario: Alarm stop does not confirm awake
- **GIVEN** a compressed Fajr or Suhoor scenario has a primary alarm event
- **WHEN** the tester records the primary alarm as stopped or dismissed
- **THEN** the Wake Session SHALL remain unconfirmed
- **AND** eligible Wake Checks SHALL remain pending until the tester explicitly confirms awake or cancels through Quiet

#### Scenario: Awake confirmation cancels remaining checks
- **GIVEN** a compressed Fajr or Suhoor scenario has remaining Wake Checks
- **WHEN** the tester confirms `I'm awake for Fajr` or `I'm awake for Suhoor`
- **THEN** the Wake Session SHALL record the matching awake confirmation
- **AND** remaining test Wake Checks SHALL be cancelled
- **AND** Fajr prayer SHALL remain separate from awake confirmation

#### Scenario: Suhoor confirmation records fasting intent only
- **GIVEN** a compressed Suhoor scenario is active
- **WHEN** the tester confirms `I'm awake for Suhoor`
- **THEN** the MorningLog SHALL record Suhoor awake confirmation and fasting intent confirmation
- **AND** it SHALL NOT record Fajr prayer confirmation or fast completion

#### Scenario: Suhoor unconfirmed hands off to Fajr
- **GIVEN** a compressed Suhoor scenario reaches Fajr begins without Suhoor awake confirmation
- **WHEN** the tester opens the current-morning action path
- **THEN** the app SHALL allow `I'm awake for Fajr` before `I prayed Fajr`
- **AND** it SHALL NOT treat unconfirmed Suhoor as confirmed wake or missed Fajr

#### Scenario: Quiet during active checks requires confirmation
- **GIVEN** a test Wake Session has pending Wake Checks
- **WHEN** the tester selects Quiet
- **THEN** the app SHALL show the active-session confirmation sheet
- **AND** confirming Quiet SHALL cancel pending Wake Checks and log `quietMorning`
- **AND** it SHALL NOT log missed Fajr

### Requirement: Test records and inspectors are isolated from real history
The system SHALL mark test-created Wake Sessions, MorningLogs, scheduled events, and delivery records as test-scoped and provide debug-only inspectors and cleanup actions that cannot delete real user data.

#### Scenario: MorningLog inspector shows test facts
- **GIVEN** a test scenario has created records
- **WHEN** the tester opens the MorningLog inspector
- **THEN** it SHALL show WakeSessionID, mode, primary alarm time, Wake Check times, pending and cancelled IDs, status, recorded events, and whether the record is test data
- **AND** every test record SHALL be marked `isTest = true` or equivalent
- **AND** test records SHALL NOT count toward real prayer history, fasting history, streaks, Qada, Plus analytics, export, or sync

#### Scenario: Pending alarm inspector shows test delivery state
- **GIVEN** a test scenario has scheduled or cancelled test alarms
- **WHEN** the tester opens the pending alarm inspector
- **THEN** it SHALL show alarm IDs, fire dates, primary versus Wake Check role, fake versus real AlarmKit mode, and cancellation/failure status
- **AND** it SHALL distinguish test alarms from any production pending alarms

#### Scenario: Safety actions clear only test state
- **GIVEN** test sessions, test logs, and test alarms exist
- **WHEN** the tester chooses `Cancel All Test Alarms`, `Clear Test Wake Sessions`, `Clear Test MorningLogs`, or `Exit Test Mode`
- **THEN** the harness SHALL cancel or clear only test-scoped data
- **AND** it SHALL preserve real user settings, real MorningLogs, and production scheduled alarms

### Requirement: Real AlarmKit compressed test is explicit and near-future
The system SHALL support an explicit debug/internal real AlarmKit compressed test for physical-device QA using near-future real device fire dates, without changing the iPhone system clock or fake app time for actual AlarmKit delivery.

#### Scenario: Real AlarmKit compressed test schedules near-future alarms
- **GIVEN** the tester explicitly starts `Start Real AlarmKit Compressed Test`
- **WHEN** the harness schedules real device delivery
- **THEN** the primary alarm SHALL be scheduled near future real time such as `now + 2 minutes`
- **AND** Wake Checks SHALL be scheduled at near future real times such as `now + 3`, `now + 4`, and `now + 5 minutes`
- **AND** the lab SHALL clearly warn that real alarms will ring

#### Scenario: Automated tests do not run real alarms by default
- **GIVEN** the unit or integration test suite runs
- **WHEN** harness tests exercise real AlarmKit support
- **THEN** they SHALL verify the guarded code path exists without scheduling real platform alarms unless an explicit safe manual/device mode is enabled
