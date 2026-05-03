## ADDED Requirements

### Requirement: Onboarding Uses Four Fajr-Centered Activation Steps
The onboarding flow SHALL use the existing four required first-run steps: value preview, location, reliability, and ready. It SHALL explain Subh as a Fajr-centered morning system and SHALL NOT add mandatory fasting, Tahajjud, Ramadan, Qada, calculation-method, or wake-offset steps during first-run onboarding.

#### Scenario: Fresh user sees the v1 flow
- **GIVEN** `AppSettings.isConfigured` is false
- **WHEN** onboarding starts
- **THEN** the flow SHALL begin with the value preview
- **AND** the required flow SHALL contain no more than value preview, location, reliability, and ready steps.

#### Scenario: Value preview advances to first unresolved setup step
- **GIVEN** the user is on the value preview
- **WHEN** the user taps the primary setup CTA
- **THEN** onboarding SHALL advance to location if location is not ready
- **AND** it SHALL advance to reliability if location is ready and AlarmKit is not ready
- **AND** it SHALL advance to ready only when location, prayer-time, and AlarmKit readiness are already true.

### Requirement: Location Readiness Is Required
Onboarding SHALL require either usable automatic location or a chosen fixed city before completion. The app SHALL request location permission only after the user taps the location CTA, and manual city selection SHALL remain available as the fallback.

#### Scenario: Automatic location without fix stays blocked
- **GIVEN** location permission is authorized
- **AND** no usable location fix exists
- **WHEN** onboarding evaluates readiness
- **THEN** location readiness SHALL be false
- **AND** onboarding SHALL keep offering city selection.

#### Scenario: Fixed city satisfies location readiness
- **GIVEN** the user chooses a city
- **WHEN** the fixed location is saved
- **THEN** location readiness SHALL be true
- **AND** onboarding SHALL request schedule refresh for the selected city.

#### Scenario: Calculation method is hidden by default
- **GIVEN** the user is in normal first-run onboarding
- **WHEN** the location step renders
- **THEN** calculation-method selection SHALL NOT be shown by default.

### Requirement: Prayer-Time Preview Readiness Is Required
Onboarding SHALL require a resolved schedule preview before writing onboarding completion. If location exists but no Fajr-centered schedule can be resolved, onboarding SHALL show a blocked or repair state instead of "Your first wake is ready."

#### Scenario: Location exists but schedule is empty
- **GIVEN** location readiness is true
- **AND** the active schedule window has no visible days
- **WHEN** the user reaches completion
- **THEN** onboarding completion SHALL be blocked
- **AND** `AppSettings.isConfigured` SHALL remain false.

#### Scenario: Schedule exists for the next relevant morning
- **GIVEN** location readiness is true
- **AND** a schedule exists for the next relevant morning
- **WHEN** the value or ready preview renders
- **THEN** onboarding SHALL show actual wake and Fajr timing for that morning.

### Requirement: AlarmKit Authorization Is Required For Completion
Onboarding SHALL treat AlarmKit authorization as required. AlarmKit denied, restricted, unavailable, not determined, or needs-follow-up states SHALL block onboarding completion and SHALL NOT be replaced by notification readiness.

#### Scenario: AlarmKit authorized allows completion readiness
- **GIVEN** location readiness is true
- **AND** prayer-time readiness is true
- **AND** AlarmKit state is authorized
- **WHEN** onboarding evaluates readiness
- **THEN** completion readiness SHALL be true regardless of notification authorization.

#### Scenario: AlarmKit denied blocks completion
- **GIVEN** location readiness is true
- **AND** prayer-time readiness is true
- **AND** AlarmKit state is denied
- **WHEN** onboarding evaluates readiness
- **THEN** completion readiness SHALL be false
- **AND** the blocked reason SHALL be missing AlarmKit.

#### Scenario: AlarmKit unavailable blocks completion
- **GIVEN** notifications are authorized
- **AND** AlarmKit state is unavailable
- **WHEN** onboarding evaluates readiness
- **THEN** completion readiness SHALL be false
- **AND** onboarding SHALL NOT describe notifications as wake fallback activation.

### Requirement: Notifications Are Recommended And Non-Blocking
Onboarding SHALL present notifications as recommended support for reminders and schedule updates. Notification not-determined, denied, restricted, or unavailable states SHALL NOT block onboarding completion when location, prayer-time, and AlarmKit readiness are true.

#### Scenario: Notifications denied still allows ready state
- **GIVEN** location readiness is true
- **AND** prayer-time readiness is true
- **AND** AlarmKit state is authorized
- **AND** notifications are denied
- **WHEN** onboarding evaluates readiness
- **THEN** onboarding SHALL allow completion
- **AND** the ready state SHALL communicate notifications off without blocking the user.

#### Scenario: Notifications prompt follows user action
- **GIVEN** the reliability step is visible
- **WHEN** notification state is not determined
- **THEN** onboarding SHALL show an optional notification action
- **AND** the system notification permission request SHALL occur only when the user taps that action.

### Requirement: Ready Completion Is Guarded
The ready screen SHALL write `AppSettings.isConfigured = true` only after rechecking location readiness, prayer-time readiness, and AlarmKit readiness. If any precondition fails, the ready screen SHALL show a blocked state and route the user back to the unresolved step.

#### Scenario: Preconditions pass
- **GIVEN** location readiness is true
- **AND** prayer-time readiness is true
- **AND** AlarmKit state is authorized
- **WHEN** the user taps the ready CTA
- **THEN** onboarding SHALL refresh schedules if needed
- **AND** it SHALL set `AppSettings.isConfigured = true`
- **AND** root routing SHALL be allowed to show Home.

#### Scenario: Preconditions fail on ready screen
- **GIVEN** the user reaches the ready step
- **AND** AlarmKit state is unavailable
- **WHEN** the ready step renders or completion is attempted
- **THEN** onboarding SHALL NOT show "Your first wake is ready"
- **AND** it SHALL show a blocked setup state with a CTA back to the unresolved step
- **AND** `AppSettings.isConfigured` SHALL remain false.

### Requirement: Repair Routing Matches Required Readiness
Configured users SHALL be routed to onboarding repair when required location or AlarmKit readiness regresses. Notification denial alone SHALL NOT route a configured user away from Home.

#### Scenario: Configured user loses AlarmKit
- **GIVEN** `AppSettings.isConfigured` is true
- **AND** AlarmKit state is denied or unavailable
- **WHEN** bootstrap state is evaluated
- **THEN** the app SHALL route to onboarding repair instead of Home.

#### Scenario: Configured user denies notifications only
- **GIVEN** `AppSettings.isConfigured` is true
- **AND** location readiness is true
- **AND** AlarmKit state is authorized
- **AND** notifications are denied
- **WHEN** bootstrap state is evaluated
- **THEN** the app SHALL show Home.

### Requirement: Onboarding Visuals Use Subh Home Language
Onboarding SHALL use Subh's dawn background, contrast overlay, glass surfaces, premium time typography, and a read-only Home-hero-like preview for value and ready screens. Onboarding SHALL NOT expose wake adjustment or quick wake-mode selection.

#### Scenario: Value preview uses labeled actual or example data
- **GIVEN** schedule data is unavailable
- **WHEN** the value preview renders example wake and Fajr times
- **THEN** the preview SHALL be labeled as an example
- **AND** VoiceOver SHALL include "Example" in the preview label.

#### Scenario: Ready preview is read-only
- **GIVEN** the ready screen is shown
- **WHEN** the hero-like wake preview renders
- **THEN** it SHALL show the target day, location or city, wake time, Fajr relationship, AlarmKit readiness, and notification state when useful
- **AND** it SHALL NOT persist wake adjustments or show quick wake-mode selection.
