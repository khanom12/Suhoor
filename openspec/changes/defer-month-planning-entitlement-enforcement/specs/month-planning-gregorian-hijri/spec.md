# month-planning-gregorian-hijri Specification

## ADDED Requirements

### Requirement: Development builds expose Month Planning for validation
Month Planning SHALL remain wired to the shared entitlement model while allowing full feature access in Debug/development builds for end-to-end validation.

#### Scenario: Debug build opens Month Planning without locked preview
- **GIVEN** the app is running in a Debug/development build
- **AND** no debug opt-out has disabled the development entitlement override
- **WHEN** the user taps `Calendar Months` or `Hijri Months`
- **THEN** the app SHALL open the corresponding Month Picker instead of the locked preview
- **AND** Month Detail SHALL be accessible from available picker rows
- **AND** row taps SHALL open the existing Day Detail screen
- **AND** Suhoor/Fasting controls SHALL be visible where the current resolver and domain model already support them

#### Scenario: Release build keeps production entitlement path
- **GIVEN** the app is running in a Release/production build
- **WHEN** Month Planning checks access
- **THEN** it SHALL use the real entitlement snapshot provided by the entitlement service
- **AND** it SHALL NOT permanently force all users to Complete
- **AND** pricing/tier concepts SHALL remain available for later production gating

#### Scenario: Debug locked-state testing remains possible
- **GIVEN** a developer disables the development entitlement override through the centralized debug entitlement provider
- **WHEN** a Free entitlement snapshot is effective
- **THEN** Month Planning SHALL show the locked/preview behavior
- **AND** the locked behavior SHALL be produced by the shared entitlement model rather than view-local tier logic
