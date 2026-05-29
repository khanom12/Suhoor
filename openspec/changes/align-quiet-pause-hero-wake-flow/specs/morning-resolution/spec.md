## ADDED Requirements

### Requirement: Resolved morning separates purpose, override, policy, alarm state, and execution
The morning resolver SHALL keep wake purpose, purpose-specific alarm configuration, date alarm override, global pause policy, resolved alarm state, and wake execution state as distinct layers.

#### Scenario: Active Fajr resolves from separate layers
- **GIVEN** a target morning has wake purpose Fajr
- **AND** date alarm override is none
- **AND** global wake-alarm policy is active
- **WHEN** the morning is resolved
- **THEN** the selected wake purpose SHALL be Fajr
- **AND** the resolved alarm state SHALL be active unless setup, permission, delivery, or unavailable states apply
- **AND** the Fajr alarm configuration SHALL be used without deleting the Suhoor alarm configuration

#### Scenario: Active Suhoor resolves from separate layers
- **GIVEN** a target morning has wake purpose Suhoor
- **AND** date alarm override is none
- **AND** global wake-alarm policy is active
- **WHEN** the morning is resolved
- **THEN** the selected wake purpose SHALL be Suhoor
- **AND** the Suhoor alarm configuration SHALL be used without deleting the Fajr alarm configuration

#### Scenario: Setup and issue states do not become Quiet
- **GIVEN** a target morning has missing location, missing prayer times, permission denial, blocked alarm setup, or a delivery issue
- **WHEN** the morning is resolved
- **THEN** the resolved alarm state SHALL expose setup, blocked, issue, or unavailable state as appropriate
- **AND** it SHALL NOT record or display that condition as Quiet or Pause

### Requirement: Purpose switching preserves purpose-specific alarm memory
The system SHALL preserve separate Fajr and Suhoor alarm settings when users switch wake purpose or change alarm-state policy.

#### Scenario: Switching purpose while Quiet preserves both saved alarms
- **GIVEN** a target morning is Quiet
- **AND** it has a saved Fajr alarm at one offset and a saved Suhoor alarm at another offset
- **WHEN** the user switches the wake purpose between Fajr and Suhoor
- **THEN** the date SHALL remain Quiet
- **AND** the displayed saved alarm time SHALL update to the selected purpose's saved configuration
- **AND** the unselected purpose's saved configuration SHALL remain available when the user switches back

#### Scenario: Reset affects only selected purpose
- **GIVEN** a target morning has custom Fajr and Suhoor alarm configurations
- **WHEN** the user resets the alarm time for the currently selected purpose
- **THEN** only that selected purpose's alarm configuration SHALL reset unless the user explicitly chooses a broader reset-this-morning action

### Requirement: Resolved delivery state distinguishes quiet, paused, blocked, and failed
The resolver and downstream presentation models SHALL expose distinct resolved states for active, Quiet, inherited Pause, rings-once despite Pause, setup blocked, permission blocked, delivery issue, and unavailable morning data.

#### Scenario: Forecast consumes resolved alarm state
- **GIVEN** Next 7 Mornings, Month Planning, or Day Detail receives a resolved morning
- **WHEN** the row or screen displays the alarm state
- **THEN** it SHALL use the resolver-provided state rather than inferring Quiet or Pause from local UI flags

#### Scenario: Ring exception resolves active while Pause remains
- **GIVEN** global Pause is active
- **AND** the target date has a ring-despite-pause exception
- **WHEN** the morning is resolved
- **THEN** the resolved alarm state SHALL be rings-once despite Pause
- **AND** the saved global policy SHALL remain paused indefinitely

### Requirement: Fajr end hands Home to the next morning
The current Home morning target SHALL roll forward to the next relevant morning when the current morning's Fajr end boundary has passed.

#### Scenario: Completed current morning is historical after Fajr end
- **GIVEN** the current morning has awake, fasting, or Fajr prayer records
- **WHEN** Fajr end passes
- **THEN** Home SHALL resolve and display the next morning
- **AND** the completed records SHALL remain tied to the actual current morning in logs/history-capable storage
- **AND** Home SHALL NOT continue acting as a full-day tracker for the completed morning
