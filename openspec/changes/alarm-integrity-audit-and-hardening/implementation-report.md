# Implementation Report

## Summary

The alarm integrity hardening pass is implemented. The default wake rule remains daily active, supported Fajr end, 30 minutes before Fajr end. The delivery pipeline now treats platform scheduling state as mutable external state that must be verified and reasserted independently from schedule-window cache reuse.

## Changed Areas

- `Subh/Core/Scheduling/SchedulingIdentifierSet.swift`: shared current and legacy identifier expansion for notification and AlarmKit IDs.
- `Subh/Core/Services/DeliveryReconciliationReport.swift`: expected-vs-pending delivery verification models and report summaries.
- `Subh/Core/Services/AlarmDeliveryLedgerStore.swift`: capped local-only ledger for schedule, cancellation, and verification decisions.
- `Subh/Core/Services/ScheduleService.swift`: cached-window reconciliation, delivery diagnostics, ledger recording, and diagnostics/export summaries.
- `Subh/Core/Services/AlarmScheduler.swift`: stale-safe per-day cancellation before unknown-day scheduling.
- `Subh/Core/Services/RoutineScheduler.swift`: testable scheduling protocol plus shared identifier cancellation.
- `Subh/Core/Services/NotificationScheduler.swift`: pending notification inspection and shared cancellation sets.
- `Subh/Core/Services/AlarmKitScheduling.swift` and `Subh/Core/Services/AlarmKitScheduler.swift`: AlarmKit state inspection and shared cancellation sets.
- `Subh/Core/Services/ScheduleRefreshCoordinator.swift`: significant time and timezone refresh reasons.
- `Subh/App/SubhApp.swift`: root lifecycle handlers for significant time and timezone notifications.
- `Subh/Features/Settings/PermissionsReliabilityView.swift` and `Subh/Features/Settings/SettingsRootView.swift`: delivery check and ledger diagnostics.
- `SubhTests/ScheduleServiceExtractionTests.swift`: regression coverage for wake default, cache invalidation/reuse, stale identifiers, notifications, AlarmKit mismatches, and time-change behavior.

## Verification

- `xcodebuild test -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,id=D91F0066-DFFD-4172-ABD0-C87CB1692D0B' -only-testing:SubhTests/ScheduleServiceExtractionTests`
  - Passed: 51 tests.
- `xcodebuild test -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,id=D91F0066-DFFD-4172-ABD0-C87CB1692D0B' -only-testing:SubhTests`
  - Passed: 166 tests.
- `openspec validate alarm-integrity-audit-and-hardening --strict`
  - Passed after proposal, design, specs, tasks, and report creation.

## Residual Risk

- The April 30, 2026 device incident cannot be proven from code alone without the device's delivery mode, pending alarm state, Focus/DND state, permissions, and any competing alarm-app behavior.
- AlarmKit state inspection remains platform-availability dependent. The code compares state where available and reports degraded/unavailable modes where not.
- Full-suite simulator logs can show transient expected-vs-pending mismatches while tests concurrently mutate the simulator notification center. The deterministic reconciliation helpers are unit-covered, and the full target passes.
