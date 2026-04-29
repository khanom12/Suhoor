## MODIFIED Requirements

### Requirement: Morning Hero renders only eligible within-Fajr visual rows
The home hero SHALL render the Fajr window row only when the target morning has available Fajr begin/end times and the current wake or planned anchor is eligible for the v0.3 within-Fajr treatment.

#### Scenario: Ordinary suhoor secondary context still renders the adjuster
- **GIVEN** the target morning has primary standard context, secondary suhoor context, no fasting tags, available Fajr begin/end values, and an active wake inside the Fajr window
- **WHEN** the Morning Hero renders
- **THEN** it SHALL render the Fajr begin time, endpoint circles, track, active alarm marker, and Fajr end time
- **AND** the row SHALL be eligible for wake adjustment

#### Scenario: True fasting day hides the v0.3 row
- **GIVEN** the target morning has fasting, qada fast, sunnah fast context, or fasting tags
- **WHEN** the Morning Hero renders
- **THEN** it SHALL hide the v0.3 Fajr window visual
- **AND** it SHALL NOT expose an adjustable wake control for that hidden row

### Requirement: Morning Hero supports immediate wake adjustment
The home hero SHALL expose the within-Fajr active alarm marker as a wake adjustment control that updates local display during interaction and commits the new wake to the resolved morning engine on release.

#### Scenario: UI automation can verify the adjuster
- **GIVEN** the hero is rendered for an active within-Fajr wake plan
- **WHEN** automated UI verification inspects the hero
- **THEN** the primary wake time, relation line, Fajr window row, begin time, track, marker, and end time SHALL be discoverable by stable identifiers
- **AND** dragging the marker SHALL update the displayed primary wake time and keep the row present after commit

