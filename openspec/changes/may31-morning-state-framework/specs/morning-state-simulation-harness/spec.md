## ADDED Requirements

### Requirement: May 31 scenario pack
The testing harness SHALL include a May 31 Morning State Framework scenario pack that allows a tester to validate Home, context, Next 7, wake attempts, logs, and scheduled event previews without waiting for real mornings.

#### Scenario: Scenario pack has boundary presets
- **GIVEN** the tester opens the May 31 scenario pack
- **WHEN** the scenario controls render
- **THEN** the harness SHALL expose presets for daytime, evening, before midnight, midnight, before Suhoor window, Suhoor window start, Suhoor cutoff, Fajr begins, Fajr active window, default wake time, final check, Fajr end, and after Fajr

#### Scenario: Scenario uses calculated times
- **GIVEN** the scenario has valid prayer-time data and location
- **WHEN** expected and actual previews render
- **THEN** the harness SHALL show calculated Fajr begins, Fajr ends, Suhoor window start, latest wake time, latest new-session time, and generated attempts
- **AND** standard scenarios SHALL NOT show `No time available`

#### Scenario: Scenario supports 24-hour scrubbing
- **GIVEN** a start date/time and location are selected
- **WHEN** the tester uses the scenario scrubber
- **THEN** the harness SHALL allow minute-by-minute movement through the next 24 hours
- **AND** it SHOULD support 48 hours where current data is available

### Requirement: Simulation drives real presentation surfaces
The testing harness SHALL feed simulated time and resolved state into the same Home Hero, context card, and Next 7 presentation path used by normal app surfaces.

#### Scenario: Home uses simulated time
- **GIVEN** simulation time is active
- **WHEN** Home renders
- **THEN** the Hero, context card, late prompt, and Next 7 rows SHALL use the simulated clock and scenario state
- **AND** the harness SHALL visibly indicate that simulation is active

#### Scenario: Branch actions mutate simulated state
- **GIVEN** simulation time is active
- **WHEN** the tester triggers branch actions such as Quiet confirmation, purpose switching, slider commits, `I’m awake`, `I’m Awake for Fajr`, `I Prayed Fajr`, late Fajr logging, or optional Fajr follow-up
- **THEN** the harness SHALL update the simulated resolved state and expected-vs-actual previews from that branch
- **AND** it SHALL NOT permanently mutate production settings or worship history

#### Scenario: Expected versus actual previews are inspectable
- **GIVEN** a scenario branch is selected
- **WHEN** the tester opens the preview
- **THEN** the harness SHALL show expected and actual Hero state, context card, late prompt, Next 7 row, wake attempts, logs, and scheduled AlarmKit or fake events

### Requirement: Harness protects readability and isolation
The testing harness SHALL remain readable, avoid clipped text in standard scenarios, and isolate test records from production data.

#### Scenario: Standard scenario text fits
- **GIVEN** a standard May 31 scenario is rendered on supported device sizes
- **WHEN** labels, cards, and previews appear
- **THEN** text SHALL NOT clip or run off screen in the harness UI

#### Scenario: Test records are namespaced
- **GIVEN** the harness creates simulated or real mapped test events
- **WHEN** identifiers and logs are written
- **THEN** they SHALL be clearly marked as test records
- **AND** they SHALL NOT collide with production wake-session identifiers

#### Scenario: Exiting simulation clears test state
- **GIVEN** simulation mode is active
- **WHEN** the tester exits or resets simulation
- **THEN** active simulated state SHALL be cleared
- **AND** production settings, real prayer history, and real fasting history SHALL remain unchanged
