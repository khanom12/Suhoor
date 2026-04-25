## ADDED Requirements

### Requirement: Morning resolution inputs
The system SHALL resolve a morning from Fajr start, supported Fajr end, location, timezone, calculation method, reliability state, user settings, context flags, temporary overrides, and available institution or masjid context.

#### Scenario: Inputs are available
- **GIVEN** location, timezone, calculation method, Fajr start, supported Fajr end, settings, and context flags are available
- **WHEN** the system resolves tomorrow morning
- **THEN** the result SHALL include the anchor window, wake plan, explanation, context flags, reliability state, and trust notes needed to explain the morning

#### Scenario: Location or calculation inputs are degraded
- **GIVEN** a required input is missing, stale, approximate, or denied
- **WHEN** the system resolves tomorrow morning
- **THEN** the result SHALL include a degraded trust or reliability state
- **AND** user-facing surfaces SHALL avoid presenting the morning as fully precise

### Requirement: Deterministic calculation outside SwiftUI
The system SHALL keep morning-resolution, prayer-time, scheduling, and migration rules outside SwiftUI view bodies.

#### Scenario: Home renders a resolved morning
- **GIVEN** a SwiftUI home view is rendering tomorrow morning
- **WHEN** it needs wake time, Fajr window, context flags, or trust notes
- **THEN** it SHALL consume a presentation snapshot or provider result
- **AND** it SHALL NOT compute prayer times or migration rules inside the view body

### Requirement: Explanation is part of the resolved morning
The system SHALL store or expose enough derived state to explain why a morning resolved the way it did.

#### Scenario: User opens a morning detail
- **GIVEN** a resolved morning has a wake time based on supported Fajr end
- **WHEN** the user opens detail
- **THEN** the system SHALL explain the relevant anchor, buffer, calculation method, provider or approximation state, and any applied context flags
