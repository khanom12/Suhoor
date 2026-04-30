# morning-day-purpose-resolution Specification

## Purpose

Define how Subh resolves each date into observance opportunities, user intention, wake classification, required actions, outcomes, and analytics credits without collapsing them into a single day state.

## ADDED Requirements

### Requirement: Dates expose observance opportunities independent of user intention
The system SHALL derive observance opportunities for a date without requiring the user to plan or complete those observances.

#### Scenario: Monday opportunity remains default Fajr
- **GIVEN** a date falls on Monday or Thursday
- **AND** the user has not selected a fast intention for the date
- **WHEN** the date is resolved
- **THEN** the resolved day SHALL include a Monday/Thursday observance opportunity
- **AND** the resolved intention SHALL remain default Fajr
- **AND** the wake classification SHALL remain the default Fajr wake classification
- **AND** the system SHALL NOT require fast completion for that date

#### Scenario: White Day opportunity remains default Fajr
- **GIVEN** a date is a White Day
- **AND** the user has not selected a fast intention for the date
- **WHEN** the date is resolved
- **THEN** the resolved day SHALL include a White Days observance opportunity
- **AND** the resolved intention SHALL remain default Fajr
- **AND** analytics SHALL emit opportunity-available credit but no planned or missed-after-planning credit

### Requirement: User intention drives active day purpose
The system SHALL use resolved user intention to distinguish default Fajr, fast, Tahajjud, and quiet days.

#### Scenario: User plans voluntary fast on a Monday opportunity
- **GIVEN** a date has a Monday/Thursday opportunity
- **AND** the user selects a voluntary fast intention for that date
- **WHEN** the date is resolved
- **THEN** the resolved intention SHALL be fast
- **AND** selected opportunity IDs SHALL include the Monday/Thursday opportunity when it is the compatible opportunity
- **AND** the wake classification SHALL reflect the resolved wake result without creating a second wake engine
- **AND** the system SHALL include fast completion as a relevant action

#### Scenario: User chooses qada on a Sunnah opportunity date
- **GIVEN** a date has a Sunnah fast opportunity
- **AND** the user selects qada fast intention
- **WHEN** the date is resolved
- **THEN** the resolved intention SHALL be fast with qada makeup intent
- **AND** the Sunnah opportunity SHALL remain available
- **AND** completion credit SHALL target qada rather than the Sunnah opportunity

### Requirement: Ramadan resolves as an auto-obligatory fast context
The system SHALL treat Ramadan as an auto-obligatory fasting context unless a quiet or future exception policy suppresses prompts.

#### Scenario: Ramadan date has no explicit user selection
- **GIVEN** a date is in Ramadan
- **AND** the user has not selected a quiet day
- **WHEN** the date is resolved
- **THEN** the resolved day SHALL include a Ramadan opportunity
- **AND** the resolved intention SHALL be fast with Ramadan obligatory intent
- **AND** analytics SHALL emit opportunity-available and planned credits for Ramadan

### Requirement: Optional opportunities are not missed unless planned
The system SHALL only emit missed-after-planning credit when the user planned or auto-planned the observance.

#### Scenario: User ignores Arafah opportunity
- **GIVEN** a date has an Arafah opportunity
- **AND** the user keeps the default Fajr intention
- **WHEN** analytics credits are resolved
- **THEN** the system SHALL emit Arafah opportunity-available credit
- **AND** it MAY emit kept-default credit for reporting
- **AND** it SHALL NOT emit Arafah missed-after-planning credit

#### Scenario: User plans but does not complete voluntary fast
- **GIVEN** a date has a White Days opportunity
- **AND** the user plans a voluntary fast for that opportunity
- **AND** the user logs the fast as not completed
- **WHEN** analytics credits are resolved
- **THEN** the system SHALL emit White Days opportunity-available credit
- **AND** it SHALL emit White Days planned credit
- **AND** it SHALL emit White Days missed-after-planning credit

### Requirement: Forbidden fast days cannot be treated as normal planned fasts
The system SHALL mark forbidden fasting dates as forbidden opportunities and SHALL NOT offer normal fast planning behavior for them.

#### Scenario: Eid date is resolved
- **GIVEN** a date is Eid al-Fitr or Eid al-Adha
- **WHEN** the date is resolved
- **THEN** the resolved day SHALL include a forbidden observance opportunity
- **AND** the system SHALL NOT auto-plan a fast
- **AND** the default intention SHALL remain default Fajr unless the user has a quiet or other non-fast intention

#### Scenario: User logs completed fast on a forbidden date
- **GIVEN** a date has a forbidden fast opportunity
- **AND** a completed fast record exists for the date
- **WHEN** analytics credits are resolved
- **THEN** the system SHALL emit invalid-forbidden-fast credit
- **AND** it SHALL NOT emit completed Sunnah or Ramadan fast credit

### Requirement: Analytics count credits rather than visual tags
The system SHALL aggregate future progress metrics from observance credits rather than raw `DayTag` values.

#### Scenario: Annual Monday/Thursday report
- **GIVEN** a date range includes multiple Monday/Thursday opportunities
- **WHEN** the report counts opportunities, planned fasts, and completed fasts
- **THEN** opportunity count SHALL use `opportunityAvailable` credits
- **AND** planned count SHALL use `planned` credits
- **AND** completed count SHALL use `completed` credits
- **AND** unplanned opportunities SHALL NOT count as missed planned fasts
