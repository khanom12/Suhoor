## MODIFIED Requirements

### Requirement: Deterministic calculation outside SwiftUI
The system SHALL keep morning-resolution, prayer-time, scheduling, migration, and wake-time rules outside SwiftUI view bodies and local presentation recomputation.

#### Scenario: Home renders a resolved morning
- **GIVEN** a SwiftUI home view is rendering tomorrow morning
- **WHEN** it needs wake time, Fajr window, context flags, or trust notes
- **THEN** it SHALL consume a presentation snapshot, resolved schedule, decision log, or provider result
- **AND** it SHALL NOT compute prayer times, migration rules, or wake offsets inside the view body

### Requirement: Explanation is part of the resolved morning
The system SHALL store or expose enough derived state to explain why a morning resolved the way it did, including the resolved wake anchor and wake time.

#### Scenario: User opens a morning detail
- **GIVEN** a resolved morning has a wake time based on supported Fajr end
- **WHEN** the user opens detail
- **THEN** the system SHALL explain the relevant anchor, buffer, calculation method, provider or approximation state, and any applied context flags from the resolved morning
- **AND** it SHALL NOT produce a contradictory explanation by recomputing the wake from legacy Fajr-start offsets
