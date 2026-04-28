# fajr-end-mvp-wake Delta

## Modified Requirements

### Requirement: Debug install reset must not silently disable morning reliability
The system SHALL avoid automatic debug install state clearing unless explicitly enabled, and SHALL emit diagnostics when scheduling appears healthy but deliverable alarms are missing.

#### Scenario: Debug install reset is disabled by default
- **GIVEN** a debug build with no explicit install-reset mode configured
- **WHEN** the app starts
- **THEN** persisted local state SHALL remain intact
- **AND** the startup timeline SHALL record that reset was skipped

#### Scenario: Alarm diagnostics detect empty deliverable pipeline
- **GIVEN** morning scheduling is enabled and future morning events exist in the visible window
- **WHEN** reconciliation finishes with no deliverable scheduled events
- **THEN** the system SHALL record a scheduling diagnostics warning
- **AND** it SHALL NOT silently treat the pipeline as healthy
