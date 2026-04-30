## MODIFIED Requirements

### Requirement: Morning resolution inputs
The system SHALL resolve a morning from Fajr start, supported Fajr end, location, timezone, calculation method, reliability state, user settings, context flags, temporary overrides, available institution or masjid context, and day-purpose inputs that distinguish date meaning from user intention.

#### Scenario: Inputs are available
- **GIVEN** location, timezone, calculation method, Fajr start, supported Fajr end, settings, context flags, fast-intention selections, and completion records are available
- **WHEN** the system resolves tomorrow morning
- **THEN** the result SHALL include the anchor window, wake plan, explanation, context flags, reliability state, trust notes, and resolved day purpose needed to explain the morning

#### Scenario: Location or calculation inputs are degraded
- **GIVEN** a required input is missing, stale, approximate, or denied
- **WHEN** the system resolves tomorrow morning
- **THEN** the result SHALL include a degraded trust or reliability state
- **AND** user-facing surfaces SHALL avoid presenting the morning as fully precise

### Requirement: Explanation is part of the resolved morning
The system SHALL store or expose enough derived state to explain why a morning resolved the way it did, including the difference between observance opportunity, user intention, wake classification, and completion credit.

#### Scenario: User opens a morning detail
- **GIVEN** a resolved morning has a wake time based on supported Fajr end
- **WHEN** the user opens detail
- **THEN** the system SHALL explain the relevant anchor, buffer, calculation method, provider or approximation state, any applied context flags, and the resolved purpose facts behind the morning
