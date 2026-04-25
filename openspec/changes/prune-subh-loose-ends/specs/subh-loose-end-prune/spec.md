## ADDED Requirements

### Requirement: Retired Surfaces Removed From Production
The app SHALL not compile retired tab-era screens that have no Subh MVP entry point.

#### Scenario: Retired primary surface has no code path
- **WHEN** the app launches after onboarding
- **THEN** production navigation SHALL expose the single Subh home and settings paths, not legacy Today, Plans, Progress, Wake-list, fasting planning, Qada planning, or old alarm editing screens.

### Requirement: MVP Runtime Path Protected
The prune SHALL preserve the Subh MVP runtime path.

#### Scenario: MVP surface remains available
- **WHEN** a user opens the completed app
- **THEN** onboarding completion, Tomorrow Morning, Weekly Fajrcast, 10-day Morningcast, Tomorrow Morning detail, settings, prayer/Hijri configuration, permissions/reliability, and alarm scheduling SHALL remain available.

### Requirement: Onboarding Uses MVP Wake Doctrine
Onboarding SHALL not expose retired pre-Fajr offset customization or plan-era branching in the MVP path.

#### Scenario: New user reaches onboarding
- **WHEN** a fresh user begins setup
- **THEN** onboarding SHALL explain the fixed 30-minutes-before-supported-Fajr-end relationship
- **AND** it SHALL only ask for location and reliability permissions before completion.

### Requirement: Dormant Data Preserved
The prune SHALL remove dormant runtime paths without deleting existing local legacy storage namespaces.

#### Scenario: Legacy data stays on disk
- **WHEN** legacy planning, fasting, progress, or Qada code paths are removed
- **THEN** existing `Suhoor.*` storage keys SHALL remain untouched unless a future migration explicitly changes them.

### Requirement: Disabled Diagnostic Runtime Removed
The prune SHALL remove disabled test/diagnostic runtime paths that have no production entry point.

#### Scenario: Disabled experiments do not inflate launch
- **WHEN** the app constructs the MVP schedule manager
- **THEN** it SHALL not construct countdown live-activity managers, AlarmKit test-mode stores, test alarm runners, or debug event logs that are not reachable from the MVP user experience.

### Requirement: Removal-First Implementation
The prune SHALL remove more code than it adds.

#### Scenario: Change is reviewed
- **WHEN** the cleanup diff is inspected
- **THEN** deleted production/test code SHALL materially exceed new support code.
