# single-screen-morning-home Specification

## Purpose
Define the primary post-onboarding Subh home: one focused surface that answers what tomorrow morning requires, keeps Fajrcast and Morningcast as supporting context, and avoids returning to tab-first legacy information architecture.
## Requirements
### Requirement: Single primary home surface
The system SHALL use a single Subh home surface as the primary post-onboarding experience.

#### Scenario: User completes onboarding
- **GIVEN** the user has completed onboarding
- **WHEN** the app launches
- **THEN** the user SHALL land in one `NavigationStack`-based Subh home surface
- **AND** the app SHALL NOT present Wake, Plans, Progress, or fasting as bottom-tab primary areas

### Requirement: MVP home cards
The first-wave Subh home SHALL contain the MVP cards: Tomorrow Morning, Weekly Fajrcast, and a 10-item Morningcast list.

#### Scenario: Home snapshot is available
- **GIVEN** the app has resolved schedule data
- **WHEN** the Subh home renders
- **THEN** it SHALL show a Tomorrow Morning hero
- **AND** it SHALL show the Weekly Fajrcast
- **AND** it SHALL show the next 10 Morningcast items

### Requirement: Cards navigate to details
The system SHALL allow the user to open detail surfaces from home cards while keeping settings available from the top bar.

#### Scenario: User taps a home card
- **GIVEN** the Subh home is visible
- **WHEN** the user taps Tomorrow Morning, Weekly Fajrcast, or a Morningcast item
- **THEN** the app SHALL navigate to a relevant detail screen
- **AND** settings SHALL remain reachable from the home toolbar

### Requirement: Legacy surfaces are not primary IA
The system SHALL remove Plans, Progress, and Wake from primary tab navigation while allowing retained legacy surfaces to remain reachable only through contextual details or settings where still needed.

#### Scenario: User scans primary navigation
- **GIVEN** the app is in the first-wave Subh home experience
- **WHEN** the user looks for primary navigation
- **THEN** the app SHALL NOT show a bottom tab bar with Wake, Plans, and Progress as product areas
