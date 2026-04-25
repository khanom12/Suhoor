## ADDED Requirements

### Requirement: Renamed build surfaces preserve app data identity
The system SHALL rename the project, scheme, app target, test target, app module, app entry point, and primary folders to Subh while preserving the app target bundle identifier.

#### Scenario: Xcode surfaces after rename
- **GIVEN** the rename wave has been applied
- **WHEN** the project list is generated for `Subh.xcodeproj`
- **THEN** the app scheme SHALL be named Subh
- **AND** the app target SHALL build as module Subh
- **AND** `PRODUCT_BUNDLE_IDENTIFIER` SHALL remain `khanomar.Suhoor`

### Requirement: Legacy storage keys are not mechanically renamed
The system SHALL preserve existing persisted storage keys and document remaining Suhoor-era storage names as compatibility surfaces.

#### Scenario: Existing local data after rename
- **GIVEN** a user has existing data persisted by a Suhoor-era build
- **WHEN** the Subh build launches
- **THEN** the app SHALL continue reading that data from the same keys
- **AND** the rename SHALL NOT reset defaults solely because visible identity changed
