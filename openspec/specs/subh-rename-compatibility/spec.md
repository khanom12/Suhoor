# subh-rename-compatibility Specification

## Purpose
TBD - created by archiving change define-subh-morning-system. Update Purpose after archive.
## Requirements
### Requirement: Visible identity is Subh
The system SHALL use Subh as the canonical visible product name across app display name, primary navigation, onboarding, settings copy, and project/test surfaces changed in this wave.

#### Scenario: User views app identity
- **GIVEN** the user sees the installed app name or primary in-app surfaces
- **WHEN** product identity is shown
- **THEN** the visible name SHALL be Subh
- **AND** new visible copy SHALL NOT introduce Suhoor as the product name

### Requirement: Bundle identifier is preserved in wave one
The system SHALL preserve the existing app bundle identifier during the first Subh rename wave.

#### Scenario: Project settings are inspected after rename
- **GIVEN** the Xcode project has been renamed to Subh
- **WHEN** build settings are inspected
- **THEN** the app target's `PRODUCT_BUNDLE_IDENTIFIER` SHALL remain `khanomar.Suhoor`

### Requirement: Legacy storage namespaces remain readable
The system SHALL continue reading existing persisted data from legacy storage namespaces during the first Subh rename wave.

#### Scenario: Existing user data was written by the Suhoor build
- **GIVEN** user defaults or local stores contain data under existing Suhoor-era keys
- **WHEN** Subh launches after the rename
- **THEN** the system SHALL read and preserve that data
- **AND** it SHALL NOT delete or reset it solely because the visible product name changed

### Requirement: Legacy namespace is documented
The system SHALL document legacy storage namespaces as compatibility surfaces until a later explicit migration proposal changes them.

#### Scenario: Engineer reviews rename behavior
- **GIVEN** an engineer reads OpenSpec or implementation notes
- **WHEN** they encounter `Suhoor.*` storage or bundle identifiers after the rename
- **THEN** the documentation SHALL identify them as intentional compatibility names

