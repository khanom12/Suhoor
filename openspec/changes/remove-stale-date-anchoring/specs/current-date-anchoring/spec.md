## ADDED Requirements

### Requirement: Current date source is explicit
The system SHALL resolve active morning windows, cache freshness, onboarding date previews, and Home date labels from the device clock unless DEBUG/UI-test configuration explicitly provides a fixed clock.

#### Scenario: Production app launch uses device time
- **GIVEN** the app is launched outside DEBUG/UI-test fixed-time configuration
- **WHEN** scheduling resolves the active morning window
- **THEN** the current date SHALL come from the device clock
- **AND** persisted cache SHALL NOT override the current local day.

#### Scenario: UI test uses fixed time
- **GIVEN** a DEBUG UI-test launch supplies a fixed current date argument
- **WHEN** scheduling and Home presentation resolve date-sensitive output
- **THEN** they SHALL use that fixed date consistently
- **AND** production builds SHALL NOT expose or honor that override.

### Requirement: Stale active-window cache is rejected
The system SHALL reuse cached active-window data only when it is fresh for the current local day and structurally matches the current daily morning model.

#### Scenario: Cache points to future Ramadan
- **GIVEN** the device date is outside Ramadan
- **AND** cached visible days begin at a future implicit Ramadan date
- **WHEN** the app launches or returns to foreground
- **THEN** the cache SHALL be rejected
- **AND** the active window SHALL be recomputed from the current local day when location and settings are available.

#### Scenario: Cache contains current daily window
- **GIVEN** cached visible days include the current local day and tomorrow
- **AND** the cache was generated and scheduled on the current local day
- **WHEN** the app launches or returns to foreground
- **THEN** the cache MAY be reused until a required refresh invalidates it.
