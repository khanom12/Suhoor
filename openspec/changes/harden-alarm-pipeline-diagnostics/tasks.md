## 1. OpenSpec
- [x] 1.1 Add proposal, design, spec delta, and tasks for `harden-alarm-pipeline-diagnostics`.
- [x] 1.2 Validate OpenSpec change artifacts.

## 2. Debug reset reliability
- [x] 2.1 Gate debug install reset behind explicit mode configuration.
- [x] 2.2 Log whether startup reset was applied or skipped.

## 3. Alarm pipeline diagnostics
- [x] 3.1 Add diagnostics report helper for expected deliverable events.
- [x] 3.2 Log schedule diagnostics after reconciliation.
- [x] 3.3 Warn when scheduling remains enabled but no deliverable events exist.
- [x] 3.4 In notification mode, compare expected IDs against pending requests and log misses.

## 4. Verification
- [x] 4.1 Update reset tests for explicit mode behavior.
- [x] 4.2 Add tests for default-disabled and environment-driven reset mode.
- [x] 4.3 Run focused test suite for migration/reset behavior.
