## ADDED Requirements

### Requirement: Canonical Resolved Wake State
The system SHALL resolve each visible morning into a `ResolvedMorningWakeState` payload that includes quick selection, underlying wake mode, day context, boundary regime, wake boundary, wake-time resolution, alarm activation, schedule status, visual mode, and copy state.

#### Scenario: Fajr default morning resolves through one payload
- **GIVEN** a morning with Fajr begins, Fajr ends, Maghrib, and no explicit early-worship intention
- **WHEN** the wake state is resolved
- **THEN** the payload quick selection SHALL be `fajr`, boundary regime SHALL be `defaultFajrWindow`, wake time SHALL be 30 minutes before Fajr ends, alarm activation SHALL be `active`, and visual mode SHALL be `interactiveDefaultFajr`

#### Scenario: Fast default morning resolves through one payload
- **GIVEN** a morning with Fajr begins, Fajr ends, Maghrib, and an intended fasting quick selection
- **WHEN** the wake state is resolved
- **THEN** the payload quick selection SHALL be `fast`, underlying wake mode SHALL be `earlyWorship`, boundary regime SHALL be `earlyWorshipWindow`, wake time SHALL be 30 minutes before Fajr begins, and visual mode SHALL be `interactiveEarlyWorship`

### Requirement: Quiet Is An Activation Overlay
Quiet selection SHALL suppress alarm activation without deleting the underlying Fajr or early-worship wake mode, day context, or available boundary.

#### Scenario: Quiet from Fajr preserves Fajr boundary
- **GIVEN** a Fajr-mode morning with a known Fajr begins and Fajr ends window
- **WHEN** the user selects Quiet
- **THEN** the resolved payload SHALL use `quickWakeSelection = quiet`, `underlyingWakeMode = fajr`, `alarmActivation = quietSuppressed`, `scheduleStatus = notScheduledBecauseQuiet`, and `visualMode = staticDefaultFajrQuiet`

#### Scenario: Quiet from Fast preserves early-worship boundary
- **GIVEN** an early-worship morning with a known final-third start and Fajr begins boundary
- **WHEN** the user selects Quiet
- **THEN** the resolved payload SHALL use `quickWakeSelection = quiet`, `underlyingWakeMode = earlyWorship`, `alarmActivation = quietSuppressed`, `scheduleStatus = notScheduledBecauseQuiet`, and `visualMode = staticEarlyWorshipQuiet`

### Requirement: Opportunity Does Not Imply Intention
The resolver SHALL distinguish fasting opportunities from intended fasting and SHALL NOT switch the boundary regime to early worship for opportunity-only mornings.

#### Scenario: Monday or White Days opportunity stays Fajr
- **GIVEN** a morning has a recommended fasting opportunity but no user-selected or automatic fasting intention
- **WHEN** the wake state is resolved
- **THEN** the payload SHALL keep `underlyingWakeMode = fajr` and `boundaryRegime = defaultFajrWindow`

### Requirement: Manual Adjustment Does Not Infer Worship Intent
Manual wake adjustment SHALL update wake-time origin without inferring fasting or Tahajjud intent.

#### Scenario: Dragging earlier in Fajr mode remains Fajr
- **GIVEN** a Fajr-mode morning
- **WHEN** the user commits a wake adjustment inside the supported adjustment window
- **THEN** the resolved payload SHALL mark the wake time as adjusted and SHALL NOT change the underlying wake mode to early worship

### Requirement: Activation Is Separate From Schedule Status
The resolver SHALL preserve active alarm intent separately from whether a platform scheduler has scheduled, failed, or blocked delivery.

#### Scenario: Permission blocked preserves active intent
- **GIVEN** a valid Fajr or Fast wake time with active alarm intent
- **WHEN** scheduling permission is blocked
- **THEN** the resolved payload SHALL keep `alarmActivation = active` and set `scheduleStatus = permissionBlocked`

#### Scenario: Quiet schedule status is not active failure
- **GIVEN** a valid Fajr or Fast wake time
- **WHEN** Quiet is selected
- **THEN** the resolved payload SHALL set `alarmActivation = quietSuppressed` and `scheduleStatus = notScheduledBecauseQuiet`
