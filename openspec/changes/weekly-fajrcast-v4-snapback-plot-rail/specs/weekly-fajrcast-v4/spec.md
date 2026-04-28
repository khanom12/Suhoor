## ADDED Requirements

### Requirement: Weekly Fajrcast inspection snaps back to resting focus
The compact Weekly Fajrcast SHALL treat touch chart interaction as temporary inspection and SHALL return to the resting focus when the interaction ends.

#### Scenario: User scrubs to another visible day
- **GIVEN** the card is showing an anchored seven-day window
- **WHEN** the user scrubs to another visible day
- **THEN** the guide, callout, marker emphasis, footer, and accessibility value SHALL describe the inspected day
- **AND** the visible date window SHALL remain unchanged

#### Scenario: User releases the chart
- **GIVEN** the user is inspecting a non-resting visible day
- **WHEN** the chart gesture ends
- **THEN** the guide, callout, marker emphasis, footer, and accessibility value SHALL return to the resting focus
- **AND** the chart SHALL NOT pan, scroll, recenter, or load another day

### Requirement: Weekly Fajrcast static elapsed overlay does not follow inspection
The compact Weekly Fajrcast elapsed/past overlay SHALL be anchored to the resting focus boundary and SHALL NOT follow the inspected day.

#### Scenario: User inspects a past or future day
- **GIVEN** the chart renders a static elapsed overlay
- **WHEN** the user scrubs to any visible day
- **THEN** the overlay SHALL remain anchored to the resting focus boundary
- **AND** only the guide, callout, marker emphasis, footer, and accessibility value SHALL change

### Requirement: Weekly Fajrcast v4 plot and y-axis rail layout
The compact Weekly Fajrcast chart SHALL use v4 chart sizing guardrails and right-aligned y-axis labels.

#### Scenario: Default text size renders compact chart
- **GIVEN** the user uses default text size
- **WHEN** the compact chart renders
- **THEN** the card SHALL use at least 292 pt minimum height
- **AND** the chart region SHALL use at least 214 pt minimum height
- **AND** the plotted y-axis scale SHALL use at least 160 pt height
- **AND** y-axis labels SHALL be trailing-aligned to the right content boundary

#### Scenario: Larger text expands the rail leftward
- **GIVEN** the user uses larger text
- **WHEN** the compact chart renders
- **THEN** the y-axis rail SHALL expand leftward
- **AND** y-axis label right edges SHALL remain aligned to the same right content boundary
