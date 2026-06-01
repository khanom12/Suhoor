## MODIFIED Requirements

### Requirement: Completion and logging states are explicit
The morning resolution layer SHALL distinguish explicit completed, explicit not completed, unrecorded, and expired unresolved states for Fajr prayer and fast completion prompts.

#### Scenario: Late Fajr yes logs prayed
- **GIVEN** a late Fajr prompt is eligible
- **WHEN** the user taps the check control
- **THEN** the relevant Fajr prayer record SHALL be marked explicitly prayed
- **AND** any future Qada Fajr relevance for that date SHALL be cleared when correction is allowed

#### Scenario: Late Fajr no logs not prayed
- **GIVEN** a late Fajr prompt is eligible
- **WHEN** the user taps the X control
- **THEN** the relevant Fajr prayer record SHALL be marked explicitly not prayed
- **AND** future Qada Fajr relevance SHALL be created for that date

#### Scenario: Late Fajr silence remains unrecorded
- **GIVEN** a late Fajr prompt is eligible
- **WHEN** the user does not respond
- **THEN** the system SHALL keep the record unrecorded until expiry
- **AND** it SHALL NOT infer not prayed from silence

#### Scenario: Late Fajr expiry does not create Qada
- **GIVEN** a late Fajr prompt expires without response
- **WHEN** resolution runs after expiry
- **THEN** the prompt SHALL be marked expired unresolved where stored
- **AND** future Qada Fajr relevance SHALL NOT be created

#### Scenario: Fast completion yes logs completed
- **GIVEN** a fast completion prompt is eligible
- **WHEN** the user taps the check control
- **THEN** the relevant fast record SHALL be marked explicitly completed

#### Scenario: Fast completion no logs not completed
- **GIVEN** a fast completion prompt is eligible
- **WHEN** the user taps the X control
- **THEN** the relevant fast record SHALL be marked explicitly not completed
- **AND** Ramadan fast no SHALL create future Qada fast relevance
- **AND** optional fast no SHALL support statistics/encouragement but SHALL NOT create the same Qada fast requirement

#### Scenario: Fast completion silence remains unrecorded
- **GIVEN** a fast completion prompt is eligible
- **WHEN** the user does not respond
- **THEN** the system SHALL keep the fast record unrecorded until expiry
- **AND** it SHALL NOT infer not completed from silence

#### Scenario: Fast completion expiry does not create Qada
- **GIVEN** a fast completion prompt expires without response
- **WHEN** resolution runs after expiry
- **THEN** the prompt SHALL be marked expired unresolved where stored
- **AND** future Qada fast relevance SHALL NOT be created

### Requirement: Fast completion prompt eligibility follows June 1 rules
The morning resolution layer SHALL expose fast completion prompts after Maghrib only when a fast was selected for that morning or the date is a Ramadan day.

#### Scenario: Selected Suhoor morning shows fast completion prompt
- **GIVEN** Suhoor was selected for the morning
- **WHEN** Maghrib has passed and fast completion is unresolved
- **THEN** a fast completion prompt SHALL be eligible

#### Scenario: Ramadan day shows fast completion prompt
- **GIVEN** the date is a Ramadan day
- **WHEN** Maghrib has passed and fast completion is unresolved
- **THEN** a fast completion prompt SHALL be eligible even if Suhoor was not selected

#### Scenario: Optional opportunity without selection does not show prompt
- **GIVEN** the date has only an optional fasting opportunity
- **AND** Suhoor or a fast was not selected for that morning
- **WHEN** Maghrib has passed
- **THEN** a fast completion prompt SHALL NOT be eligible merely because the opportunity existed
