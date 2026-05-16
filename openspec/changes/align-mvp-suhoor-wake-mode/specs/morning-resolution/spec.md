## MODIFIED Requirements

### Requirement: Date-specific wake mode selection
The shared morning-resolution model SHALL expose only `Suhoor`, `Fajr`, and `Quiet` as MVP user-selectable wake modes.

#### Scenario: User selects Suhoor for a morning
- **GIVEN** a selected morning has valid Fajr start and supported Fajr wake data
- **WHEN** the user selects `Suhoor`
- **THEN** the resolved morning SHALL wake before Fajr begins using the supported Suhoor boundary
- **AND** the selected quick wake mode SHALL be stored and presented as Suhoor
- **AND** the morning SHALL use the Suhoor fasting-intention path
- **AND** the system SHALL NOT expose Tahajjud-only or other early worship as MVP choices

#### Scenario: Suhoor has no specific fasting opportunity
- **GIVEN** a selected morning is eligible for Suhoor
- **AND** no specific Sunnah or calendar fasting opportunity is resolved for that date
- **WHEN** Suhoor is selected
- **THEN** the default fasting intention SHALL be voluntary fasting

#### Scenario: Suhoor has a resolved fasting opportunity
- **GIVEN** a selected morning has a resolved fasting opportunity
- **WHEN** Suhoor is selected
- **THEN** the default fasting intention SHALL use that opportunity
- **AND** supported fasting-intention overrides SHALL remain available where the day-purpose resolver permits them

#### Scenario: Legacy before-Fajr values are loaded
- **GIVEN** persisted data contains a legacy before-Fajr value such as `Fast`, `Pre-Fajr`, or `Early`
- **WHEN** the app decodes and resolves the selected morning
- **THEN** the active MVP state SHALL normalize that value to Suhoor-compatible behavior
- **AND** the active UI SHALL NOT revive the legacy label as a selectable mode

### Requirement: Quiet remains the only alarm-off mode
The shared wake-state model SHALL distinguish the selected wake mode from alarm activation, with Quiet as the only user-facing alarm-off mode.

#### Scenario: Fajr mode uses Fajr wake audio
- **GIVEN** `Fajr` mode is selected
- **WHEN** the selected audio is a Fajr wake sound
- **THEN** the wake alarm SHALL remain enabled
- **AND** the date SHALL NOT be treated as alarm-off

#### Scenario: Quiet mode is selected
- **GIVEN** the user selects `Quiet`
- **WHEN** the date-specific state is resolved
- **THEN** the wake alarm SHALL be suppressed for that date
- **AND** the system SHALL preserve enough underlying morning context to restore Fajr or Suhoor behavior when Quiet is cleared

### Requirement: Alarm delivery uses resolved morning events
The scheduling path SHALL hand off the resolved morning event fire dates without inventing a separate alarm schedule.

#### Scenario: Schedule extraction receives active events
- **GIVEN** the morning resolver produces active scheduled events for a selected day
- **WHEN** schedule extraction hands those events to the routine scheduler
- **THEN** the scheduled fire dates SHALL match the resolved event fire dates
- **AND** the result SHALL remain ordered or comparable without changing the semantic fire dates
