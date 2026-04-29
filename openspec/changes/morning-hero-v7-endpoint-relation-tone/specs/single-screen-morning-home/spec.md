## MODIFIED Requirements

### Requirement: Morning Hero uses v0.7 endpoint-aware relation copy and tone
The home hero SHALL render endpoint-aware active relation copy and red endpoint tone while retaining compact Fajr-end relation copy for ordinary wake positions.

#### Scenario: Non-endpoint relation copy stays compact
- **GIVEN** the hero has an active wake time between Fajr begin and Fajr end
- **AND** the wake time is not exactly equal to either endpoint
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the relation line SHALL read `Wake up {X} min before Fajr ends`
- **AND** it SHALL use the normal relation tone

#### Scenario: Fajr begin endpoint uses endpoint copy
- **GIVEN** the active or tentative wake time is exactly Fajr begin after clamping and rounding
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the relation line SHALL read `Wake up as Fajr begins`
- **AND** it SHALL use the endpoint red tone

#### Scenario: Fajr end endpoint uses endpoint copy
- **GIVEN** the active or tentative wake time is exactly Fajr end after clamping and rounding
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the relation line SHALL read `Wake up as Fajr ends`
- **AND** it SHALL use the endpoint red tone
- **AND** it SHALL NOT read `Wake up 0 min before Fajr ends`

#### Scenario: Drag updates endpoint relation live
- **GIVEN** the Fajr-window visual is interactive
- **WHEN** the user drags the alarm marker to Fajr begin or Fajr end
- **THEN** the primary wake row and final relation line SHALL update live
- **AND** the final relation line SHALL use the matching endpoint copy and endpoint red tone

#### Scenario: Inactive wake states remain stateful
- **GIVEN** the hero has no active alarm, an off alarm, missing Fajr data, quiet state, or unavailable wake data
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the line SHALL describe that state rather than pretending an active wake relation exists
