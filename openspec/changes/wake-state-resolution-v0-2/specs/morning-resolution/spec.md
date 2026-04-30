## ADDED Requirements

### Requirement: Morning Resolution Emits Wake-State Handoff
Morning resolution SHALL expose a wake-state handoff that surface snapshots and scheduler handoff code can consume without rebuilding alarm semantics.

#### Scenario: Early-worship contexts share one boundary
- **GIVEN** a morning is resolved as intended fasting, Ramadan fasting, Qada fast, Sunnah/custom fast, Tahajjud, or fasting plus Tahajjud
- **WHEN** the wake-state handoff is built
- **THEN** it SHALL use one `earlyWorshipWindow` from final-third start to Fajr begins and SHALL NOT create competing fasting and Tahajjud boundaries

#### Scenario: Missing early-worship boundary is truthful
- **GIVEN** Fajr begins is known but Maghrib is missing or invalid for final-third calculation
- **WHEN** an early-worship wake state is resolved
- **THEN** the wake-state handoff SHALL mark the boundary unavailable and SHALL NOT invent final-third start
