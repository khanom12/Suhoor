## ADDED Requirements

### Requirement: Canonical quick wake-mode resolution
The system SHALL resolve target-morning `Fast`, `Fajr`, and `Quiet` selections through one canonical wake-state path before scheduling or presenting downstream surfaces.

#### Scenario: Fajr mode selected
- **GIVEN** a target morning has selected quick wake mode `fajr`
- **WHEN** the morning is resolved
- **THEN** the wake rule SHALL be 30 min before Fajr ends
- **AND** scheduling SHALL create or update the active wake alarm when required timing data is available

#### Scenario: Fast mode selected
- **GIVEN** a target morning has selected quick wake mode `fast`
- **WHEN** the morning is resolved
- **THEN** the wake rule SHALL be 30 min before Fajr begins
- **AND** the early-worship boundary SHALL be used by presentation when final-third start is available
- **AND** no recurring fasting rule SHALL be created implicitly

#### Scenario: Quiet mode selected
- **GIVEN** a target morning has selected quick wake mode `quiet`
- **WHEN** the morning is resolved
- **THEN** wake/reminder/Fajr-boundary alarm delivery for that morning SHALL be disabled
- **AND** the morning SHALL remain resolvable for Fajr boundary display
- **AND** no hidden active wake alarm SHALL remain scheduled for that morning

#### Scenario: Manual drag preserves selected mode
- **GIVEN** the user has selected `fast` or `fajr`
- **WHEN** the user drags the hero wake adjuster
- **THEN** the wake time SHALL be saved inside that mode's active boundary window
- **AND** the selected quick mode SHALL NOT change
