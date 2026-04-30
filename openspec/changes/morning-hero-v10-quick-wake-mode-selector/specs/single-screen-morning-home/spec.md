## ADDED Requirements

### Requirement: Morning Hero quick wake-state selector
The Morning Hero SHALL render a final quick wake-state selector below the relation/status line when a target morning is available.

#### Scenario: Ordinary Fajr mode is selected
- **GIVEN** the target morning has no explicit Fast or Quiet selection
- **WHEN** the Morning Hero renders
- **THEN** the selector SHALL show three segments in order: `Fast`, `Fajr`, `Quiet`
- **AND** `Fajr` SHALL be selected
- **AND** the hero SHALL show an active wake 30 min before Fajr ends when Fajr end data is available

#### Scenario: Fast mode is selected
- **GIVEN** the user selects `Fast` from the Morning Hero
- **WHEN** the shared wake-state resolver saves and returns the updated target morning
- **THEN** `Fast` SHALL be selected
- **AND** the primary wake row SHALL use the wake 30 min before Fajr begins
- **AND** the early-worship adjuster SHALL render when final-third start and Fajr begin are available
- **AND** the relation line SHALL say `Wake up 30 min before Fajr begins`

#### Scenario: Quiet mode is selected
- **GIVEN** the user selects `Quiet` from the Morning Hero
- **WHEN** the shared wake-state resolver saves and returns the updated target morning
- **THEN** `Quiet` SHALL be selected
- **AND** the primary wake row SHALL say exactly `Quiet mode on`
- **AND** the relation line SHALL follow `No alarm will ring for {relative day}`
- **AND** the Fajr begin -> Fajr end visual SHALL be static with no alarm marker when Fajr data is available

#### Scenario: Selection uses shared resolver
- **GIVEN** the user taps `Fast`, `Fajr`, or `Quiet`
- **WHEN** the action is handled
- **THEN** the Hero SHALL emit a wake-mode selection intent
- **AND** it SHALL NOT create, cancel, or schedule alarms directly
- **AND** Weekly Fajrcast and next-ten morning data SHALL update from the rebuilt active-day snapshot

### Requirement: Quick selector accessibility
The Morning Hero quick wake-state selector SHALL expose accessible selectable segments.

#### Scenario: Assistive technology reads the selector
- **GIVEN** the selector is visible
- **WHEN** accessibility focuses each segment
- **THEN** each segment SHALL expose its label and selected state
- **AND** the control group SHALL be identifiable as wake mode selection
