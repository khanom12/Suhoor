## ADDED Requirements

### Requirement: Home presentation uses scheduling current date
The Home surface SHALL use the same current-date source as scheduling when choosing the hero morning, weekly Fajrcast anchor, morningcast entries, and relative day labels.

#### Scenario: Home renders after onboarding
- **GIVEN** onboarding has just completed
- **AND** location and scheduling permissions are resolved enough to build a schedule
- **WHEN** Home first appears
- **THEN** the hero and Fajrcast SHALL describe the current or next real local morning
- **AND** stale cached future Ramadan dates SHALL NOT be presented as today, tomorrow, or the selected weekly anchor.

#### Scenario: Fixed-time UI test renders Home
- **GIVEN** a DEBUG UI test provides a fixed current date
- **WHEN** Home builds hero, weekly Fajrcast, and morningcast presentation
- **THEN** all relative day labels SHALL be computed from the fixed date
- **AND** the labels SHALL match the schedule window built from that same fixed date.
