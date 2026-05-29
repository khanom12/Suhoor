## Why

The latest May 29 specification bundle resolves several product-model conflicts around Quiet, indefinite Pause, Home Hero state, and wake-session copy. Subh needs this pass now so the MVP stays anchored on a single Fajr/Suhoor morning engine instead of exposing Quiet/Pause or older Pre-Fajr terminology as parallel wake modes.

## What Changes

- Align user-facing wake-purpose selection to `Fajr | Suhoor` only across Home, Day Detail, forecast, month-planning, and test surfaces.
- Move Quiet out of the wake-purpose selector and into date-level alarm-state controls that preserve the selected Fajr/Suhoor purpose and saved alarm settings.
- Add indefinite app-wide wake-alarm Pause behavior, with a one-morning `Ring tomorrow only` / `Ring this morning only` exception while Pause remains active.
- Keep setup, permission, delivery issue, Quiet, Pause, and ring-once states distinct in resolution and presentation.
- Update Home Hero presentation to a fixed-height six-slot state model, including one active alarm action: `I’m awake`.
- Update wake execution copy and post-awake CTAs: delayed `I’m fasting today`, delayed `I prayed Fajr`, Fajr-begin handoff during Suhoor flow, and Fajr-end handoff to the next morning.
- Update Wake Session Lab/test harness scenarios to cover the new Quiet/Pause/Hero state model using user-facing labels first.
- Preserve existing user settings, saved plans, and scheduled-alarm safety; refresh/cancel only the affected Subh wake alarms when state changes require it.

No breaking user-data migration is intended. Existing legacy/internal names may remain where renaming would risk persistence or scheduling compatibility, but visible MVP copy must align with the May 29 vocabulary.

## Capabilities

### New Capabilities

- `quiet-pause-wake-alarm-policy`: Owns date-level Quiet, indefinite app-wide Pause, one-morning ring exceptions while paused, and the distinction between alarm-state policy and wake purpose.

### Modified Capabilities

- `morning-resolution`: Separates wake purpose, date alarm override, global pause policy, resolved alarm state, and wake execution state.
- `single-screen-morning-home`: Updates the Home Hero selector, alarm-state button, fixed-slot layout behavior, planning/paused/quiet/active/post-awake copy, and Slot 6 CTA rules.
- `wake-session-execution`: Updates active alarm acknowledgement, follow-up cancellation, system dismissal treatment, CTA timing, and Suhoor/Fajr post-awake flow.

## Impact

- Affected Swift domain and store code: `MorningModels`, `MorningPlanStore`, `MorningWakeResolutionService`, `WakeStateSelectionResolver`, `WakeSessionStore`, `WakeSessionTestingHarness`, and scheduling/reconciliation services where Quiet/Pause suppression changes delivery.
- Affected SwiftUI and presentation code: `MorningHomePresentation`, `SubhHomeView`, `MorningHeroWakeAdjustmentMapper`, `AlarmDayDetailView`, forecast/month rows, Settings wake-alarm controls, and Wake Session Lab surfaces.
- Affected tests: domain/persistence tests for purpose-specific memory and override precedence, presentation tests for hero/forecast vocabulary, wake-session tests for acknowledgement and CTA timing, and harness tests for new state cards.
- Existing scheduled alarms may be cancelled/rescheduled when Quiet, Pause, resume, ring-once exception, purpose changes, or wake-time changes are applied. Unrelated alarms and unrelated date keys must not be cancelled.
- No new production dependency is expected.
