## MODIFIED Requirements

### Requirement: Top-hero asset-backed atmospheric home background
The Subh home surface SHALL render the atmospheric background using the provided AI-generated top-hero cloud image assets above the static wake background, above a weak atmosphere base overlay, below a softer foreground readability overlay, and below the foreground home content. The cloud bands SHALL render as seamless, feathered, overscanned right-to-left atmospheric fields without relying on perfectly seamless asset edges.

#### Scenario: Home renders top-hero cloud layer
- **GIVEN** the Subh home is visible after onboarding
- **WHEN** the background stack renders
- **THEN** the system SHALL place `AppHomeAtmosphereBaseOverlay` above `AppPageBackground`
- **AND** the system SHALL place `AppAtmosphericCloudLayer` above `AppHomeAtmosphereBaseOverlay`
- **AND** the system SHALL place `AppHomeForegroundContrastOverlay` above `AppAtmosphericCloudLayer`
- **AND** the layer SHALL render the provided `SubhDawnHeroCloudMist`, `SubhDawnHeroCloudFar`, `SubhDawnHeroCloudMid`, `SubhDawnHeroCloudLow`, and `SubhDawnHeroCloudNear` assets
- **AND** visible cloud content SHALL be confined to the upper hero area
- **AND** the foreground home content SHALL remain readable

#### Scenario: Cloud bands render without visible tile seams
- **GIVEN** Reduce Motion is disabled
- **WHEN** a cloud band drifts horizontally through its animation cycle
- **THEN** repeated cloud tiles SHALL overlap and crossfade at their horizontal edges
- **AND** repeated cloud tiles SHALL include offscreen overscan before entering from the right and after exiting to the left
- **AND** no hard vertical boundary between repeated images SHALL be visible in the hero region
- **AND** no new cloud mass SHALL abruptly appear inside the visible hero region

#### Scenario: Cloud assets preserve transparent canvas
- **GIVEN** the cloud assets are transparent top-hero canvases
- **WHEN** the cloud layer renders a repeated tile
- **THEN** the renderer SHALL preserve the cloud canvas aspect ratio without cropping away the designed transparent margins

#### Scenario: Clouds animate with depth-based parallax when motion is allowed
- **GIVEN** Reduce Motion is disabled
- **WHEN** the Subh home remains visible
- **THEN** the atmospheric cloud bands SHALL move horizontally in slow seamless loops
- **AND** `SubhDawnHeroCloudNear` SHALL move faster than `SubhDawnHeroCloudLow`
- **AND** `SubhDawnHeroCloudLow` SHALL move faster than `SubhDawnHeroCloudMid`
- **AND** `SubhDawnHeroCloudMid` SHALL move faster than `SubhDawnHeroCloudFar`
- **AND** `SubhDawnHeroCloudFar` SHALL move faster than `SubhDawnHeroCloudMist`
- **AND** the layers SHALL generally drift right-to-left

#### Scenario: Clouds are static when motion is reduced
- **GIVEN** Reduce Motion is enabled
- **WHEN** the Subh home renders
- **THEN** the atmospheric cloud bands SHALL render without horizontal animation
- **AND** the static cloud positions SHALL use deterministic phase offsets
- **AND** the static cloud positions SHALL NOT expose tile seams

#### Scenario: Clouds remain decorative only
- **GIVEN** the Subh home is visible
- **WHEN** the user interacts with home content
- **THEN** the atmospheric cloud layer SHALL NOT intercept taps, drags, or gestures
- **AND** the atmospheric cloud layer SHALL NOT appear in the accessibility tree
