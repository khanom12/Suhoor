## 1. OpenSpec and Domain State

- [x] 1.1 Add a target-morning quick wake-mode enum and persist explicit selections on daily overrides.
- [x] 1.2 Expose explicit quick wake mode through effective daily config and active-day resolution.
- [x] 1.3 Add a shared resolver/helper for selected mode, early-worship eligibility, quiet state, and mode-specific override mutations.

## 2. Scheduling and Snapshot Flow

- [x] 2.1 Add a ScheduleManager intent method for selecting Fast, Fajr, or Quiet for the hero target morning.
- [x] 2.2 Preserve selected quick mode when committing hero wake-time drags.
- [x] 2.3 Ensure selection rebuilds the active day and refreshes Weekly Fajrcast / next-ten snapshots through the existing active-window path.

## 3. Hero UI

- [x] 3.1 Add quick wake-mode fields to the hero presentation contract.
- [x] 3.2 Render the liquid-glass `Fast | Fajr | Quiet` selector below the relation line with stable accessibility identifiers.
- [x] 3.3 Render Quiet mode as static Fajr boundary context with no marker or adjustable control.

## 4. Validation

- [x] 4.1 Add/update presentation and domain tests for Fast, Fajr, Quiet, drag preservation, and missing-data behavior.
- [x] 4.2 Add/update schedule-manager tests for target-morning-only persistence and downstream snapshot refresh.
- [x] 4.3 Add/update UI coverage for selector rendering and mode changes.
- [x] 4.4 Run OpenSpec validation, focused tests, UI tests, and diff checks.
