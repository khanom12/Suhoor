## ADDED Requirements

### Requirement: Active simulation context drives internal testing
The system SHALL provide a debug/internal active simulation context for Wake Session testing, State Explorer, Home Simulation Mode, fake scheduler playback, dry runs, and Real AlarmKit mapped playback without creating a second morning engine.

#### Scenario: Simulation context becomes active
- **GIVEN** a debug/internal build with Wake Session Lab access
- **WHEN** the tester activates a simulated date, time, location, mode, and jump point
- **THEN** the system SHALL create an active simulation context with a simulation ID, `isTest = true`, scenario kind, run mode, clock mode, simulated date, simulated now, simulated time zone, simulated location, prayer-window source, simulated prayer window, created-at real date, and optional Wake Session and mapping plan
- **AND** the context SHALL be observable by Home, Wake Session logic, scheduler/test services, MorningLog inspector, and pending alarm inspector
- **AND** the context SHALL NOT become a separate Fajr, Suhoor, Quiet, Ramadan, or testing-only product engine

#### Scenario: Simulation context is inactive
- **GIVEN** no active simulation context exists
- **WHEN** Home or scheduling surfaces request the current morning snapshot
- **THEN** the system SHALL use the real resolved morning snapshot and production clock behavior
- **AND** no fake time, fake scheduler, or test scenario state SHALL affect production Home

### Requirement: Injected clocks support real and simulated time
The system SHALL support a production clock using real app/device time and a test clock using simulated time for debug/internal testing.

#### Scenario: Production uses real time
- **GIVEN** the app is running outside an active simulation context
- **WHEN** morning resolution, Wake Session planning, Home snapshot building, or MorningLog recording asks for now
- **THEN** the system SHALL use the production real-time provider
- **AND** production Wake Session behavior SHALL remain unchanged

#### Scenario: Simulation uses test time
- **GIVEN** an active simulation context with clock mode `frozen`, `jumpOnly`, `runningRealTime`, or `mappedPlayback`
- **WHEN** the harness updates simulated now or a named jump point
- **THEN** Home, Morning Hero state, Wake Session test records, and test inspectors SHALL consume the simulated time supplied by the context
- **AND** SwiftUI views SHALL NOT call `Date()` directly for simulated domain decisions

### Requirement: State Explorer supports date, time, location, mode, and jump selection
The system SHALL provide a debug/internal State Explorer that lets the tester inspect supported simulated Fajr, Suhoor, Quiet, Wake Check, confirmation, and permission states instantly without scheduling real platform alarms.

#### Scenario: Tester selects a simulated state
- **GIVEN** the tester opens State Explorer
- **WHEN** the tester selects a date preset or date picker value, simulated time or named jump point, current/manual/test location, mode, prayer-window source, clock mode, Wake Session state, and outcome toggles
- **THEN** the harness SHALL build a test-scoped simulation context and preview the resulting state
- **AND** no real AlarmKit or notification alarm SHALL be scheduled unless Real AlarmKit Mapped Playback is explicitly enabled and confirmed

#### Scenario: Named jump points are instant
- **GIVEN** a Fajr, Suhoor, or Quiet simulation is active
- **WHEN** the tester selects a named jump point such as `Wake check 3 pending`, `Prayer CTA available`, `Fasting intent confirmed`, or `Quiet confirmed`
- **THEN** the harness SHALL update simulated time and test Wake Session/MorningLog state immediately
- **AND** the instant jump SHALL NOT imply one-minute, two-minute, or otherwise compressed scheduled Wake Check intervals

### Requirement: Home Simulation Mode uses the real Home surface
The system SHALL make the actual Home screen and Morning Hero consume the active simulation context when Home Simulation Mode is active.

#### Scenario: Activate simulation on Home
- **GIVEN** a simulation context has been prepared
- **WHEN** the tester taps `Activate on Home`
- **THEN** the system SHALL save the active simulation context, mark it as test-scoped, route Home to a simulated resolved morning snapshot, and show `TEST MODE ACTIVE`
- **AND** the real Home and Morning Hero UI SHALL render the simulated state through the same Home snapshot path used by production
- **AND** real user settings, real plans, real logs, real location settings, real Hijri adjustments, and real entitlement state SHALL remain untouched

#### Scenario: Exit simulation restores real Home
- **GIVEN** Home Simulation Mode is active
- **WHEN** the tester exits test mode
- **THEN** the system SHALL cancel pending test alarms, clear the active simulation context, restore Home to the real resolved morning snapshot, and preserve real user data

### Requirement: Home simulation overlay exposes internal controls safely
The system SHALL show an internal Home overlay or dock while simulation is active and SHALL keep it out of production builds.

#### Scenario: Overlay displays test state
- **GIVEN** a simulation context is active on Home
- **WHEN** Home renders
- **THEN** the overlay SHALL show `TEST MODE ACTIVE`, scenario name, simulated Gregorian date/time, simulated Hijri date when available, simulated location, run mode, current jump point, and safety actions
- **AND** for mapped playback it SHALL show the next real test alarm countdown, simulated event name, and mapped real fire time
- **AND** the overlay SHALL NOT visually block the core Hero in a way that prevents UX testing

#### Scenario: Overlay actions are internal only
- **GIVEN** the app is built for App Store production without internal testing enabled
- **WHEN** the user opens Home or Settings
- **THEN** the simulation overlay, Wake Session Lab, State Explorer, fake clock controls, fake scheduler controls, mapped playback controls, simulated alarm buttons, and `TEST MODE ACTIVE` banner SHALL NOT be visible or routeable

### Requirement: Real AlarmKit mapped playback preserves five-minute Wake Checks
The system SHALL provide explicit, confirmable Real AlarmKit Mapped Playback that maps simulated Wake Session events to near-future real AlarmKit alarms while preserving production five-minute Wake Check spacing.

#### Scenario: Default mapped playback sequence
- **GIVEN** the tester starts Real AlarmKit Mapped Playback with the default sequence
- **WHEN** the primary alarm is the selected anchor and the start delay is 90 seconds
- **THEN** the mapped real primary alarm SHALL fire at real now plus the selected start delay
- **AND** mapped Wake Check 1 SHALL be primary plus five minutes
- **AND** mapped Wake Check 2 SHALL be primary plus ten minutes
- **AND** mapped Wake Check 3 SHALL be primary plus fifteen minutes
- **AND** mapped Wake Check 4 SHALL be primary plus twenty minutes
- **AND** mapped Wake Check 5 SHALL be primary plus twenty-five minutes
- **AND** the harness SHALL NOT schedule one-minute or two-minute mapped Wake Checks

#### Scenario: Sequence length selector
- **GIVEN** the tester configures mapped playback
- **WHEN** the tester chooses `Primary only`, `Primary + 1 wake check`, `Primary + 2 wake checks`, `Primary + 3 wake checks`, `Primary + 4 wake checks`, or `Primary + 5 wake checks`
- **THEN** the mapping builder SHALL schedule only the selected number of eligible test alarm events
- **AND** the default SHALL be `Primary + 5 wake checks`

#### Scenario: Simulated cutoff filters mapped events
- **GIVEN** mapped playback requests more Wake Checks than the simulated Fajr or Suhoor cutoff allows
- **WHEN** the mapping plan is built
- **THEN** cutoff eligibility SHALL be evaluated in simulated time before real-time mapping
- **AND** Fajr Wake Checks later than five minutes before Fajr ends SHALL be excluded
- **AND** Suhoor Wake Checks later than five minutes before Fajr begins SHALL be excluded
- **AND** the confirmation UI SHALL explain why fewer events were scheduled

### Requirement: Real alarm scheduling requires confirmation
The system SHALL require a confirmation sheet before scheduling real mapped AlarmKit test alarms.

#### Scenario: Confirmation sheet summarizes mapped alarms
- **GIVEN** the tester requests Real AlarmKit Mapped Playback
- **WHEN** the confirmation sheet appears
- **THEN** it SHALL be titled `Schedule real test alarms?`
- **AND** it SHALL state that Subh will schedule real AlarmKit alarms using the selected sound and that Wake Checks remain five minutes apart
- **AND** it SHALL show selected simulated date, location, scenario, sequence length, mapped real alarm fire times, simulated event times, sound role or asset when available, and a note that `Cancel All Test Alarms` is available
- **AND** real alarms SHALL NOT be scheduled until the tester confirms `Schedule Test Alarms`

#### Scenario: Automated tests do not ring real alarms
- **GIVEN** automated unit or integration tests exercise mapped playback
- **WHEN** the tests build mapping plans or verify guarded scheduling paths
- **THEN** they SHALL NOT schedule platform AlarmKit alarms unless an explicit safe manual/device mode is enabled

### Requirement: Mapped playback follows Wake Session confirmation semantics
The system SHALL keep mapped playback behavior aligned with core Wake Session semantics.

#### Scenario: Stopping mapped alarm does not confirm awake
- **GIVEN** a mapped primary alarm fires
- **WHEN** the user stops or dismisses the system alarm
- **THEN** the test Wake Session SHALL remain unconfirmed
- **AND** pending mapped Wake Checks SHALL remain scheduled unless the user confirms awake, confirms Quiet, exits test mode, or cancels all test alarms

#### Scenario: Confirming awake cancels mapped checks
- **GIVEN** mapped Wake Checks remain pending
- **WHEN** the tester taps `I'm awake for Fajr` or `I'm awake for Suhoor` in Subh
- **THEN** the harness SHALL mark the test Wake Session confirmed for the selected mode
- **AND** it SHALL cancel remaining mapped test alarms
- **AND** it SHALL write only test-scoped MorningLog records
- **AND** Fajr prayer, fasting intent, and fast completion SHALL remain separate according to the mode-specific Wake Session rules

### Requirement: Fake scheduler records simulation and mapped playback
The system SHALL provide a fake scheduler adapter for non-platform tests and dry runs that records deterministic scheduled, fired, cancelled, failed, and pending test alarm state without replacing production AlarmKit scheduling.

#### Scenario: Fake scheduler records mapped fields
- **GIVEN** a fake scheduler playback or mapped playback dry run
- **WHEN** the harness schedules primary and Wake Check events
- **THEN** the fake scheduler SHALL record alarm identifier, role, mode, simulated fire date, mapped real fire date when relevant, channel, status, cancellation time, failure reason, and `isTest`
- **AND** remaining pending test alarms SHALL be available to the pending alarm inspector

#### Scenario: Reschedule cancels stale test IDs
- **GIVEN** a test Wake Session has pending primary and Wake Check identifiers
- **WHEN** the simulated wake time is adjusted
- **THEN** the harness SHALL cancel stale test identifiers, schedule the latest eligible identifiers, and leave no duplicate pending Wake Checks for the same test session

### Requirement: Inspectors and safety controls isolate test data
The system SHALL provide debug/internal MorningLog and pending alarm inspectors plus safety controls that operate only on test-scoped data.

#### Scenario: MorningLog inspector shows factual test records
- **GIVEN** test Wake Session records exist
- **WHEN** the tester opens the MorningLog inspector
- **THEN** it SHALL show WakeSessionID, scenario, mode, status, simulated date/time, mapped real primary alarm, mapped real Wake Checks, confirmed awake status, Fajr prayer status, fasting intent status, event list, and `isTest`
- **AND** it SHALL NOT create automatic `fajrMissed`, `fastMissed`, or `fastCompletionConfirmed` records

#### Scenario: Pending alarm inspector manages test alarms
- **GIVEN** test alarms exist
- **WHEN** the tester opens the pending alarm inspector
- **THEN** it SHALL show identifier, role, mode, simulated fire date, mapped real fire date, channel, status, and `isTest`
- **AND** the tester SHALL be able to refresh pending test alarms, cancel a selected test alarm, and cancel all test alarms
- **AND** production pending alarms SHALL be clearly distinguished from test pending alarms

#### Scenario: Exit Test Mode clears only test state
- **GIVEN** a simulation context, test Wake Sessions, test MorningLogs, and test alarms exist
- **WHEN** the tester chooses `Exit Test Mode`
- **THEN** the system SHALL cancel mapped real AlarmKit test alarms, cancel fake or notification test alarms, clear active simulation context, restore real Home, preserve real user settings and logs, and never copy test confirmations into real worship history

### Requirement: Permission and failure simulation stays separate from Quiet
The system SHALL allow fake/integration simulation of delivery and permission failures without changing real iOS permission settings or rewriting wake intent.

#### Scenario: Permission failure is simulated
- **GIVEN** the tester selects a simulated permission failure such as AlarmKit denied, AlarmKit unavailable, notification denied, degraded fallback, schedule failure, missing pending alarm, mismatched fire date, duplicate identifier, or sound asset missing
- **WHEN** the simulation runs
- **THEN** the harness SHALL record a delivery or permission failure state for test inspection
- **AND** the Fajr or Suhoor wake intent SHALL remain active
- **AND** the state SHALL NOT become Quiet or missed prayer

#### Scenario: Quiet during active checks remains intentional
- **GIVEN** a test Wake Session has active or pending Wake Checks
- **WHEN** the tester selects Quiet
- **THEN** the app SHALL show the active-session confirmation sheet
- **AND** choosing `Keep wake checks` SHALL leave checks pending
- **AND** choosing `Stop for this morning` SHALL cancel pending test checks, log `quietMorning`, and NOT log missed Fajr
