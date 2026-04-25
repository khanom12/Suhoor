## MODIFIED Requirements

### Requirement: Legacy storage namespaces remain readable
The system SHALL continue reading existing persisted data from legacy storage namespaces during the first Subh rename and performance-prune waves.

#### Scenario: Existing user data was written by the Suhoor build
- **GIVEN** user defaults or local stores contain data under existing Suhoor-era keys
- **WHEN** Subh launches after the rename and MVP performance prune
- **THEN** the system SHALL read and preserve retained settings needed by the MVP
- **AND** it SHALL NOT delete or reset dormant legacy domain data solely because the visible product name or production runtime path changed

### Requirement: Legacy namespace is documented
The system SHALL document legacy storage namespaces and dormant old domain data as compatibility surfaces until a later explicit migration proposal changes them.

#### Scenario: Engineer reviews prune behavior
- **GIVEN** an engineer reads OpenSpec or implementation notes
- **WHEN** they encounter `Suhoor.*` storage, bundle identifiers, or dormant fasting/planning/Qada/progress data after the prune
- **THEN** the documentation SHALL identify them as intentional compatibility names or preserved dormant data
