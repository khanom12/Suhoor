## ADDED Requirements

### Requirement: Morning resolution consumes resolved prayer-window metadata
Morning resolution SHALL consume a single resolved prayer-window contract that includes Fajr begin, Fajr end, calculation method identity, source metadata, applied adjustments, timezone, and validation state.

#### Scenario: Resolved prayer window is available
- **GIVEN** Subh has resolved a valid prayer window for a morning
- **WHEN** the morning resolver computes wake anchors, events, explanation, and presentation snapshots
- **THEN** those consumers SHALL use the same adjusted Fajr begin and adjusted Fajr end values from the prayer window
- **AND** they SHALL NOT recompute Fajr begin or Fajr end in SwiftUI views or renderers.

### Requirement: Missing Fajr end remains degraded instead of guessed
Morning resolution SHALL preserve missing or invalid Fajr end as degraded data unless a configured fallback source explicitly succeeds.

#### Scenario: Fajr end is unavailable
- **GIVEN** Fajr begin is available but Fajr end is missing or invalid
- **WHEN** the morning resolver builds wake planning and presentation data
- **THEN** the resolver SHALL avoid treating a renderer-derived offset as Fajr end
- **AND** user-facing surfaces SHALL avoid precise Fajr-end relation text for that day.
