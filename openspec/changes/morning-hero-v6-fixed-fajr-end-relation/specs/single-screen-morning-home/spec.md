## MODIFIED Requirements

### Requirement: Morning Hero uses v0.6 fixed Fajr-end relation copy
The home hero SHALL render active wake relation copy with a fixed Fajr-end boundary using compact minute wording.

#### Scenario: Active relation copy uses fixed Fajr-end pattern
- **GIVEN** the hero has an active wake time and resolved Fajr end time
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the relation line SHALL read `Wake up {X} min before Fajr ends`
- **AND** `X` SHALL be the whole-minute difference between the active wake time and Fajr end
- **AND** the line SHALL use compact `min` wording

#### Scenario: Drag updates relation copy with same pattern
- **GIVEN** the Fajr-window visual is interactive
- **WHEN** the user drags the alarm marker
- **THEN** the primary wake row and final relation line SHALL update live
- **AND** the final relation line SHALL keep the `Wake up {X} min before Fajr ends` pattern

#### Scenario: Alternate active boundary wording is not used
- **GIVEN** the active wake time is at Fajr begin, at Fajr end, or between them
- **WHEN** the Morning Hero renders the final relation line
- **THEN** it SHALL NOT use `before Fajr begins`, `after Fajr begins`, `at the start of Fajr`, or `at the end of Fajr`

#### Scenario: Inactive wake states remain stateful
- **GIVEN** the hero has no active alarm, an off alarm, missing Fajr data, quiet state, or unavailable wake data
- **WHEN** the Morning Hero renders the final relation line
- **THEN** the line SHALL describe that state rather than pretending an active wake relation exists
