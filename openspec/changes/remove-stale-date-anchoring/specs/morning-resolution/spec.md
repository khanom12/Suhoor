## ADDED Requirements

### Requirement: Daily activation is the current-product default
The system SHALL initialize missing current-product morning-plan state as daily active, even when legacy Suhoor settings or alarm configuration are present.

#### Scenario: Legacy settings without morning-plan state
- **GIVEN** persisted legacy settings exist
- **AND** no `MorningPlanState` has been persisted
- **WHEN** the morning-plan store initializes
- **THEN** activation mode SHALL be `dailyActive`
- **AND** active-window resolution SHALL start from the current local day instead of the next sparse legacy or implicit Ramadan date.

#### Scenario: Persisted legacy compatibility state
- **GIVEN** persisted `MorningPlanState` uses `legacyCompat`
- **WHEN** the morning-plan store initializes
- **THEN** it SHALL migrate the state to `dailyActive`
- **AND** persist the migrated activation mode.

### Requirement: Active morning window starts from current reality
The system SHALL resolve the active daily morning window from the current local date in the selected timezone unless an explicit test clock is supplied.

#### Scenario: Current date after prior Ramadan
- **GIVEN** the current local date is after Ramadan 1447
- **AND** the next implicit Ramadan starts on February 8, 2027
- **WHEN** the app resolves the active morning window
- **THEN** the first visible days SHALL include the current local day and tomorrow
- **AND** February 8, 2027 SHALL NOT appear as today or tomorrow unless it is actually within the current window.
