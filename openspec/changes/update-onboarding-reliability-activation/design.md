## Context

The attached onboarding specification preserves the existing four-step SwiftUI flow: `valuePreview`, `location`, `permissions`, and `success`. Current implementation already uses `OnboardingViewModel`, `OnboardingView`, `LocationSearchView`, `ScheduleManager.permissionSnapshot`, `LocationService`, `AlarmKitScheduler`, and `NotificationScheduler`, but the activation rules are behind the spec:

- `OnboardingViewModel.isSchedulingReady` treats AlarmKit `.unavailable` plus authorized notifications as ready.
- Notifications can be described as required or fallback wake delivery in onboarding copy.
- `completeOnboarding()` writes `settings.isConfigured = true` without checking location, prayer-time, and AlarmKit readiness immediately before the write.
- Calculation method summary is shown by default during location setup.
- Onboarding uses plain grouped-card styling instead of the app's dawn background, contrast overlay, and glass surfaces.
- `ScheduleManager.shouldBlockOnboarding(on:)` blocks notifications but does not block denied/unavailable AlarmKit for repair routing.

Relevant code areas:

- `Subh/App/OnboardingPreviewModels.swift`: step and readiness presentation models.
- `Subh/App/OnboardingViewModel.swift`: step navigation, readiness, permission actions, completion guard, onboarding copy.
- `Subh/App/OnboardingView.swift`: step layout, permission rows, ready/blocked state, read-only hero preview, accessibility behavior.
- `Subh/Core/Services/BootstrapEvaluator.swift` and `Subh/Core/Services/ScheduleService.swift`: repair routing and permission blocking semantics.
- `Subh/Core/Utilities/Strings.swift` and `Info.plist`: onboarding and purpose-string copy.
- `Subh/Features/Home/SubhHomeView.swift`, `Subh/Features/Home/MorningHomePresentation.swift`, and shared glass/typography components: visual language to reuse without changing Home behavior.
- `SubhTests`: focused readiness and blocking behavior coverage.

## Goals / Non-Goals

**Goals:**

- Keep onboarding to no more than four required screens.
- Make completion require location readiness, prayer-time readiness, and AlarmKit authorization.
- Keep notifications visible as recommended but non-blocking.
- Remove onboarding notification-fallback language.
- Preserve manual city fallback and request location only after the user taps the location CTA.
- Hide calculation-method selection during normal onboarding.
- Present value and ready screens with a read-only Home-hero-like wake preview using shared Subh visual language.
- Add focused tests for readiness, notifications non-blocking behavior, AlarmKit blocking behavior, and completion guard logic.

**Non-Goals:**

- Do not change alarm scheduling semantics, notification delivery semantics, or prayer-time calculation rules.
- Do not add fasting, Tahajjud, Ramadan, Qada, or wake-offset onboarding steps.
- Do not change persistence ownership or add a second onboarding completion flag.
- Do not redesign Home, Day detail, Settings, or the interactive Home hero.
- Do not remove existing notification fallback scheduling outside onboarding; that remains a follow-up reliability doctrine question.

## Decisions

1. Add pure onboarding readiness state alongside the existing view model.

   Rationale: The readiness contract is important enough to test directly. A small `OnboardingReadiness`/`OnboardingBlockedReason`/`OnboardingReadyState` model keeps the rules explicit without introducing persisted state or a parallel morning engine.

   Alternative considered: Put all readiness checks inline in SwiftUI views. Rejected because completion preconditions and repair routing need auditable, testable rules.

2. Treat `alarmKitState == .authorized` as the only AlarmKit-ready onboarding state.

   Rationale: The spec explicitly says denied, restricted, unavailable, and not determined must not reach "Your first wake is ready." The simulator remains blocked unless a separate explicit test fixture is introduced later.

   Alternative considered: Preserve simulator notification fallback for local convenience. Rejected because the attached spec calls for production-facing copy and onboarding completion to be strict.

3. Keep notifications in the Reliability screen but remove them from completion readiness.

   Rationale: Notifications support reminders and schedule updates but are not a wake fallback in onboarding. Denial should be clear and humane, not blocking.

   Alternative considered: Skip the notification row entirely once AlarmKit is authorized. Rejected because the spec still recommends a visible optional row.

4. Use an onboarding-specific read-only hero preview rather than extracting the private Home hero wholesale.

   Rationale: Home hero extraction would be larger and riskier because it owns live wake adjustment, quick mode selection, and navigation. A small onboarding preview can reuse the same display model, `MorningHeroPrimaryWakeRow`, `FajrWindowRangeVisual`, `MorningHeroFadingRelationText`, `MorningHeroMetrics`, glass surfaces, and typography while disabling interaction.

   Alternative considered: Copy the full `TomorrowMorningHero`. Rejected to avoid a large fork that will drift.

5. Tighten repair routing through permission blocking without changing delivery planning.

   Rationale: Configured users who lose AlarmKit should return to onboarding repair. Notifications alone should not force repair.

   Alternative considered: Change scheduler fallback policy now. Rejected as out of scope for this onboarding v1 change.

## Risks / Trade-offs

- AlarmKit unavailable on Simulator will block real onboarding completion -> Mitigation: document validation limits and keep tests focused on pure readiness and copy; a separate explicit debug fixture can be proposed later if needed.
- Home hero component reuse may expose compile coupling to Home display types -> Mitigation: use only internal shared pieces already used across app code and keep the onboarding display adapter small.
- Dynamic Type can overcrowd permission rows and hero content -> Mitigation: use `ViewThatFits`, vertical button stacking where needed, glass surfaces without fixed heights, and existing hero metrics.
- Bootstrap repair routing may surprise users who previously completed with notification fallback only -> Mitigation: this is the intended reliability correction; persisted settings remain intact and repair asks only for the missing required permission.
- Prayer-time readiness depends on the active schedule window being populated -> Mitigation: preserve existing schedule refresh behavior and request a refresh when location and AlarmKit readiness are present but the window is empty.
