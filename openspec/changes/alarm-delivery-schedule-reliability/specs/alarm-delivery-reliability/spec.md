## ADDED Requirements

### Requirement: Delivery consumes resolver-materialized events
The delivery layer SHALL schedule only resolver-materialized `ScheduledEvent`s and delivery metadata. It SHALL NOT calculate prayer boundaries, religious meaning, wake intent, wake boundary, wake time, visual tags, or completion credit.

#### Scenario: Scheduler receives materialized events
- **GIVEN** morning resolution has produced `ResolvedDaySnapshot` materialized events and a `ResolvedMorningWakeState`
- **WHEN** the delivery layer builds a delivery plan
- **THEN** the plan SHALL be derived from those materialized events
- **AND** it SHALL NOT independently create Fajr, Fast, Tahajjud, Ramadan, Qada, iftar, reminder, Fajr-begins, or wake events from prayer-time inputs

#### Scenario: Delivery failure does not rewrite intent
- **GIVEN** a resolved morning has an active Fajr, Fast, or Tahajjud wake
- **WHEN** delivery is permission-blocked, degraded, missing, or failed
- **THEN** the resolved wake mode, day purpose, wake boundary, wake time, and alarm activation SHALL remain unchanged
- **AND** only delivery or schedule status SHALL reflect the platform problem

### Requirement: Delivery modes are explicit
The system SHALL model delivery mode separately from morning intent, alarm activation, platform permission, and verification result.

#### Scenario: Notification fallback is degraded delivery
- **GIVEN** AlarmKit is unavailable or unauthorized and notifications are authorized
- **WHEN** a true wake alarm is deliverable through notification fallback under policy
- **THEN** delivery mode SHALL be `notifications` or degraded notification fallback
- **AND** the transaction SHALL NOT be treated as scheduling failure
- **AND** user-facing state SHALL NOT claim AlarmKit-only behavior such as app-level snooze guarantees

#### Scenario: Mixed delivery uses split channels
- **GIVEN** AlarmKit is available and authorized for wake alarms and notification delivery is appropriate for secondary cues
- **WHEN** a morning has a wake alarm plus reminder, Fajr-boundary, or iftar notification events
- **THEN** delivery mode SHALL be `mixed`
- **AND** wake alarm deliveries SHALL use AlarmKit where expected
- **AND** secondary notification deliveries SHALL use UserNotifications where expected

#### Scenario: None is valid for Quiet
- **GIVEN** a resolved morning is Quiet or has no deliverable anchor
- **WHEN** the delivery plan is built
- **THEN** delivery mode MAY be `none`
- **AND** no active wake delivery SHALL be scheduled
- **AND** underlying Fajr, Fast, Tahajjud, Ramadan, Qada, or opportunity state SHALL remain resolver-owned upstream state

### Requirement: Permissions remain separate from delivery planning
The system SHALL model notification authorization, AlarmKit authorization or availability, and combined delivery readiness independently from wake intent and alarm activation.

#### Scenario: Active Fajr with notification permission denied
- **GIVEN** a resolved Fajr morning has `alarmActivation = active`
- **AND** notification permission is denied and AlarmKit is unavailable
- **WHEN** delivery planning runs
- **THEN** the wake intent SHALL remain active
- **AND** delivery status SHALL be permission blocked or equivalent
- **AND** the morning SHALL NOT become Quiet, off, or no-anchor

#### Scenario: AlarmKit verification is limited
- **GIVEN** AlarmKit scheduling is selected on a platform where exact pending-state verification is unavailable or limited
- **WHEN** reconciliation runs
- **THEN** the report SHALL mark AlarmKit verification as unavailable or limited
- **AND** it SHALL NOT pretend pending AlarmKit state was fully matched

### Requirement: Expected deliveries and identifiers are canonical
The system SHALL generate deterministic, date-scoped, event-kind-aware, and channel-aware expected delivery identifiers from one shared identifier path used by scheduling, cancellation, reconciliation, and ledger code.

#### Scenario: Shared identifiers drive all delivery operations
- **GIVEN** a scheduled event has a date key, event type, delivery kind, and selected platform channel
- **WHEN** scheduling, cancellation, reconciliation, or ledger code needs an identifier
- **THEN** each layer SHALL use the canonical identifier helper
- **AND** SwiftUI views and individual adapters SHALL NOT invent separate identifier formats

#### Scenario: Legacy identifiers remain cancellable
- **GIVEN** a date or schedule horizon may contain current and known legacy pending deliveries
- **WHEN** a scoped transaction repairs that date or horizon
- **THEN** current canonical identifiers and known legacy identifier patterns in scope SHALL be cancellable
- **AND** stale legacy deliveries SHALL NOT survive as duplicate wake or cue events

### Requirement: Delivery transactions are idempotent
Scheduling SHALL be transactional and idempotent for a resolved scope.

#### Scenario: Same transaction does not duplicate pending deliveries
- **GIVEN** a resolved delivery scope has the same expected future deliveries twice
- **WHEN** the transaction is run twice
- **THEN** pending notifications or alarms SHALL NOT be duplicated
- **AND** identifiers SHALL be stable across both runs
- **AND** the second run SHALL reconcile against the same expected deliveries

#### Scenario: Past events are skipped
- **GIVEN** a resolved scheduled event is already in the past at transaction time
- **WHEN** the delivery plan is built
- **THEN** the event SHALL NOT be scheduled
- **AND** it SHALL NOT be counted as a missing future delivery
- **AND** diagnostics MAY record it as skipped past

#### Scenario: Per-date edit scopes repair only that date
- **GIVEN** one date-specific wake override changes within an active schedule window
- **WHEN** the safe per-date transaction runs
- **THEN** only that affected date or known safe scope SHALL be rescheduled
- **AND** unrelated dates SHALL remain stable

### Requirement: Reconciliation compares expected and pending state
The system SHALL compare expected deliveries with pending platform state and report explicit reconciliation categories.

#### Scenario: Missing expected pending notification
- **GIVEN** an expected notification delivery exists for a future event
- **WHEN** pending UserNotification requests do not contain its identifier
- **THEN** reconciliation SHALL report `missingExpected`
- **AND** aggregate delivery status SHALL be degraded or failed according to policy

#### Scenario: Fire-date mismatch
- **GIVEN** an expected delivery identifier exists in pending platform state
- **WHEN** the pending fire date differs beyond tolerance
- **THEN** reconciliation SHALL report `fireDateMismatch`

#### Scenario: Unexpected extra pending delivery
- **GIVEN** a pending delivery exists in the repaired scope but is not expected by the current resolved events
- **WHEN** reconciliation runs
- **THEN** reconciliation SHALL report `unexpectedExtra`
- **AND** repair policy SHALL cancel it when it is safely in scope

#### Scenario: Duplicate pending delivery
- **GIVEN** pending platform state contains duplicate deliveries for the same expected identifier or equivalent legacy/current event
- **WHEN** reconciliation runs
- **THEN** reconciliation SHALL report `duplicate`
- **AND** repair policy SHALL avoid leaving more than one active delivery for the same event

### Requirement: Quiet and audio roles affect delivery without changing activation meaning
Quiet suppression and audio role selection SHALL affect delivery details without being used as substitutes for wake intent or activation.

#### Scenario: Quiet cancels delivery without deleting state
- **GIVEN** a resolved morning has underlying Fajr, Fast, or Tahajjud state
- **WHEN** the user selects Quiet
- **THEN** active deliveries for that date or scope SHALL be cancelled or suppressed
- **AND** schedule status SHALL be not scheduled because Quiet
- **AND** underlying morning state SHALL remain restorable by the resolver

#### Scenario: Fajr adhan wake audio stays active
- **GIVEN** a wake event uses Fajr adhan audio
- **WHEN** delivery planning runs
- **THEN** the event SHALL remain an active wake delivery
- **AND** audio role SHALL NOT convert activation to off, Quiet, no-anchor, or unavailable

#### Scenario: Later Fajr adhan toggle affects only boundary cue
- **GIVEN** an Early plus Fast morning has a pre-Fajr wake event and a later Fajr-begins cue
- **WHEN** the later Fajr adhan cue is disabled
- **THEN** only the later boundary cue SHALL be removed or cancelled
- **AND** the pre-Fajr wake delivery SHALL remain expected when activation is active

### Requirement: Cache reuse still verifies platform delivery
A valid resolved schedule cache SHALL NOT be treated as proof that pending platform deliveries still exist.

#### Scenario: Cached window is reconciled
- **GIVEN** the app reuses a valid cached active schedule window on launch or foreground
- **WHEN** schedule calculation is skipped
- **THEN** pending platform state SHALL still be queried and reconciled against expected deliveries
- **AND** missing, mismatched, stale, duplicate, or verification-limited results SHALL be reported

### Requirement: Lifecycle and state changes trigger refresh or reconciliation
The system SHALL refresh and/or reconcile delivery on lifecycle, permission, time, location, calculation, observance, override, and identifier-migration changes that can affect deliverability.

#### Scenario: Permission change triggers reconciliation
- **GIVEN** notification or AlarmKit permission changes after a schedule was built
- **WHEN** the app observes or requests the permission change
- **THEN** schedule refresh or reconciliation SHALL be requested
- **AND** delivery status SHALL reflect the new permission state without changing morning intent

#### Scenario: Timezone or significant time change repairs scope
- **GIVEN** device time or timezone changes
- **WHEN** the app observes the change
- **THEN** schedule refresh or reconciliation SHALL be requested
- **AND** old identifiers in the affected date or horizon scope SHALL be cancelled or repaired

#### Scenario: Calculation and observance changes refresh delivery
- **GIVEN** location, prayer calculation method, Fajr or Maghrib adjustment, Hijri adjustment, date-specific wake override, Quick mode, fast purpose, Ramadan or Qada plan, or schedule horizon rollover changes
- **WHEN** the app observes the change
- **THEN** the affected delivery scope SHALL be refreshed or reconciled from newly resolved materialized events

### Requirement: Local delivery ledger is privacy preserving
The system SHALL record local delivery diagnostics sufficient for support without collecting raw location, personal religious analytics, sensitive notes, remote telemetry, or unnecessary provider payloads.

#### Scenario: Transaction summary is recorded
- **GIVEN** a delivery transaction completes
- **WHEN** the local ledger records the transaction
- **THEN** it SHALL include transaction id or entry id, timestamp, trigger reason, scope, expected count, scheduled count, matched count, missing count, failed count, degraded or fallback status, permission snapshot, and high-level adapter result
- **AND** it SHALL avoid raw coordinates, sensitive user notes, personal religious analytics, and remote telemetry by default

### Requirement: User-facing reliability copy stays compact
User-facing surfaces SHALL consume resolved delivery status and avoid becoming diagnostics screens.

#### Scenario: Home shows compact warning
- **GIVEN** a morning has an active wake intent but blocked or missing delivery
- **WHEN** Home renders the hero
- **THEN** it MAY show compact copy such as "Alarm permission needed" or "Wake selected, but alarm not scheduled"
- **AND** it SHALL NOT show full pending-request diagnostics

#### Scenario: Forecast surfaces stay compact
- **GIVEN** Weekly Fajrcast or Next 10 renders resolved forecast rows
- **WHEN** delivery status is degraded
- **THEN** the surfaces SHALL remain compact
- **AND** they SHALL NOT add verbose reliability prose to chart cards or rows
