## MODIFIED Requirements

### Requirement: Morning resolution inputs
The system SHALL resolve a morning from Fajr start, supported Fajr end, location, timezone, calculation method, reliability state, user settings, context flags, anchored planning intentions, temporary overrides, and available institution or masjid context.

#### Scenario: Anchored planning meaning feeds resolution
- **GIVEN** a future morning has an anchored user planning record such as Gregorian date, Hijri date, observance, weekday pattern, or Hijri month window
- **WHEN** the system resolves that morning
- **THEN** the anchored planning meaning SHALL be included before wake-state and day-purpose resolution
- **AND** the resolver SHALL NOT infer user intention merely from generated display tags

#### Scenario: Generated default display remains non-durable
- **GIVEN** a future generated day is visible in Next 10 or month browsing with no user edit
- **WHEN** the morning resolver builds display context
- **THEN** the day may show generated meaning or opportunity tags
- **AND** it SHALL NOT become a durable user intention unless selected or auto-obligatory by product rules
