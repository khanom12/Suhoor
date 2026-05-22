## MODIFIED Requirements

### Requirement: MVP home cards
The first-wave Subh home SHALL contain a Tomorrow Morning hero, primary context where meaningful, a Plan ahead section with Next 7 Mornings and Month Planning entry tiles, and Weekly Fajrcast.

#### Scenario: Home snapshot is available
- **GIVEN** the app has resolved schedule data
- **WHEN** the Subh home renders
- **THEN** it SHALL show a Tomorrow Morning hero
- **AND** it SHALL show the primary morning context card when the context presenter says it is visible
- **AND** it SHALL show a high-contrast `Plan ahead` section
- **AND** the Plan ahead section SHALL show `NEXT 7 MORNINGS` above `Calendar Months` and `Hijri Months`
- **AND** it SHALL show the Weekly Fajrcast below Plan ahead

#### Scenario: Forecast visibility does not schedule alarms
- **GIVEN** a date appears in Next 7 Mornings, Month Planning, or Weekly Fajrcast
- **WHEN** the Home support surfaces render
- **THEN** the app SHALL NOT schedule, cancel, or mutate alarms merely because the date is visible
- **AND** delivery SHALL remain limited to resolver-materialized events in the active scheduled horizon
