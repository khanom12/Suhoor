## ADDED Requirements

### Requirement: Morning Hero quick-mode transitions
The Morning Hero SHALL animate quick wake-mode changes across the selector, primary wake row, wake-boundary visual, marker, boundary labels, and relation/status line without changing the resolved alarm pipeline.

#### Scenario: Selector highlight moves
- **GIVEN** the Morning Hero quick wake-state selector is visible
- **WHEN** the selected mode changes between `Fast`, `Fajr`, and `Quiet`
- **THEN** the selected-state highlight SHALL move or morph as one selected treatment
- **AND** label emphasis SHALL update with the selected segment
- **AND** the selector container SHALL remain stationary with the same logical segment widths

#### Scenario: Fajr changes to Fast
- **GIVEN** the Morning Hero is showing `Fajr` mode with an eligible within-Fajr adjuster
- **WHEN** the user selects `Fast` and the shared resolver returns an eligible early-worship wake state
- **THEN** the hero SHALL animate the wake marker earlier/leftward through the Fajr-begins handoff
- **AND** it SHALL transition the range visual to the final-third start -> Fajr begins row
- **AND** it SHALL settle on the resolved Fast wake time and relation text

#### Scenario: Fast changes to Fajr
- **GIVEN** the Morning Hero is showing `Fast` mode with an eligible early-worship adjuster
- **WHEN** the user selects `Fajr` and the shared resolver returns an eligible within-Fajr wake state
- **THEN** the hero SHALL animate the wake marker later/rightward through the Fajr-begins handoff
- **AND** it SHALL transition the range visual to the Fajr begins -> Fajr ends row
- **AND** it SHALL settle on the resolved Fajr wake time and relation text

#### Scenario: Quiet keeps layout stable
- **GIVEN** the Morning Hero is showing an active `Fast` or `Fajr` wake state
- **WHEN** the user selects `Quiet` and the shared resolver returns Quiet mode
- **THEN** the primary row SHALL show `Quiet mode on` in the same primary row slot
- **AND** the Fajr begin -> Fajr end visual SHALL remain static when Fajr data is available
- **AND** no alarm marker or adjustable control SHALL be visible
- **AND** the hero stack SHALL NOT jump vertically because the large time digits were replaced

#### Scenario: Leaving Quiet restores active visual
- **GIVEN** the Morning Hero is showing `Quiet` mode
- **WHEN** the user selects `Fast` or `Fajr` and the shared resolver returns an active wake state
- **THEN** the primary row SHALL transition from `Quiet mode on` to the resolved wake time
- **AND** the appropriate interactive range visual SHALL return when eligible
- **AND** the alarm marker SHALL fade or move into the resolved wake position

### Requirement: Morning Hero reduced-motion mode changes
The Morning Hero SHALL respect system Reduce Motion for quick-mode transitions.

#### Scenario: Reduce Motion is enabled
- **GIVEN** system Reduce Motion is enabled
- **WHEN** the user changes quick wake mode
- **THEN** directional marker travel SHALL be replaced with a short crossfade or minimal movement
- **AND** selected-state feedback, text updates, layout stability, and accessibility updates SHALL still occur
