## ADDED Requirements

### Requirement: Home Fajrcast shows the next seven mornings
The compact Weekly Fajrcast on the Subh home SHALL show a rolling seven-day window beginning with tomorrow.

#### Scenario: User opens home after today's wake has passed
- **GIVEN** today is Sunday night and today's wake has already passed
- **WHEN** the home compact Fajrcast renders
- **THEN** its date range SHALL begin with tomorrow
- **AND** it SHALL NOT show the expired Monday-Sunday week that ended today

#### Scenario: Compact Fajrcast selection is built
- **GIVEN** tomorrow exists in the resolved active window
- **WHEN** the compact Fajrcast snapshot is built for home
- **THEN** tomorrow SHALL be the selected day

### Requirement: Ten-day wake forecast starts with tomorrow
The home forecast list SHALL be titled `10-Day Wake Forecast` and SHALL include tomorrow as the first row when tomorrow is resolved.

#### Scenario: Forecast entries are built
- **GIVEN** resolved schedule entries include today, tomorrow, and later mornings
- **WHEN** the home forecast entries are selected
- **THEN** today SHALL be excluded
- **AND** tomorrow SHALL be the first row
- **AND** the list SHALL contain no more than 10 rows

### Requirement: Home controls are non-redundant
The home screen SHALL avoid floating controls that duplicate primary card navigation.

#### Scenario: Fajrcast card is visible
- **GIVEN** the Weekly Fajrcast card is visible and tappable
- **WHEN** the home floating controls render
- **THEN** there SHALL NOT be a separate floating Fajrcast or calendar button
- **AND** settings SHALL remain available from a floating settings control
