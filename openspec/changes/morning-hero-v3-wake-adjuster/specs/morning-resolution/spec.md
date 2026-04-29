## ADDED Requirements

### Requirement: Immediate hero wake adjustment persists as a date override
The morning engine SHALL persist a committed Morning Hero wake adjustment as a date-specific override for the target morning instead of mutating global defaults or calculating a UI-only wake time.

#### Scenario: User commits an adjusted wake inside Fajr window
- **GIVEN** the target morning has a resolved active wake and available Fajr begin/end values
- **WHEN** the Morning Hero commits a new wake time inside the Fajr window
- **THEN** the system SHALL store a date-specific wake override for that target date
- **AND** the stored override SHALL resolve the wake to the committed clock time for that date
- **AND** global default wake settings SHALL remain unchanged

#### Scenario: Override is resolved after commit
- **GIVEN** a date-specific wake override was committed from the Morning Hero
- **WHEN** the schedule engine rebuilds that target date
- **THEN** the resolved morning SHALL use the override wake time
- **AND** the schedule row SHALL indicate that a date-specific wake change is active

#### Scenario: Commit affects only target date
- **GIVEN** the active schedule window contains multiple mornings
- **WHEN** the Morning Hero commits a wake adjustment for the target morning
- **THEN** unrelated mornings SHALL keep their existing wake rules
- **AND** unrelated scheduled alarms SHALL NOT be cancelled or rewritten solely because of this adjustment

#### Scenario: Commit cannot resolve target date
- **GIVEN** the target morning is no longer resolvable after the user releases the adjustment
- **WHEN** the system attempts to persist or rebuild the adjusted wake
- **THEN** it SHALL restore the previous resolved hero state on the next snapshot
- **AND** it SHALL avoid saving a guessed wake time for a missing Fajr window
