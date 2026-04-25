## 1. Architecture

- [x] 1.1 Expose resolver-owned wake calculation helpers that can be reused by compatibility schedule builders.
- [x] 1.2 Replace duplicate wake math in `DayScheduleBuilder` with resolver-owned wake calculation.
- [x] 1.3 Audit first-wave display/scheduling paths and document any remaining legacy paths as non-authoritative compatibility surfaces.

## 2. Cache And Presentation

- [x] 2.1 Keep schedule-cache invalidation tied to wake-rule signatures so stale resolver projections cannot render.
- [x] 2.2 Ensure Tomorrow Morning and Morningcast consume resolved schedules/decision logs rather than local offset recomputation.

## 3. Tests And Validation

- [x] 3.1 Add or keep focused tests proving compatibility schedule building matches Fajr-end resolver output.
- [x] 3.2 Add or keep focused tests proving stale wake-rule cache entries are ignored.
- [x] 3.3 Run `openspec validate --all --strict`.
- [x] 3.4 Run focused Xcode tests for alarm config migration and home snapshot behavior.
