## ADDED Requirements

### Requirement: Expected Delivery Plan Persistence
The system SHALL persist a compact local expected-delivery plan derived from resolver-materialized scheduled events.

#### Scenario: Expected deliveries survive cold start
- **GIVEN** Subh has scheduled future wake deliveries
- **WHEN** the app process restarts
- **THEN** the system SHALL be able to compare the current resolved plan, the persisted expected delivery plan, and pending platform state
- **AND** the persisted plan SHALL NOT become a source of wake time, wake mode, day purpose, prayer-time calculation, or completion truth

### Requirement: Actionable Delivery Repair
The system SHALL repair Subh-owned pending delivery drift after schedule reconciliation.

#### Scenario: Missing expected delivery is rescheduled
- **GIVEN** a future Subh wake delivery is expected
- **AND** the matching pending notification or AlarmKit delivery is missing
- **WHEN** delivery repair runs
- **THEN** the system SHALL schedule the expected delivery through the selected platform channel
- **AND** record a local repair result

#### Scenario: Mismatched expected delivery is replaced
- **GIVEN** a future Subh wake delivery is expected for one fire date
- **AND** pending platform state contains the matching identifier at a materially different fire date
- **WHEN** delivery repair runs
- **THEN** the system SHALL cancel the stale pending delivery
- **AND** schedule the expected delivery at the resolved fire date

#### Scenario: Unexpected Subh-owned delivery is cancelled
- **GIVEN** pending platform state contains a Subh-owned delivery inside the scheduling horizon
- **AND** that delivery is not expected by the current resolved plan or persisted repair scope
- **WHEN** delivery repair runs
- **THEN** the system SHALL cancel that delivery
- **AND** it SHALL NOT cancel non-Subh platform deliveries

### Requirement: Local Repair Diagnostics
The system SHALL record delivery repair diagnostics locally without remote telemetry.

#### Scenario: Repair result is recorded
- **GIVEN** delivery repair cancels, reschedules, skips, or cannot verify a delivery
- **WHEN** the repair transaction completes
- **THEN** the system SHALL record local counts for cancelled stale, rescheduled missing, rescheduled mismatched, unchanged, verification-limited, and failed deliveries
- **AND** diagnostics SHALL avoid raw location, remote analytics, and religious outcome inference

### Requirement: Debug Install Alarm Cleanup
Debug install reset SHALL clean Subh-owned platform deliveries across supported channels when explicitly enabled.

#### Scenario: Debug reset can access AlarmKit
- **GIVEN** debug install reset is explicitly enabled
- **AND** AlarmKit cleanup is available
- **WHEN** reset runs for a changed build fingerprint
- **THEN** pending notifications and Subh-owned AlarmKit identifiers in the scheduling horizon SHALL be cancelled

#### Scenario: Debug reset cannot verify AlarmKit cleanup
- **GIVEN** debug install reset is explicitly enabled
- **AND** AlarmKit cleanup is unavailable or unverified
- **WHEN** reset runs
- **THEN** the system SHALL record a local verification-limited warning
- **AND** it SHALL NOT claim that all AlarmKit deliveries were cleaned
