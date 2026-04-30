## 1. Domain Models

- [x] 1.1 Add day-purpose models for observance opportunities, resolved intention, wake classification, required actions, analytics credits, explanation, and `ResolvedDayPurpose`.
- [x] 1.2 Wire `ResolvedDayPurpose` into `ResolvedDaySnapshot`.

## 2. Resolvers

- [x] 2.1 Add `ObservanceOpportunityResolver` using `FastIntentEngine`, `TagComputationResult`, and scheduled-date provenances where available.
- [x] 2.2 Add `DayIntentionResolver` that separates opportunity from default/fast/tahajjud/quiet intention and adapts existing `fastTagSelections`.
- [x] 2.3 Add `DayWakeClassificationResolver` that maps intention plus existing wake resolution into product-facing wake classes.
- [x] 2.4 Add `DayRequiredActionResolver` so optional opportunities do not create fast completion pressure.
- [x] 2.5 Add `ObservanceCreditResolver` for opportunity/planned/completed/missed/kept-default/quiet/forbidden credits.
- [x] 2.6 Add `DayPurposeResolver` as the orchestration layer.

## 3. Integration

- [x] 3.1 Wire `DayPurposeResolver` into `MorningScheduleResolver.resolve(...)` without changing prayer-time or event materialization behavior.
- [x] 3.2 Preserve existing `ResolvedDayContext` output as compatibility/presentation data.
- [x] 3.3 Ensure qada completion credits qada without automatically crediting Sunnah opportunities.

## 4. MVP Persistence Compatibility

- [x] 4.1 Adapt existing `fastTagSelections` into fast intentions for MVP.
- [x] 4.2 Do not require immediate migration to a unified `DayIntentionSelection` store.
- [x] 4.3 Add future hooks for quiet and Tahajjud selections without inventing persistence.

## 5. Tests

- [x] 5.1 Test Monday/Thursday opportunity with default Fajr intention.
- [x] 5.2 Test White Day opportunity with default Fajr intention.
- [x] 5.3 Test voluntary fast planned/completed on Monday/Thursday.
- [x] 5.4 Test voluntary fast planned/not-completed on White Day.
- [x] 5.5 Test qada completed on White Day does not credit White Day completion.
- [x] 5.6 Test Ramadan auto-intention.
- [x] 5.7 Test Eid/Tashreeq forbidden opportunity and invalid forbidden fast logging.

## 6. Validation

- [x] 6.1 Run OpenSpec strict validation.
- [x] 6.2 Run focused unit tests for new resolvers.
- [x] 6.3 Run existing scheduling and completion tests touched by the pipeline.
