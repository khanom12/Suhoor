## MODIFIED Requirements

### Requirement: Legacy surfaces are not primary IA
The system SHALL remove Plans, Progress, Wake, fasting planning, and Qada planning from primary navigation and production MVP entry points.

#### Scenario: User scans primary navigation
- **GIVEN** the app is in the first-wave Subh home experience
- **WHEN** the user looks for primary navigation
- **THEN** the app SHALL NOT show a bottom tab bar with Wake, Plans, Progress, fasting, or Qada as product areas
- **AND** the app SHALL NOT expose retired product areas through first-level home buttons, legacy notifications, or onboarding completion routes

### Requirement: MVP home cards
The first-wave Subh home SHALL contain the MVP cards: Tomorrow Morning, Weekly Fajrcast, and a 10-item Morningcast list.

#### Scenario: Home snapshot is available
- **GIVEN** the app has resolved schedule data
- **WHEN** the Subh home renders
- **THEN** it SHALL show a Tomorrow Morning hero
- **AND** it SHALL show the Weekly Fajrcast
- **AND** it SHALL show the next 10 Morningcast items
- **AND** those cards SHALL be derived from the same cached or published home snapshot
