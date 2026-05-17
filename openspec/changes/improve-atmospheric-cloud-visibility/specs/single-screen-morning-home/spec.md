## MODIFIED Requirements

### Requirement: Top-hero asset-backed atmospheric home background
The Subh home surface SHALL render the atmospheric background using the provided AI-generated top-hero cloud image assets above the static wake background, above a weak atmosphere base overlay, below a softer foreground readability overlay, and below the foreground home content.

#### Scenario: Home renders top-hero cloud layer
- **GIVEN** the Subh home is visible after onboarding
- **WHEN** the background stack renders
- **THEN** the system SHALL place `AppHomeAtmosphereBaseOverlay` above `AppPageBackground`
- **AND** the system SHALL place `AppAtmosphericCloudLayer` above `AppHomeAtmosphereBaseOverlay`
- **AND** the system SHALL place `AppHomeForegroundContrastOverlay` above `AppAtmosphericCloudLayer`
- **AND** the layer SHALL render the provided `SubhDawnHeroCloudMist`, `SubhDawnHeroCloudFar`, `SubhDawnHeroCloudMid`, `SubhDawnHeroCloudLow`, and `SubhDawnHeroCloudNear` assets
- **AND** visible cloud content SHALL be confined to the upper hero area
- **AND** the foreground home content SHALL remain readable

#### Scenario: Split contrast preserves atmospheric visibility
- **GIVEN** the Subh home is visible after onboarding
- **WHEN** the background stack renders
- **THEN** the lower atmosphere overlay SHALL be weaker than the previous full home contrast overlay
- **AND** the foreground readability overlay SHALL preserve text contrast without obscuring cloud detail in the top hero area

#### Scenario: Clouds animate with depth-based parallax when motion is allowed
- **GIVEN** Reduce Motion is disabled
- **WHEN** the Subh home remains visible
- **THEN** the atmospheric cloud bands SHALL move horizontally in slow seamless loops
- **AND** `SubhDawnHeroCloudNear` SHALL move faster than `SubhDawnHeroCloudLow`
- **AND** `SubhDawnHeroCloudLow` SHALL move faster than `SubhDawnHeroCloudMid`
- **AND** `SubhDawnHeroCloudMid` SHALL move faster than `SubhDawnHeroCloudFar`
- **AND** `SubhDawnHeroCloudFar` SHALL move faster than `SubhDawnHeroCloudMist`
- **AND** the layers SHALL generally drift in the same horizontal direction

#### Scenario: Clouds are static when motion is reduced
- **GIVEN** Reduce Motion is enabled
- **WHEN** the Subh home renders
- **THEN** the atmospheric cloud bands SHALL render without horizontal animation
- **AND** the static cloud positions SHALL use deterministic phase offsets

#### Scenario: Clouds remain decorative only
- **GIVEN** the Subh home is visible
- **WHEN** the user interacts with home content
- **THEN** the atmospheric cloud layer SHALL NOT intercept taps, drags, or gestures
- **AND** the atmospheric cloud layer SHALL NOT appear in the accessibility tree
