## ADDED Requirements

### Requirement: May 31 Hero presentation
The Home Hero and Detail hero-like alarm panel SHALL use the May 31 six-slot behavior for morning label, alarm-state control, slider feedback, and purpose selection.

#### Scenario: Hero shows title-case morning label
- **GIVEN** Home is rendering a planning state for the next relevant morning
- **WHEN** the resolved target is before midnight
- **THEN** Slot 2 SHALL display `Tomorrow Morning`
- **AND** it SHALL NOT display only `Tomorrow`

#### Scenario: Hero alarm-state row stays minimal
- **GIVEN** the resolved target has alarm delivery on
- **WHEN** Slot 3 renders
- **THEN** it SHALL show an alarm icon and wake time as the primary state
- **AND** it SHALL NOT add explanatory body copy under the wake time inside the Hero

#### Scenario: Alarm-state control opens Quiet confirmation
- **GIVEN** the resolved target has alarm delivery on
- **WHEN** the user taps the alarm icon or adjacent wake time control
- **THEN** Home SHALL open the May 31 Quiet confirmation
- **AND** the alarm SHALL NOT be silenced until the user confirms `Make Quiet`

#### Scenario: Slider live feedback stays synchronized
- **GIVEN** the user drags the wake-time slider in an active planning state
- **WHEN** the drag value changes
- **THEN** Slot 3 wake time, slider thumb position, and helper copy SHALL update together

#### Scenario: Purpose selector contains only Suhoor and Fajr
- **GIVEN** the Hero is in a planning state
- **WHEN** the purpose selector renders
- **THEN** it SHALL show visible choices in the order `Suhoor | Fajr`
- **AND** it SHALL NOT include Quiet or Pause

### Requirement: Sentence-based context card
The primary context card SHALL be the explanatory layer below the Hero and SHALL use sentence-based copy instead of visual tags as its main communication method.

#### Scenario: Active Fajr context explains the morning
- **GIVEN** Tomorrow Morning is a normal Fajr morning with alarm delivery on
- **WHEN** the context card renders
- **THEN** it SHALL explain that the user is waking for Fajr
- **AND** it SHALL include the wake time
- **AND** it SHALL avoid internal terms such as anchor, event line, scheduler state, or wake-check generator

#### Scenario: Fasting opportunity context is specific
- **GIVEN** Tomorrow Morning has a Monday, Thursday, White Days, Ramadan, Arafah, or Ashura opportunity
- **WHEN** the context card renders
- **THEN** it SHALL explain the specific opportunity by name
- **AND** it SHALL explain whether the user has planned to fast when that fact is known

#### Scenario: Quiet context is plain
- **GIVEN** a target morning is Quiet
- **WHEN** the context card renders
- **THEN** it SHALL state that no alarm will ring for that morning
- **AND** it SHALL explain that the user can turn the alarm back on without changing the saved Suhoor/Fajr plan

### Requirement: Late Fajr logging below context
Home SHALL show unresolved previous-morning Fajr prayer logging below the context card after the Hero has rolled to the next relevant morning.

#### Scenario: Same-day late logging CTA appears below context
- **GIVEN** Fajr has ended today and Fajr prayer completion was not logged
- **WHEN** Home renders after Hero rollover
- **THEN** a separate prompt below the context card SHALL show `I Prayed Fajr Earlier Today`
- **AND** the Hero SHALL remain focused on the next relevant morning

#### Scenario: Yesterday late logging CTA appears below context
- **GIVEN** Fajr prayer completion was not logged for the previous relevant morning
- **WHEN** Home renders after midnight and before late prompt expiry
- **THEN** the separate prompt below the context card SHALL show `I Prayed Fajr Yesterday Morning`

#### Scenario: Tapping late logging records previous morning
- **GIVEN** the late Fajr logging prompt is visible
- **WHEN** the user taps the prompt CTA
- **THEN** Fajr prayer completion SHALL be logged for the previous relevant morning
- **AND** the prompt SHALL disappear

### Requirement: Next 7 May 31 row layout
Next 7 Mornings rows SHALL use left wake time or `Quiet` plus date, middle purpose plus specific opportunity tags, and right one-morning Quiet toggle.

#### Scenario: Alarm-on row uses three zones
- **GIVEN** a Next 7 row has alarm delivery on for Fajr
- **WHEN** the row renders
- **THEN** the left zone SHALL show the wake time as the dominant value with the date below it
- **AND** the middle zone SHALL show `Awake for Fajr`
- **AND** the right zone SHALL show the Quiet toggle on

#### Scenario: Quiet row shows Quiet without changing purpose
- **GIVEN** a Next 7 row is Quiet for a Suhoor plan
- **WHEN** the row renders
- **THEN** the left zone SHALL show `Quiet` with the date below it
- **AND** the middle zone SHALL show `Awake for Suhoor`
- **AND** the right toggle SHALL be off

#### Scenario: Opportunity tags are specific only
- **GIVEN** a Next 7 row has opportunity context
- **WHEN** the middle zone renders tags
- **THEN** it SHALL include only specific labels such as `Monday`, `Thursday`, `White Days`, `Ramadan`, `Arafah`, or `Ashura`
- **AND** it SHALL NOT show `Fasting Opportunity`, `Fajr`, `Suhoor`, `Quiet`, `Paused`, `Rings once`, or `Fasting` as opportunity tags

#### Scenario: Quiet toggle is the only inline mutation
- **GIVEN** the user interacts with a Next 7 row
- **WHEN** the user toggles the right-column Quiet control
- **THEN** the app SHALL set or clear only that morning's Quiet override
- **AND** it SHALL NOT change purpose, pause all alarms, change wake time, or mutate Month Planning or Weekly Fajrcast

## MODIFIED Requirements

### Requirement: Quiet selection confirms active-session cancellation
The Home Hero SHALL ask for explicit confirmation before cancelling pending wake-session events when the user switches an active morning to Quiet, and SHALL use May 31 Quiet copy for normal planning-state Quiet entry.

#### Scenario: Quiet selected with pending wake checks
- **GIVEN** the current morning has pending wake-session primary or wake-check events
- **WHEN** the user selects Quiet from an approved alarm-state control
- **THEN** the app SHALL show an explicit confirmation before cancellation
- **AND** the confirmation SHALL explain that remaining alarms/checks will be cancelled
- **AND** confirming SHALL NOT log awake acknowledgement or Fajr prayer completion

#### Scenario: Planning alarm opens May 31 Quiet confirmation
- **GIVEN** the target morning has alarm delivery on and no active wake execution
- **WHEN** the user taps the Hero alarm-state control
- **THEN** the dialog title SHALL be `Make Tomorrow Morning Quiet?` or `Make Today Morning Quiet?` based on target morning
- **AND** the body SHALL be `No alarm or wake checks will ring. Use this only if you do not need Subh to wake you.`
- **AND** the actions SHALL include `Keep Alarm On` and `Make Quiet`

#### Scenario: User keeps alarm on
- **GIVEN** the Quiet confirmation dialog is visible
- **WHEN** the user chooses `Keep Alarm On`
- **THEN** the existing wake plan SHALL remain active
- **AND** pending wake-session events SHALL remain scheduled

#### Scenario: User makes morning Quiet
- **GIVEN** the Quiet confirmation dialog is visible
- **WHEN** the user chooses `Make Quiet`
- **THEN** remaining wake-session events for the target morning SHALL be cancelled when applicable
- **AND** the target morning SHALL resolve as Quiet
- **AND** the system SHALL NOT record Fajr missed
