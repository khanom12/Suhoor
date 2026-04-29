## ADDED Requirements

### Requirement: Fajr-end wake anchors carry source metadata
Wake anchors based on supported Fajr end SHALL carry source metadata from the resolved prayer window.

#### Scenario: Supported Fajr end is sunrise-derived
- **GIVEN** the resolved prayer window has Fajr end source `solarSunrise`
- **WHEN** the wake resolver creates a Fajr-end wake anchor
- **THEN** the anchor SHALL preserve source notes indicating a solar sunrise Fajr-end boundary
- **AND** wake explanation copy SHALL NOT describe the boundary as a renderer proxy.

### Requirement: Fajr end adjustment affects Fajr-end wake anchors
Wake anchors based on Fajr end SHALL use the adjusted Fajr-end boundary after any Fajr-end adjustment is applied.

#### Scenario: User adjusts Fajr end
- **GIVEN** a Fajr-end wake rule and a non-zero Fajr-end adjustment
- **WHEN** Subh resolves the wake anchor
- **THEN** the wake anchor SHALL be relative to the adjusted Fajr-end boundary
- **AND** Fajr begin adjustment SHALL NOT affect the Fajr-end anchor.
