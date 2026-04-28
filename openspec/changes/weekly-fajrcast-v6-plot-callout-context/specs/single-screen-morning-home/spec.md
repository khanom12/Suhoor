## ADDED Requirements

### Requirement: Home Weekly Fajrcast uses v6 plotted scale height
The Home/Wake Weekly Fajrcast card SHALL use a compact plotted y-axis scale height of at least 144 pt across the seven standard text-size stops.

#### Scenario: Default stop uses v6 plot height
- **GIVEN** the Weekly Fajrcast card is rendered at the default text-size stop
- **WHEN** the compact chart is measured
- **THEN** the plotted y-axis scale height SHALL be at least 144 pt
- **AND** the plot height reduction SHALL NOT be taken from top callout breathing space, x-axis breathing space, or footer padding

#### Scenario: Standard stops keep stable plotted scale
- **GIVEN** the Weekly Fajrcast card is rendered from xSmall through xxxLarge text-size stops
- **WHEN** the compact chart is measured
- **THEN** the plotted y-axis scale height SHALL remain at least 144 pt
- **AND** it SHALL remain visually stable across those standard stops

### Requirement: Home Weekly Fajrcast balances focused callout spacing
The Weekly Fajrcast compact chart SHALL reserve balanced breathing space above and below the focused callout block before the top plot boundary.

#### Scenario: Default stop balances callout breathing
- **GIVEN** the Weekly Fajrcast card is rendered at the default text-size stop
- **WHEN** the focused callout is drawn above the plot
- **THEN** the chart SHALL reserve approximately 10 pt above the callout block
- **AND** it SHALL reserve approximately 10 pt below the callout block before the plot boundary
- **AND** the chart region SHALL grow beyond its minimum when measured callout content requires more room

#### Scenario: Larger stops preserve callout breathing
- **GIVEN** the Weekly Fajrcast card is rendered at xLarge, xxLarge, or xxxLarge
- **WHEN** scaled callout text is drawn
- **THEN** the chart SHALL reserve at least 12 pt above and below the callout block

#### Scenario: Accessibility stops grow instead of crowding
- **GIVEN** the Weekly Fajrcast card is rendered at an accessibility text-size stop
- **WHEN** scaled callout text needs additional room
- **THEN** the chart and card SHALL grow rather than allowing the callout to crowd the top divider or plot boundary

### Requirement: Home Weekly Fajrcast footer secondary reflects focused context
The Weekly Fajrcast footer secondary line SHALL reflect the focused day's strongest resolved context/status when a focused context is present.

#### Scenario: Focused adjusted day uses adjusted footer context
- **GIVEN** the Weekly Fajrcast visible week contains an adjusted day
- **WHEN** the adjusted day is the focused day
- **THEN** the footer secondary line SHALL include the adjusted context for that focused day
- **AND** it SHALL still describe that focused day's alarm/off status with the correct tense

#### Scenario: Non-focused adjusted day does not hijack footer context
- **GIVEN** the Weekly Fajrcast visible week contains an adjusted day
- **WHEN** another ordinary day is the focused day
- **THEN** the footer secondary line SHALL describe the focused ordinary day
- **AND** adjusted-week information MAY remain in compact insight data without replacing the focused footer sentence
