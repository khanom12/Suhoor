## Implementation Report

Date: 2026-05-30

## What Changed

- Synced the May 30 reconciled Subh specification bundle into the active Desktop spec folder and repo `docs/specs` mirror, bumped active spec filenames/internal versions by exactly +1, and archived the superseded active root specs.
- Updated the OpenSpec change `align-quiet-pause-hero-wake-flow` so the proposal, design, delta spec, and implementation report reference the promoted May 30 v2 alignment spec.
- Audited the existing domain model and verified it already separates `WakePurpose`, `DateAlarmOverride`, `GlobalWakeAlarmPolicy`, `ResolvedAlarmState`, and `WakeAcknowledgementSource`.
- Removed the old active-session Quiet cancellation path from Home, Day Detail, ScheduleService, and Wake Session Lab. Quiet is now exposed before execution, not after the first alarm begins.
- Added Slot 3 alarm-state action sheets on Home and Day Detail for Quiet, turning a quiet morning back on, one-morning ring exceptions while paused, and resuming global wake alarms.
- Updated paused Hero presentation so inherited Pause surfaces as `Alarms paused` instead of `Alarm off`, and changed permission-blocked delivery summary copy to the user action `Turn on alarms`.
- Reworked the Wake Session Lab quiet scenario as `Quiet Before Execution`, with no test wake alarms scheduled and no active-session Stop-check confirmation flow.
- Updated tests and UI helpers to remove obsolete Stop-check expectations and cover the quiet-before-execution and paused-Hero states.

## Validation

- `openspec validate align-quiet-pause-hero-wake-flow --strict` passed.
- `openspec validate --all --strict` passed with 88 valid items and 0 failures.
- `xcodebuild -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' build` passed.
- `xcodebuild -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' test -only-testing:SubhTests/ScheduleServiceExtractionTests` passed with 111 tests.
- `xcodebuild -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' test` passed with 251 app/unit tests and 4 UI tests.

## User-Visible Impact

- Home and Day Detail planning states expose Fajr/Suhoor as the wake-purpose selector and keep Quiet/Pause in the alarm-state control.
- Quiet keeps the selected morning plan saved while suppressing that date's wake alarm before execution begins.
- Paused mornings show `Alarms paused`, can ring once for the target morning, and can resume global wake alarms without wiping manual Quiet overrides.
- Active alarm execution no longer exposes Quiet or Stop-check copy; the visible action remains `I'm awake`.
- Suhoor wake, fasting intent, Fajr wake acknowledgement, and Fajr prayer logging remain separate current-morning facts.

## Privacy And Reliability Notes

- No new production dependency, network call, analytics path, or third-party SDK was added.
- Pause and Quiet are local settings/overrides, and the implementation keeps schedule, observance state, and alarm history within existing local stores.
- Scheduling changes are scoped to Subh wake deliveries and wake-session identifiers; boundary and unrelated non-wake reminders remain outside Quiet/Pause suppression.
- Existing legacy enum compatibility remains isolated at decoding/resolver boundaries instead of forcing a broad persistence rename.

## Remaining Risk

- Xcode still reports pre-existing actor-isolation warnings and the iOS 26 `UIRequiresFullScreen` deprecation warning during build/test.
- AlarmKit callback precision still depends on the platform adapter path; the wake-session layer records system dismissal as its own acknowledgement source where that event is available.
