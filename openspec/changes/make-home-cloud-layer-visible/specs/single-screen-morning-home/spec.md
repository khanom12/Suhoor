## ADDED Requirements

### Requirement: Decorative atmospheric home background
The Subh home surface SHALL render a decorative atmospheric cloud layer above the static wake background and below the home contrast overlay and foreground content.

#### Scenario: Home renders atmospheric clouds
- **GIVEN** the Subh home is visible after onboarding
- **WHEN** the background stack renders
- **THEN** the system SHALL place the atmospheric cloud layer above `AppPageBackground`
- **AND** the system SHALL place it below `AppHomeContrastOverlay`
- **AND** the foreground home content SHALL remain readable

#### Scenario: Clouds are decorative only
- **GIVEN** the Subh home is visible
- **WHEN** the user interacts with home content
- **THEN** the atmospheric cloud layer SHALL NOT intercept taps, drags, or gestures
- **AND** the atmospheric cloud layer SHALL NOT appear in the accessibility tree

#### Scenario: Motion setting is reduced
- **GIVEN** Reduce Motion is enabled
- **WHEN** the Subh home renders
- **THEN** the atmospheric cloud layer SHALL render a static or dramatically reduced-motion state
- **AND** the foreground home content SHALL remain unchanged
