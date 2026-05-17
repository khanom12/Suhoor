## MODIFIED Requirements

### Requirement: MVP home cards
The first-wave Subh home SHALL contain the MVP cards: Tomorrow Morning, Next 7 Days, and Weekly Fajrcast. The Next 7 Days forecast and Weekly Fajrcast SHALL use the same seven visible date keys in the same order.

#### Scenario: Home snapshot is available
- **GIVEN** the app has resolved schedule data
- **WHEN** the Subh home renders
- **THEN** it SHALL show a Tomorrow Morning hero
- **AND** it SHALL show the Next 7 Days forecast card
- **AND** it SHALL show the Weekly Fajrcast

#### Scenario: Next 7 Days expands
- **GIVEN** the Next 7 Days forecast card is ready
- **WHEN** the user expands it
- **THEN** it SHALL show exactly seven resolved rows
- **AND** the first row SHALL represent the next immediate alarm or next relevant morning
- **AND** the remaining rows SHALL represent the six following calendar mornings

#### Scenario: Weekly Fajrcast aligns with Next 7 Days
- **GIVEN** the Home snapshot includes a Next 7 Days forecast and Weekly Fajrcast
- **WHEN** the app resolves their visible date keys
- **THEN** Weekly Fajrcast visible date keys SHALL equal the Next 7 Days row date keys exactly and in the same order
- **AND** neither surface SHALL include previous mornings in the aligned MVP behavior

#### Scenario: Forecast visibility does not schedule alarms
- **GIVEN** a date appears in Next 7 Days or Weekly Fajrcast
- **WHEN** the Home support surfaces render
- **THEN** the app SHALL NOT schedule, cancel, or mutate alarms merely because the date is visible
- **AND** delivery SHALL remain limited to resolver-materialized events in the active scheduled horizon
