## ADDED Requirements

### Requirement: Compact Fajrcast callout identifies the immediate selected morning
The compact Weekly Fajrcast home card SHALL use the selected overlay callout to identify immediate selected mornings with relative labels, while preserving weekday initials on the chart axis.

#### Scenario: Tomorrow is selected in the compact Fajrcast
- **GIVEN** tomorrow exists in the compact Weekly Fajrcast window
- **WHEN** the compact Weekly Fajrcast snapshot is built with tomorrow selected
- **THEN** the selected overlay callout label SHALL be `TOMORROW`
- **AND** the chart x-axis SHALL continue to use weekday initials for the seven plotted mornings

#### Scenario: Today is selected in the compact Fajrcast
- **GIVEN** today exists in the compact Weekly Fajrcast window
- **WHEN** the compact Weekly Fajrcast snapshot is built with today selected
- **THEN** the selected overlay callout label SHALL be `TODAY`
