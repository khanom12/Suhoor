## Context

The app already has a Subh shell, single home, morning resolver, scheduling services, AlarmKit/notification adapters, completion domain code, and several OpenSpec changes. The audit's highest-value executable work in this local session is not adding new user-facing features; it is turning static uncertainty into tracked evidence and removing drift that weakens confidence.

## Goals / Non-Goals

**Goals:**
- Create OpenSpec coverage for MVP readiness validation.
- Make `TEST_PLAN.md` reflect Subh's current Fajr-centered MVP rather than the older Suhoor/Ramadan framing.
- Replace `Purpose TBD` in durable specs with concrete purpose statements.
- Rename presentation-only onboarding preview fields from Suhoor to wake language.
- Run simulator build/test validation and record remaining manual/device gaps.

**Non-Goals:**
- No AlarmKit implementation changes or physical-device claims.
- No storage-key, bundle identifier, or persisted schema renames.
- No completion UI, override UI, or fasting/Qada workflow expansion in this pass.
- No GitHub repository metadata update from local code unless a separate publishing step is requested.

## Decisions

- Treat compatibility-bound `Suhoor.*` keys and `SuhoorSettingsStore` as out of scope because the rename compatibility spec intentionally preserves them until a migration proposal exists.
- Update main spec purpose text directly because those headers are durable documentation drift, not behavioral deltas that can be satisfied solely by archived requirements.
- Add a new `mvp-readiness-validation` capability so future MVP work has a clear contract for evidence, ordinary-loop readiness, and unresolved device QA.
- Keep code cleanup to `OnboardingTomorrowPreview` and related preview consumers because those names are presentation-only and do not affect persistence or scheduling.

## Risks / Trade-offs

- [Risk] Documentation can imply device reliability that has not been proven. -> Mitigation: the updated plan separates simulator proof from required physical-device AlarmKit QA.
- [Risk] Broad Suhoor renames can break persisted data. -> Mitigation: this pass only touches non-persistent preview naming and explicitly documents compatibility-bound surfaces.
- [Risk] Full test-plan execution can uncover pre-existing failures. -> Mitigation: record the exact commands and results, then keep fixes focused if failures are local and actionable.
