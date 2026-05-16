## MODIFIED Requirements

### Requirement: Home hero exposes Suhoor, Fajr, and Quiet
The primary Home hero SHALL expose the MVP quick wake modes as `Suhoor`, `Fajr`, and `Quiet`.

#### Scenario: User scans the Home hero quick selector
- **GIVEN** the Subh home is visible
- **WHEN** the user scans the quick wake selector
- **THEN** the selector SHALL offer Suhoor, Fajr, and Quiet
- **AND** it SHALL NOT offer Tahajjud-only, other early worship, `Fast`, `Early`, or `Pre-Fajr` as active MVP choices

### Requirement: Alarm Detail saves MVP wake changes immediately
The selected-day detail surface SHALL persist MVP wake mode and reset changes immediately.

#### Scenario: User changes the selected day to Suhoor
- **GIVEN** the selected-day detail view is open
- **WHEN** the user selects Suhoor
- **THEN** the date-specific wake state SHALL save immediately
- **AND** the detail view SHALL present the morning as a Suhoor intention

#### Scenario: User resets the selected day
- **GIVEN** the selected-day detail view has a date-specific override
- **WHEN** the user taps reset to default
- **THEN** the override SHALL reset immediately
- **AND** the detail view SHALL not require a separate Done action to commit the reset

### Requirement: Supporting forecast surfaces use Suhoor vocabulary
The Fajr Window, Next 10, Weekly Fajrcast, and related supporting surfaces SHALL use Suhoor vocabulary for MVP before-Fajr wake behavior.

#### Scenario: A supporting surface describes a before-Fajr wake
- **GIVEN** a forecast or detail surface displays a before-Fajr wake state
- **WHEN** the state is part of the MVP wake-mode model
- **THEN** the surface SHALL describe it as Suhoor
- **AND** it SHALL avoid historical labels that imply a separate Tahajjud or other early-worship mode
