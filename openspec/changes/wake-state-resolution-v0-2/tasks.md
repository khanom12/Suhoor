## 1. Domain Model

- [x] 1.1 Add canonical resolved wake-state enums and value models for boundary regime, wake-time origin, alarm activation, schedule status, visual mode, copy state, and resolved state.
- [x] 1.2 Add a resolver/service that composes `ResolvedMorningWakeState` from an `ActiveAlarmDay`, existing decision-log timing, and scheduler status input.
- [x] 1.3 Extend quick wake selection helpers so Quiet preserves the prior underlying wake mode where existing override state allows it.

## 2. Consumers

- [x] 2.1 Route Morning Hero presentation boundary, visual mode, and relation copy through the resolved wake-state payload.
- [x] 2.2 Route hero wake adjustment clamp-window selection through the resolved wake-state payload.
- [x] 2.3 Keep scheduling handoff centralized and avoid adding new direct alarm scheduling from views.

## 3. Tests And Validation

- [x] 3.1 Add focused resolver tests for Fajr default, Fast default, Quiet from Fajr/Fast, opportunity-only, Tahajjud, manual adjustment origin, and activation/status separation.
- [x] 3.2 Update focused presentation/service tests for hero visual/copy and adjustment-window behavior.
- [x] 3.3 Run `openspec validate wake-state-resolution-v0-2 --strict` and `openspec validate --all --strict`.
- [x] 3.4 Run the narrowest meaningful XCTest suite covering morning resolution, schedule extraction, and quick wake mode behavior.
