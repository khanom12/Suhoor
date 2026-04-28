## ADDED Requirements

### Requirement: Home Weekly Fajrcast uses v7 compact plot height
The Home/Wake Weekly Fajrcast card SHALL use a compact plotted y-axis scale height of at least 128 pt across the seven standard text-size stops.

#### Scenario: Default stop uses v7 plot height
- **GIVEN** the Weekly Fajrcast card is rendered at the default text-size stop
- **WHEN** the compact chart is measured
- **THEN** the plotted y-axis scale height SHALL be at least 128 pt
- **AND** the removed height SHALL NOT be reintroduced as blank padding around the chart

#### Scenario: Standard stops keep stable compact scale
- **GIVEN** the Weekly Fajrcast card is rendered from xSmall through xxxLarge text-size stops
- **WHEN** the compact chart is measured
- **THEN** the plotted y-axis scale height SHALL remain at least 128 pt
- **AND** it SHALL remain visually stable across those standard stops

### Requirement: Home Weekly Fajrcast uses compact balanced callout spacing
The Weekly Fajrcast compact chart SHALL reserve compact, equal breathing space above and below the focused callout block.

#### Scenario: Default stop uses compact callout breathing
- **GIVEN** the Weekly Fajrcast card is rendered at the default text-size stop
- **WHEN** the focused callout is drawn above the plot
- **THEN** the chart SHALL reserve approximately 5 pt above the callout block
- **AND** it SHALL reserve approximately 5 pt below the callout block before the plot boundary

#### Scenario: Larger stops keep compact callout breathing
- **GIVEN** the Weekly Fajrcast card is rendered at xLarge, xxLarge, or xxxLarge
- **WHEN** scaled callout text is drawn
- **THEN** the chart SHALL reserve at least 6 pt above and below the callout block

### Requirement: Home Weekly Fajrcast separates plot and x-axis labels
The Weekly Fajrcast compact chart SHALL keep a small intentional gap between the lower plot boundary and the x-axis weekday labels.

#### Scenario: Default stop separates plot and x-axis
- **GIVEN** the Weekly Fajrcast card is rendered at the default text-size stop
- **WHEN** x-axis weekday labels are drawn below the plot
- **THEN** the top of the x-axis label line box SHALL sit about 4 pt below the lower plot boundary
- **AND** the existing x-axis-to-footer divider breathing space SHALL still be preserved below the label line box

#### Scenario: Smaller and larger stops use tuned x-axis gap
- **GIVEN** the Weekly Fajrcast card is rendered at a standard non-default text-size stop
- **WHEN** x-axis weekday labels are drawn below the plot
- **THEN** smaller stops SHALL keep at least 3 pt below the lower plot boundary
- **AND** larger stops SHALL keep at least 5 pt below the lower plot boundary
