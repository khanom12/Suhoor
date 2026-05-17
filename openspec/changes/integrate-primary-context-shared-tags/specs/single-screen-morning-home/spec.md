## MODIFIED Requirements

### Requirement: MVP home cards
The first-wave Subh home SHALL contain the MVP cards and modules in this order: Tomorrow Morning Hero, Primary Morning Context when compact context is visible, Next 7 Days, and Weekly Fajrcast. The Next 7 Days forecast and Weekly Fajrcast SHALL use the same seven visible date keys in the same order.

#### Scenario: Home snapshot is available
- **GIVEN** the app has resolved schedule data
- **WHEN** the Subh home renders
- **THEN** it SHALL show a Tomorrow Morning hero
- **AND** it SHALL show compact Primary Morning Context after the hero when the resolved tomorrow context is meaningful, selected, Quiet, forbidden, Ramadan, or unavailable
- **AND** it SHALL show the Next 7 Days forecast card
- **AND** it SHALL show the Weekly Fajrcast

#### Scenario: Ordinary Home context is hidden
- **GIVEN** the resolved tomorrow morning is ordinary default Fajr
- **AND** there is no selected override, Quiet state, opportunity, forbidden state, Ramadan state, or unavailable context state
- **WHEN** the Subh home renders
- **THEN** the compact Primary Morning Context module SHALL be hidden
- **AND** the Hero SHALL remain the primary explanation of wake execution

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

## ADDED Requirements

### Requirement: Next 7 Days consumes shared tags
Next 7 Days SHALL consume shared day tag presentation derived from the resolved morning graph while preserving its row anatomy, lane measurement, no-wrap compact layout, collapsed/expanded behavior, and row routing.

#### Scenario: Opportunity-only row renders
- **GIVEN** a Next 7 Days row has a fasting opportunity
- **AND** the resolved intention is default Fajr
- **WHEN** row tags render
- **THEN** the row SHALL NOT show `Suhoor`
- **AND** it SHALL use shared tag presentation to show `Fajr` plus approved opportunity context where compact density allows

#### Scenario: Selected Suhoor row renders
- **GIVEN** a Next 7 Days row has selected Suhoor
- **WHEN** row tags render
- **THEN** the row SHALL show `Suhoor` as the wake-mode tag
- **AND** it SHALL show selected purpose or opportunity tags from the shared tag snapshot
- **AND** it SHALL NOT show legacy `Fasting` as the top-level wake-mode tag

#### Scenario: Quiet row renders
- **GIVEN** a Next 7 Days row has Quiet selected
- **WHEN** row tags render
- **THEN** the compact visible tag SHALL be `Quiet`
- **AND** row accessibility SHALL preserve underlying meaningful tags when they exist
