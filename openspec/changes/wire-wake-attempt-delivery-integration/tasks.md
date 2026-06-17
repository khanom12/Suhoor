## 1. OpenSpec

- [x] 1.1 Create proposal, design, tasks, and wake-session execution spec delta.
- [x] 1.2 Validate `wire-wake-attempt-delivery-integration` with `openspec validate --strict` before implementation.

## 2. Scheduling Integration Proof

- [x] 2.1 Add tests proving Repeat mode active days expose primary plus all derived wake checks.
- [x] 2.2 Add tests proving Single mode active days expose only the primary wake delivery.
- [x] 2.3 Add tests proving `AlarmScheduler.scheduleDay` schedules every wake attempt in notifications, AlarmKit, and mixed modes.
- [x] 2.4 Add tests proving expected-delivery persistence includes all Repeat attempts and only the Single primary attempt.

## 3. Fallback Cleanup

- [x] 3.1 Route `scheduleTomorrowActivation()` cache-miss fallback through resolver-built active days.
- [x] 3.2 Route `dayForCancellation()` cache-miss fallback through resolver-built active days.
- [x] 3.3 Verify remaining compatibility fallback usage is not on the production wake-attempt scheduling path.

## 4. Legacy Scheduler Cleanup

- [x] 4.1 Remove unused direct `RoutineScheduler` wake/reminder/adhan scheduling helpers.
- [x] 4.2 Keep `RoutineScheduling.scheduleEvent` as the canonical scheduling interface.
- [x] 4.3 Preserve `snoozeDuration: nil` for wake attempts and document it as intentional.

## 5. Validation

- [x] 5.1 Run focused scheduling tests.
- [x] 5.2 Run app build.
- [x] 5.3 Attempt broader unit target and record unrelated failures separately.
- [x] 5.4 Validate OpenSpec strict mode again before commit.
