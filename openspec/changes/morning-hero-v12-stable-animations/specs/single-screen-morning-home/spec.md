## MODIFIED Requirements

### Requirement: Morning Hero Quick Wake Mode Transitions

The Morning Hero SHALL animate Fast, Fajr, and Quiet quick wake-state changes without moving the hero stack or rebuilding rows directionally.

#### Scenario: Relation text changes in place

- **WHEN** the selected quick wake mode changes
- **THEN** the relation/status line SHALL change using an in-place fade-through or direct content transition
- **AND** it SHALL NOT slide in from any edge.

#### Scenario: Quiet keeps the hero vertically stable

- **WHEN** the selected quick wake mode changes to or from Quiet
- **THEN** the primary row SHALL keep the same settled height as active wake modes
- **AND** the range row, relation row, selector row, and following home cards SHALL NOT jump vertically due to ordinary mode switching.

#### Scenario: Active wake time rolls between Fast and Fajr

- **WHEN** the selected quick wake mode changes from Fajr to Fast or Fast to Fajr
- **THEN** the primary wake time SHALL animate through a rapid monotonic minute roll toward the resolved wake time
- **AND** the final displayed time SHALL match the resolver result.

#### Scenario: Range row remains anchored

- **WHEN** the selected quick wake mode changes between Fajr and Fast
- **THEN** the range row frame, track, and boundary label slots SHALL remain anchored
- **AND** boundary time labels SHALL crossfade in place
- **AND** the alarm marker SHALL be the only visibly traveling element.

#### Scenario: Selector uses forecast-card glass language

- **WHEN** the quick wake-state selector is visible
- **THEN** it SHALL use a single translucent glass pill with a gliding selected capsule
- **AND** it SHALL NOT read as an opaque or frosted gray segmented control.
