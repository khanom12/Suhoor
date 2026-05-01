## ADDED Requirements

### Requirement: Morning Hero quick-mode transitions remain anchored
The Morning Hero SHALL keep its primary wake row and Fajr range row anchored during quick-mode changes while animating only the affected text and marker elements.

#### Scenario: Fajr changes to Fast
- **GIVEN** the Morning Hero is showing an active Fajr quick wake mode with an interactive range marker
- **WHEN** the user selects Fast
- **THEN** the range endpoint times SHALL fade out and fade in without moving the range row
- **AND** the relation text SHALL fade from the Fajr-end wording to the Fajr-begin wording
- **AND** the marker SHALL move left to the edge, disappear, reappear at the right edge, and settle leftward into the Fast position

#### Scenario: Fast changes to Fajr
- **GIVEN** the Morning Hero is showing an active Fast quick wake mode with an interactive range marker
- **WHEN** the user selects Fajr
- **THEN** the range endpoint times SHALL fade out and fade in without moving the range row
- **AND** the relation text SHALL fade from the Fajr-begin wording to the Fajr-end wording
- **AND** the marker SHALL move right to the edge, disappear, reappear at the left edge, and settle rightward into the Fajr position

#### Scenario: Active mode follows Quiet
- **GIVEN** the Morning Hero is showing Quiet mode
- **WHEN** the user selects Fajr or Fast and then switches to the other active mode
- **THEN** the primary wake time SHALL use the same rapid rolling animation used for ordinary Fajr/Fast transitions

#### Scenario: Reduced motion
- **GIVEN** reduced motion is enabled
- **WHEN** the user changes between Fajr, Fast, and Quiet quick modes
- **THEN** the Morning Hero SHALL use short fades and direct marker placement without physical marker travel
