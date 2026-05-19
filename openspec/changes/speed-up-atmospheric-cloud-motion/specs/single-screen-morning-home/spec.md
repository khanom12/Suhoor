## ADDED Requirements

### Requirement: Tuned atmospheric cloud motion speed
The Subh home atmospheric cloud layer SHALL allow the decorative cloud drift speed to be tuned while preserving the established right-to-left direction, seamless rendering model, top-hero confinement, parallax depth ordering, and Reduce Motion behavior.

#### Scenario: Cloud bands use faster proportional motion
- **GIVEN** the home atmospheric cloud layer is rendered with motion enabled
- **WHEN** the cloud bands drift across the top hero region
- **THEN** each cloud band SHALL use a loop duration that is proportionally shortened by the same 2.5x speed factor
- **AND** the relative ordering SHALL remain mist slowest, far slow, mid moderate, low faster, and near fastest

#### Scenario: Reduced motion remains static
- **GIVEN** Reduce Motion is enabled
- **WHEN** the home atmospheric cloud layer renders
- **THEN** cloud bands SHALL remain visible at deterministic static phase offsets
- **AND** no horizontal cloud animation SHALL run
