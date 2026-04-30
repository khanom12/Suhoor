## ADDED Requirements

### Requirement: Wake Semantics Are Resolver-Owned
The system SHALL treat resolved wake-state semantics as resolver output, not as presentation-local or scheduler-local decisions.

#### Scenario: Hero consumes resolved wake state
- **GIVEN** a resolved active day payload
- **WHEN** the Morning Hero builds its snapshot
- **THEN** boundary regime, visual mode, relation copy, and adjuster availability SHALL come from `ResolvedMorningWakeState` or projections of it

#### Scenario: Adjustment window consumes resolved boundary
- **GIVEN** the user drags the hero wake handle
- **WHEN** the service clamps and persists the committed wake time
- **THEN** the clamp window SHALL come from the resolved wake boundary rather than a separate local final-third calculation
