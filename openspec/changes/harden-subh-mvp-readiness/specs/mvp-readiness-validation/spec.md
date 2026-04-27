## ADDED Requirements

### Requirement: MVP readiness evidence is explicit
Subh SHALL maintain executable and manual validation evidence for MVP readiness, separating simulator proof from physical-device alarm reliability proof.

#### Scenario: Simulator validation is run
- **WHEN** a contributor performs MVP readiness validation locally
- **THEN** the result SHALL include the exact build and test commands that were run
- **AND** it SHALL identify whether the Subh app target and configured test plan passed

#### Scenario: Device-only reliability remains unverified
- **WHEN** AlarmKit, notification fallback, permissions, timezone, DST, or location behavior has not been verified on the required device or simulator environment
- **THEN** the test plan SHALL keep that item as an open MVP gate
- **AND** Subh SHALL NOT claim wake reliability beyond the verified environment

### Requirement: Ordinary Fajr morning loop is the first MVP path
Subh SHALL prioritize proof of the ordinary Fajr morning loop before expanding advanced fasting, Qada, Ramadan, analytics, or content surfaces.

#### Scenario: MVP acceptance is reviewed
- **WHEN** maintainers review readiness for MVP
- **THEN** the first acceptance path SHALL cover onboarding, location/calculation readiness, permission handling, tomorrow home explanation, wake scheduling, completion logging, and calm reflection
- **AND** advanced observance workflows SHALL remain secondary unless they are necessary for the ordinary loop

### Requirement: MVP test plan reflects Subh product doctrine
The test plan SHALL describe Subh as a Fajr-centered morning system and SHALL organize validation around resolver correctness, wake reliability, degraded-state clarity, completion, and naming compatibility.

#### Scenario: Engineer reads the test plan
- **WHEN** an engineer opens the repository test plan
- **THEN** the plan SHALL use Subh and wake/morning language for non-compatibility surfaces
- **AND** compatibility-bound Suhoor storage or bundle names SHALL be called out as intentional exceptions rather than product framing
