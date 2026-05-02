## ADDED Requirements

### Requirement: Canonical morning state pipeline
The system SHALL resolve a target morning through one canonical pipeline from prayer-window inputs to `ResolvedDaySnapshot`, `ResolvedMorningWakeState`, surface snapshots, and scheduler commands.

#### Scenario: Default Fajr morning resolves through the pipeline
- **GIVEN** a target morning has Fajr begins, supported Fajr ends, location timezone, prayer settings, no date-specific wake override, and no early-worship intention
- **WHEN** the morning is resolved
- **THEN** the resolved quick wake selection SHALL be `fajr`
- **AND** the boundary regime SHALL be `defaultFajrWindow`
- **AND** the wake time SHALL default to 30 minutes before Fajr ends
- **AND** alarm activation SHALL be active
- **AND** relation copy SHALL say "Wake up 30 min before Fajr ends"

#### Scenario: Pipeline preserves layer separation
- **GIVEN** a resolved morning includes day meaning, user intention, wake boundary, wake time, alarm activation, delivery status, and completion records
- **WHEN** surfaces, scheduler handoff, and completion logic consume that morning
- **THEN** each consumer SHALL use the resolved layer it needs
- **AND** it SHALL NOT infer one layer from another layer such as visible tags, audio role, delivery status, or completion credit

### Requirement: SwiftUI surfaces emit intents only
SwiftUI views SHALL consume resolved snapshots and emit domain intents without calculating prayer boundaries, scheduling alarms, writing date overrides directly, or inferring religious intention from presentation state.

#### Scenario: Home Hero interaction emits wake intents
- **GIVEN** Home Hero displays a `ResolvedMorningWakeState`
- **WHEN** the user changes quick wake mode or commits a wake adjustment
- **THEN** the view SHALL emit a domain intent for the selected date
- **AND** the view SHALL NOT create alarms, cancel alarms, write `DailyAlarmOverride` directly, derive Fajr end, calculate final-third start, or infer fasting or Tahajjud from the dragged wake time

#### Scenario: Alarm Detail edits one selected date
- **GIVEN** Alarm Detail has a selected `dateKey`, `ResolvedDaySnapshot`, `ResolvedMorningWakeState`, and `ResolvedDayPurpose`
- **WHEN** the user edits wake mode, wake time, early purpose, fast purpose, or Fajr adhan boundary behavior
- **THEN** the surface SHALL commit a date-specific domain intent for that selected date only
- **AND** global defaults SHALL remain unchanged
- **AND** the surface SHALL NOT create a second resolver or persistence model

#### Scenario: Static architecture guardrails cover SwiftUI views
- **GIVEN** SwiftUI view files are scanned by tests
- **WHEN** the architecture test runs
- **THEN** view files SHALL NOT call alarm create, cancel, or schedule APIs directly
- **AND** view files SHALL NOT calculate final-third start or Fajr end
- **AND** view files SHALL NOT write `DailyAlarmOverride` directly

### Requirement: Date-specific intent handling
The system SHALL centralize one-date wake and purpose mutations through an intent-handling path that persists date-specific overrides without mutating global defaults.

#### Scenario: Fast quick selection saves a date-specific fast wake intent
- **GIVEN** a target date is using the default Fajr wake
- **WHEN** the user selects Fast for that date
- **THEN** the system SHALL save a date-specific fast wake intent
- **AND** the boundary regime SHALL become `earlyWorshipWindow`
- **AND** the wake time SHALL default to 30 minutes before Fajr begins
- **AND** an active wake event SHALL be materialized when required timing data is available

#### Scenario: Manual drag saves wake time without inferring purpose
- **GIVEN** a target date has a resolved Fajr or Fast wake mode
- **WHEN** the user commits a dragged wake time
- **THEN** the system SHALL save a date-specific wake-time override and wake-time origin
- **AND** it SHALL NOT infer a fast intention
- **AND** it SHALL NOT infer a Tahajjud intention

#### Scenario: Restoring default wake removes only date-specific wake edits
- **GIVEN** a target date has date-specific quick mode, wake rule, wake time, or audio-boundary overrides
- **WHEN** the user restores the default wake for that date
- **THEN** date-specific wake edits SHALL be cleared for that date
- **AND** global wake defaults SHALL remain unchanged
- **AND** day meaning from Ramadan, Qada, Sunnah opportunities, or other observance context SHALL remain resolvable

### Requirement: Quiet Mode is an overlay
Quiet Mode SHALL suppress delivery for a target date without deleting the underlying Fajr, Fast, Tahajjud, Ramadan, Qada, selected fast purpose, or opportunity state.

#### Scenario: Quiet over Fajr restores Fajr
- **GIVEN** a target date resolves to Fajr mode
- **WHEN** the user selects Quiet and later reselects Fajr
- **THEN** Quiet SHALL suppress wake delivery while selected
- **AND** the underlying Fajr mode SHALL be preserved
- **AND** reselecting Fajr SHALL restore prior or default Fajr behavior

#### Scenario: Quiet over Fast restores Fast
- **GIVEN** a target date resolves to Fast mode with a selected fast purpose
- **WHEN** the user selects Quiet and later reselects Fast
- **THEN** Quiet SHALL suppress wake delivery while selected
- **AND** the selected fast purpose SHALL be preserved
- **AND** the underlying early-worship mode and prior Fast wake behavior SHALL be restored before defaulting

### Requirement: Opportunities, intentions, and completion credit remain separate
The system SHALL distinguish day meaning and observance opportunities from user intention, wake classification, required actions, and completion or analytics credit.

#### Scenario: White Days opportunity remains opportunity-only
- **GIVEN** a target date has a White Days opportunity and no selected or auto-obligatory fast intention
- **WHEN** the morning is resolved
- **THEN** the user intention SHALL remain default Fajr
- **AND** no fast required action SHALL be created
- **AND** no early-worship boundary SHALL be used
- **AND** Next 10 may show `Fajr` and `White Days` tags without treating the date as intended fasting

#### Scenario: Qada assignment resolves as a fast intention
- **GIVEN** a target date has a Qada fast assignment and overlapping Sunnah opportunities
- **WHEN** the morning is resolved
- **THEN** the day purpose SHALL resolve as a fast intention
- **AND** the early-worship boundary SHALL be used
- **AND** Qada credit SHALL remain primary
- **AND** overlapping Sunnah opportunities SHALL NOT auto-credit completion

#### Scenario: Tahajjud uses early worship without fast controls
- **GIVEN** a target date has a Tahajjud intention and no fast intention
- **WHEN** the morning is resolved
- **THEN** the early-worship boundary SHALL be used
- **AND** no fast-purpose selector SHALL be required
- **AND** no fast required actions SHALL be created

### Requirement: Ramadan resolves through the same morning engine
Ramadan SHALL remain date meaning inside the canonical morning pipeline and SHALL NOT create a separate Ramadan alarm engine.

#### Scenario: Ramadan context remains when wake execution changes
- **GIVEN** a target date resolves as Ramadan
- **WHEN** the user changes wake execution to Fajr or Quiet
- **THEN** Ramadan day context SHALL remain present
- **AND** only wake execution or delivery suppression SHALL change
- **AND** the system SHALL NOT create or use a separate Ramadan alarm engine

#### Scenario: Ramadan fast purpose is locked in detail
- **GIVEN** a target date resolves as Ramadan fasting under existing product rules
- **WHEN** Alarm Detail displays fast purpose controls
- **THEN** the Ramadan fast purpose SHALL be shown as locked or non-editable
- **AND** Ramadan defaults SHALL continue to resolve through the normal fast and early-worship pipeline

### Requirement: Activation, delivery status, and audio role are separate
The system SHALL model alarm activation, schedule or delivery status, and audio role as separate concepts.

#### Scenario: Permission blocked preserves active intent
- **GIVEN** a target date has `quickWakeSelection = fajr` and `alarmActivation = active`
- **WHEN** platform delivery is permission blocked
- **THEN** `scheduleStatus` SHALL be `permissionBlocked`
- **AND** UI and domain state SHALL NOT become Quiet or no-alarm

#### Scenario: Fajr adhan wake audio is still active alarm
- **GIVEN** Fajr mode uses Fajr adhan audio as the wake sound
- **WHEN** the wake state is resolved
- **THEN** alarm activation SHALL remain active
- **AND** the system SHALL NOT display or persist the morning as off merely because the audio role is Fajr adhan

#### Scenario: Later Fajr adhan toggle does not disable pre-Fajr wake
- **GIVEN** a non-Ramadan Early plus Fast morning has a pre-Fajr wake event and a later Fajr-boundary adhan event
- **WHEN** the user disables Fajr adhan at Fajr begins for that date
- **THEN** only the later Fajr-boundary event SHALL be disabled
- **AND** the pre-Fajr wake event SHALL remain active when activation is active

### Requirement: Boundary copy and missing boundary data are truthful
The system SHALL generate copy from resolved boundary and wake-time state, and SHALL NOT invent unavailable prayer or final-third boundaries.

#### Scenario: Endpoint copy is generated by the resolver
- **GIVEN** default Fajr wake resolves exactly at Fajr begins
- **WHEN** copy state is built
- **THEN** relation copy SHALL say "Wake up as Fajr begins"
- **AND** if default Fajr wake resolves exactly at Fajr ends, relation copy SHALL say "Wake up as Fajr ends"
- **AND** if early-worship wake resolves exactly at final-third start, relation copy SHALL say "Wake up for the last third of the night"
- **AND** if early-worship wake resolves exactly at Fajr begins, relation copy SHALL say "Wake up as Fajr begins"

#### Scenario: Red urgent relation tone is narrowly scoped
- **GIVEN** a resolved wake state has relation copy and visual tone
- **WHEN** the default Fajr wake is 14 minutes or less before Fajr ends
- **THEN** the urgent red relation tone SHALL apply
- **AND** it SHALL NOT apply merely because any endpoint is used
- **AND** it SHALL NOT apply to Quiet copy

#### Scenario: Missing Fajr end is not invented by renderers
- **GIVEN** Fajr begins is known and supported Fajr end is missing
- **WHEN** a renderer displays the morning
- **THEN** it SHALL NOT invent Fajr end
- **AND** it SHALL NOT show a guessed within-Fajr slider
- **AND** the resolved state SHALL expose unavailable or degraded behavior

#### Scenario: Missing final-third data is not invented
- **GIVEN** an early-worship wake is requested and Maghrib or final-third inputs are missing
- **WHEN** the morning is resolved
- **THEN** final-third start SHALL be unavailable
- **AND** the system SHALL use a safe unavailable or fallback state
- **AND** surfaces SHALL NOT calculate their own final-third start

### Requirement: Surface snapshots consume resolved state
Surface snapshots SHALL adapt resolved day and wake state for layout without owning prayer calculation, intention inference, schedule materialization, or completion credit rules.

#### Scenario: Weekly Fajrcast supports live provisional preview
- **GIVEN** Weekly Fajrcast receives resolved seven-day snapshots and a provisional hero wake override for a visible date
- **WHEN** the user drags the hero wake marker
- **THEN** the chart marker SHALL update live from the supplied preview value
- **AND** no persistence or scheduling SHALL occur until commit
- **AND** the chart SHALL NOT choose a new snap-back target outside its supplied snapshot

#### Scenario: Next 10 uses resolved tags and wake status
- **GIVEN** Next 10 receives resolved row snapshots
- **WHEN** it renders a row
- **THEN** it SHALL show date, tag cluster, and wake time or status from the resolved snapshot
- **AND** it SHALL NOT infer intention from visible tag text
- **AND** it SHALL NOT show explanatory row prose

### Requirement: Scheduler handoff consumes materialized events
The scheduler and delivery layer SHALL consume resolved materialized events and report delivery status back without redefining day meaning, user intention, quick mode, activation, or completion credit.

#### Scenario: Scheduler schedules from resolved events
- **GIVEN** a `ResolvedDaySnapshot` contains materialized wake and boundary events
- **WHEN** scheduler handoff runs
- **THEN** the scheduler SHALL schedule or cancel only from the resolved materialized events and activation state
- **AND** it SHALL NOT independently derive prayer boundaries, fast intention, Tahajjud intention, or Quiet state

#### Scenario: Timezone and DST use resolved location timezone
- **GIVEN** a target date crosses midnight, daylight-saving change, or device timezone difference from the resolved location timezone
- **WHEN** date keys, prayer windows, wake instants, and overrides are resolved
- **THEN** they SHALL use the resolved location timezone
- **AND** final-third calculation SHALL use real `Date` instants across midnight
- **AND** date-specific overrides SHALL apply to the intended local morning date
