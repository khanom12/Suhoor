## MODIFIED Requirements

### Requirement: MVP home cards
The first-wave Subh home SHALL contain the MVP cards: Tomorrow Morning, Weekly Fajrcast, and a Next 10 Mornings wake forecast.

#### Scenario: Forecast rows use a shared centered three-lane grid
- **GIVEN** the Next 10 Mornings card renders multiple future mornings with different date-label widths, tag counts, and trailing wake-time widths
- **WHEN** the rows are laid out
- **THEN** all rows SHALL use the same balanced leading date lane, centered tag lane, and trailing time/status lane
- **AND** the leading date lane and trailing time/status lane SHALL reserve equal outer widths for a resolved snapshot
- **AND** date labels SHALL be leading-aligned inside the shared leading lane
- **AND** tag clusters SHALL be centered inside the shared tag lane
- **AND** trailing wake times or statuses SHALL be trailing-aligned inside the shared trailing lane
- **AND** shorter or longer date labels SHALL NOT create row-specific tag drift

#### Scenario: Forecast opportunity tags use resolved context
- **GIVEN** a future morning has no intended fast, no Ramadan state, no Tahajjud intention, and no quiet-mode override
- **AND** either the date-derived opportunity input or the resolved day context identifies a compatible opportunity such as White Days
- **WHEN** the Next 10 Mornings presentation prepares the row
- **THEN** it SHALL show `[Fajr]` with the compatible opportunity tag
- **AND** it SHALL continue to suppress Monday/Thursday as an opportunity-only tag
- **AND** it SHALL continue to apply completion-aware Shawwal 6 suppression
