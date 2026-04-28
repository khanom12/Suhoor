## ADDED Requirements

### Requirement: Home Weekly Fajrcast follows v3 focused-day contract
The Weekly Fajrcast card on the Subh home surface SHALL preserve the anchored seven-day window while applying the v3 focused-day footer, accessibility, and dynamic sizing rules.

#### Scenario: User focuses a past visible day
- **GIVEN** the Subh home Weekly Fajrcast shows an anchored seven-day window
- **WHEN** the user focuses a previous visible day
- **THEN** the visible date range SHALL remain unchanged
- **AND** the footer SHALL describe that focused previous day using past tense
- **AND** the accessibility summary SHALL describe that focused previous day

#### Scenario: User focuses another visible day at larger text size
- **GIVEN** the user uses a larger text-size setting
- **WHEN** the Subh home Weekly Fajrcast renders
- **THEN** the card SHALL grow according to v3 guardrails
- **AND** it SHALL preserve readable axis, callout, week pill, and footer text
