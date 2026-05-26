## 1. Retrospec Documentation

- [x] 1.1 Confirm the implementation commit that was completed before this OpenSpec record: `18a2404 feat: add wake sessions and wake checks`.
- [x] 1.2 Record the retrospective proposal explaining why this OpenSpec change exists after implementation.
- [x] 1.3 Record the design decisions, alternatives, risks, migration notes, and open questions from the implemented code.
- [x] 1.4 Add delta specs for the new `wake-session-execution` capability.
- [x] 1.5 Add delta specs for the affected `morning-resolution` capability.
- [x] 1.6 Add delta specs for the affected `single-screen-morning-home` capability.
- [x] 1.7 Add an implementation report tying code files, behavior, and validation back to this retrospec.

## 2. Implemented Model And Persistence

- [x] 2.1 Add a local Wake Session model for one target morning's execution lifecycle.
- [x] 2.2 Add statuses for scheduled, active, fired/unconfirmed, wake checks pending, confirmed, expired, cancelled, and Quiet outcomes.
- [x] 2.3 Add local MorningLog operational records for wake-session lifecycle and current-morning check-ins.
- [x] 2.4 Persist Wake Sessions and MorningLogs locally without adding cloud sync, export, historical editing, or paid history UI.

## 3. Implemented Scheduling Behavior

- [x] 3.1 Derive Wake Checks from the existing morning resolver output instead of creating a second morning engine.
- [x] 3.2 Schedule up to five 5-minute Wake Checks after the primary wake attempt.
- [x] 3.3 Enforce Fajr cutoff no later than five minutes before Fajr ends.
- [x] 3.4 Enforce Suhoor cutoff no later than five minutes before Fajr begins.
- [x] 3.5 Schedule only future Wake Checks in the active scheduled horizon.
- [x] 3.6 Use deterministic wake-session and wake-check identifiers.
- [x] 3.7 Include stale wake-check identifiers in reconciliation cancellation candidates.
- [x] 3.8 Disable native AlarmKit snooze for MVP wake-session events.

## 4. Implemented Current-Morning Behavior

- [x] 4.1 Confirming awake for Fajr marks wake confirmation and cancels remaining wake-session events without confirming prayer.
- [x] 4.2 Confirming awake for Suhoor marks wake confirmation, cancels remaining wake-session events, and confirms/plans fasting intent without confirming Fajr prayer or fast completion.
- [x] 4.3 Confirming `I prayed Fajr` records prayer confirmation separately from awake confirmation.
- [x] 4.4 Alarm stop or dismissal remains operational and does not confirm awake.
- [x] 4.5 Quiet active-session cancellation requires explicit user confirmation.
- [x] 4.6 Quiet cancellation cancels remaining wake-session events and records `quietMorning` without missed-prayer logging.

## 5. Implemented Home Hero And Entitlement Behavior

- [x] 5.1 Add a fixed Home Hero Action Slot for active-session CTAs and confirmed states.
- [x] 5.2 Show `I'm awake for Fajr`, `I'm awake for Suhoor`, and `I prayed Fajr` in the current-morning context according to wake/prayer state.
- [x] 5.3 Keep Quiet state from showing an awake-confirmation CTA.
- [x] 5.4 Keep Wake Sessions, core Wake Checks, current-morning check-ins, and Quiet Morning free/core with no StoreKit or paywall work.

## 6. Validation

- [x] 6.1 Add/update tests for Fajr Wake Check defaults and cutoff behavior.
- [x] 6.2 Add/update tests for Suhoor Wake Check defaults and cutoff behavior.
- [x] 6.3 Add/update tests for confirming awake cancelling pending wake checks.
- [x] 6.4 Add/update tests that platform alarm stop does not confirm awake.
- [x] 6.5 Add/update tests for Quiet cancellation and `quietMorning` logging without missed-prayer logging.
- [x] 6.6 Add/update tests for Suhoor confirmation separating fasting intent, Fajr prayer, and fast completion.
- [x] 6.7 Add/update tests for Fajr prayer confirmation separate from awake confirmation.
- [x] 6.8 Add/update tests for stale wake-check reconciliation.
- [x] 6.9 Add/update tests that entitlement does not block core Wake Session behavior.
- [x] 6.10 Run `git diff --check`.
- [x] 6.11 Run targeted ScheduleService and ScheduleManagerHijri test suites.
- [x] 6.12 Run targeted Home Hero UI selector test.
- [x] 6.13 Run the full `Subh` Xcode test suite successfully.
