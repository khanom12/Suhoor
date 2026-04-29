## MODIFIED Requirements

### Requirement: Morning Hero uses v0.4 location-first anatomy
The home hero SHALL render the v0.4 anatomy with a location line, relative day label, primary wake row, conditional Fajr window visual, and final wake relation line.

#### Scenario: Automatic location renders icon and place name
- **GIVEN** the home snapshot is resolved from automatic/current-location mode
- **WHEN** the Morning Hero renders
- **THEN** the first visible row SHALL show a location icon and the detected location display name
- **AND** it SHALL NOT render the Gregorian/Hijri date line in the visible stack

#### Scenario: Manual location renders place name without icon
- **GIVEN** the home snapshot is resolved from a manually selected location
- **WHEN** the Morning Hero renders
- **THEN** the first visible row SHALL show the selected location display name
- **AND** it SHALL NOT show the automatic/current-location icon
- **AND** it SHALL NOT reserve space for the hidden date line

#### Scenario: Eligible Fajr visual precedes relation line
- **GIVEN** the hero has an eligible active wake inside the Fajr begin/end window
- **WHEN** the Morning Hero renders
- **THEN** the Fajr window visual SHALL appear directly below the primary wake row
- **AND** the wake relation line SHALL be the final visible row below the visual

#### Scenario: Hidden visual keeps relation final
- **GIVEN** the Fajr window visual is hidden because the morning is fasting, missing data, or out of window
- **WHEN** the Morning Hero renders
- **THEN** the wake relation line SHALL remain visible as the final row below the primary wake row
