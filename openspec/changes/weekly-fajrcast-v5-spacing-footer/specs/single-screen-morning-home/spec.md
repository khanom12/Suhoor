## ADDED Requirements

### Requirement: Home Weekly Fajrcast uses v5 compact chart sizing
The Home/Wake Weekly Fajrcast card SHALL use the v5 seven-stop Dynamic Type guardrails for compact card height, chart height, right-side y-axis rail width, and plotted scale height.

#### Scenario: Default stop uses v5 compact dimensions
- **GIVEN** the Weekly Fajrcast card is rendered at the default text-size stop
- **WHEN** the compact chart is measured
- **THEN** the card minimum height SHALL be 288 pt
- **AND** the compact chart minimum height SHALL be 210 pt
- **AND** the right-side y-axis rail minimum width SHALL be 46 pt
- **AND** the plotted y-axis scale height SHALL be at least 150 pt

#### Scenario: Standard text-size stops keep stable plot scale
- **GIVEN** the Weekly Fajrcast card is rendered at any of the seven standard text-size stops from xSmall through xxxLarge
- **WHEN** the compact chart is measured
- **THEN** the plotted y-axis scale height SHALL remain at least 150 pt
- **AND** it SHALL remain visually stable across those standard stops

### Requirement: Home Weekly Fajrcast preserves x-axis breathing space
The Weekly Fajrcast compact chart SHALL reserve explicit visual breathing space between the x-axis weekday labels and the bottom divider/footer boundary.

#### Scenario: Default stop preserves x-axis spacing
- **GIVEN** the Weekly Fajrcast card is rendered at the default text-size stop
- **WHEN** weekday labels are drawn under the plot
- **THEN** the bottom of the weekday label line box SHALL sit at least 10 pt above the chart bottom edge and card bottom divider boundary

#### Scenario: Larger stops preserve additional x-axis spacing
- **GIVEN** the Weekly Fajrcast card is rendered at xLarge, xxLarge, or xxxLarge
- **WHEN** weekday labels are drawn under the plot
- **THEN** the bottom of the weekday label line box SHALL sit at least 12 pt above the chart bottom edge and card bottom divider boundary

#### Scenario: Accessibility stops grow instead of crowding
- **GIVEN** the Weekly Fajrcast card is rendered at an accessibility text-size stop
- **WHEN** scaled axis labels need additional room
- **THEN** the chart and card SHALL grow rather than allowing the x-axis labels to crowd the bottom divider

### Requirement: Home Weekly Fajrcast footer uses equal full-opacity lines
The Weekly Fajrcast footer SHALL render primary and secondary footer text with the same size, regular weight, and full-opacity white treatment.

#### Scenario: Secondary footer is not dimmed
- **GIVEN** the Weekly Fajrcast footer has both primary and secondary text
- **WHEN** the footer is rendered
- **THEN** the secondary line SHALL use the same base font size as the primary line
- **AND** the secondary line SHALL use the same regular font weight as the primary line
- **AND** the secondary line SHALL use full-opacity white rather than a dimmed or lower-opacity treatment
