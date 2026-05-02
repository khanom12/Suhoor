## MODIFIED Requirements

### Requirement: Morning resolution inputs
The system SHALL resolve a morning from Fajr start, supported Fajr end, location, timezone, calculation method, reliability state, user settings, context flags, temporary overrides, and available institution or masjid context. Delivery-layer feedback MAY inform schedule or reliability status, but SHALL NOT redefine day meaning, user intention, wake boundary, wake time, alarm activation, or completion credit.

#### Scenario: Inputs are available
- **GIVEN** location, timezone, calculation method, Fajr start, supported Fajr end, settings, and context flags are available
- **WHEN** the system resolves tomorrow morning
- **THEN** the result SHALL include the anchor window, wake plan, explanation, context flags, reliability state, and trust notes needed to explain the morning

#### Scenario: Location or calculation inputs are degraded
- **GIVEN** a required input is missing, stale, approximate, or denied
- **WHEN** the system resolves tomorrow morning
- **THEN** the result SHALL include a degraded trust or reliability state
- **AND** user-facing surfaces SHALL avoid presenting the morning as fully precise

#### Scenario: Delivery status does not rewrite morning intent
- **GIVEN** a resolved morning has active Fajr, Fast, or Tahajjud wake intent
- **WHEN** downstream alarm delivery reports permission blocked, fallback notification delivery, missing pending state, scheduling failure, or verification unavailable
- **THEN** morning resolution SHALL preserve the resolved day meaning, user intention, wake boundary, wake time, and alarm activation
- **AND** it SHALL expose only schedule or delivery status as degraded, blocked, failed, or limited
- **AND** it SHALL NOT convert the morning to Quiet, off, no-anchor, unavailable, or a different religious/product state unless resolver-owned inputs explicitly require that state
