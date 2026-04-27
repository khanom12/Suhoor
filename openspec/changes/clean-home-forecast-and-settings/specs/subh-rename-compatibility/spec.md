## ADDED Requirements

### Requirement: Settings sheet uses neutral readable chrome
The settings sheet SHALL use neutral high-contrast chrome rather than the warm home image background.

#### Scenario: Settings opens from home
- **GIVEN** the user opens settings from the home screen
- **WHEN** the settings sheet appears
- **THEN** the sheet background SHALL be neutral and readable
- **AND** warm/orange home background tones SHALL NOT bleed through the settings content

### Requirement: Warning badges avoid orange-heavy styling
Settings warning states SHALL use a calmer non-orange visual treatment while preserving readable contrast.

#### Scenario: A warning badge is shown in settings
- **WHEN** the badge renders
- **THEN** it SHALL remain distinguishable from neutral and success states
- **AND** it SHALL NOT rely on orange foreground or orange wash backgrounds
