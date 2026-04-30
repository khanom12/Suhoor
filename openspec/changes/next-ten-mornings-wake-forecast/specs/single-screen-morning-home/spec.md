## MODIFIED Requirements

### Requirement: MVP home cards
The first-wave Subh home SHALL contain the MVP cards: Tomorrow Morning, Weekly Fajrcast, and a Next 10 Mornings wake forecast.

#### Scenario: Home snapshot is available
- **GIVEN** the app has resolved schedule data
- **WHEN** the Subh home renders
- **THEN** it SHALL show a Tomorrow Morning hero
- **AND** it SHALL show the Weekly Fajrcast
- **AND** it SHALL show the Next 10 Mornings card with up to ten upcoming future mornings
- **AND** the card header SHALL read `NEXT 10 MORNINGS`
- **AND** the card SHALL NOT show the legacy `10-Day Wake Forecast` title or `Next 10 mornings` subtitle

#### Scenario: User scans a forecast row
- **GIVEN** a future morning is visible in the Next 10 Mornings card
- **WHEN** the row renders
- **THEN** the row SHALL show a Gregorian-first date label
- **AND** the row SHALL show compact state tags
- **AND** the row SHALL show the resolved wake time or concise wake status
- **AND** the row SHALL NOT show a visible subtitle, bullet-separated explanation, Fajr relation prose, adjustment prose, provenance prose, or latest-wake-cap prose

#### Scenario: Forecast row state tags are resolved
- **GIVEN** a future morning has resolved day context and fasting tag computation output
- **WHEN** the Next 10 Mornings presentation prepares the row
- **THEN** it SHALL show `[Fajr]` only as the fallback tag for an ordinary Fajr morning
- **AND** it SHALL show `[Ramadan]` alone for Ramadan
- **AND** it SHALL show `[Fasting]` only when fasting was intended or planned
- **AND** it SHALL show opportunity tags such as `[Ashura]`, `[Arafah]`, `[White Days]`, `[Dhul Hijjah]`, or `[Shawwal 6]` without `[Fasting]` when the fast was not intended
- **AND** it SHALL suppress Monday/Thursday as an opportunity-only tag
- **AND** it SHALL cap visible tags without wrapping them
- **AND** it SHALL preserve full tag meaning in accessibility text

#### Scenario: User opens a forecast row
- **GIVEN** the Next 10 Mornings card is visible
- **WHEN** the user taps a forecast row
- **THEN** the app SHALL navigate to that morning's detail screen
- **AND** individual tags SHALL NOT be separate tap targets

#### Scenario: Forecast data is unavailable
- **GIVEN** no upcoming mornings can be resolved
- **WHEN** the Next 10 Mornings card renders
- **THEN** the card SHALL show the `NEXT 10 MORNINGS` header
- **AND** it SHALL show calm unavailable copy instead of fake wake times or fake tags
