## ADDED Requirements

### Requirement: Cached lifecycle refreshes reconcile delivery state
The system SHALL verify and reassert platform deliveries on app launch and foreground refresh even when the resolved schedule window cache is reusable.

#### Scenario: Launch reuses the cached schedule window
- **GIVEN** the active schedule window cache is valid for the current day and wake rule
- **WHEN** the app launch refresh runs
- **THEN** the system SHALL run delivery reconciliation for the cached scheduled events
- **AND** it SHALL NOT skip delivery verification solely because schedule calculation was reused

#### Scenario: Foreground refresh reuses the cached schedule window
- **GIVEN** the active schedule window cache is valid for the current day and wake rule
- **WHEN** the app returns to foreground
- **THEN** the system SHALL run delivery reconciliation for the cached scheduled events
- **AND** it SHALL refresh delivery diagnostics after reconciliation

### Requirement: Unknown day rescheduling cancels stale identifiers
The system SHALL cancel every known current and legacy identifier for a date before scheduling that date when no prior in-memory plan is available.

#### Scenario: Rescheduling a date without prior in-memory state
- **GIVEN** a resolved active day has no prior scheduled plan in memory
- **WHEN** the system schedules that day
- **THEN** it SHALL cancel current event identifiers, current daily identifiers, legacy dot identifiers, and legacy V1 identifiers for that date
- **AND** it SHALL cancel both notification identifiers and AlarmKit alarm identifiers before scheduling the resolved events

### Requirement: Notification delivery verification covers every expected delivery
The system SHALL compare all expected pending notification deliveries against the platform pending-request state after scheduling.

#### Scenario: One expected notification is missing while others remain
- **GIVEN** two future notification deliveries are expected
- **AND** only one matching pending notification request exists
- **WHEN** delivery reconciliation runs
- **THEN** the report SHALL flag the missing delivery
- **AND** diagnostics SHALL warn about the mismatch

#### Scenario: A pending notification has the wrong fire date
- **GIVEN** a future notification delivery is expected at a resolved fire date
- **AND** a pending notification with the same identifier exists at a different fire date
- **WHEN** delivery reconciliation runs
- **THEN** the report SHALL flag the time mismatch

### Requirement: AlarmKit delivery verification covers every expected alarm
The system SHALL compare all expected AlarmKit deliveries against available AlarmKit scheduled alarm state when AlarmKit delivery mode is active.

#### Scenario: AlarmKit alarm has the wrong fire date
- **GIVEN** AlarmKit delivery mode is active
- **AND** an expected AlarmKit alarm identifier exists in the platform state at a different fire date
- **WHEN** delivery reconciliation runs
- **THEN** the report SHALL flag the time mismatch

#### Scenario: AlarmKit alarm is missing
- **GIVEN** AlarmKit delivery mode is active
- **AND** no scheduled AlarmKit alarm exists for an expected wake delivery
- **WHEN** delivery reconciliation runs
- **THEN** the report SHALL flag the missing delivery

### Requirement: Delivery ledger remains local and privacy-preserving
The system SHALL record scheduling, cancellation, and verification decisions in a local-only delivery ledger without raw location or remote analytics.

#### Scenario: A wake event is scheduled
- **WHEN** the system records a schedule decision for a wake event
- **THEN** the ledger entry SHALL include the event date, event type, fire date, channel, permission mode, wake-rule signature, lifecycle reason, and result
- **AND** it SHALL NOT include raw location
- **AND** it SHALL NOT send the entry to an external service

#### Scenario: A schedule is cancelled
- **WHEN** the system records a cancellation
- **THEN** the ledger entry SHALL include the cancellation reason and affected delivery context
- **AND** it SHALL remain local to the device

### Requirement: Time changes force schedule refresh and reconciliation
The system SHALL force schedule refresh and delivery reconciliation after significant device time changes or timezone changes.

#### Scenario: Significant time changes
- **WHEN** the app receives a significant time-change notification
- **THEN** the system SHALL request a forced schedule refresh
- **AND** it SHALL reconcile platform delivery state for the refreshed schedule

#### Scenario: Timezone changes
- **WHEN** the app receives a timezone-change notification
- **THEN** the system SHALL request a forced schedule refresh
- **AND** it SHALL reconcile platform delivery state for the refreshed schedule

### Requirement: Notification fallback is degraded delivery
The system SHALL continue to treat notification-based fallback as degraded delivery and SHALL NOT expose app-level snooze behavior from notification mode.

#### Scenario: Notifications are used instead of AlarmKit
- **GIVEN** AlarmKit delivery is unavailable or not selected
- **WHEN** the system schedules wake delivery through notifications
- **THEN** diagnostics SHALL represent the mode as notification delivery
- **AND** the system SHALL NOT claim app-level snooze behavior
