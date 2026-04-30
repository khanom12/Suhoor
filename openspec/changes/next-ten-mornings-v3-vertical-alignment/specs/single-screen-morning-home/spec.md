## MODIFIED Requirements

### Requirement: MVP home cards
The first-wave Subh home SHALL contain the MVP cards: Tomorrow Morning, Weekly Fajrcast, and a Next 10 Mornings wake forecast.

#### Scenario: Forecast rows use a shared measured middle lane
- **GIVEN** the Next 10 Mornings card renders multiple future mornings with different date-label widths, tag counts, and trailing wake-time widths
- **WHEN** the rows are laid out
- **THEN** all rows SHALL use the same measured date lane, centered tag lane, and trailing time/status lane
- **AND** the tag lane SHALL sit between the shared date lane and shared trailing lane with consistent minimum gaps
- **AND** tag clusters SHALL be centered inside that shared middle lane
- **AND** shorter or longer date labels SHALL NOT create row-specific tag drift

#### Scenario: Forecast row content is vertically centered
- **GIVEN** a Next 10 Mornings forecast row is visible between horizontal dividers
- **WHEN** the row renders
- **THEN** the date label, tag cluster, and wake time/status lockup SHALL share the same row center
- **AND** the row SHALL NOT use first-baseline alignment for the outer date/tag/time layout
- **AND** vertical padding SHALL remain symmetric around the row center

#### Scenario: Forecast tags use compact fit metrics
- **GIVEN** an opportunity-only row should show `[Fajr] [White Days]`
- **WHEN** the row renders at standard supported iPhone widths and standard dynamic type
- **THEN** both tags SHOULD fit before the row reduces visible tags
- **AND** the compact forecast chips SHALL use tighter padding and inter-tag spacing than larger general-purpose chips
