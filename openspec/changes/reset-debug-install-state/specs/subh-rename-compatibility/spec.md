# subh-rename-compatibility Delta

## Modified Requirements

### Requirement: Legacy persistence remains readable
The system SHALL continue reading documented legacy persistence keys needed for compatibility.

#### Scenario: Existing install has legacy storage
- **GIVEN** a user has existing persisted settings in a `Suhoor.*` storage namespace
- **WHEN** the renamed Subh app launches in normal release behavior
- **THEN** the app SHALL read or migrate the existing data according to the active migration rules
- **AND** it SHALL NOT delete or reset it solely because the visible product name changed

#### Scenario: Developer installs a new debug build over an old test build
- **GIVEN** a DEBUG build is installed over a previous developer build on a test device
- **WHEN** the installed app binary fingerprint changes
- **THEN** Subh MAY clear local persisted developer state before stores initialize
- **AND** this reset SHALL NOT apply to release behavior

