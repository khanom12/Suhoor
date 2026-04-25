# alarmkit-test-store-recovery Specification

## Purpose
Define how AlarmKit test-mode settings and diagnostic test-run state recover when persisted UserDefaults payloads are missing, valid, or invalid.

## Requirements
### Requirement: AlarmKit test settings recover from invalid persisted data
The system SHALL reset AlarmKit test settings to their default values when persisted settings data cannot be decoded.

#### Scenario: Missing settings data
- **WHEN** the AlarmKit test settings store loads and no persisted settings exist
- **THEN** the store exposes default AlarmKit test settings

#### Scenario: Valid settings data
- **WHEN** the AlarmKit test settings store loads valid persisted settings
- **THEN** the store exposes the persisted settings without changing them

#### Scenario: Invalid settings data
- **WHEN** the AlarmKit test settings store loads persisted data that cannot decode as AlarmKit test settings
- **THEN** the store exposes default AlarmKit test settings
- **AND** the persisted settings payload is replaced with default settings data

### Requirement: AlarmKit test-run state clears invalid persisted data
The system SHALL clear AlarmKit test-run state when persisted run data cannot be decoded.

#### Scenario: Missing test-run data
- **WHEN** the AlarmKit test-run store loads and no persisted run state exists
- **THEN** the store returns no test-run state

#### Scenario: Valid test-run data
- **WHEN** the AlarmKit test-run store loads valid persisted run state
- **THEN** the store returns the persisted run state

#### Scenario: Invalid test-run data
- **WHEN** the AlarmKit test-run store loads persisted data that cannot decode as AlarmKit test-run state
- **THEN** the store returns no test-run state
- **AND** the persisted run payload is removed
