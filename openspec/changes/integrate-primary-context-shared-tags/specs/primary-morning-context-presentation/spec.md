## ADDED Requirements

### Requirement: Primary Morning Context explains day meaning
The system SHALL expose a Primary Morning Context presentation derived from the resolved morning graph and shared tag snapshot.

#### Scenario: Presentation is built
- **GIVEN** a resolved day includes `ResolvedDayPurpose`
- **WHEN** Primary Morning Context presentation is requested
- **THEN** the presentation SHALL include a primary kind, title, optional body, compact tags, expanded tags, and accessibility summary
- **AND** it SHALL preserve whether the date is ordinary, opportunity-only, selected for Suhoor, selected for a fasting purpose, Ramadan, forbidden for fasting, Quiet, or unavailable

#### Scenario: Presentation copy renders near Hero
- **GIVEN** the Home Hero already presents wake time, wake relation, boundary visual, quick selector, and Quiet delivery state
- **WHEN** Primary Morning Context copy is built
- **THEN** it SHALL NOT repeat Hero wake-mechanic lines such as wake offset, Fajr boundary relation, or no-alarm delivery copy
- **AND** it SHALL focus on day meaning and selected-purpose explanation

### Requirement: Home compact context appears only when useful
The Home surface SHALL render compact Primary Morning Context after the Hero and before Next 7 Days when the resolved day has meaningful context or a selected modifier.

#### Scenario: Ordinary default Fajr morning
- **GIVEN** tomorrow is an ordinary default Fajr morning
- **AND** there is no selected override, Quiet state, opportunity, forbidden state, Ramadan state, or unavailable context state
- **WHEN** Home renders
- **THEN** compact Primary Morning Context SHALL be hidden

#### Scenario: Opportunity-only morning
- **GIVEN** tomorrow has a recognized Sunnah fasting opportunity
- **AND** the resolved intention remains default Fajr
- **WHEN** Home renders
- **THEN** compact Primary Morning Context SHALL show the opportunity as recognized
- **AND** it SHALL say Suhoor has not been planned for that morning

#### Scenario: Quiet meaningful morning
- **GIVEN** tomorrow has a recognized opportunity or selected fasting purpose
- **AND** Quiet is selected
- **WHEN** Home renders compact Primary Morning Context
- **THEN** the context SHALL preserve the day meaning
- **AND** it SHALL describe Quiet as a modifier without saying the opportunity was deleted

### Requirement: Alarm Detail reuses expanded Primary Morning Context
Alarm Detail SHALL consume the same Primary Morning Context presentation payload in expanded density instead of maintaining a separate context-copy engine.

#### Scenario: User opens an ordinary selected day
- **GIVEN** the user opens Alarm Detail for an ordinary default Fajr date
- **WHEN** the detail context renders
- **THEN** expanded Primary Morning Context SHALL be visible
- **AND** it SHALL explain that no special fasting opportunity is recognized for the day

#### Scenario: Qada is selected on an opportunity day
- **GIVEN** the user opens Alarm Detail for a White Days opportunity
- **AND** the selected fasting purpose is Qada
- **WHEN** expanded Primary Morning Context renders
- **THEN** it SHALL show Qada as the user's plan
- **AND** it SHALL mention the White Days opportunity as day meaning
- **AND** it SHALL NOT present the White Days opportunity as completion credit

#### Scenario: Ramadan is selected
- **GIVEN** the selected day resolves to Ramadan
- **WHEN** expanded Primary Morning Context renders
- **THEN** it SHALL show Ramadan as the locked fasting purpose
- **AND** it SHALL suppress optional Sunnah opportunities as alternatives

### Requirement: Forbidden and unavailable states are explicit
Primary Morning Context SHALL surface forbidden fasting and unavailable day-context states without claiming false certainty.

#### Scenario: Forbidden fasting day
- **GIVEN** the resolved day has Eid or Tashreeq forbidden fasting context
- **WHEN** Primary Morning Context renders
- **THEN** it SHALL say fasting is unavailable for the day
- **AND** it SHALL NOT show ordinary fasting-purpose controls as if the date were a normal fast plan

#### Scenario: Day context cannot be resolved
- **GIVEN** prayer data is available
- **AND** day-context data is unavailable or conflicting
- **WHEN** Primary Morning Context renders
- **THEN** it SHALL say additional day context is unavailable
- **AND** it SHALL NOT claim that no opportunities exist
