## Implementation Report

Date: 2026-05-29

## What Changed

- Synced the May 29 Subh specification bundle into the active Desktop spec folder and archived the superseded Desktop specs.
- Added the OpenSpec change `align-quiet-pause-hero-wake-flow` with proposal, design, and delta specs for the Quiet/Pause/Home Hero/Wake Flow alignment.
- Split wake purpose from alarm state in the domain model: Fajr/Suhoor remain the visible purposes, while Quiet, global Pause, and ring-once exceptions resolve as alarm-state policy.
- Added persistence and resolver support for date alarm overrides, global wake-alarm pause, resolved alarm state, and acknowledgement source without destructive migration.
- Updated scheduling and reconciliation so Quiet and Pause suppress only Subh wake deliveries, while a one-morning ring exception can schedule despite global Pause.
- Updated wake execution so in-app awake confirmation and explicit system alarm dismissal both complete the MVP wake acknowledgement, with fasting intent and Fajr prayer confirmation remaining separate records.
- Updated Home Hero, Day Detail, forecast/month rows, Settings, notification copy, and testing harness copy to use the final vocabulary: Quiet, Alarms paused, Ring tomorrow only, Time to wake, I'm awake, I'm fasting today, and I prayed Fajr.
- Updated the Wake Session Lab preview cards and guidance so the internal harness names the final Active, Quiet, Paused, Exception, Setup/issue, Execution, Post-awake, Boundary, and Handoff state groups.

## Validation

- `openspec validate align-quiet-pause-hero-wake-flow --strict` passed.
- `openspec validate --all --strict` passed with 88 valid items and 0 failures.
- `xcodebuild -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' build` passed.
- `xcodebuild -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' test -only-testing:SubhTests/ScheduleServiceExtractionTests` passed with 111 tests.
- `xcodebuild -project Subh.xcodeproj -scheme Subh -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.2' test` passed with 251 unit tests and 4 UI tests.

## User-Visible Impact

- Home planning selection now presents Fajr and Suhoor as the wake-purpose choices; Quiet is no longer treated as a third purpose.
- Quiet keeps the selected morning plan saved while suppressing that date's wake alarm.
- Settings can pause Subh wake alarms indefinitely, and Home can ring one morning despite Pause without resuming all future alarms.
- Active alarm Hero copy is one-action: Time to wake with I'm awake; when no follow-up alarm is eligible it says Final alarm this morning.
- Suhoor awake acknowledgement no longer automatically confirms fasting intent; the user gets a separate I'm fasting today action.
- Fajr prayer confirmation remains separate from waking, including after a Suhoor-to-Fajr handoff.

## Privacy And Reliability Notes

- No new production dependency, network call, analytics path, or third-party SDK was added.
- Pause and Quiet are local settings/overrides, and the implementation keeps schedule, observance state, and alarm history within existing local stores.
- Scheduling changes are scoped to Subh wake deliveries and wake-session identifiers; boundary and unrelated non-wake reminders remain outside Quiet/Pause suppression.
- Existing legacy enum values are normalized at resolver/presentation boundaries instead of forcing a broad persistence rename.

## Remaining Risk

- Xcode still reports pre-existing actor-isolation warnings and the iOS 26 `UIRequiresFullScreen` deprecation warning during build/test.
- AlarmKit callback precision still depends on the platform adapter path; the wake-session layer records system dismissal as its own acknowledgement source where that event is available.
