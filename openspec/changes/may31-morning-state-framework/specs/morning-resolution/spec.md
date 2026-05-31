## ADDED Requirements

### Requirement: May 31 morning state resolution
The system SHALL resolve May 31 morning state from the selected wake purpose, one-morning Quiet override, global Pause policy, current time, location-derived prayer times, fasting/opportunity context, wake execution state, and previous-morning Fajr prayer completion eligibility.

#### Scenario: Planning before midnight resolves tomorrow
- **GIVEN** valid prayer-time data, selected Fajr purpose, and no one-morning Quiet override
- **WHEN** the user opens Home before midnight for the next relevant morning
- **THEN** the resolved morning label SHALL be `Tomorrow Morning`
- **AND** the resolved state SHALL include wake purpose, wake time, context explanation inputs, and active alarm delivery state

#### Scenario: Same target after midnight resolves today
- **GIVEN** the same target morning remains before Fajr end after midnight
- **WHEN** the morning is re-resolved
- **THEN** the resolved morning label SHALL be `Today Morning`
- **AND** the saved purpose and wake plan SHALL NOT reset because the calendar date changed

#### Scenario: Quiet preserves purpose
- **GIVEN** a target morning has selected Suhoor or Fajr purpose and saved purpose-specific wake settings
- **WHEN** the user confirms one-morning Quiet for that target
- **THEN** the resolved delivery state SHALL be Quiet for that morning only
- **AND** the selected purpose and saved wake settings SHALL remain available for restoration

### Requirement: Suhoor boundary and cutoff resolution
The system SHALL calculate Suhoor eligibility from the daily last-third-of-night boundary and Fajr begins cutoff rather than hard-coded clock examples.

#### Scenario: Last-third boundary is calculated
- **GIVEN** valid sunset or Maghrib for the prior evening and Fajr begins for the target morning
- **WHEN** Suhoor window start is resolved
- **THEN** the start SHALL equal `Fajr begins - ((Fajr begins - prior night start) / 3)`
- **AND** example times from specifications SHALL NOT be hard-coded

#### Scenario: Suhoor remains switchable before window
- **GIVEN** the current time is before the Suhoor window begins
- **WHEN** the user switches between Suhoor and Fajr
- **THEN** the resolver SHALL allow the change without active-session cancellation confirmation

#### Scenario: Suhoor is blocked after latest creation cutoff
- **GIVEN** the current time is later than `Fajr begins - 6 minutes`
- **WHEN** the user attempts to newly schedule Suhoor for Today Morning
- **THEN** the resolver SHALL reject the mutation
- **AND** the presentation state SHALL explain that it is too close to Fajr to schedule Suhoor for Today Morning

### Requirement: Late Fajr prompt eligibility
The system SHALL keep previous-morning Fajr prayer completion eligibility separate from the Hero target after Fajr end.

#### Scenario: Same-day late prompt is eligible
- **GIVEN** Fajr ended for the previous relevant morning and Fajr prayer completion was not logged
- **WHEN** the current calendar day is still the same day as that Fajr
- **THEN** the resolved Home state SHALL include a late Fajr prompt with CTA `I Prayed Fajr Earlier Today`
- **AND** the Hero target SHALL resolve to the next relevant morning

#### Scenario: Next-day late prompt is eligible
- **GIVEN** Fajr ended for the previous relevant morning and Fajr prayer completion was not logged
- **WHEN** the current calendar day is after midnight but before the late prompt expiry boundary
- **THEN** the resolved Home state SHALL include a late Fajr prompt with CTA `I Prayed Fajr Yesterday Morning`

#### Scenario: Late prompt expires at next relevant wake window
- **GIVEN** a late Fajr prompt is eligible
- **WHEN** the next selected purpose's wake window begins
- **THEN** the late prompt SHALL no longer be resolved for Home

## MODIFIED Requirements

### Requirement: Wake, prayer, fasting, Quiet, and delivery states remain separate
The system SHALL keep awake confirmation, Fajr prayer confirmation, fasting intent, fast completion, Quiet Morning, alarm delivery, and unconfirmed execution outcomes as separate state concepts.

#### Scenario: Awake confirmation does not confirm prayer
- **GIVEN** a user confirms awake for Fajr
- **WHEN** the morning state is updated
- **THEN** `confirmedAwakeForFajr` SHALL be recorded
- **AND** `fajrPrayerConfirmed` SHALL remain unconfirmed until the user explicitly confirms prayer with `I Prayed Fajr`

#### Scenario: Suhoor confirmation does not complete Fajr or the fast
- **GIVEN** a user confirms awake for Suhoor
- **WHEN** the morning state is updated
- **THEN** `confirmedAwakeForSuhoor` SHALL be recorded
- **AND** remaining Suhoor wake checks SHALL be eligible for cancellation
- **AND** no full Fajr wake-check session SHALL be created unless the user explicitly opts into Fajr follow-up
- **AND** Fajr wake acknowledgement, Fajr prayer completion, and fast completion SHALL remain unconfirmed

#### Scenario: Alarm stop is operational only
- **GIVEN** a platform alarm is stopped, dismissed, or otherwise no longer sounding
- **WHEN** Subh records or observes that event
- **THEN** the Wake Session SHALL record awake acknowledgement only when the active execution contract treats system dismissal as acknowledgement
- **AND** the source SHALL remain available for analytics/debugging
- **AND** the system SHALL NOT infer Fajr prayer, fast completion, or missed prayer from the platform stop

#### Scenario: Quiet Morning is intentional suppression
- **GIVEN** the user chooses Quiet for a target morning
- **WHEN** the user confirms the Quiet action
- **THEN** the morning SHALL record `quietMorning` or an equivalent one-morning quiet delivery override
- **AND** the selected Suhoor/Fajr purpose and saved wake settings SHALL be preserved
- **AND** the system SHALL NOT treat the quiet outcome as permission failure, delivery failure, or missed prayer

#### Scenario: Expired wake execution remains factual
- **GIVEN** the wake window passes without user confirmation
- **WHEN** the Wake Session expires
- **THEN** the system SHALL record an unconfirmed or expired-unconfirmed wake outcome
- **AND** the system SHALL NOT automatically record a missed Fajr prayer
