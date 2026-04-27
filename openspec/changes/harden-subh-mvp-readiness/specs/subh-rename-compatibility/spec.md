## ADDED Requirements

### Requirement: Non-compatibility surfaces use Subh and wake language
The system SHALL use Subh and wake/morning language in docs, tests, and presentation-only symbols unless a surface is intentionally preserved for storage, migration, bundle, or backwards-compatibility reasons.

#### Scenario: Documentation is updated after the rename
- **GIVEN** a repository document is not describing a legacy storage, bundle, or migration compatibility surface
- **WHEN** the document describes the product, test plan, or MVP behavior
- **THEN** it SHALL use Subh as the product name
- **AND** it SHALL use wake or Fajr morning language instead of Suhoor-only framing

#### Scenario: Compatibility-bound symbol remains
- **GIVEN** a symbol, key, or identifier is tied to persisted data, bundle identity, AlarmKit metadata compatibility, or documented migration behavior
- **WHEN** rename cleanup is performed
- **THEN** the symbol MAY retain Suhoor naming until an explicit migration proposal changes it
- **AND** the compatibility reason SHALL remain documented
