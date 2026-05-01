## MODIFIED Requirements

### Requirement: Single primary home surface
The system SHALL use a single Subh home surface as the primary post-onboarding experience.

#### Scenario: Home background renders
- **GIVEN** the user has completed onboarding
- **WHEN** the Subh home renders
- **THEN** the home SHALL use the provided dawn gradient image as the main page background
- **AND** the home SHALL apply a subtle dark tint over the background to protect text readability, especially near the bottom of the screen
- **AND** the existing home layout, cards, controls, navigation, and contrast overlay SHALL remain unchanged
