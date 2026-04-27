# Design

## Approach
Keep the current gradient/glass identity and improve information structure inside existing screens. Presentation logic should remain in presentation/model helpers where possible, while SwiftUI views focus on layout.

## Daily Details
- Replace the ambiguous “Fajr 4:46 AM” footer under the wake time with a structured Fajr support window/timeline.
- Show:
  - Fajr starts
  - Wake
  - Supported Fajr end, with provider/trust phrasing such as “based on sunrise for this date”
  - Rule, such as “Wake 30 min before supported Fajr end”
- Use human labels:
  - “Fajr support window”
  - “supported Fajr wake window”
  - “daily Fajr morning plan”
  - “based on sunrise for this date”
- Add a wake delivery row using existing scheduling mode:
  - “Using AlarmKit”
  - “Using notification fallback”
  - “Wake delivery not ready” when blocked/none

## Home
- Preserve the centered hero and glass cards.
- Add top safe-area-aware spacing above the hero/card stack so chart/header text cannot sit under the status area or Dynamic Island.
- Increase bottom content padding so the floating settings button does not cover forecast rows.
- Clarify Weekly Fajrcast as a wake-time pattern surface:
  - add subtle “Wake time” labeling,
  - improve compact y-axis contrast,
  - make the selected/current day marker visually stronger.

## Settings
- Keep bottom sheet presentation and coherent Subh chrome.
- Use readable primary/secondary text instead of amber/orange as the main text color.
- Use amber/gold only as small accent where useful.
- Refactor summary rows into a clear leading layout:
  - icon,
  - title/subtitle,
  - optional status pill,
  - chevron.
- Let status pills wrap to a second line when horizontal space is tight so titles do not get squeezed.
- Make the fallback attention card actionable and plain-language:
  - title: “Wake delivery is limited” or “Wake-ups need attention”
  - subtitle: “This device is using notifications instead of AlarmKit.”
  - status: “Using fallback” or “Fix setup”
- Split Prayer & Timing summary into scannable lines for calculation method and offsets.
- Add a root Reliability section and enrich the reliability detail surface with delivery mode, notification permission, next scheduled wake, and last schedule update when available.

## Testing Strategy
- Unit/presentation tests for daily-detail copy and reliability text where feasible.
- Existing home snapshot tests continue protecting tomorrow selection and forecast ordering.
- Build and full test plan catch SwiftUI compile issues and integration regressions.
- Manual visual checks remain important for Dynamic Island, Dynamic Type, and settings readability.
