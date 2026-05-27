## ADDED Requirements

### Requirement: Wake Session Lab uses tester-first information architecture
The system SHALL expose the debug/internal Wake Session Lab as a task-oriented launchpad with exactly three top-level areas: Preview Home UI, Real Alarm Test, and Diagnostics.

#### Scenario: Lab opens in preview mode
- **GIVEN** a debug/internal build with Wake Session Lab access
- **WHEN** the tester opens Wake Session Lab
- **THEN** Preview Home UI SHALL be the default selected area
- **AND** Real Alarm Test SHALL be the second area
- **AND** Diagnostics SHALL be the third area with diagnostic subsections collapsed by default
- **AND** the lab SHALL NOT lead with subsystem labels such as State Explorer, Pending Test Alarms, MorningLog Inspector, or Real AlarmKit Mapped Playback

#### Scenario: Production build hides lab
- **GIVEN** an App Store production build without internal testing enabled
- **WHEN** the user opens Settings or Home
- **THEN** Wake Session Lab, Preview Home UI controls, Home Simulation controls, Diagnostics controls, Real Alarm Test controls, fake clock controls, and `TEST MODE ACTIVE` SHALL NOT be visible or routeable

### Requirement: Preview Home UI provides guided scenario cards
The system SHALL provide Preview Home UI scenario cards for Fajr Flow, Suhoor Flow, Quiet During Wake Checks, and Custom Date & Time.

#### Scenario: Scenario cards explain the task
- **GIVEN** the tester views Preview Home UI
- **WHEN** the scenario cards are displayed
- **THEN** each card SHALL show a title, plain-language description, what it tests, whether real alarms ring, approximate duration, what to expect, and a primary action
- **AND** preview cards SHALL state that real alarms do not ring

#### Scenario: Guided preview starts Home simulation
- **GIVEN** the tester taps Start Fajr Preview, Start Suhoor Preview, or Start Quiet Preview
- **WHEN** the harness activates the scenario
- **THEN** the system SHALL create an `isTest` active simulation context
- **AND** Home SHALL consume the simulated resolved morning snapshot through the same Home snapshot path used by production
- **AND** no real platform alarms SHALL be scheduled

### Requirement: Custom Home Preview is compact by default
The system SHALL provide a Custom Home Preview flow with Date, Location, Mode, and State as the default primary fields.

#### Scenario: Tester configures a custom preview
- **GIVEN** the tester opens Custom Home Preview
- **WHEN** the form is displayed
- **THEN** Date, Location, Mode, and State SHALL be visible as the primary fields
- **AND** advanced controls such as prayer-window source, clock mode, outcome toggles, permission simulation, and artificial windows SHALL be collapsed by default
- **AND** the state choices SHALL adapt to Fajr, Suhoor, or Quiet mode

#### Scenario: Custom preview activates Home
- **GIVEN** the tester selected a date, location, mode, and state
- **WHEN** the tester taps Preview on Home
- **THEN** Home SHALL open or become the testing stage with `TEST MODE ACTIVE`
- **AND** real settings, real plans, real logs, real location settings, and real entitlements SHALL remain untouched

### Requirement: Home simulation dock guides state inspection
The system SHALL show a compact internal Home simulation dock whenever Home Simulation Mode is active.

#### Scenario: Dock displays expected state
- **GIVEN** Home Simulation Mode is active
- **WHEN** Home renders
- **THEN** the dock SHALL show `TEST MODE ACTIVE`, scenario name, exact simulated Gregorian date/time, expected-state guidance, and actions for Previous State, Next State, Change State, and Exit
- **AND** the dock SHALL NOT obscure the core Hero in a way that prevents layout and interaction testing

#### Scenario: Dock steps through states
- **GIVEN** a Fajr, Suhoor, or Quiet preview is active
- **WHEN** the tester taps Previous State or Next State
- **THEN** the harness SHALL jump immediately to the adjacent supported state
- **AND** the jump SHALL update Home via the active simulation context
- **AND** the jump SHALL NOT schedule one-minute, two-minute, or compressed Wake Checks

### Requirement: Real Alarm Test is explicit, confirmable, and five-minute-spaced
The system SHALL provide Real Alarm Test cards and setup for Fajr and Suhoor mapped AlarmKit tests.

#### Scenario: Real alarm cards warn that alarms ring
- **GIVEN** the tester views Real Alarm Test
- **WHEN** the Fajr Alarm Test and Suhoor Alarm Test cards are displayed
- **THEN** each card SHALL explain that real alarms will ring, the default sequence is primary plus five Wake Checks, a full test takes about 25-30 minutes, and the tester must set up the test before scheduling alarms

#### Scenario: Setup builds mapped preview
- **GIVEN** the tester opens Real Alarm Setup
- **WHEN** the setup screen appears
- **THEN** it SHALL show Scenario, Start delay, Sequence length, Sound, real alarm schedule preview, simulated schedule preview, and Schedule Real Test Alarms
- **AND** Start delay SHALL support 60 seconds, 90 seconds, and 120 seconds with 90 seconds as the default
- **AND** Sequence length SHALL support Primary only through Primary plus five Wake Checks with Primary plus five as the default

#### Scenario: Real mapped playback preserves production interval
- **GIVEN** the tester confirms Real Alarm Test scheduling
- **WHEN** the mapping plan is built
- **THEN** the real primary alarm SHALL be scheduled at real now plus the selected start delay
- **AND** mapped Wake Checks SHALL be scheduled at primary plus five, ten, fifteen, twenty, and twenty-five minutes according to selected eligible sequence length
- **AND** the harness SHALL NOT schedule one-minute or two-minute mapped Wake Checks
- **AND** simulated cutoff rules SHALL be evaluated before mapping events to real fire dates

#### Scenario: Confirmation is required
- **GIVEN** the tester taps Schedule Real Test Alarms
- **WHEN** the confirmation sheet appears
- **THEN** it SHALL be titled `Schedule real test alarms?`
- **AND** it SHALL state that alarms will ring on this iPhone and Wake Checks remain five minutes apart
- **AND** it SHALL show selected scenario, sequence length, mapped real fire times, simulated event times, sound role or asset when available, and Cancel All Test Alarms availability
- **AND** platform AlarmKit alarms SHALL NOT be scheduled until the tester confirms Schedule Test Alarms

### Requirement: Diagnostics are secondary and test-scoped
The system SHALL provide collapsed Diagnostics sections for Scheduled Test Alarms, Test Event Log, Permission Simulation, and Reset Test Mode.

#### Scenario: Scheduled Test Alarms inspect test alarms
- **GIVEN** test alarms exist
- **WHEN** the tester expands Scheduled Test Alarms
- **THEN** the inspector SHALL show identifier, role, mode, simulated fire time, mapped real fire time, channel, status, and `isTest`
- **AND** the tester SHALL be able to refresh, cancel a selected test alarm, and cancel all test alarms
- **AND** production pending alarms SHALL be clearly distinguished from test alarms

#### Scenario: Test Event Log is factual and clearable
- **GIVEN** test events exist
- **WHEN** the tester expands Test Event Log
- **THEN** the log SHALL show factual test-only events such as preview started, primary alarm scheduled, alarm stopped, wake check fired, awake confirmed, prayer confirmed, or quietMorning
- **AND** automatic `fajrMissed`, `fastMissed`, and `fastCompletionConfirmed` records SHALL NOT be created by the harness
- **AND** the tester SHALL be able to copy the report and clear test logs

#### Scenario: Permission simulation is not Quiet
- **GIVEN** the tester simulates AlarmKit unavailable, AlarmKit denied, Notification denied, sound missing, or schedule failure
- **WHEN** the simulation runs
- **THEN** the failure SHALL be recorded for test inspection without changing real iOS permission settings
- **AND** the Fajr or Suhoor wake intent SHALL remain active
- **AND** the simulated state SHALL NOT become Quiet or missed prayer

#### Scenario: Exit Test Mode clears only test state
- **GIVEN** active simulation context, test Wake Sessions, test logs, or test alarms exist
- **WHEN** the tester chooses Exit Test Mode
- **THEN** the system SHALL cancel mapped real AlarmKit test alarms, cancel fake or notification test alarms, clear active simulation context, restore real Home, preserve real user data, and never copy test confirmations into real worship history
