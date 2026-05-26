## ADDED Requirements

### Requirement: Morning Hero includes a stable Wake Session Action Slot
The Home Hero SHALL reserve a stable action slot for wake-session state and current-morning check-ins so active-session controls do not cause vertical layout jumps.

#### Scenario: Normal planning state shows adjustment controls
- **GIVEN** the target morning is in normal planning state
- **WHEN** the Home Hero renders
- **THEN** the wake adjustment slider or equivalent visual control SHALL remain available
- **AND** the Wake Session Action Slot SHALL preserve the hero stack's vertical rhythm

#### Scenario: Active window before the primary alarm fires
- **GIVEN** the target morning is in the active wake window before the primary alarm has fired
- **WHEN** the Home Hero renders
- **THEN** wake adjustment controls SHALL remain available where the layout supports them
- **AND** the hero MAY show a compact already-awake affordance
- **AND** the hero stack SHALL NOT jump vertically when the affordance appears

#### Scenario: Primary alarm fired and unconfirmed
- **GIVEN** the primary alarm has fired and the Wake Session remains unconfirmed
- **WHEN** the Home Hero renders
- **THEN** the primary action SHALL be `I'm awake for Fajr` for Fajr mode or `I'm awake for Suhoor` for Suhoor mode
- **AND** supporting text MAY explain that wake checks continue until confirmation

#### Scenario: Awake confirmed
- **GIVEN** the user confirmed awake for the current morning
- **WHEN** the Home Hero renders
- **THEN** the action slot SHALL show a calm confirmation such as `Awake confirmed at {time}`
- **AND** it SHALL communicate that wake checks stopped for the morning where space permits

#### Scenario: Suhoor transitions to Fajr prayer
- **GIVEN** the user confirmed Suhoor awake before Fajr begins
- **WHEN** Fajr has begun and the current morning remains relevant
- **THEN** the primary current-morning action SHALL become `I prayed Fajr`
- **AND** Suhoor awake confirmation SHALL NOT be presented as Fajr prayer confirmation

#### Scenario: Suhoor unconfirmed after Fajr begins
- **GIVEN** the user did not confirm Suhoor awake before Fajr begins
- **WHEN** Fajr has begun and the current morning remains relevant
- **THEN** the hero SHALL prioritize `I'm awake for Fajr` before allowing Fajr prayer confirmation where required by the active product spec

#### Scenario: Quiet state suppresses awake confirmation
- **GIVEN** the current morning is Quiet
- **WHEN** the Home Hero renders
- **THEN** the action slot SHALL NOT show an awake-confirmation CTA for wake execution
- **AND** any future logging-only Quiet surface SHALL be distinct from re-enabling wake checks

### Requirement: Quiet selection confirms active-session cancellation
The Home Hero SHALL ask for explicit confirmation before cancelling pending wake-session events when the user switches an active morning to Quiet.

#### Scenario: Quiet selected with pending wake checks
- **GIVEN** the current morning has pending wake-session primary or wake-check events
- **WHEN** the user selects Quiet
- **THEN** the app SHALL show a confirmation dialog titled `Stop wake checks for this morning?`
- **AND** the dialog SHALL explain that Subh will cancel remaining alarms and mark the morning as quiet
- **AND** the dialog SHALL offer `Keep wake checks` and `Stop for this morning`

#### Scenario: User keeps wake checks
- **GIVEN** the Quiet cancellation dialog is visible
- **WHEN** the user chooses `Keep wake checks`
- **THEN** the existing Wake Session SHALL remain active
- **AND** pending wake-session events SHALL remain scheduled

#### Scenario: User stops for this morning
- **GIVEN** the Quiet cancellation dialog is visible
- **WHEN** the user chooses `Stop for this morning`
- **THEN** remaining wake-session events for the morning SHALL be cancelled
- **AND** the Wake Session SHALL record a Quiet Morning outcome
- **AND** the system SHALL NOT record Fajr missed
