## ADDED Requirements

### Requirement: Completed onboarding launches without bottom tabs
The system SHALL launch completed users into the Subh home without presenting the legacy bottom tab shell.

#### Scenario: App launches after onboarding
- **GIVEN** onboarding is complete
- **WHEN** `ContentView` renders the app root
- **THEN** the primary view SHALL be `SubhHomeView`
- **AND** the legacy bottom tab bar SHALL NOT be visible

### Requirement: Legacy feature code remains non-primary
The system SHALL keep retained legacy Wake, Plans, and Progress surfaces outside the primary information architecture.

#### Scenario: Legacy surfaces remain compiled
- **GIVEN** retained legacy surfaces still exist in the codebase
- **WHEN** the user is on the primary Subh home
- **THEN** those surfaces SHALL NOT appear as top-level tabs
- **AND** they MAY be reached only through contextual details or settings paths
