## MODIFIED Requirements

### Requirement: Morning Hero uses v0.5 final relation copy and spacing
The home hero SHALL render the v0.5 location-first anatomy with active wake relation copy that reads as a complete wake instruction and with the Fajr-window visual spaced according to the v0.5 baseline.

#### Scenario: Active relation copy begins with Wake up
- **GIVEN** the hero has an active wake time resolved relative to Fajr
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the relation line SHALL begin with `Wake up`
- **AND** it SHALL name the exact Fajr boundary as `Fajr begins` or `Fajr ends`
- **AND** it SHALL use full-word minute wording such as `30 minutes`, not compact `30 min`

#### Scenario: Boundary relation copy remains explicit
- **GIVEN** the active wake time is exactly at the Fajr begin or Fajr end boundary
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the relation line SHALL read `Wake up at the start of Fajr` or `Wake up at the end of Fajr`

#### Scenario: Drag updates relation copy live
- **GIVEN** the Fajr-window visual is interactive
- **WHEN** the user drags the alarm marker
- **THEN** the primary wake row and final relation line SHALL update live
- **AND** the final relation line SHALL keep the v0.5 `Wake up ... minutes ...` wording

#### Scenario: Inactive wake states remain stateful
- **GIVEN** the hero has no active alarm, an off alarm, missing Fajr data, quiet state, or unavailable wake data
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the line SHALL describe that state rather than pretending an active wake relation exists

#### Scenario: Fajr visual uses v0.5 vertical spacing
- **GIVEN** the Fajr-window visual is eligible
- **WHEN** the Morning Hero renders
- **THEN** the primary wake row to Fajr-window visual gap SHALL use the 8 pt baseline
- **AND** the Fajr-window visual to relation-line gap SHALL use the 12 pt baseline
