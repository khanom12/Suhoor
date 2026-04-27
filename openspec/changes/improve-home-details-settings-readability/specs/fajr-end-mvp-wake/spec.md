# fajr-end-mvp-wake Delta

## Modified Requirements

### Requirement: Fajr end trust language is transparent
The system SHALL avoid overstating the precision or authority of the supported Fajr end boundary.

#### Scenario: Supported boundary is sunrise-derived
- **GIVEN** the current provider uses a sunrise-derived boundary for supported Fajr end
- **WHEN** the user sees wake explanation copy
- **THEN** the system SHALL describe the boundary as supported, configured, or provider-derived
- **AND** the system SHALL NOT imply a hidden religious ruling beyond the configured calculation method
- **AND** the system SHALL prefer human copy such as “based on sunrise for this date” over internal terms such as “supported end marker”

#### Scenario: User opens a day whose wake is based on supported Fajr end
- **GIVEN** a resolved morning has Fajr start, wake time, supported Fajr end, and a wake buffer
- **WHEN** the user opens the daily detail surface
- **THEN** the system SHALL show Fajr start, wake time, supported Fajr end, and the wake rule as separate readable items
- **AND** the system SHALL NOT show only Fajr start beneath the wake time in a way that makes the wake appear incorrectly late

### Requirement: Wake delivery state is visible
The system SHALL expose wake delivery reliability on user-facing morning surfaces.

#### Scenario: User opens a resolved daily detail
- **GIVEN** the app has a current scheduling mode
- **WHEN** the daily detail surface renders
- **THEN** it SHALL show whether wake delivery is using AlarmKit, notification fallback, or is not ready
- **AND** notification fallback copy SHALL make clear that wake delivery may be affected by notification settings, Focus, or Silent Mode
