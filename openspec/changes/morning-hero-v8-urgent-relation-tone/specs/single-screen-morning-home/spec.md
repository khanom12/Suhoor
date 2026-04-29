## MODIFIED Requirements

### Requirement: Morning Hero uses v0.8 urgent relation tone
The home hero SHALL render endpoint-aware active relation copy and SHALL apply red relation text only for urgent wake times 10 minutes or less before Fajr ends.

#### Scenario: Non-urgent relation copy uses normal tone
- **GIVEN** the hero has an active wake time more than 10 rounded whole minutes before Fajr end
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the relation line SHALL read `Wake up {X} min before Fajr ends`
- **AND** it SHALL use the normal relation tone

#### Scenario: Ten-minute warning uses urgent red
- **GIVEN** the hero has an active wake time 10 rounded whole minutes before Fajr end
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the relation line SHALL read `Wake up 10 min before Fajr ends`
- **AND** it SHALL use urgent red tone

#### Scenario: Smaller warning values use urgent red
- **GIVEN** the hero has an active wake time fewer than 10 rounded whole minutes before Fajr end
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the relation line SHALL use the matching `Wake up {X} min before Fajr ends` copy
- **AND** it SHALL use urgent red tone

#### Scenario: Fajr begin endpoint is not inherently urgent
- **GIVEN** the active or tentative wake time is at Fajr begin after clamping and rounding
- **AND** Fajr begin is more than 10 rounded whole minutes before Fajr end
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the relation line SHALL read `Wake up as Fajr begins`
- **AND** it SHALL use the normal relation tone

#### Scenario: Fajr end endpoint uses endpoint copy and urgent red
- **GIVEN** the active or tentative wake time is at Fajr end after clamping and rounding
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the relation line SHALL read `Wake up as Fajr ends`
- **AND** it SHALL use urgent red tone
- **AND** it SHALL NOT read `Wake up 0 min before Fajr ends`

#### Scenario: Inactive wake states remain stateful
- **GIVEN** the hero has no active alarm, an off alarm, missing Fajr data, quiet state, or unavailable wake data
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the line SHALL describe that state rather than pretending an active wake relation exists
- **AND** it SHALL NOT use urgent red tone
