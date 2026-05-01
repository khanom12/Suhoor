## MODIFIED Requirements

### Requirement: MVP home cards
The first-wave Subh home SHALL contain the MVP cards in this order: Tomorrow Morning, Next 10 Mornings, then Weekly Fajrcast.

#### Scenario: Home liquid glass stays shared and frosted
- **GIVEN** the Subh home renders liquid-glass cards or controls such as the hero wake-mode selector, Next 10 Mornings, Weekly Fajrcast, or settings
- **WHEN** those surfaces appear on the home screen
- **THEN** they SHALL use the shared home liquid-glass surface treatment
- **AND** the treatment SHALL provide a modestly increased frost/diffusion effect compared with the prior grouped home baseline
- **AND** future home cards and controls SHALL be able to reuse the same home surface treatment without local restyling
- **AND** non-home settings and detail grouped surfaces SHALL NOT be restyled by this home-specific adjustment

### Requirement: Cards navigate to details
The system SHALL allow the user to open detail surfaces from home cards while keeping settings available from the top-right home control.

#### Scenario: User taps home settings
- **GIVEN** the Subh home is visible
- **WHEN** the user looks at the top-right of the home screen
- **THEN** the settings control SHALL be visible there using the shared home liquid-glass treatment
- **AND** the bottom-right floating settings control SHALL NOT be shown
- **WHEN** the user taps the settings control
- **THEN** the app SHALL open the existing settings sheet
