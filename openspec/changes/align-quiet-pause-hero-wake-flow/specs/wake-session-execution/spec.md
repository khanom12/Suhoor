## ADDED Requirements

### Requirement: Awake acknowledgement ends the current wake flow
The system SHALL treat in-app `I’m awake` and explicit system alarm dismissal as acknowledgement for MVP wake-flow completion.

#### Scenario: User taps in-app acknowledgement
- **GIVEN** a Fajr or Suhoor Wake Session is ringing or has follow-up alarms pending
- **WHEN** the user taps `I’m awake`
- **THEN** the Wake Session SHALL record awake acknowledgement
- **AND** it SHALL cancel remaining primary and follow-up alarms for that morning
- **AND** it SHALL preserve the acknowledgement source as in-app button where the model can store it
- **AND** it SHALL NOT record Fajr prayer completion automatically

#### Scenario: User dismisses system alarm
- **GIVEN** a platform alarm event represents an explicit system alarm dismissal for the current Wake Session
- **WHEN** Subh receives the dismissal event
- **THEN** the Wake Session SHALL be treated as awake acknowledged for MVP
- **AND** remaining follow-up alarms for that morning SHALL be cancelled
- **AND** the acknowledgement source SHALL be preserved as system alarm dismissal where the event path can distinguish it

### Requirement: Follow-up alarms respect Fajr and Suhoor boundaries
The system SHALL schedule follow-up alarms only while there is enough time before the relevant boundary for the selected wake purpose.

#### Scenario: Fajr purpose near Fajr end
- **GIVEN** a Fajr-purpose primary alarm is too close to Fajr end for another eligible follow-up alarm
- **WHEN** follow-up alarms are planned
- **THEN** no follow-up alarm SHALL be scheduled after the Fajr-purpose cutoff
- **AND** the active Hero SHALL be able to show `Final alarm this morning`

#### Scenario: Suhoor purpose near Fajr begins
- **GIVEN** a Suhoor-purpose primary alarm is too close to Fajr begins for another eligible follow-up alarm
- **WHEN** follow-up alarms are planned
- **THEN** no follow-up alarm SHALL be scheduled after the Suhoor-purpose cutoff
- **AND** the active Hero SHALL be able to show `Final alarm this morning`

### Requirement: Fajr and Suhoor post-awake records remain separate
The system SHALL keep awake acknowledgement, fasting status, and Fajr prayer confirmation as separate current-morning outcomes.

#### Scenario: Fajr flow records prayer separately
- **GIVEN** a user acknowledges a Fajr alarm
- **WHEN** the user later taps `I prayed Fajr` during the eligible Fajr window
- **THEN** the system SHALL record Fajr prayer confirmation for that morning
- **AND** the prayer confirmation SHALL remain separate from the earlier awake acknowledgement

#### Scenario: Suhoor flow records fasting status before Fajr
- **GIVEN** a user acknowledges a Suhoor alarm before Fajr begins
- **WHEN** the user taps `I’m fasting today` before Fajr begins
- **THEN** the system SHALL record current-day fasting status or intention
- **AND** it SHALL NOT record fast completion
- **AND** it SHALL NOT record Fajr prayer confirmation

#### Scenario: Fajr prayer CTA takes priority after Fajr begins
- **GIVEN** a user acknowledged Suhoor but did not tap `I’m fasting today` before Fajr begins
- **WHEN** Fajr begins and the 60-second action delay is satisfied
- **THEN** the primary post-awake CTA SHALL be `I prayed Fajr`
- **AND** the Hero SHALL NOT show a second awake acknowledgement prompt

### Requirement: Wake execution test harness covers final state model
The internal testing harness SHALL provide task-oriented scenarios for the final Quiet/Pause/Hero state model using user-facing labels first and diagnostics second.

#### Scenario: Harness exposes required scenario groups
- **GIVEN** the internal Wake Session Lab or Home simulation harness is available
- **WHEN** the tester views scenario cards or state choices
- **THEN** the harness SHALL include scenarios for Active Fajr, Active Suhoor, Quiet Fajr, Quiet Suhoor, Paused Fajr, Paused Suhoor, Rings tomorrow only while paused, Turn on alarms, Set location, Alarm issue, Time to wake, Next alarm soon, Final alarm this morning, post-awake Fajr, post-awake Suhoor, boundary cutoff, and Fajr-end handoff
- **AND** developer diagnostics SHALL remain secondary to the user-facing scenario labels

#### Scenario: Harness does not create a second product engine
- **GIVEN** a tester previews a Quiet, Pause, Fajr, Suhoor, or post-awake state
- **WHEN** Home is rendered in simulation
- **THEN** the harness SHALL drive the same Home snapshot or presentation path used by production
- **AND** real user settings, real plans, real logs, real entitlements, and production scheduled alarms SHALL remain untouched unless the tester explicitly runs a real test alarm flow
