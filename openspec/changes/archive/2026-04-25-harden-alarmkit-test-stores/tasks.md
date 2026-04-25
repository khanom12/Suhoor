## 1. Store Recovery

- [x] 1.1 Add `UserDefaults` injection to `AlarmKitTestSettingsStore` while preserving the default `.standard` behavior.
- [x] 1.2 Reset invalid AlarmKit test settings payloads to encoded defaults during load.
- [x] 1.3 Add `UserDefaults` injection to `AlarmKitTestRunStore` while preserving the default `.standard` behavior.
- [x] 1.4 Remove invalid AlarmKit test-run payloads during load.

## 2. Verification

- [x] 2.1 Add tests for missing, valid, and invalid AlarmKit test settings persistence.
- [x] 2.2 Add tests for missing, valid, and invalid AlarmKit test-run persistence.
- [x] 2.3 Run the focused XCTest target or an available equivalent verification command.
