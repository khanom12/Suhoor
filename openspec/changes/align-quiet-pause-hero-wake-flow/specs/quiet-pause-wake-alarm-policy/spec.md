## ADDED Requirements

### Requirement: Quiet and Pause are alarm-state policies
The system SHALL model Quiet as a date-level alarm override and Pause as an indefinite app-wide wake-alarm policy, separate from the selected wake purpose.

#### Scenario: Selector contains only wake purposes
- **GIVEN** an editable MVP morning is displayed on Home or Day Detail
- **WHEN** the user views the wake-purpose selector
- **THEN** the selector SHALL expose only `Fajr` and `Suhoor`
- **AND** Quiet, Pause, Pre-Fajr, Early, Early worship, Fast mode, and Quiet mode SHALL NOT appear as wake-purpose choices

#### Scenario: Quiet preserves purpose and saved alarms
- **GIVEN** a morning has a selected Fajr or Suhoor purpose with saved Fajr and Suhoor alarm configurations
- **WHEN** the user sets that morning to Quiet
- **THEN** the system SHALL store `DateAlarmOverride.quiet`
- **AND** it SHALL preserve the selected purpose, Fajr alarm configuration, Suhoor alarm configuration, day context, and observance context

#### Scenario: Pause preserves plans globally
- **GIVEN** the user has saved Fajr and Suhoor plans across upcoming mornings
- **WHEN** the user pauses Subh wake alarms from Settings
- **THEN** the system SHALL store an indefinite global pause policy
- **AND** it SHALL preserve saved Fajr plans, saved Suhoor plans, and date-specific overrides
- **AND** it SHALL NOT create date-range pause, recurring pause, or a pause reason record

### Requirement: Alarm-state precedence is explicit
The system SHALL resolve setup and issue states, manual Quiet, global Pause, ring-once exceptions, and active alarms in a deterministic precedence order.

#### Scenario: Manual Quiet beats Pause exception
- **GIVEN** a date somehow has both manual Quiet and a ring-despite-pause exception
- **WHEN** the resolved alarm state is computed
- **THEN** the resolved state SHALL be Quiet
- **AND** the date SHALL NOT ring while Quiet remains active

#### Scenario: Global Pause is inherited unless excepted
- **GIVEN** global Pause is active
- **AND** the selected date has no manual Quiet and no ring-despite-pause exception
- **WHEN** the morning is resolved
- **THEN** the resolved alarm state SHALL be paused inherited
- **AND** visible copy SHALL use `Alarms paused`

#### Scenario: Ring tomorrow only does not resume all alarms
- **GIVEN** global Pause is active for Subh wake alarms
- **WHEN** the user chooses `Ring tomorrow only` for the target morning
- **THEN** the system SHALL store a date-level ring-despite-pause exception for that morning
- **AND** global Pause SHALL remain active for future mornings

#### Scenario: Stay paused clears the exception
- **GIVEN** global Pause is active
- **AND** the target morning has a ring-despite-pause exception
- **WHEN** the user chooses to stay paused for that morning
- **THEN** the system SHALL clear the ring-despite-pause exception
- **AND** the morning SHALL inherit Pause again
- **AND** the system SHALL NOT create manual Quiet unless the user explicitly chooses Quiet outside the inherited Pause path

#### Scenario: Resume keeps manual Quiet
- **GIVEN** global Pause is active
- **AND** one upcoming morning has manual Quiet
- **WHEN** the user resumes alarms globally
- **THEN** non-Quiet paused mornings SHALL return to their saved Fajr or Suhoor plans
- **AND** the manual Quiet morning SHALL remain Quiet

### Requirement: Quiet and Pause control scoped Subh wake delivery
The system SHALL suppress or cancel only the affected Subh wake alarms and follow-up alarms when Quiet or Pause applies.

#### Scenario: Quiet before execution cancels target delivery
- **GIVEN** a target morning has scheduled primary or follow-up Subh wake alarms
- **WHEN** the user sets that target morning to Quiet before the first alarm begins
- **THEN** the system SHALL cancel stale scheduled delivery for that target morning
- **AND** it SHALL prevent a Wake Session from starting for that target morning
- **AND** it SHALL NOT cancel unrelated date keys or unrelated alarms

#### Scenario: Pause suppresses future wake delivery
- **GIVEN** global Pause is active
- **WHEN** the schedule refreshes upcoming Subh wake alarms
- **THEN** eligible future wake alarms and follow-up alarms SHALL NOT be scheduled unless their date has a ring-despite-pause exception
- **AND** schedule diagnostics SHALL distinguish pause suppression from Quiet, setup blocked, permission blocked, and delivery issue states

#### Scenario: Quiet unavailable after execution starts
- **GIVEN** the first alarm for a morning has begun
- **WHEN** the user views the active wake flow
- **THEN** Quiet SHALL NOT be exposed as a user-facing action for that morning
- **AND** the primary user-facing action SHALL be `I’m awake`

### Requirement: Quiet and Pause are Free core controls
The system SHALL allow Quiet, global Pause, Resume, one-morning ring exceptions, and active alarm acknowledgement without paid entitlement.

#### Scenario: Free user controls alarms
- **GIVEN** the user has the Free entitlement
- **WHEN** they use Quiet, Resume alarms, Pause Subh wake alarms, Ring tomorrow only, `I’m awake`, `I’m fasting today`, or `I prayed Fajr`
- **THEN** the system SHALL allow the action without a paywall
