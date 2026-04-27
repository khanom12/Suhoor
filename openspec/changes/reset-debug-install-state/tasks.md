## 1. OpenSpec

- [x] 1.1 Add proposal, design, spec deltas, and tasks for `reset-debug-install-state`.
- [x] 1.2 Validate the change with `openspec validate reset-debug-install-state`.

## 2. Debug Reset

- [x] 2.1 Add a DEBUG-only install fingerprint reset utility.
- [x] 2.2 Run the reset before settings and alarm stores initialize in `SubhApp`.
- [x] 2.3 Clear local app `UserDefaults` state and pending notification requests only when the debug install fingerprint changes.

## 3. Verification

- [x] 3.1 Add focused tests for unchanged, first-run, and changed-fingerprint reset behavior.
- [x] 3.2 Run `openspec validate reset-debug-install-state`.
- [x] 3.3 Run the focused migration/reset tests.
- [x] 3.4 Run the Subh simulator build.
- [x] 3.5 Run the configured Subh test plan.
