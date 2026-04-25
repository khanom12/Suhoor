## ADDED Requirements

### Requirement: MVP runtime path excludes retired product domains
The system SHALL limit production runtime entry points to the Subh MVP surfaces: onboarding, single home, Tomorrow Morning detail, Weekly Fajrcast, 10-day Morningcast, settings, reliability, prayer/Hijri configuration, and alarm scheduling.

#### Scenario: Completed user launches the app
- **GIVEN** onboarding is complete
- **WHEN** the app root renders
- **THEN** the user SHALL enter the single Subh home
- **AND** the app SHALL NOT construct or present a bottom tab shell for Wake, Plans, Progress, fasting, or Qada product areas

#### Scenario: Legacy navigation intent is emitted
- **GIVEN** retained code or a notification attempts to open a retired Plans, Progress, Wake-list, fasting, or Qada surface
- **WHEN** the production app handles that intent
- **THEN** it SHALL avoid opening the retired surface
- **AND** it MAY route to Subh home or settings when an action is still meaningful

### Requirement: Legacy domain data is dormant, not deleted
The system SHALL preserve existing local data for retired fasting, planning, Qada, and progress domains while preventing that data from participating in the MVP runtime path.

#### Scenario: Existing install contains old domain data
- **GIVEN** local storage contains legacy fasting, planning, Qada, progress, or `Suhoor.*` values
- **WHEN** Subh launches after the performance prune
- **THEN** the app SHALL NOT delete that data solely because the domain is no longer part of the MVP
- **AND** the MVP home and scheduler SHALL NOT require those dormant stores to resolve mornings

### Requirement: Launch refreshes are coalesced
The system SHALL avoid redundant full schedule refreshes during normal launch and foreground activation.

#### Scenario: App launches to the completed-user home
- **GIVEN** the app root and home view appear during the same launch
- **WHEN** app launch, scene activation, and view appearance events fire close together
- **THEN** the scheduler SHALL perform at most one necessary full refresh for the same input signature
- **AND** repeated requests SHALL be coalesced, skipped, or satisfied from valid cached state

### Requirement: Performance traces cover MVP work
The system SHALL expose lightweight DEBUG or test-visible traces for expensive MVP operations without changing release behavior.

#### Scenario: Engineer runs focused performance tests
- **GIVEN** deterministic location, calendar, timezone, and settings inputs
- **WHEN** schedule refresh and home snapshot tests run
- **THEN** traces or metrics SHALL identify refresh, active-window build, home snapshot build, Fajrcast snapshot build, and alarm reconciliation work
- **AND** tests SHALL use relative guardrails or structural assertions rather than brittle wall-clock simulator budgets
