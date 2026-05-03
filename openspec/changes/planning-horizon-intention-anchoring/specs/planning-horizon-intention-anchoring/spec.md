## ADDED Requirements

### Requirement: Planning horizons are separate concepts
The system SHALL distinguish knowledge range, display horizon, edit horizon, active scheduled horizon, and history horizon.

#### Scenario: Displayed future rows are not automatically scheduled
- **GIVEN** Subh can resolve more future mornings than it should schedule on the platform
- **WHEN** Next 10, Weekly Fajrcast, or month browsing displays future resolved rows
- **THEN** those rows SHALL belong to the display or edit horizon
- **AND** they SHALL NOT become active scheduled platform deliveries unless the active window builder explicitly includes them in the active scheduled horizon

#### Scenario: Active window exposes schedule scope explicitly
- **GIVEN** an active window contains visible days and a smaller scheduled horizon
- **WHEN** alarm delivery builds a delivery plan
- **THEN** delivery SHALL consume only the active scheduled horizon
- **AND** visible-only days SHALL remain display/planning context

### Requirement: Generated default days are not durable decisions
The system SHALL NOT persist generated default future days as date-specific user decisions merely because they were displayed, previewed, cached, or browsed.

#### Scenario: Next 10 browsing stores nothing
- **GIVEN** Next 10 displays generated Fajr, Ramadan, White Days, or other opportunity tags
- **WHEN** the user only views the rows
- **THEN** no durable date-specific planning record SHALL be created
- **AND** no alarm SHALL be scheduled solely from row visibility

#### Scenario: Month browsing stores nothing until the user acts
- **GIVEN** the user opens a Hijri or Gregorian month view
- **WHEN** generated days are displayed without an edit
- **THEN** Subh SHALL NOT create durable day-specific source records
- **AND** Subh SHALL NOT schedule platform deliveries from those generated month rows

### Requirement: Future user decisions are anchored
The system SHALL persist future user planning decisions with an explicit anchor that captures what the user meant.

#### Scenario: User chooses Fast Arafah
- **GIVEN** a future date is displayed as Arafah
- **WHEN** the user chooses to fast Arafah
- **THEN** the durable planning record SHALL be anchored to the Arafah observance or Hijri date meaning
- **AND** the plan SHALL be eligible to move if Hijri calendar adjustment moves that observance before the morning becomes historical

#### Scenario: User chooses Fast this date
- **GIVEN** a future Gregorian date displays an observance opportunity
- **WHEN** the user chooses to fast this date rather than the observance
- **THEN** the durable planning record SHALL be anchored to that Gregorian date
- **AND** it SHALL stay on that Gregorian date if later Hijri adjustment changes the visible observance label

#### Scenario: Recurring Monday and Thursday plan uses weekday anchor
- **GIVEN** the user creates a recurring Monday/Thursday fast plan
- **WHEN** the durable record is saved
- **THEN** the record SHALL be anchored to the weekday pattern
- **AND** generated future occurrences SHALL resolve from that weekday anchor rather than from stored default rows

### Requirement: Hijri adjustment re-resolves future anchored intentions
Future intentions anchored to Hijri dates, Hijri month windows, or observances SHALL re-resolve when Hijri/calendar adjustment changes the mapped Gregorian dates.

#### Scenario: Observance-anchored plan moves with Hijri adjustment
- **GIVEN** an Arafah or Ashura fast plan is anchored to the observance
- **WHEN** a Hijri month adjustment moves that observance from one Gregorian date to another before completion
- **THEN** the future plan SHALL move to the newly resolved Gregorian date
- **AND** Subh SHALL record review/explanation state that the plan moved because the Hijri calendar changed

#### Scenario: Gregorian-date plan stays fixed
- **GIVEN** a user planned a fast on a specific Gregorian date
- **WHEN** a Hijri adjustment changes the observance label for that date
- **THEN** the plan SHALL remain on the original Gregorian date
- **AND** any explanation SHALL describe that the date-specific plan stayed while the Hijri label changed

### Requirement: Completed history does not move
Completion and history records SHALL remain attached to the date and calendar context that existed when the user completed, missed, skipped, or logged the morning.

#### Scenario: Completed fast remains on original date
- **GIVEN** the user completed a fast on March 12
- **WHEN** a later Hijri adjustment maps the related observance to March 13
- **THEN** the completion record SHALL remain on March 12
- **AND** Subh SHALL NOT move completion credit to March 13
- **AND** Subh MAY offer a new future/current plan only if product rules allow it

### Requirement: Immediate alarm override is narrowly scoped
Turning off the next active alarm SHALL be represented as a narrow immediate-alarm override and SHALL NOT delete future planning meaning.

#### Scenario: User turns off next alarm only
- **GIVEN** tomorrow has an active resolved alarm and future planned fasts also exist
- **WHEN** the user turns off the next active alarm
- **THEN** only the immediate active alarm SHALL be suppressed
- **AND** future plans SHALL remain durable
- **AND** the override SHALL expire or resolve after the relevant alarm or morning passes

### Requirement: Planning changes feed canonical resolver
Anchored planning records SHALL feed the canonical morning-resolution pipeline and SHALL NOT create a parallel resolver or scheduler.

#### Scenario: Month edit resolves through morning pipeline
- **GIVEN** the user edits a date from a month browsing surface
- **WHEN** the record is saved
- **THEN** the saved anchor SHALL feed the same morning-resolution pipeline as Home Hero, Alarm Detail, Next 10, and delivery
- **AND** the month surface SHALL NOT calculate prayer windows, infer wake intent from visible tags, or schedule alarms directly

#### Scenario: Delivery failure does not rewrite anchor
- **GIVEN** an anchored future plan resolves to an active wake but platform delivery is blocked
- **WHEN** delivery reports permission-blocked, degraded, missing, or failed status
- **THEN** the planning anchor and morning intention SHALL remain unchanged
- **AND** only delivery status SHALL describe the platform problem
