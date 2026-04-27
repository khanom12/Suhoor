## Context

`SubhHomeView` renders tomorrow, compact Weekly Fajrcast, and the compact Morningcast list from `MorningHomeSnapshot`. The compact Fajrcast currently derives its days from the current Monday-Sunday calendar week, while Morningcast intentionally starts after tomorrow from the previous cleanup pass. Settings is presented as a sheet but uses the shared image-backed `appPresentedChrome`, which brings warm/orange background tones into settings.

## Goals / Non-Goals

**Goals:**
- Make home forecast surfaces forward-looking from tomorrow.
- Keep the Fajrcast detail reachable through the Fajrcast card only.
- Make the forecast card visually consistent with the Fajrcast card.
- Use neutral settings sheet chrome with readable system text colors.

**Non-Goals:**
- No calculation or alarm scheduling changes.
- No redesign of Fajrcast detail, day detail, or settings information architecture.
- No compatibility-bound rename or persistence migration.

## Decisions

- Change `activeDaysForWeeklyFajrcast` to resolve seven active days starting at tomorrow.
- Change `MorningHomeSnapshot.shouldShowInMorningcast` to include tomorrow and exclude today.
- Add small presentation constants for the forecast title/subtitle so tests can lock the visible naming.
- Replace `HomeFloatingControls` with a single trailing `HomeSettingsFloatingControl`.
- Add a settings-specific chrome modifier that uses neutral system grouped colors instead of `WakeScreenBackground`.
- Change warning badge tone from orange to a neutral/yellow-free subdued treatment to avoid the current orange cast.

## Risks / Trade-offs

- [Risk] "Weekly Fajrcast" no longer means calendar week on home. -> Mitigation: the card still shows a clear 7-day date range and detail navigation remains available.
- [Risk] Tomorrow appears twice on home. -> Mitigation: the hero remains the primary answer; the forecast list is explicitly a 10-day sequence.
- [Risk] Settings loses visual continuity with home. -> Mitigation: keep glass grouping and typography, but use a calmer neutral background for readability.
