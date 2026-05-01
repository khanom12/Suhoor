## MODIFIED Requirements

### Requirement: MVP home cards
The first-wave Subh home SHALL contain the MVP cards in this order: Tomorrow Morning, Next 10 Mornings, then Weekly Fajrcast.

#### Scenario: Home snapshot is available
- **GIVEN** the app has resolved schedule data
- **WHEN** the Subh home renders
- **THEN** it SHALL show a Tomorrow Morning hero first
- **AND** it SHALL show the Next 10 Mornings card below the hero
- **AND** it SHALL show the Weekly Fajrcast below the Next 10 Mornings card
- **AND** the cards SHALL preserve their existing data, styling, navigation, and interaction behavior
